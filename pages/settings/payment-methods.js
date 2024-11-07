import { useState, useEffect } from 'react'
import { requireAuth } from '@/lib/auth/requireAuth'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Plus, Edit2 } from 'lucide-react'
import { Alert } from '@/components/ui/alert'
import PaymentMethodFormModal from '@/components/PaymentMethodFormModal'
import { useAuth } from '@/lib/context/AuthContext'

function PaymentMethodManagement() {
  const { user: currentUser } = useAuth()
  const [methods, setMethods] = useState([])
  const [userRole, setUserRole] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingMethod, setEditingMethod] = useState(null)
  const [message, setMessage] = useState(null)

  // Fetch current user's role and payment methods list
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
          
          // Only fetch payment methods if user is admin
          if (profile.role === 'admin') {
            const { data: methods, error: methodsError } = await supabase
              .from('payment_methods')
              .select('*')
              .order('name')

            if (methodsError) {
              console.error('Error fetching payment methods:', methodsError)
            } else {
              setMethods(methods)
            }
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

  // Only admin can manage payment methods
  if (!['admin'].includes(userRole)) {
    return (
      <div className="p-4">
        <Alert variant="destructive">
          You don't have permission to manage payment methods.
        </Alert>
      </div>
    )
  }

  const handleSubmit = async (formData) => {
    try {
      if (editingMethod) {
        const { error } = await supabase
          .from('payment_methods')
          .update({
            name: formData.name,
            description: formData.description,
            status: formData.status,
            updated_at: new Date().toISOString()
          })
          .eq('id', editingMethod.id)

        if (error) throw error
        setMessage('Payment method updated successfully')
      } else {
        const { error } = await supabase
          .from('payment_methods')
          .insert([formData])

        if (error) throw error
        setMessage('Payment method created successfully')
      }

      // Refresh payment methods list
      const { data: updatedMethods, error: refreshError } = await supabase
        .from('payment_methods')
        .select('*')
        .order('name')

      if (refreshError) {
        console.error('Error refreshing payment methods:', refreshError)
      } else {
        setMethods(updatedMethods)
      }

      // Close modal and reset editing state
      setIsModalOpen(false)
      setEditingMethod(null)
    } catch (error) {
      console.error('Error saving payment method:', error)
    }
  }

  return (
    <div className="space-y-6">
      {message && (
        <Alert className="mb-4">{message}</Alert>
      )}

      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Payment Methods</h2>
        <Button onClick={() => {
          setEditingMethod(null)
          setIsModalOpen(true)
        }}>
          <Plus className="h-4 w-4 mr-2" />
          Add Method
        </Button>
      </div>

      <div className="bg-white shadow rounded-lg p-6">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead>
              <tr>
                <th className="px-6 py-3 text-left">Name</th>
                <th className="px-6 py-3 text-left">Description</th>
                <th className="px-6 py-3 text-left">Status</th>
                <th className="px-6 py-3 text-left">Actions</th>
              </tr>
            </thead>
            <tbody>
              {methods.map((method) => (
                <tr key={method.id} className="border-t">
                  <td className="px-6 py-4">{method.name}</td>
                  <td className="px-6 py-4">{method.description}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 rounded text-sm ${
                      method.status === 'active' 
                        ? 'bg-green-100 text-green-800' 
                        : 'bg-red-100 text-red-800'
                    }`}>
                      {method.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setEditingMethod(method)
                          setIsModalOpen(true)
                        }}
                      >
                        <Edit2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <PaymentMethodFormModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false)
          setEditingMethod(null)
        }}
        onSubmit={handleSubmit}
        editingMethod={editingMethod}
      />
    </div>
  )
}

export default requireAuth(PaymentMethodManagement)