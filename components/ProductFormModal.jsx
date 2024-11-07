import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { X } from 'lucide-react'

export default function ProductFormModal({ 
  isOpen, 
  onClose, 
  onSubmit, 
  editingProduct = null,
  categories = []
}) {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    default_price: '',
    unit_of_sale: 'unit',
    category_id: '',
    status: 'active'
  })
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)

  useEffect(() => {
    if (editingProduct) {
      setFormData({
        name: editingProduct.name || '',
        description: editingProduct.description || '',
        default_price: editingProduct.default_price?.toString() || '',
        unit_of_sale: editingProduct.unit_of_sale || 'unit',
        category_id: editingProduct.category_id || '',
        status: editingProduct.status || 'active'
      })
    } else {
      setFormData({
        name: '',
        description: '',
        default_price: '',
        unit_of_sale: 'unit',
        category_id: categories[0]?.id || '', // Set first category as default if exists
        status: 'active'
      })
    }
  }, [editingProduct, categories])

  if (!isOpen) return null

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)

    try {
      // Convert default_price to number before submitting
      const submissionData = {
        ...formData,
        default_price: parseFloat(formData.default_price)
      }
      await onSubmit(submissionData)
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
          {editingProduct ? 'Edit Product' : 'Create New Product'}
        </h2>

        {error && (
          <Alert variant="destructive" className="mb-4">{error}</Alert>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            name="name"
            placeholder="Product Name"
            value={formData.name}
            onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
            required
          />

          <textarea
            name="description"
            placeholder="Description"
            value={formData.description}
            onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
            className="w-full p-2 border rounded min-h-[100px]"
          />

          <div className="grid grid-cols-2 gap-4">
            <Input
              type="number"
              name="default_price"
              placeholder="Default Price"
              value={formData.default_price}
              onChange={(e) => setFormData(prev => ({ ...prev, default_price: e.target.value }))}
              required
              step="0.01"
              min="0"
            />

            <select
              name="unit_of_sale"
              value={formData.unit_of_sale}
              onChange={(e) => setFormData(prev => ({ ...prev, unit_of_sale: e.target.value }))}
              className="w-full p-2 border rounded"
              required
            >
              <option value="unit">Unit</option>
              <option value="box">Box</option>
              <option value="pack">Pack</option>
              <option value="liter">Liter</option>
            </select>
          </div>

          <select
            name="category_id"
            value={formData.category_id}
            onChange={(e) => setFormData(prev => ({ ...prev, category_id: e.target.value }))}
            className="w-full p-2 border rounded"
            required
          >
            <option value="">Select Category</option>
            {categories.map(category => (
              <option key={category.id} value={category.id}>
                {category.name}
              </option>
            ))}
          </select>

          <select
            name="status"
            value={formData.status}
            onChange={(e) => setFormData(prev => ({ ...prev, status: e.target.value }))}
            className="w-full p-2 border rounded"
            required
          >
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>

          <div className="flex gap-2">
            <Button type="submit" disabled={isLoading}>
              {isLoading ? 'Saving...' : editingProduct ? 'Update' : 'Create'}
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