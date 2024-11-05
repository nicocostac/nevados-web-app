import AuthForm from '@/components/AuthForm'
import { useAuth } from '@/lib/context/AuthContext'
import { useRouter } from 'next/router'
import { useEffect } from 'react'

export default function Login() {
  const { user, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading && user) {
      router.replace('/dashboard')
    }
  }, [user, loading, router])

  // If loading, show loading state
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-xl">Loading...</div>
      </div>
    )
  }

  // If not loading and no user, show login form
  if (!loading && !user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <AuthForm />
      </div>
    )
  }

  // This will briefly show while redirecting
  return null
}