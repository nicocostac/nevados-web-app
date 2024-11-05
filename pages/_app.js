import { AuthProvider } from '@/lib/context/AuthContext'
import Layout from '@/components/Layout'
import '@/styles/globals.css'

export default function App({ Component, pageProps }) {
  return (
    <AuthProvider>
      <Layout>
        <Component {...pageProps} />
      </Layout>
    </AuthProvider>
  )
}