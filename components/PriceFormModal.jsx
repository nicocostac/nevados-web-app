import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { X, DollarSign } from 'lucide-react'
import { formatCurrency } from '@/lib/utils/format'

// Utility function to format dates for input fields
const formatDateForInput = (dateString) => {
  const date = new Date(dateString);
  // Add timezone offset to get the correct local date
  const timezoneOffset = date.getTimezoneOffset() * 60000;
  const localDate = new Date(date.getTime() + timezoneOffset);
  return localDate.toISOString().split('T')[0];
};

// Utility function to get today's date in the correct format
const getTodayFormatted = () => {
  const today = new Date();
  return formatDateForInput(today.toISOString());
};

export default function PriceFormModal({ 
  isOpen, 
  onClose, 
  onSubmit,
  editingPrice = null,
  productName = ''
}) {
  const [formData, setFormData] = useState({
    price: '',
    start_date: getTodayFormatted(),
    end_date: ''
  })

  useEffect(() => {
    if (editingPrice) {
      setFormData({
        price: editingPrice.price.toString(),
        start_date: formatDateForInput(editingPrice.start_date),
        end_date: editingPrice.end_date ? formatDateForInput(editingPrice.end_date) : ''
      })
    } else {
      setFormData({
        price: '',
        start_date: getTodayFormatted(),
        end_date: ''
      })
    }
  }, [editingPrice, isOpen])

  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)

    try {
      // Validate price
      if (isNaN(parseFloat(formData.price))) {
        throw new Error('El precio debe ser un número válido')
      }
      if (!formData.start_date) {
        throw new Error('La fecha de inicio es requerida')
      }

      // Convert price to number
      const submissionData = {
        ...formData,
        price: parseFloat(formData.price)
      }
      
      await onSubmit(submissionData)
      onClose()
    } catch (error) {
      console.error('Form submission error:', error)
      setError(error.message)
    } finally {
      setIsLoading(false)
    }
  }

  if (!isOpen) return null

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
          {editingPrice ? 'Editar Precio' : 'Agregar Precio'}
          {productName && <span className="block text-sm text-gray-500 mt-1">{productName}</span>}
        </h2>

        {error && (
          <Alert variant="destructive" className="mb-4">{error}</Alert>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Precio</label>
              <div className="relative">
                <DollarSign className="h-4 w-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                <Input
                  type="number"
                  value={formData.price}
                  onChange={(e) => setFormData(prev => ({ ...prev, price: e.target.value }))}
                  className="pl-8"
                  required
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Fecha de Inicio</label>
              <Input
                type="date"
                value={formData.start_date}
                onChange={(e) => setFormData(prev => ({ ...prev, start_date: e.target.value }))}
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Fecha de Fin (opcional)</label>
              <Input
                type="date"
                value={formData.end_date}
                onChange={(e) => setFormData(prev => ({ ...prev, end_date: e.target.value || null }))}
              />
            </div>
          </div>

          <div className="flex gap-2 pt-4 border-t">
            <Button
              type="button"
              variant="outline"
              onClick={onClose}
              disabled={isLoading}
            >
              Cancelar
            </Button>
            <Button
              type="submit"
              disabled={isLoading}
            >
              {isLoading ? 'Guardando...' : editingPrice ? 'Guardar Cambios' : 'Agregar Precio'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
}
