import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { X } from 'lucide-react'
import { supabase } from '@/lib/supabaseClient'

export default function AddressFormModal({
  isOpen,
  onClose,
  onSubmit,
  editingAddress = null
}) {
  const [formData, setFormData] = useState({
    street_address: '',
    borough_id: '',
    neighborhood_id: '',
    additional_info: '',
    contact_person: '',
    is_default: false
  })
  const [error, setError] = useState(null)
  const [boroughs, setBoroughs] = useState([])
  const [neighborhoods, setNeighborhoods] = useState([])

  useEffect(() => {
    fetchBoroughs()
  }, [])

  // Fetch neighborhoods when borough is selected
  useEffect(() => {
    if (formData.borough_id) {
      fetchNeighborhoods(formData.borough_id)
    } else {
      setNeighborhoods([])
      setFormData(prev => ({ ...prev, neighborhood_id: '' }))
    }
  }, [formData.borough_id])

  // Set form data when editing
  useEffect(() => {
    if (editingAddress) {
      setFormData({
        street_address: editingAddress.street_address || '',
        borough_id: editingAddress.borough_id || '',
        neighborhood_id: editingAddress.neighborhood_id || '',
        additional_info: editingAddress.additional_info || '',
        contact_person: editingAddress.contact_person || '',
        is_default: editingAddress.is_default || false
      })
      if (editingAddress.borough_id) {
        fetchNeighborhoods(editingAddress.borough_id)
      }
    } else {
      setFormData({
        street_address: '',
        borough_id: '',
        neighborhood_id: '',
        additional_info: '',
        contact_person: '',
        is_default: false
      })
    }
  }, [editingAddress])

  const fetchBoroughs = async () => {
    const { data, error } = await supabase
      .from('boroughs')
      .select('*')
      .eq('status', 'active')
      .order('name')

    if (error) {
      console.error('Error fetching boroughs:', error)
      setError('Error fetching boroughs')
    } else {
      setBoroughs(data || [])
    }
  }

  const fetchNeighborhoods = async (boroughId) => {
    const { data, error } = await supabase
      .from('neighborhoods')
      .select('*')
      .eq('borough_id', boroughId)
      .eq('status', 'active')
      .order('name')

    if (error) {
      console.error('Error fetching neighborhoods:', error)
      setError('Error fetching neighborhoods')
    } else {
      setNeighborhoods(data || [])
    }
  }

  if (!isOpen) return null

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)

    if (!formData.borough_id) {
      setError('Please select a borough')
      return
    }

    try {
      // Only send the IDs and other necessary data
      const addressData = {
        street_address: formData.street_address,
        borough_id: formData.borough_id,
        neighborhood_id: formData.neighborhood_id || null,
        additional_info: formData.additional_info,
        contact_person: formData.contact_person,
        is_default: formData.is_default
      }

      await onSubmit(addressData)
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
            {editingAddress ? 'Edit Address' : 'New Address'}
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
            <label className="block mb-2">Street Address</label>
            <Input
              type="text"
              value={formData.street_address}
              onChange={(e) => setFormData({ ...formData, street_address: e.target.value })}
              required
            />
          </div>

          <div>
            <label className="block mb-2">Contact Person</label>
            <Input
              type="text"
              value={formData.contact_person}
              onChange={(e) => setFormData({ ...formData, contact_person: e.target.value })}
              placeholder="Optional - defaults to client name"
            />
          </div>

          <div>
            <label className="block mb-2">Borough</label>
            <select
              value={formData.borough_id}
              onChange={(e) => setFormData({ ...formData, borough_id: e.target.value })}
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
            <label className="block mb-2">Neighborhood</label>
            <select
              value={formData.neighborhood_id}
              onChange={(e) => setFormData({ ...formData, neighborhood_id: e.target.value })}
              className="w-full p-2 border rounded"
              disabled={!formData.borough_id}
            >
              <option value="">Select Neighborhood</option>
              {neighborhoods.map(neighborhood => (
                <option key={neighborhood.id} value={neighborhood.id}>
                  {neighborhood.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block mb-2">Additional Information</label>
            <Input
              type="text"
              value={formData.additional_info}
              onChange={(e) => setFormData({ ...formData, additional_info: e.target.value })}
              placeholder="Apartment number, floor, etc."
            />
          </div>

          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="is_default"
              checked={formData.is_default}
              onChange={(e) => setFormData({ ...formData, is_default: e.target.checked })}
              className="rounded border-gray-300"
            />
            <label htmlFor="is_default">Set as default address</label>
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit">
              {editingAddress ? 'Update' : 'Create'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
} 