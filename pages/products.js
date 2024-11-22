import { useState, useEffect } from 'react'
import { requireAuth } from '@/lib/auth/requireAuth'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Alert } from '@/components/ui/alert'
import { Edit2, Trash2, Plus } from 'lucide-react'
import { useAuth } from '@/lib/context/AuthContext'
import ProductFormModal from '@/components/ProductFormModal'
import { formatCurrency } from '@/lib/utils/format'

function ProductManagement() {
  const { user: currentUser } = useAuth()
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [userRole, setUserRole] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingProduct, setEditingProduct] = useState(null)
  const [message, setMessage] = useState(null)

  // Helper function to format dates consistently
  const formatDate = (dateString) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('es-CL', { timeZone: 'UTC' })
  }

  // Helper function to get the next future price
  const getNextFuturePrice = (futurePrices) => {
    if (!futurePrices || futurePrices.length === 0) return null;
    
    // Sort future prices by start date and get the closest one
    return futurePrices.sort((a, b) => 
      new Date(a.start_date) - new Date(b.start_date)
    )[0];
  }

  const fetchProducts = async () => {
    try {
      const { data: products, error } = await supabase
        .from('products')
        .select(`
          *,
          product_categories (
            name
          ),
          product_prices (
            id,
            price,
            start_date,
            end_date
          )
        `)
        .order('name');

      if (error) throw error;

      const currentDate = new Date();
      const formattedProducts = products.map(product => {
        // Sort prices by start_date in descending order
        const sortedPrices = product.product_prices.sort((a, b) => 
          new Date(b.start_date) - new Date(a.start_date)
        );

        // Find current price (price where current date falls between start and end date)
        const currentPrice = sortedPrices.find(price => {
          const startDate = new Date(price.start_date);
          const endDate = price.end_date ? new Date(price.end_date) : null;
          return startDate <= currentDate && (!endDate || endDate >= currentDate);
        });

        // Find future prices (start date is after current date)
        const futurePrices = sortedPrices.filter(price => 
          new Date(price.start_date) > currentDate
        );

        // Find historical prices (end date is before current date)
        const historicalPrices = sortedPrices.filter(price => 
          price.end_date && new Date(price.end_date) < currentDate
        );

        return {
          ...product,
          currentPrice: currentPrice ? currentPrice.price : 0,
          currentPriceId: currentPrice ? currentPrice.id : null,
          price_start_date: currentPrice ? currentPrice.start_date : null,
          futurePrices,
          historicalPrices
        };
      });

      setProducts(formattedProducts);
    } catch (error) {
      console.error('Error fetching products:', error);
    }
  };

  // Fetch current user's role, categories and products list
  useEffect(() => {
    async function fetchData() {
      if (currentUser?.id) {
        // Get user's role
        const { data: profile, error } = await supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single()

        if (error) {
          console.error('Error fetching profile:', error)
        } else {
          setUserRole(profile.role)
          
          // Fetch categories
          const { data: categories, error: categoriesError } = await supabase
            .from('product_categories')
            .select('*')
            .order('name')

          if (categoriesError) {
            console.error('Error fetching categories:', categoriesError)
          } else {
            setCategories(categories)
          }

          await fetchProducts();
        }
      }
    }
    fetchData()
  }, [currentUser?.id])

  // Add event listener for product updates
  useEffect(() => {
    const handleProductsUpdate = () => {
      fetchProducts();
    };

    window.addEventListener('productsUpdated', handleProductsUpdate);
    return () => window.removeEventListener('productsUpdated', handleProductsUpdate);
  }, []);

  // Show loading state while role is being fetched
  if (!userRole) {
    return <div className="p-4 text-center">Loading...</div>
  }

  // Only admin and manager can manage products
  if (!['admin', 'manager'].includes(userRole)) {
    return (
      <div className="p-4">
        <Alert variant="destructive">
          You don't have permission to manage products.
        </Alert>
      </div>
    )
  }

  const isAdmin = userRole === 'admin';

  const handleSubmit = async (formData) => {
    try {
      console.log('Handling form submission:', formData)

      if (editingProduct) {
        // Update existing product
        const { error } = await supabase
          .from('products')
          .update({
            name: formData.name,
            description: formData.description,
            category_id: formData.category_id,
            unit_of_sale: formData.unit_of_sale,
            status: formData.status
          })
          .eq('id', editingProduct.id)

        if (error) throw error

        // Update prices if user is admin
        if (isAdmin) {
          // Process each price in the form
          for (const price of formData.prices) {
            if (price.id) {
              // Update existing price if changed
              const { error } = await supabase
                .from('product_prices')
                .update({
                  price: parseFloat(price.price),
                  start_date: price.start_date,
                  end_date: price.end_date,
                  updated_by: currentUser.id
                })
                .eq('id', price.id)

              if (error) throw error
            } else {
              // Check for overlapping dates
              const { data: overlappingPrices, error: overlapError } = await supabase
                .from('product_prices')
                .select('id')
                .eq('product_id', editingProduct.id)
                .or(`start_date.lte.${price.end_date || '9999-12-31'},and(end_date.gte.${price.start_date},end_date.is.null)`)

              if (overlapError) throw overlapError

              // Delete overlapping prices
              if (overlappingPrices.length > 0) {
                const { error: deleteError } = await supabase
                  .from('product_prices')
                  .delete()
                  .in('id', overlappingPrices.map(p => p.id))

                if (deleteError) throw deleteError
              }

              // Insert new price
              const { error } = await supabase
                .from('product_prices')
                .insert({
                  product_id: editingProduct.id,
                  price: parseFloat(price.price),
                  start_date: price.start_date,
                  end_date: price.end_date,
                  created_by: currentUser.id
                })

              if (error) throw error
            }
          }
        }

        setMessage('Product updated successfully')
      } else {
        // Create new product
        const { data: newProduct, error } = await supabase
          .from('products')
          .insert({
            name: formData.name,
            description: formData.description,
            category_id: formData.category_id,
            unit_of_sale: formData.unit_of_sale,
            status: formData.status
          })
          .select()
          .single()

        if (error) throw error

        // Insert initial price
        if (formData.prices.length > 0) {
          const initialPrice = formData.prices[0]
          const { error: priceError } = await supabase
            .from('product_prices')
            .insert({
              product_id: newProduct.id,
              price: parseFloat(initialPrice.price),
              start_date: initialPrice.start_date,
              end_date: initialPrice.end_date,
              created_by: currentUser.id
            })

          if (priceError) throw priceError
        }

        setMessage('Product created successfully')
      }

      await fetchProducts()
      setIsModalOpen(false)
      setEditingProduct(null)
    } catch (error) {
      console.error('Error handling form submission:', error)
      setMessage(error.message)
    }
  }

  const handleDelete = async (productId) => {
    if (!window.confirm('Are you sure you want to delete this product?')) {
      return
    }

    try {
      const { error } = await supabase
        .from('products')
        .delete()
        .eq('id', productId)

      if (error) throw error

      setProducts(products.filter(p => p.id !== productId))
      setMessage('Product deleted successfully')
    } catch (error) {
      console.error('Error deleting product:', error)
    }
  }

  return (
    <div className="space-y-6">
      {message && (
        <Alert className="mb-4">{message}</Alert>
      )}

      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Products</h2>
        <Button onClick={() => {
          setEditingProduct(null)
          setIsModalOpen(true)
        }}>
          <Plus className="h-4 w-4 mr-2" />
          Add Product
        </Button>
      </div>

      <div className="bg-white shadow rounded-lg p-6">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead>
              <tr>
                <th className="px-6 py-3 text-left">Name</th>
                <th className="px-6 py-3 text-left">Category</th>
                <th className="px-6 py-3 text-left">Current Price</th>
                <th className="px-6 py-3 text-left">Unit</th>
                <th className="px-6 py-3 text-left">Status</th>
                <th className="px-6 py-3 text-left">Actions</th>
              </tr>
            </thead>
            <tbody>
              {products.map((product) => (
                <tr key={product.id} className="border-t">
                  <td className="px-6 py-4">{product.name}</td>
                  <td className="px-6 py-4">{product.product_categories?.name}</td>
                  <td className="px-6 py-4">
                    <div className="flex flex-col">
                      {product.currentPrice ? (
                        <>
                          <div>
                            <span className="font-medium">{formatCurrency(product.currentPrice)}</span>
                            <span className="text-sm text-gray-500 ml-2">
                              (desde {formatDate(product.price_start_date)})
                            </span>
                          </div>
                          {product.futurePrices && product.futurePrices.length > 0 && (
                            <div className="text-sm mt-1">
                              {(() => {
                                const nextPrice = getNextFuturePrice(product.futurePrices);
                                if (nextPrice) {
                                  return (
                                    <span className="text-blue-600">
                                      Próximo precio: {formatCurrency(nextPrice.price)} 
                                      <span className="text-gray-500"> (desde {formatDate(nextPrice.start_date)})</span>
                                    </span>
                                  );
                                }
                              })()}
                            </div>
                          )}
                        </>
                      ) : (
                        <span className="text-gray-500">Sin precio definido</span>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4">{product.unit_of_sale}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 rounded text-sm ${
                      product.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                    }`}>
                      {product.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      <Button
                        variant="outline"
                        size="icon"
                        onClick={() => {
                          setEditingProduct(product)
                          setIsModalOpen(true)
                        }}
                      >
                        <Edit2 className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="outline"
                        size="icon"
                        onClick={() => handleDelete(product.id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <ProductFormModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false)
          setEditingProduct(null)
        }}
        onSubmit={handleSubmit}
        editingProduct={editingProduct}
        categories={categories}
      />
    </div>
  )
}

export default requireAuth(ProductManagement)