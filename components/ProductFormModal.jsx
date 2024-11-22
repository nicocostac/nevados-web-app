import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { X, Plus, Trash2, Edit2 } from 'lucide-react'
import { formatCurrency } from '@/lib/utils/format'
import { useAuth } from '@/lib/context/AuthContext'
import { supabase } from '@/lib/supabaseClient'
import PriceFormModal from './PriceFormModal'

// Utility function to format dates consistently
const formatDateForDisplay = (dateString) => {
  const date = new Date(dateString);
  // Add timezone offset to get the correct local date
  const timezoneOffset = date.getTimezoneOffset() * 60000;
  const localDate = new Date(date.getTime() + timezoneOffset);
  return localDate.toLocaleDateString('es-CL');
};

// Utility function to format dates for input fields
const formatDateForInput = (dateString) => {
  const date = new Date(dateString);
  // Add timezone offset to get the correct local date
  const timezoneOffset = date.getTimezoneOffset() * 60000;
  const localDate = new Date(date.getTime() + timezoneOffset);
  return localDate.toISOString().split('T')[0];
};

export default function ProductFormModal({ 
  isOpen, 
  onClose, 
  onSubmit, 
  editingProduct = null,
  categories = []
}) {
  const { user: currentUser } = useAuth()
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    unit_of_sale: 'unit',
    category_id: '',
    status: 'active',
    prices: []
  })
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)
  const [isAdmin, setIsAdmin] = useState(false)
  const [isPriceModalOpen, setIsPriceModalOpen] = useState(false)
  const [editingPrice, setEditingPrice] = useState(null)
  const [editingProductId, setEditingProductId] = useState(null)

  useEffect(() => {
    // Check if user is admin
    const checkUserRole = async () => {
      try {
        const { data: profile, error } = await supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single()

        if (error) throw error
        setIsAdmin(profile.role === 'admin')
      } catch (error) {
        console.error('Error checking user role:', error)
      }
    }
    checkUserRole()
  }, [currentUser])

  useEffect(() => {
    // Set the product ID when editing
    if (editingProduct) {
      setEditingProductId(editingProduct.id)
    }
  }, [editingProduct])

  useEffect(() => {
    if (editingProduct) {
      // Combine all prices into a single array and sort by start_date
      const allPrices = [
        ...(editingProduct.historicalPrices || []),
        ...(editingProduct.futurePrices || [])
      ]
      if (editingProduct.currentPrice) {
        allPrices.push({
          id: editingProduct.currentPriceId, // Add the price ID
          price: editingProduct.currentPrice,
          start_date: editingProduct.price_start_date,
          end_date: null
        })
      }
      
      // Sort prices by start_date and preserve IDs
      const sortedPrices = allPrices.sort((a, b) => 
        new Date(b.start_date) - new Date(a.start_date)
      ).map(price => ({
        id: price.id, // Preserve the price ID
        price: price.price,
        start_date: price.start_date,
        end_date: price.end_date
      }))

      setFormData({
        name: editingProduct.name || '',
        description: editingProduct.description || '',
        unit_of_sale: editingProduct.unit_of_sale || 'unit',
        category_id: editingProduct.category_id || '',
        status: editingProduct.status || 'active',
        prices: sortedPrices
      })
    } else {
      setFormData({
        name: '',
        description: '',
        unit_of_sale: 'unit',
        category_id: categories[0]?.id || '',
        status: 'active',
        prices: [{
          id: null, // New prices have no ID
          price: '',
          start_date: new Date().toISOString().split('T')[0],
          end_date: null
        }]
      })
    }
  }, [editingProduct, categories])

  const handleRemovePrice = async (index) => {
    const priceToDelete = formData.prices[index];
    
    // Show confirmation alert
    if (!window.confirm('¿Estás seguro que quieres eliminar este precio?')) {
      return;
    }

    setIsLoading(true);
    setError(null);
    
    try {
      if (priceToDelete.id) {
        // Delete from database if it's an existing price
        const { error: deleteError } = await supabase
          .from('product_prices')
          .delete()
          .match({ id: priceToDelete.id });

        if (deleteError) {
          throw new Error(`Error al eliminar el precio: ${deleteError.message}`);
        }

        // Update the UI state after successful deletion
        setFormData(prev => ({
          ...prev,
          prices: prev.prices.filter((_, i) => i !== index)
        }));

        // Trigger products list refresh
        if (typeof window !== 'undefined') {
          window.dispatchEvent(new Event('productsUpdated'));
        }
      } else {
        // If it's a new price (not yet in database), just remove from UI
        setFormData(prev => ({
          ...prev,
          prices: prev.prices.filter((_, i) => i !== index)
        }));
      }
    } catch (error) {
      console.error('Error deleting price:', error);
      setError(error.message);
    } finally {
      setIsLoading(false);
    }
  };

  if (!isOpen) return null

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)

    try {
      // Validate prices
      for (const price of formData.prices) {
        if (isNaN(parseFloat(price.price))) {
          throw new Error('All prices must be valid numbers')
        }
        if (!price.start_date) {
          throw new Error('All prices must have a start date')
        }
      }

      // Convert prices to numbers
      const submissionData = {
        ...formData,
        prices: formData.prices.map(price => ({
          ...price,
          price: parseFloat(price.price)
        }))
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

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-2xl relative max-h-[90vh] overflow-y-auto">
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

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 gap-6">
            {/* Product Details Section */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium">Product Details</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Product Name</label>
                  <Input
                    name="name"
                    placeholder="Product Name"
                    value={formData.name}
                    onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Category</label>
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
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Unit of Sale</label>
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

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
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
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea
                  name="description"
                  placeholder="Description"
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  className="w-full p-2 border rounded min-h-[100px]"
                />
              </div>
            </div>

            {/* Price History Section */}
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-medium">Historial de Precios</h3>
                {isAdmin && (
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => {
                      setEditingPrice(null)
                      setIsPriceModalOpen(true)
                    }}
                  >
                    <Plus className="h-4 w-4 mr-1" />
                    Agregar Precio
                  </Button>
                )}
              </div>

              <div className="border rounded-lg overflow-hidden">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Precio</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Fecha Inicio</th>
                      {isAdmin && (
                        <>
                          <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Fecha Fin</th>
                          <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                        </>
                      )}
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {formData.prices.map((price, index) => (
                      <tr key={index} className="hover:bg-gray-50">
                        <td className="px-4 py-2">
                          {formatCurrency(price.price)}
                        </td>
                        <td className="px-4 py-2">
                          {formatDateForDisplay(price.start_date)}
                        </td>
                        {isAdmin && (
                          <>
                            <td className="px-4 py-2">
                              {price.end_date ? formatDateForDisplay(price.end_date) : '-'}
                            </td>
                            <td className="px-4 py-2">
                              <div className="flex gap-2">
                                <Button
                                  type="button"
                                  variant="ghost"
                                  size="sm"
                                  onClick={() => {
                                    setEditingPrice(price)
                                    setIsPriceModalOpen(true)
                                  }}
                                  disabled={isLoading}
                                >
                                  <Edit2 className="h-4 w-4 text-blue-500" />
                                </Button>
                                <Button
                                  type="button"
                                  variant="ghost"
                                  size="sm"
                                  onClick={() => handleRemovePrice(index)}
                                  disabled={isLoading}
                                >
                                  <Trash2 className="h-4 w-4 text-red-500" />
                                </Button>
                              </div>
                            </td>
                          </>
                        )}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div className="flex gap-2 pt-4 border-t">
            <Button type="submit" disabled={isLoading}>
              {isLoading ? 'Saving...' : editingProduct ? 'Update Product' : 'Create Product'}
            </Button>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
          </div>
        </form>
      </div>

      {/* Price Form Modal */}
      <PriceFormModal
        isOpen={isPriceModalOpen}
        onClose={() => {
          setIsPriceModalOpen(false)
          setEditingPrice(null)
        }}
        onSubmit={async (priceData) => {
          try {
            if (editingPrice) {
              // Update existing price in the database
              const { error: updateError } = await supabase
                .from('product_prices')
                .update({
                  price: priceData.price,
                  start_date: priceData.start_date,
                  end_date: priceData.end_date || null
                })
                .eq('id', editingPrice.id)

              if (updateError) throw updateError

            } else {
              // Insert new price in the database
              const { error: insertError } = await supabase
                .from('product_prices')
                .insert({
                  product_id: editingProductId,
                  price: priceData.price,
                  start_date: priceData.start_date,
                  end_date: priceData.end_date || null,
                  created_by: currentUser.id
                })

              if (insertError) throw insertError
            }

            // Refresh the product data to get updated prices
            const { data: updatedProduct, error: fetchError } = await supabase
              .from('products')
              .select(`
                *,
                product_categories (
                  name
                ),
                product_prices (
                  id,
                  price,
                  start_date,
                  end_date
                )
              `)
              .eq('id', editingProductId)
              .single()

            if (fetchError) throw fetchError

            // Sort prices by start_date in descending order
            const sortedPrices = updatedProduct.product_prices.sort((a, b) => 
              new Date(b.start_date) - new Date(a.start_date)
            )

            // Update the form data with new prices
            setFormData(prev => ({
              ...prev,
              prices: sortedPrices
            }))

            // Trigger products list refresh
            if (typeof window !== 'undefined') {
              window.dispatchEvent(new Event('productsUpdated'))
            }

            setIsPriceModalOpen(false)
            setEditingPrice(null)
          } catch (error) {
            console.error('Error updating price:', error)
            alert('Error al actualizar el precio: ' + error.message)
          }
        }}
        editingPrice={editingPrice}
        productName={formData.name}
      />
    </div>
  )
}