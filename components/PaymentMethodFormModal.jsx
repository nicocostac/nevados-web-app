import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { X } from 'lucide-react'

export default function PaymentMethodFormModal({
  isOpen,
  onClose,
  onSubmit,
  editingMethod = null
}) {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    status: 'active'
  })
  const [error, setError] = useState(null)

  useEffect(() => {
    if (editingMethod) {
      setFormData({
        name: editingMethod.name || '',
        description: editingMethod.description || '',
        status: editingMethod.status || 'active'
      })
    } else {
      setFormData({
        name: '',
        description: '',
        status: 'active'
      })
    }
  }, [editingMethod])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)

    try {
      await onSubmit(formData)
      onClose()
    } catch (error) {
      setError(error.message)
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">
            {editingMethod ? 'Edit Payment Method' : 'New Payment Method'}
          </h2>
          <button onClick={onClose}>
            <X className="h-5 w-5" />
          </button>
        </div>

        {error && (
          <Alert variant="destructive" className="mb-4">{error}</Alert>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block mb-2">Name</label>
            <Input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              required
            />
          </div>

          <div>
            <label className="block mb-2">Description</label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              className="w-full p-2 border rounded min-h-[100px]"
            />
          </div>

          <div>
            <label className="block mb-2">Status</label>
            <select
              value={formData.status}
              onChange={(e) => setFormData(prev => ({ ...prev, status: e.target.value }))}
              className="w-full p-2 border rounded"
            >
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>

          <div className="flex justify-end gap-4">
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit">
              {editingMethod ? 'Update' : 'Create'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
} 