import { useState, useEffect } from 'react'
import { requireAuth } from '@/lib/auth/requireAuth'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Alert } from '@/components/ui/alert'
import { Edit2, Trash2, Plus, History } from 'lucide-react'
import { useAuth } from '@/lib/context/AuthContext'
import ProductFormModal from '@/components/ProductFormModal'
import PriceHistoryModal from '@/components/PriceHistoryModal'
import { formatCurrency } from '@/lib/utils/format'

function ProductManagement() {
  const { user: currentUser } = useAuth()
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [userRole, setUserRole] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isPriceHistoryModalOpen, setIsPriceHistoryModalOpen] = useState(false)
  const [editingProduct, setEditingProduct] = useState(null)
  const [message, setMessage] = useState(null)

  // Helper function to format dates consistently
  const formatDate = (dateString) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-GB', { timeZone: 'UTC' })
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
          default_price: currentPrice ? currentPrice.price : null,
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

  const handleSubmit = async (formData) => {
    try {
      console.log('Handling form submission:', formData)

      if (editingProduct) {
        // Update existing product
        const { error } = await supabase
          .from('products')
          .update({
            name: formData.name,
            category_id: formData.category_id,
            unit_of_sale: formData.unit_of_sale,
            status: formData.status,
            default_price: 0  // Set to 0 since we're using product_prices table
          })
          .eq('id', editingProduct.id)

        if (error) throw error

        // Update price if provided
        console.log('Updating price for existing product:', formData.default_price)
        const { error: priceError } = await supabase
          .rpc('update_product_price', {
            p_product_id: editingProduct.id,
            new_price: parseInt(formData.default_price || 0, 10),
            price_start_date: formData.price_start_date || new Date().toISOString().split('T')[0],
            user_id: currentUser.id
          })

        if (priceError) {
          console.error('Price update error:', priceError)
          throw priceError
        }

        setMessage('Product updated successfully')
      } else {
        // Create new product
        const { data: newProduct, error } = await supabase
          .from('products')
          .insert({
            name: formData.name,
            category_id: formData.category_id,
            unit_of_sale: formData.unit_of_sale,
            status: formData.status,
            default_price: 0  // Set to 0 since we're using product_prices table
          })
          .select()
          .single()

        if (error) throw error

        // Create initial price record
        console.log('Creating initial price for new product:', formData.default_price)
        const { error: priceError } = await supabase
          .rpc('update_product_price', {
            p_product_id: newProduct.id,
            new_price: parseInt(formData.default_price || 0, 10),
            price_start_date: formData.price_start_date || new Date().toISOString().split('T')[0],
            user_id: currentUser.id
          })

        if (priceError) {
          console.error('Price creation error:', priceError)
          throw priceError
        }

        setMessage('Product created successfully')
      }

      // Refresh the products list
      await fetchProducts()

      // Close modal and reset editing state
      setIsModalOpen(false)
      setEditingProduct(null)
    } catch (error) {
      console.error('Error saving product:', error)
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
                      {product.default_price ? (
                        <>
                          <span>{formatCurrency(product.default_price)}</span>
                          <span className="text-sm text-gray-500">
                            since {formatDate(product.price_start_date)}
                          </span>
                        </>
                      ) : (
                        <span className="text-gray-500">No current price</span>
                      )}
                      {product.futurePrices.length > 0 && (
                        <div className="mt-1 text-sm text-blue-600">
                          Next: {formatCurrency(product.futurePrices[0].price)}
                          <span className="text-gray-500 ml-1">
                            (from {formatDate(product.futurePrices[0].start_date)})
                          </span>
                        </div>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4">{product.unit_of_sale}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 rounded text-sm ${
                      product.status === 'active' 
                        ? 'bg-green-100 text-green-800' 
                        : 'bg-red-100 text-red-800'
                    }`}>
                      {product.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setEditingProduct(product)
                          setIsModalOpen(true)
                        }}
                      >
                        <Edit2 className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setEditingProduct(product)
                          setIsPriceHistoryModalOpen(true)
                        }}
                      >
                        <History className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDelete(product.id)}
                      >
                        <Trash2 className="h-4 w-4 text-red-500" />
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

      {isPriceHistoryModalOpen && editingProduct && (
        <PriceHistoryModal
          isOpen={isPriceHistoryModalOpen}
          onClose={() => setIsPriceHistoryModalOpen(false)}
          product={editingProduct}
          onSave={async (updatedPrices) => {
            try {
              // Handle each price update
              for (const price of updatedPrices) {
                if (price.id) {
                  // Update existing price
                  const { error } = await supabase
                    .from('product_prices')
                    .update({
                      price: price.price,
                      start_date: price.start_date,
                      end_date: price.end_date,
                      updated_by: currentUser.id
                    })
                    .eq('id', price.id)

                  if (error) throw error
                }
              }

              // Refresh products list
              await fetchProducts()

              setMessage('Price history updated successfully')
              setIsPriceHistoryModalOpen(false)
              setEditingProduct(null)
            } catch (error) {
              console.error('Error updating price history:', error)
              setMessage(error.message)
            }
          }}
          onSubmit={fetchProducts}
          setError={setMessage}
          supabase={supabase}
        />
      )}
    </div>
  )
}

export default requireAuth(ProductManagement)