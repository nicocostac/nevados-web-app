import { useState, useEffect } from 'react'
import { requireAuth } from '@/lib/auth/requireAuth'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Alert } from '@/components/ui/alert'
import { Edit2, Trash2, Plus } from 'lucide-react'
import { useAuth } from '@/lib/context/AuthContext'
import CategoryFormModal from '@/components/CategoryFormModal'

function CategoryManagement() {
  const { user: currentUser } = useAuth()
  const [categories, setCategories] = useState([])
  const [userRole, setUserRole] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingCategory, setEditingCategory] = useState(null)
  const [message, setMessage] = useState(null)

  // Fetch current user's role and categories list
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
        }
      }
    }
    fetchData()
  }, [currentUser?.id])

  // Show loading state while role is being fetched
  if (!userRole) {
    return <div className="p-4 text-center">Loading...</div>
  }

  // Only admin and manager can manage categories
  if (!['admin', 'manager'].includes(userRole)) {
    return (
      <div className="p-4">
        <Alert variant="destructive">
          You don't have permission to manage categories.
        </Alert>
      </div>
    )
  }

  const handleSubmit = async (formData) => {
    try {
      if (editingCategory) {
        // Update existing category
        const { error } = await supabase
          .from('product_categories')
          .update(formData)
          .eq('id', editingCategory.id)

        if (error) throw error
        setMessage('Category updated successfully')
      } else {
        // Create new category
        const { error } = await supabase
          .from('product_categories')
          .insert([formData])

        if (error) throw error
        setMessage('Category created successfully')
      }

      // Refresh categories list
      const { data: updatedCategories, error: refreshError } = await supabase
        .from('product_categories')
        .select('*')
        .order('name')

      if (refreshError) {
        console.error('Error refreshing categories:', refreshError)
      } else {
        setCategories(updatedCategories)
      }

      // Close modal and reset editing state
      setIsModalOpen(false)
      setEditingCategory(null)
    } catch (error) {
      throw error
    }
  }

  const handleDelete = async (categoryId) => {
    if (!window.confirm('Are you sure you want to delete this category? Products in this category will be uncategorized.')) {
      return
    }

    try {
      const { error } = await supabase
        .from('product_categories')
        .delete()
        .eq('id', categoryId)

      if (error) throw error

      setCategories(categories.filter(c => c.id !== categoryId))
      setMessage('Category deleted successfully')
    } catch (error) {
      console.error('Error deleting category:', error)
    }
  }

  return (
    <div className="space-y-6">
      {message && (
        <Alert className="mb-4">{message}</Alert>
      )}

      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Product Categories</h2>
        <Button onClick={() => {
          setEditingCategory(null)
          setIsModalOpen(true)
        }}>
          <Plus className="h-4 w-4 mr-2" />
          Add Category
        </Button>
      </div>

      <div className="bg-white shadow rounded-lg p-6">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead>
              <tr>
                <th className="px-6 py-3 text-left">Name</th>
                <th className="px-6 py-3 text-left">Description</th>
                <th className="px-6 py-3 text-left">Actions</th>
              </tr>
            </thead>
            <tbody>
              {categories.map((category) => (
                <tr key={category.id} className="border-t">
                  <td className="px-6 py-4">{category.name}</td>
                  <td className="px-6 py-4">{category.description}</td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setEditingCategory(category)
                          setIsModalOpen(true)
                        }}
                      >
                        <Edit2 className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDelete(category.id)}
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

      <CategoryFormModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false)
          setEditingCategory(null)
        }}
        onSubmit={handleSubmit}
        editingCategory={editingCategory}
      />
    </div>
  )
}

export default requireAuth(CategoryManagement) 