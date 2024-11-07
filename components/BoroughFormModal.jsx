import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { X } from 'lucide-react'

export default function BoroughFormModal({
  isOpen,
  onClose,
  onSubmit,
  editingBorough = null
}) {
  const [formData, setFormData] = useState({
    name: ''
  })
  const [error, setError] = useState(null)

  useEffect(() => {
    if (isOpen) {
      if (editingBorough) {
        setFormData({
          name: editingBorough.name
        })
      } else {
        setFormData({
          name: ''
        })
      }
    }
  }, [isOpen, editingBorough])

  if (!isOpen) return null

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)

    try {
      await onSubmit(formData)
      setFormData({ name: '' })
      onClose()
    } catch (error) {
      setError(error.message)
    }
  }

  const handleClose = () => {
    setFormData({ name: '' })
    setError(null)
    onClose()
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">
            {editingBorough ? 'Edit Borough' : 'New Borough'}
          </h2>
          <button onClick={handleClose}>
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
            <label className="block mb-2">Name</label>
            <Input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
            />
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="ghost" onClick={handleClose}>
              Cancel
            </Button>
            <Button type="submit">
              {editingBorough ? 'Update' : 'Create'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
} 