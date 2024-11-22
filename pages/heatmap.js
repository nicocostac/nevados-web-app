import { requireAuth } from '@/lib/auth/requireAuth'
import { useAuth } from '@/lib/context/AuthContext'
import dynamic from 'next/dynamic'
import { useState } from 'react'

// Dynamically import the Heatmap component to avoid SSR issues
const Heatmap = dynamic(() => import('@/components/Heatmap'), {
  ssr: false,
})

function HeatmapPage() {
  const { user } = useAuth()
  const [updating, setUpdating] = useState(false)
  const [updateMessage, setUpdateMessage] = useState(null)

  const handleUpdateCoordinates = async () => {
    try {
      setUpdating(true)
      setUpdateMessage(null)

      const response = await fetch('/api/update-coordinates', {
        method: 'POST',
      })

      if (!response.ok) {
        throw new Error('Failed to update coordinates')
      }

      setUpdateMessage('Coordinates update process started. This may take a few minutes.')
    } catch (error) {
      console.error('Error updating coordinates:', error)
      setUpdateMessage('Error updating coordinates. Please try again.')
    } finally {
      setUpdating(false)
    }
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Delivery Heatmap</h1>
            <p className="text-gray-600">Visualize delivery locations and order frequency</p>
          </div>
          <button
            onClick={handleUpdateCoordinates}
            disabled={updating}
            className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors disabled:opacity-50"
          >
            {updating ? 'Updating...' : 'Update Missing Coordinates'}
          </button>
        </div>
        {updateMessage && (
          <div className={`mt-4 p-4 rounded ${updateMessage.includes('Error') ? 'bg-red-50 text-red-600' : 'bg-blue-50 text-blue-600'}`}>
            {updateMessage}
          </div>
        )}
      </div>
      
      <div className="bg-white rounded-lg shadow">
        <Heatmap />
      </div>
    </div>
  )
}

export default requireAuth(HeatmapPage)
