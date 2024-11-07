import { useState, useEffect } from 'react'
import { requireAuth } from '@/lib/auth/requireAuth'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Alert } from '@/components/ui/alert'
import { Edit2, Trash2, Plus, MapPin } from 'lucide-react'
import BoroughFormModal from '@/components/BoroughFormModal'
import NeighborhoodFormModal from '@/components/NeighborhoodFormModal'

function LocationManagement() {
  const [boroughs, setBoroughs] = useState([])
  const [isBoroughModalOpen, setIsBoroughModalOpen] = useState(false)
  const [isNeighborhoodModalOpen, setIsNeighborhoodModalOpen] = useState(false)
  const [message, setMessage] = useState('')
  const [editingBorough, setEditingBorough] = useState(null)
  const [editingNeighborhood, setEditingNeighborhood] = useState(null)

  useEffect(() => {
    fetchBoroughs()
  }, [])

  const fetchBoroughs = async () => {
    const { data, error } = await supabase
      .from('boroughs')
      .select(`
        *,
        neighborhoods (*)
      `)
      .order('name')
      .eq('status', 'active')

    if (error) {
      console.error('Error fetching boroughs:', error)
      setMessage('Error fetching boroughs')
    } else {
      setBoroughs(data || [])
    }
  }

  const handleBoroughSubmit = async (formData) => {
    try {
      if (editingBorough) {
        const { error } = await supabase
          .from('boroughs')
          .update({ name: formData.name })
          .eq('id', editingBorough.id)

        if (error) throw error
      } else {
        const { error } = await supabase
          .from('boroughs')
          .insert([{ name: formData.name }])

        if (error) throw error
      }

      setMessage(`Borough ${editingBorough ? 'updated' : 'created'} successfully`)
      fetchBoroughs()
      setIsBoroughModalOpen(false)
      setEditingBorough(null)
    } catch (error) {
      console.error('Error:', error)
      setMessage(error.message)
    }
  }

  const handleNeighborhoodSubmit = async (formData) => {
    try {
      if (editingNeighborhood) {
        const { error } = await supabase
          .from('neighborhoods')
          .update({
            name: formData.name,
            borough_id: formData.boroughId
          })
          .eq('id', editingNeighborhood.id)

        if (error) throw error
      } else {
        const { error } = await supabase
          .from('neighborhoods')
          .insert([{
            name: formData.name,
            borough_id: formData.boroughId
          }])

        if (error) throw error
      }

      setMessage(`Neighborhood ${editingNeighborhood ? 'updated' : 'created'} successfully`)
      fetchBoroughs()
      setIsNeighborhoodModalOpen(false)
      setEditingNeighborhood(null)
    } catch (error) {
      console.error('Error:', error)
      setMessage(error.message)
    }
  }

  return (
    <div className="space-y-6">
      {message && (
        <Alert 
          className="mb-4"
          onClose={() => setMessage('')}
        >
          {message}
        </Alert>
      )}

      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Location Management</h2>
        <div className="space-x-2">
          <Button onClick={() => setIsBoroughModalOpen(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Add Borough
          </Button>
          <Button onClick={() => setIsNeighborhoodModalOpen(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Add Neighborhood
          </Button>
        </div>
      </div>

      <div className="bg-white shadow rounded-lg p-6">
        {boroughs.map(borough => (
          <div key={borough.id} className="mb-6 last:mb-0">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-lg font-medium">{borough.name}</h3>
              <div className="flex gap-2">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => {
                    setEditingBorough(borough)
                    setIsBoroughModalOpen(true)
                  }}
                >
                  <Edit2 className="h-4 w-4" />
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={async () => {
                    if (window.confirm('Are you sure you want to delete this borough?')) {
                      const { error } = await supabase
                        .from('boroughs')
                        .update({ status: 'inactive' })
                        .eq('id', borough.id)

                      if (error) {
                        setMessage('Error deleting borough')
                      } else {
                        fetchBoroughs()
                        setMessage('Borough deleted successfully')
                      }
                    }
                  }}
                >
                  <Trash2 className="h-4 w-4 text-red-500" />
                </Button>
              </div>
            </div>

            <div className="pl-6 space-y-2">
              {borough.neighborhoods
                .filter(n => n.status === 'active')
                .map(neighborhood => (
                  <div
                    key={neighborhood.id}
                    className="flex items-center justify-between py-2 border-b last:border-0"
                  >
                    <div className="flex items-center">
                      <MapPin className="h-4 w-4 mr-2 text-gray-400" />
                      {neighborhood.name}
                    </div>
                    <div className="flex gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setEditingNeighborhood(neighborhood)
                          setIsNeighborhoodModalOpen(true)
                        }}
                      >
                        <Edit2 className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={async () => {
                          if (window.confirm('Are you sure you want to delete this neighborhood?')) {
                            const { error } = await supabase
                              .from('neighborhoods')
                              .update({ status: 'inactive' })
                              .eq('id', neighborhood.id)

                            if (error) {
                              setMessage('Error deleting neighborhood')
                            } else {
                              fetchBoroughs()
                              setMessage('Neighborhood deleted successfully')
                            }
                          }
                        }}
                      >
                        <Trash2 className="h-4 w-4 text-red-500" />
                      </Button>
                    </div>
                  </div>
                ))}
            </div>
          </div>
        ))}
      </div>

      <BoroughFormModal
        isOpen={isBoroughModalOpen}
        onClose={() => {
          setIsBoroughModalOpen(false)
          setEditingBorough(null)
        }}
        onSubmit={handleBoroughSubmit}
        editingBorough={editingBorough}
      />

      <NeighborhoodFormModal
        isOpen={isNeighborhoodModalOpen}
        onClose={() => {
          setIsNeighborhoodModalOpen(false)
          setEditingNeighborhood(null)
        }}
        onSubmit={handleNeighborhoodSubmit}
        editingNeighborhood={editingNeighborhood}
        boroughs={boroughs}
      />
    </div>
  )
}

// Add this export
export default requireAuth(LocationManagement) 