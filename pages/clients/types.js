import { useState, useEffect } from 'react'
import { requireAuth } from '@/lib/auth/requireAuth'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Alert } from '@/components/ui/alert'
import { Edit2, Trash2, Plus } from 'lucide-react'
import { useAuth } from '@/lib/context/AuthContext'
import ClientTypeFormModal from '@/components/ClientTypeFormModal'

function ClientTypeManagement() {
  const { user: currentUser } = useAuth()
  const [types, setTypes] = useState([])
  const [userRole, setUserRole] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingType, setEditingType] = useState(null)
  const [message, setMessage] = useState(null)

  // Fetch current user's role and client types list
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
          
          // Fetch client types
          const { data: types, error: typesError } = await supabase
            .from('client_types')
            .select('*')
            .order('name')

          if (typesError) {
            console.error('Error fetching client types:', typesError)
          } else {
            setTypes(types)
          }
        }
      }
    }
    fetchData()
  }, [currentUser?.id])

  // Show loading state while role is being fetched
  if (!userRole) {
    return <div className="p-4">Loading...</div>
  }

  // Only admin and manager can manage client types
  if (!['admin', 'manager'].includes(userRole)) {
    return (
      <div className="p-4">
        <Alert variant="destructive">
          You don't have permission to manage client types.
        </Alert>
      </div>
    )
  }

  const handleSubmit = async (formData) => {
    try {
      if (editingType) {
        // Update existing type
        const { error } = await supabase
          .from('client_types')
          .update(formData)
          .eq('id', editingType.id)

        if (error) throw error
        setMessage('Client type updated successfully')
      } else {
        // Create new type
        const { error } = await supabase
          .from('client_types')
          .insert([formData])

        if (error) throw error
        setMessage('Client type created successfully')
      }

      // Refresh types list
      const { data: updatedTypes, error: refreshError } = await supabase
        .from('client_types')
        .select('*')
        .order('name')

      if (refreshError) {
        console.error('Error refreshing client types:', refreshError)
      } else {
        setTypes(updatedTypes)
      }

      // Close modal and reset editing state
      setIsModalOpen(false)
      setEditingType(null)
    } catch (error) {
      throw error
    }
  }

  const handleDelete = async (typeId) => {
    if (!window.confirm('Are you sure you want to delete this client type?')) {
      return
    }

    try {
      const { error } = await supabase
        .from('client_types')
        .delete()
        .eq('id', typeId)

      if (error) throw error

      setTypes(types.filter(t => t.id !== typeId))
      setMessage('Client type deleted successfully')
    } catch (error) {
      console.error('Error deleting client type:', error)
    }
  }

  return (
    <div className="space-y-6">
      {message && (
        <Alert className="mb-4">{message}</Alert>
      )}

      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Client Types</h2>
        <Button onClick={() => {
          setEditingType(null)
          setIsModalOpen(true)
        }}>
          <Plus className="h-4 w-4 mr-2" />
          Add Type
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
              {types.map((type) => (
                <tr key={type.id} className="border-t">
                  <td className="px-6 py-4">
                    <span className="capitalize">{type.name}</span>
                  </td>
                  <td className="px-6 py-4">{type.description}</td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setEditingType(type)
                          setIsModalOpen(true)
                        }}
                      >
                        <Edit2 className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDelete(type.id)}
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

      <ClientTypeFormModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false)
          setEditingType(null)
        }}
        onSubmit={handleSubmit}
        editingType={editingType}
      />
    </div>
  )
}

export default requireAuth(ClientTypeManagement) 