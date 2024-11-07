import { useState, useEffect, useRef } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { X, Plus, Minus, Search } from 'lucide-react'
import { supabase } from '@/lib/supabaseClient'

export default function SaleFormModal({ 
  isOpen, 
  onClose, 
  onSubmit, 
  editingSale = null,
  clients = [],
  products = []
}) {
  const [error, setError] = useState('')
  const [formData, setFormData] = useState({
    clientId: '',
    saleDate: new Date().toISOString().split('T')[0],
    deliveryDate: new Date().toISOString().split('T')[0],
    items: [],
    notes: ''
  })
  const [clientSearch, setClientSearch] = useState('')
  const [filteredClients, setFilteredClients] = useState(clients)
  const [specialPrices, setSpecialPrices] = useState({})
  const [showClientDropdown, setShowClientDropdown] = useState(false)
  const [selectedClient, setSelectedClient] = useState(null)
  const [clientAddresses, setClientAddresses] = useState([])
  const dropdownRef = useRef(null)

  useEffect(() => {
    if (editingSale) {
      setFormData({
        clientId: editingSale.client_id,
        saleDate: editingSale.sale_date,
        deliveryDate: editingSale.delivery_date,
        items: editingSale.sale_items || [],
        notes: editingSale.notes || ''
      })
    } else {
      setFormData({
        clientId: '',
        saleDate: new Date().toISOString().split('T')[0],
        deliveryDate: new Date().toISOString().split('T')[0],
        items: [],
        notes: ''
      })
    }
  }, [editingSale])

  // Filter clients based on search
  useEffect(() => {
    const filtered = clients.filter(client =>
      client.name.toLowerCase().includes(clientSearch.toLowerCase())
    )
    setFilteredClients(filtered)
  }, [clientSearch, clients])

  // Fetch special prices when client is selected
  useEffect(() => {
    if (formData.clientId) {
      fetchSpecialPrices(formData.clientId)
    }
  }, [formData.clientId])

  const fetchSpecialPrices = async (clientId) => {
    const { data, error } = await supabase
      .from('client_prices')
      .select('*')
      .eq('client_id', clientId)

    if (error) {
      console.error('Error fetching special prices:', error)
    } else {
      const pricesMap = {}
      data.forEach(price => {
        pricesMap[price.product_id] = price.final_price
      })
      setSpecialPrices(pricesMap)
    }
  }

  const addItem = () => {
    setFormData(prev => ({
      ...prev,
      items: [...prev.items, { 
        productId: '', 
        quantity: 1,
        unitPrice: 0,
        totalPrice: 0,
        discountPercentage: 0
      }]
    }))
  }

  const removeItem = (index) => {
    setFormData(prev => ({
      ...prev,
      items: prev.items.filter((_, i) => i !== index)
    }))
  }

  const updateItem = (index, updates) => {
    setFormData(prev => {
      const items = [...prev.items]
      const item = { ...items[index], ...updates }
      
      // If product changed, update unit price
      if (updates.productId) {
        const specialPrice = specialPrices[updates.productId]
        item.unitPrice = specialPrice || 
          products.find(p => p.id === updates.productId)?.default_price || 0
      }

      // Calculate total price
      if (item.quantity || updates.unitPrice) {
        item.totalPrice = item.quantity * item.unitPrice
      }

      items[index] = item
      return { ...prev, items }
    })
  }

  const calculateTotal = () => {
    return formData.items.reduce((sum, item) => sum + (item.totalPrice || 0), 0)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')

    // Validate required fields
    if (!formData.clientId) {
      setError('Please select a client')
      return
    }

    if (!formData.deliveryAddressId) {
      setError('Please select a delivery address')
      return
    }

    if (formData.items.length === 0) {
      setError('Please add at least one item')
      return
    }

    // Validate each item has required fields
    const invalidItem = formData.items.find(item => 
      !item.productId || !item.quantity || item.quantity <= 0
    )
    
    if (invalidItem) {
      setError('Please complete all item details (product and quantity)')
      return
    }

    try {
      await onSubmit({
        ...formData,
        totalAmount: calculateTotal()
      })

      onClose()
    } catch (error) {
      setError(error.message)
    }
  }

  const handleClientSelect = (client) => {
    setSelectedClient(client)
    setFormData(prev => ({ ...prev, clientId: client.id }))
    setClientSearch(client.name)
    setShowClientDropdown(false)
    fetchSpecialPrices(client.id)
    fetchClientAddresses(client.id)
  }

  const fetchClientAddresses = async (clientId) => {
    const { data, error } = await supabase
      .from('client_addresses')
      .select('*')
      .eq('client_id', clientId)

    if (error) {
      console.error('Error fetching addresses:', error)
      setError('Error fetching client addresses. Please try again.')
    } else if (!data || data.length === 0) {
      setError('This client has no addresses. Please add at least one address in the client management page before creating a sale.')
      setClientAddresses([])
    } else {
      setError('')
      setClientAddresses(data)
    }
  }

  useEffect(() => {
    function handleClickOutside(event) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setShowClientDropdown(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [])

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">
            {editingSale ? 'Sale Details' : 'New Sale'}
          </h2>
          <button onClick={onClose}>
            <X className="h-5 w-5" />
          </button>
        </div>

        {error && (
          <Alert variant="destructive" className="mb-4">
            <div className="flex justify-between items-center">
              <span>{error}</span>
              {error.includes('no addresses') && (
                <Button
                  type="button"
                  size="sm"
                  onClick={() => {
                    window.location.href = `/clients?search=${encodeURIComponent(selectedClient.name)}&highlight=${selectedClient.id}`
                  }}
                  className="ml-4 whitespace-nowrap bg-white border-2 border-red-200 text-red-600 hover:bg-red-50 hover:border-red-300 transition-all duration-200 flex items-center gap-2"
                >
                  <svg
                    className="w-4 h-4"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                  Manage Client
                </Button>
              )}
            </div>
          </Alert>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Client Search */}
          <div ref={dropdownRef}>
            <label className="block mb-2">Client</label>
            <div className="relative">
              <div className="relative">
                <Input
                  type="text"
                  placeholder="Search client..."
                  value={clientSearch}
                  onChange={(e) => {
                    setClientSearch(e.target.value)
                    setShowClientDropdown(true)
                    if (!e.target.value) {
                      setSelectedClient(null)
                      setFormData(prev => ({ ...prev, clientId: '' }))
                    }
                  }}
                  className="mb-2"
                  required
                />
                <Search className="absolute right-3 top-2.5 h-5 w-5 text-gray-400" />
              </div>
              
              {showClientDropdown && clientSearch && (
                <div className="absolute z-10 w-full bg-white border rounded-md shadow-lg max-h-60 overflow-auto">
                  {filteredClients.length > 0 ? (
                    filteredClients.map(client => (
                      <div
                        key={client.id}
                        className="px-4 py-2 hover:bg-gray-100 cursor-pointer"
                        onClick={() => handleClientSelect(client)}
                      >
                        {client.name}
                      </div>
                    ))
                  ) : (
                    <div className="px-4 py-2 text-gray-500">No clients found</div>
                  )}
                </div>
              )}
            </div>
            {selectedClient && (
              <div className="mt-2 p-2 bg-gray-50 rounded">
                <p className="text-sm font-medium">{selectedClient.name}</p>
              </div>
            )}
          </div>

          {/* Delivery Address - Moved up, right after client selection */}
          {selectedClient && clientAddresses.length > 0 && (
            <div>
              <label className="block mb-2">Delivery Address</label>
              <select
                value={formData.deliveryAddressId || ''}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  deliveryAddressId: e.target.value 
                }))}
                className="w-full p-2 border rounded"
                required
              >
                <option value="">Select Delivery Address</option>
                {clientAddresses.map(address => (
                  <option key={address.id} value={address.id}>
                    {[
                      address.street_address,
                      address.neighborhood,
                      address.borough
                    ].filter(Boolean).join(' - ')}
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* Dates */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block mb-2">Sale Date</label>
              <Input
                type="date"
                value={formData.saleDate}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  saleDate: e.target.value 
                }))}
                required
              />
            </div>
            <div>
              <label className="block mb-2">Delivery Date</label>
              <Input
                type="date"
                value={formData.deliveryDate}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  deliveryDate: e.target.value 
                }))}
                required
              />
            </div>
          </div>

          {/* Items */}
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h3 className="font-medium">Items</h3>
              <Button type="button" onClick={addItem}>
                <Plus className="h-4 w-4 mr-2" />
                Add Item
              </Button>
            </div>

            {formData.items.map((item, index) => (
              <div key={index} className="grid grid-cols-12 gap-4 items-end">
                <div className="col-span-5">
                  <select
                    value={item.productId}
                    onChange={(e) => updateItem(index, { 
                      productId: e.target.value
                    })}
                    className="w-full p-2 border rounded"
                    required
                  >
                    <option value="">Select Product</option>
                    {products.map(product => (
                      <option key={product.id} value={product.id}>
                        {product.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="col-span-2">
                  <Input
                    type="number"
                    value={item.quantity}
                    onChange={(e) => updateItem(index, { 
                      quantity: parseFloat(e.target.value)
                    })}
                    placeholder="Qty"
                    required
                    min="1"
                    step="1"
                  />
                </div>

                <div className="col-span-2">
                  <Input
                    type="number"
                    value={item.unitPrice}
                    readOnly
                    placeholder="Price"
                    className="bg-gray-50"
                  />
                </div>

                <div className="col-span-2">
                  <Input
                    type="number"
                    value={item.totalPrice?.toFixed(2)}
                    readOnly
                    placeholder="Total"
                    className="bg-gray-50"
                  />
                </div>

                <div className="col-span-1">
                  <Button 
                    type="button"
                    variant="ghost"
                    onClick={() => removeItem(index)}
                  >
                    <Minus className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            ))}

            {formData.items.length > 0 && (
              <div className="flex justify-end text-lg font-semibold">
                Total: ${calculateTotal().toFixed(2)}
              </div>
            )}
          </div>

          {/* Notes */}
          <div>
            <label className="block mb-2">Notes</label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData(prev => ({ 
                ...prev, 
                notes: e.target.value 
              }))}
              className="w-full p-2 border rounded min-h-[100px]"
              placeholder="Add any notes about this sale..."
            />
          </div>

          <div className="flex justify-end gap-4">
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit">
              {editingSale ? 'Update Sale' : 'Create Sale'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
} 