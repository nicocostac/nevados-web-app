import { useAuth } from '@/lib/context/AuthContext'
import { useRouter } from 'next/router'
import { supabase } from '@/lib/supabaseClient'
import Sidebar from './Sidebar'

export default function Layout({ children }) {
  const { user } = useAuth()
  const router = useRouter()

  const handleLogout = async () => {
    try {
      const { error } = await supabase.auth.signOut()
      if (error) throw error
      router.replace('/login')
    } catch (error) {
      console.error('Error logging out:', error)
    }
  }

  // Don't show the layout on auth pages
  if (['/login', '/reset-password', '/update-password'].includes(router.pathname)) {
    return children
  }

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-full mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900">Nevados App</h1>
          {user && (
            <div className="flex items-center space-x-4">
              <span className="text-gray-600">{user.email}</span>
              <button
                onClick={handleLogout}
                className="text-gray-600 hover:text-gray-900"
              >
                Logout
              </button>
            </div>
          )}
        </div>
      </header>

      {/* Main content with sidebar */}
      <div className="flex h-[calc(100vh-4rem)]">
        {user && <Sidebar />}
        <main className="flex-1 overflow-y-auto p-8 bg-gray-50">
          {children}
        </main>
      </div>
    </div>
  )
}