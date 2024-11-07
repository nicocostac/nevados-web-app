import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { X } from 'lucide-react'

export default function NeighborhoodFormModal({
  isOpen,
  onClose,
  onSubmit,
  editingNeighborhood = null,
  boroughs = []
}) {
  const [formData, setFormData] = useState({
    name: '',
    boroughId: ''
  })
  const [error, setError] = useState(null)

  useEffect(() => {
    if (editingNeighborhood) {
      setFormData({
        name: editingNeighborhood.name,
        boroughId: editingNeighborhood.borough_id
      })
    } else {
      setFormData({
        name: '',
        boroughId: boroughs[0]?.id || ''
      })
    }
  }, [editingNeighborhood, boroughs])

  if (!isOpen) return null

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)

    if (!formData.boroughId) {
      setError('Please select a borough')
      return
    }

    try {
      await onSubmit(formData)
      onClose()
    } catch (error) {
      setError(error.message)
    }
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">
            {editingNeighborhood ? 'Edit Neighborhood' : 'New Neighborhood'}
          </h2>
          <button onClick={onClose}>
            <X className="h-5 w-5" />
          </button>
        </div>

        {error && (
          <Alert variant="destructive" className="mb-4">
            {error}
          </Alert>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block mb-2">Borough</label>
            <select
              value={formData.boroughId}
              onChange={(e) => setFormData({ ...formData, boroughId: e.target.value })}
              className="w-full p-2 border rounded"
              required
            >
              <option value="">Select Borough</option>
              {boroughs.map(borough => (
                <option key={borough.id} value={borough.id}>
                  {borough.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block mb-2">Name</label>
            <Input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
            />
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit">
              {editingNeighborhood ? 'Update' : 'Create'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
} 