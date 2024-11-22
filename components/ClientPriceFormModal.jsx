import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { X, Calculator } from 'lucide-react'
import { supabase } from '@/lib/supabaseClient'
import { formatCurrency } from '@/lib/utils/format'

export default function ClientPriceFormModal({ 
  isOpen, 
  onClose, 
  onSubmit, 
  editingPrice = null,
  products = []
}) {
  const [formData, setFormData] = useState({
    product_id: '',
    discount_percentage: '',
    final_price: '',
    start_date: new Date().toISOString().split('T')[0],
    end_date: '',
    notes: ''
  })
  const [selectedProduct, setSelectedProduct] = useState(null)
  const [currentPrice, setCurrentPrice] = useState(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)

  useEffect(() => {
    if (editingPrice) {
      setFormData({
        product_id: editingPrice.product_id || '',
        discount_percentage: editingPrice.discount_percentage?.toString() || '',
        final_price: editingPrice.final_price?.toString() || '',
        start_date: editingPrice.start_date || new Date().toISOString().split('T')[0],
        end_date: editingPrice.end_date || '',
        notes: editingPrice.notes || ''
      })
      const product = products.find(p => p.id === editingPrice.product_id)
      setSelectedProduct(product)
      if (product) {
        fetchCurrentPrice(product.id)
      }
    } else {
      setFormData({
        product_id: '',
        discount_percentage: '',
        final_price: '',
        start_date: new Date().toISOString().split('T')[0],
        end_date: '',
        notes: ''
      })
      setSelectedProduct(null)
      setCurrentPrice(null)
    }
  }, [editingPrice, products])

  const fetchCurrentPrice = async (productId) => {
    const today = new Date().toISOString().split('T')[0]
    const { data, error } = await supabase.rpc('get_product_price_at_date', {
      product_id: productId,
      target_date: today
    })
    
    if (error) {
      console.error('Error fetching current price:', error)
      return
    }

    if (data && data[0]) {
      setCurrentPrice(data[0].price)
    }
  }

  const handleProductChange = async (productId) => {
    const product = products.find(p => p.id === productId)
    setSelectedProduct(product)
    setFormData(prev => ({
      ...prev,
      product_id: productId,
      final_price: '',
      discount_percentage: ''
    }))
    
    if (product) {
      await fetchCurrentPrice(productId)
    }
  }

  const handleDiscountChange = (percentage) => {
    if (!selectedProduct || !currentPrice) return

    const discount = parseFloat(percentage)
    if (isNaN(discount)) {
      setFormData(prev => ({
        ...prev,
        discount_percentage: percentage,
        final_price: currentPrice.toString()
      }))
      return
    }

    const finalPrice = currentPrice * (1 - discount / 100)
    setFormData(prev => ({
      ...prev,
      discount_percentage: percentage,
      final_price: finalPrice.toFixed(2)
    }))
  }

  const handlePriceChange = (price) => {
    if (!selectedProduct || !currentPrice) return

    const finalPrice = parseFloat(price)
    if (isNaN(finalPrice)) {
      setFormData(prev => ({
        ...prev,
        final_price: price,
        discount_percentage: ''
      }))
      return
    }

    const discount = ((currentPrice - finalPrice) / currentPrice) * 100
    setFormData(prev => ({
      ...prev,
      final_price: price,
      discount_percentage: discount.toFixed(2)
    }))
  }

  if (!isOpen) return null

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)

    try {
      const submissionData = {
        ...formData,
        discount_percentage: parseFloat(formData.discount_percentage),
        final_price: parseFloat(formData.final_price),
        end_date: formData.end_date || null
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
          {editingPrice ? 'Edit Special Price' : 'Add Special Price'}
        </h2>

        {error && (
          <Alert variant="destructive" className="mb-4">{error}</Alert>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <select
            name="product_id"
            value={formData.product_id}
            onChange={(e) => handleProductChange(e.target.value)}
            className="w-full p-2 border rounded"
            required
          >
            <option value="">Select Product</option>
            {products.map(product => (
              <option key={product.id} value={product.id}>
                {product.name} {currentPrice && selectedProduct?.id === product.id ? `(Current: ${formatCurrency(currentPrice)})` : ''}
              </option>
            ))}
          </select>

          {selectedProduct && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Discount %
                  </label>
                  <Input
                    type="number"
                    name="discount_percentage"
                    placeholder="Discount %"
                    value={formData.discount_percentage}
                    onChange={(e) => handleDiscountChange(e.target.value)}
                    step="0.01"
                    min="0"
                    max="100"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Final Price
                  </label>
                  <Input
                    type="number"
                    name="final_price"
                    placeholder="Final Price"
                    value={formData.final_price}
                    onChange={(e) => handlePriceChange(e.target.value)}
                    step="0.01"
                    min="0"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Start Date
                  </label>
                  <Input
                    type="date"
                    name="start_date"
                    value={formData.start_date}
                    onChange={(e) => setFormData(prev => ({ ...prev, start_date: e.target.value }))}
                    required
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    End Date
                  </label>
                  <Input
                    type="date"
                    name="end_date"
                    value={formData.end_date}
                    onChange={(e) => setFormData(prev => ({ ...prev, end_date: e.target.value }))}
                  />
                </div>
              </div>

              <textarea
                name="notes"
                placeholder="Notes"
                value={formData.notes}
                onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
                className="w-full p-2 border rounded min-h-[80px]"
              />
            </div>
          )}

          <div className="flex gap-2">
            <Button type="submit" disabled={isLoading}>
              {isLoading ? 'Saving...' : editingPrice ? 'Update' : 'Add'}
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