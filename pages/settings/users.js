import { useState, useEffect } from 'react'
import { requireAuth } from '@/lib/auth/requireAuth'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { Edit2, Key } from 'lucide-react'
import { useAuth } from '@/lib/context/AuthContext'
import UserFormModal from '@/components/UserFormModal'

const roles = [
  { value: 'admin', label: 'Administrator' },
  { value: 'manager', label: 'Manager' },
  { value: 'salesperson', label: 'Salesperson' },
  { value: 'support', label: 'Support' }
]

function UserManagement() {
  const { user: currentUser } = useAuth()
  const [users, setUsers] = useState([])
  const [userRole, setUserRole] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingUser, setEditingUser] = useState(null)
  const [message, setMessage] = useState(null)

  // Debug current user
  useEffect(() => {
    console.log('AuthContext user:', currentUser)
  }, [currentUser])

  // Fetch current user's role and users list
  useEffect(() => {
    async function fetchData() {
      if (currentUser?.id) {
        console.log('Fetching role for user:', currentUser.id)
        
        // Get user's role
        const { data: profile, error } = await supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single()

        if (error) {
          console.error('Error fetching profile:', error)
        } else {
          console.log('Fetched profile:', profile)
          if (profile?.role) {
            setUserRole(profile.role)
            
            // If admin or manager, fetch all users
            if (['admin', 'manager'].includes(profile.role)) {
              console.log('Fetching users as', profile.role)
              const { data: users, error: usersError } = await supabase
                .from('profiles')
                .select('*')
                .order('created_at', { ascending: false });

              if (usersError) {
                console.error('Error fetching users:', usersError)
              } else {
                console.log('Fetched users:', users)
                setUsers(users)
              }
            }
          }
        }
      }
    }
    fetchData()
  }, [currentUser?.id])

  // Add debug log before access check
  console.log('Current state:', {
    currentUser: currentUser?.id,
    userRole,
    hasPermission: ['admin', 'manager'].includes(userRole)
  })

  // Show loading state while role is being fetched
  if (!userRole) {
    return (
      <div className="p-4">
        <div className="text-center">Loading user permissions...</div>
      </div>
    )
  }

  // If not admin or manager, show access denied
  if (!['admin', 'manager'].includes(userRole)) {
    return (
      <div className="p-4">
        <Alert variant="destructive">
          You don't have permission to access this page.
          <br />
          Current role: {userRole}
        </Alert>
      </div>
    )
  }

  const handleSubmit = async (formData) => {
    try {
      if (editingUser) {
        // Update existing user
        const { error } = await supabase
          .from('profiles')
          .update({
            first_name: formData.firstName,
            last_name: formData.lastName,
            phone: formData.phone,
            role: formData.role
          })
          .eq('id', editingUser.id)

        if (error) throw error
        setMessage('User updated successfully')
      } else {
        // Create new user
        const { data: authData, error: signUpError } = await supabase.auth.signUp({
          email: formData.email,
          password: formData.password,
          options: {
            data: {
              first_name: formData.firstName,
              last_name: formData.lastName
            },
            meta: {
              role: formData.role
            }
          }
        })
        
        if (signUpError) throw signUpError

        // Create profile after successful signup using the new user's ID
        const { error: profileError } = await supabase
          .from('profiles')
          .insert({
            id: authData.user.id,
            email: formData.email,
            role: formData.role,
            first_name: formData.firstName,
            last_name: formData.lastName,
            phone: formData.phone
          })

        if (profileError) throw profileError
        setMessage('User created successfully')
      }

      // Refresh users list
      const { data: updatedUsers, error: refreshError } = await supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false })

      if (refreshError) {
        console.error('Error refreshing users:', refreshError)
      } else {
        setUsers(updatedUsers)
      }

      // Close modal and reset editing state
      setIsModalOpen(false)
      setEditingUser(null)
    } catch (error) {
      throw error
    }
  }

  return (
    <div className="space-y-6">
      {message && (
        <Alert className="mb-4">{message}</Alert>
      )}

      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Users</h2>
        <Button onClick={() => {
          setEditingUser(null)
          setIsModalOpen(true)
        }}>
          Add User
        </Button>
      </div>

      <div className="bg-white shadow rounded-lg p-6">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead>
              <tr>
                <th className="px-6 py-3 text-left">Name</th>
                <th className="px-6 py-3 text-left">Email</th>
                <th className="px-6 py-3 text-left">Role</th>
                <th className="px-6 py-3 text-left">Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user.id} className="border-t">
                  <td className="px-6 py-4">
                    {user.first_name} {user.last_name}
                  </td>
                  <td className="px-6 py-4">{user.email}</td>
                  <td className="px-6 py-4">
                    {roles.find(r => r.value === user.role)?.label}
                  </td>
                  <td className="px-6 py-4">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => {
                        setEditingUser(user)
                        setIsModalOpen(true)
                      }}
                    >
                      <Edit2 className="h-4 w-4" />
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <UserFormModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false)
          setEditingUser(null)
        }}
        onSubmit={handleSubmit}
        editingUser={editingUser}
        roles={roles}
      />
    </div>
  )
}

export default requireAuth(UserManagement)