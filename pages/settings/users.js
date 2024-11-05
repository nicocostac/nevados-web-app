import { useState, useEffect } from 'react'
import { requireAuth } from '@/lib/auth/requireAuth'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { Edit2, Key } from 'lucide-react'
import { useAuth } from '@/lib/context/AuthContext'

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
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    firstName: '',
    lastName: '',
    phone: '',
    role: 'salesperson'
  })
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)
  const [message, setMessage] = useState(null)
  const [editingUser, setEditingUser] = useState(null)

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

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)
    setMessage(null)

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
        // Create new user with JWT claims
        const { error } = await supabase.auth.signUp({
          email: formData.email,
          password: formData.password,
          options: {
            data: {
              first_name: formData.firstName,
              last_name: formData.lastName
            },
            // Set the role in the JWT claims
            meta: {
              role: formData.role
            }
          }
        })
        
        if (error) throw error

        // Create profile after successful signup
        const { error: profileError } = await supabase
          .from('profiles')
          .insert({
            id: user.id, // ID from the newly created user
            role: formData.role,
            first_name: formData.firstName,
            last_name: formData.lastName,
            phone: formData.phone
          })

        if (profileError) throw profileError
        setMessage('User created successfully')
      }

      // Reset form and refresh users list
      setFormData({
        email: '',
        password: '',
        firstName: '',
        lastName: '',
        phone: '',
        role: 'salesperson'
      })
      setEditingUser(null)

      // Refresh users list
      const { data: updatedUsers, error: refreshError } = await supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false });

      if (refreshError) {
        console.error('Error refreshing users:', refreshError);
      } else if (updatedUsers) {
        setUsers(updatedUsers);
      }
    } catch (error) {
      setError(error.message)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Form */}
      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold mb-6">
          {editingUser ? 'Edit User' : 'Create New User'}
        </h2>
        
        {error && (
          <Alert variant="destructive" className="mb-4">{error}</Alert>
        )}
        {message && (
          <Alert className="mb-4">{message}</Alert>
        )}

        <form onSubmit={handleSubmit} className="space-y-4 max-w-md">
          <div className="grid grid-cols-2 gap-4">
            <Input
              name="firstName"
              placeholder="First Name"
              value={formData.firstName}
              onChange={(e) => setFormData(prev => ({ ...prev, firstName: e.target.value }))}
              required
            />
            <Input
              name="lastName"
              placeholder="Last Name"
              value={formData.lastName}
              onChange={(e) => setFormData(prev => ({ ...prev, lastName: e.target.value }))}
              required
            />
          </div>

          <Input
            type="email"
            name="email"
            placeholder="Email"
            value={formData.email}
            onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
            required
            disabled={editingUser}
          />

          {!editingUser && (
            <Input
              type="password"
              name="password"
              placeholder="Password"
              value={formData.password}
              onChange={(e) => setFormData(prev => ({ ...prev, password: e.target.value }))}
              required
              minLength={6}
            />
          )}

          <Input
            type="tel"
            name="phone"
            placeholder="Phone"
            value={formData.phone}
            onChange={(e) => setFormData(prev => ({ ...prev, phone: e.target.value }))}
          />

          <select
            name="role"
            value={formData.role}
            onChange={(e) => setFormData(prev => ({ ...prev, role: e.target.value }))}
            className="w-full p-2 border rounded"
            required
          >
            {roles.map(role => (
              <option key={role.value} value={role.value}>
                {role.label}
              </option>
            ))}
          </select>

          <div className="flex gap-2">
            <Button type="submit" disabled={isLoading}>
              {isLoading ? 'Saving...' : editingUser ? 'Update' : 'Create'}
            </Button>
            {editingUser && (
              <Button type="button" variant="outline" onClick={() => setEditingUser(null)}>
                Cancel
              </Button>
            )}
          </div>
        </form>
      </div>

      {/* Users List */}
      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold mb-6">Users</h2>
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
                        setFormData({
                          email: user.email || '',
                          firstName: user.first_name || '',
                          lastName: user.last_name || '',
                          phone: user.phone || '',
                          role: user.role || 'salesperson',
                          password: ''
                        })
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
    </div>
  )
}

export default requireAuth(UserManagement)