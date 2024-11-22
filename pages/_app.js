import { AuthProvider } from '@/lib/context/AuthContext'
import Layout from '@/components/Layout'
import '@/styles/globals.css'
import 'leaflet/dist/leaflet.css'

export default function App({ Component, pageProps }) {
  return (
    <AuthProvider>
      <Layout>
        <Component {...pageProps} />
      </Layout>
    </AuthProvider>
  )
}