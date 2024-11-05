import { useAuth } from '../context/AuthContext'
import { useRouter } from 'next/router'
import { useEffect } from 'react'

const withAuth = (Component) => {
  const Auth = (props) => {
    const { user, loading } = useAuth()
    const router = useRouter()

    useEffect(() => {
      if (!loading && !user) {
        router.replace('/login')
      }
    }, [user, loading, router])

    if (loading) {
      return (
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-xl">Loading...</div>
        </div>
      )
    }

    if (!user) {
      return null
    }

    return <Component {...props} />
  }

  if (Component.getInitialProps) {
    Auth.getInitialProps = Component.getInitialProps
  }

  return Auth
}

export { withAuth as requireAuth }