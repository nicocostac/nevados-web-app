import { useAuth } from '@/lib/context/AuthContext'
import { useRouter } from 'next/router'
import { useEffect } from 'react'

export default function Home() {
  const { user, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading) {
      if (user) {
        router.replace('/dashboard')
      } else {
        router.replace('/login')
      }
    }
  }, [user, loading, router])

  // Show loading state while checking authentication
  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-xl">Loading...</div>
    </div>
  )
}