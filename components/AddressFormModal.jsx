import { useState } from 'react'
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
    street_address: editingAddress?.street_address || '',
    borough: editingAddress?.borough || '',
    neighborhood: editingAddress?.neighborhood || '',
    additional_info: editingAddress?.additional_info || '',
    is_default: editingAddress?.is_default || false
  })
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)

  if (!isOpen) return null

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)

    try {
      await onSubmit(formData)
      onClose()
    } catch (error) {
      setError(error.message)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md relative">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-gray-500 hover:text-gray-700"
        >
          <X className="h-5 w-5" />
        </button>

        <h2 className="text-xl font-semibold mb-6">
          {editingAddress ? 'Edit Address' : 'Add Address'}
        </h2>

        {error && (
          <Alert variant="destructive" className="mb-4">{error}</Alert>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            name="street_address"
            placeholder="Street Address"
            value={formData.street_address}
            onChange={(e) => setFormData(prev => ({ ...prev, street_address: e.target.value }))}
            required
          />

          <div className="grid grid-cols-2 gap-4">
            <Input
              name="borough"
              placeholder="Borough"
              value={formData.borough}
              onChange={(e) => setFormData(prev => ({ ...prev, borough: e.target.value }))}
              required
            />

            <Input
              name="neighborhood"
              placeholder="Neighborhood"
              value={formData.neighborhood}
              onChange={(e) => setFormData(prev => ({ ...prev, neighborhood: e.target.value }))}
              required
            />
          </div>

          <Input
            name="additional_info"
            placeholder="Additional Information"
            value={formData.additional_info}
            onChange={(e) => setFormData(prev => ({ ...prev, additional_info: e.target.value }))}
          />

          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              checked={formData.is_default}
              onChange={(e) => setFormData(prev => ({ ...prev, is_default: e.target.checked }))}
              className="rounded border-gray-300"
            />
            <span>Set as default address</span>
          </label>

          <div className="flex gap-2">
            <Button type="submit" disabled={isLoading}>
              {isLoading ? 'Saving...' : editingAddress ? 'Update' : 'Add'}
            </Button>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
} 