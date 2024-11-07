import { useState, useEffect } from 'react'
import { requireAuth } from '@/lib/auth/requireAuth'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Alert } from '@/components/ui/alert'
import { Edit2, Trash2, Plus } from 'lucide-react'
import { useAuth } from '@/lib/context/AuthContext'
import ProductFormModal from '@/components/ProductFormModal'

function ProductManagement() {
  const { user: currentUser } = useAuth()
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [userRole, setUserRole] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingProduct, setEditingProduct] = useState(null)
  const [message, setMessage] = useState(null)

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

          // Fetch products with category details
          const { data: products, error: productsError } = await supabase
            .from('products')
            .select(`
              *,
              product_categories (
                name
              )
            `)
            .order('name')

          if (productsError) {
            console.error('Error fetching products:', productsError)
          } else {
            setProducts(products)
          }
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
      if (editingProduct) {
        // Update existing product
        const { error } = await supabase
          .from('products')
          .update(formData)
          .eq('id', editingProduct.id)

        if (error) throw error
        setMessage('Product updated successfully')
      } else {
        // Create new product
        const { error } = await supabase
          .from('products')
          .insert([formData])

        if (error) throw error
        setMessage('Product created successfully')
      }

      // Refresh products list
      const { data: updatedProducts, error: refreshError } = await supabase
        .from('products')
        .select(`
          *,
          product_categories (
            name
          )
        `)
        .order('name')

      if (refreshError) {
        console.error('Error refreshing products:', refreshError)
      } else {
        setProducts(updatedProducts)
      }

      // Close modal and reset editing state
      setIsModalOpen(false)
      setEditingProduct(null)
    } catch (error) {
      throw error
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
                <th className="px-6 py-3 text-left">Price</th>
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
                  <td className="px-6 py-4">${product.default_price.toFixed(2)}</td>
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
    </div>
  )
}

export default requireAuth(ProductManagement) 