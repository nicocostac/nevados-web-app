import { useState, useEffect, useRef } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { X, Plus, Minus, Search } from 'lucide-react'
import { supabase } from '@/lib/supabaseClient'
import { formatCurrency } from '@/lib/utils/format'

// Add this helper function at the top of the component, after the imports
const formatDate = (dateString) => {
  if (!dateString) return ''
  
  // Parse the input date string
  const date = new Date(dateString)
  
  // Get the local date components
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  
  // Return the date in YYYY-MM-DD format
  return `${year}-${month}-${day}`
}

export default function SaleFormModal({ 
  isOpen, 
  onClose, 
  onSubmit, 
  editingSale = null,
  clients = [],
  products = [],
  paymentMethods = []
}) {
  const [error, setError] = useState('')
  const [formData, setFormData] = useState({
    clientId: '',
    saleDate: new Date().toISOString().split('T')[0],
    deliveryDate: new Date().toISOString().split('T')[0],
    items: [],
    notes: '',
    paymentStatus: 'pending',
    paymentMethodId: '',
    paymentDate: '',
    paymentNotes: ''
  })
  const [clientSearch, setClientSearch] = useState('')
  const [filteredClients, setFilteredClients] = useState(clients)
  const [specialPrices, setSpecialPrices] = useState({})
  const [showClientDropdown, setShowClientDropdown] = useState(false)
  const [selectedClient, setSelectedClient] = useState(null)
  const [clientAddresses, setClientAddresses] = useState([])
  const [productPrices, setProductPrices] = useState({})
  const dropdownRef = useRef(null)

  useEffect(() => {
    if (editingSale) {
      const items = editingSale.sale_items.map(item => ({
        productId: item.product_id,
        quantity: item.quantity,
        unitPrice: item.unit_price,
        totalPrice: item.total_price,
        discountPercentage: item.discount_percentage
      }))

      // For editing, use the dates directly from the database
      setFormData({
        clientId: editingSale.client_id || '',
        saleDate: editingSale.sale_date,
        deliveryDate: editingSale.delivery_date,
        deliveryAddressId: editingSale.delivery_address_id,
        items: items || [],
        notes: editingSale.notes || '',
        paymentStatus: editingSale.payment_status || 'pending',
        paymentMethodId: editingSale.payment_method_id || '',
        paymentDate: editingSale.payment_date ? formatDate(editingSale.payment_date) : '',
        paymentNotes: editingSale.payment_notes || ''
      })

      const client = clients.find(client => client.id === editingSale.client_id)
      setSelectedClient(client)
      if (client) {
        fetchClientAddresses(client.id)
        fetchSpecialPrices(client.id)
      }
    } else {
      // For new sales, use today's date
      const today = new Date()
      setFormData({
        clientId: '',
        saleDate: formatDate(today),
        deliveryDate: formatDate(today),
        items: [],
        notes: '',
        paymentStatus: 'pending',
        paymentMethodId: '',
        paymentDate: '',
        paymentNotes: ''
      })
      setSelectedClient(null)
      setClientAddresses([])
    }
  }, [editingSale, clients])

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

  // Fetch product prices when client or sale date changes
  useEffect(() => {
    if (formData.saleDate && formData.clientId) {
      fetchProductPrices(formData.saleDate, formData.clientId)
    }
  }, [formData.saleDate, formData.clientId])

  // Add useEffect to fetch prices when component mounts with initial data
  useEffect(() => {
    if (formData.clientId && formData.saleDate) {
      console.log('Initial fetch of product prices');
      fetchProductPrices(formData.saleDate, formData.clientId);
    }
  }, []);

  const fetchSpecialPrices = async (clientId) => {
    if (!clientId) return;
    
    const currentDate = formatDate(new Date());
    
    const { data, error } = await supabase
      .from('client_prices')
      .select('*')
      .eq('client_id', clientId)
      .lte('start_date', currentDate)
      .or(`end_date.is.null,end_date.gt.${currentDate}`);

    if (error) {
      console.error('Error fetching special prices:', error);
    } else {
      console.log('Fetched special prices:', data);
      const pricesMap = {};
      data.forEach(price => {
        pricesMap[price.product_id] = {
          price: price.final_price,
          isClientPrice: true,
          validFrom: price.start_date,
          validUntil: price.end_date
        };
      });
      setSpecialPrices(pricesMap);
    }
  };

  const fetchProductPrices = async (saleDate, clientId) => {
    if (!saleDate || !clientId) {
      console.log('Missing required data:', { saleDate, clientId });
      return;
    }
    
    const formattedDate = formatDate(saleDate);
    console.log('Fetching prices with:', { 
      originalDate: saleDate,
      formattedDate,
      clientId,
      products: products.map(p => ({ id: p.id, name: p.name }))
    });
    
    try {
      // Get prices for all products
      const { data, error } = await supabase
        .from('products')
        .select('id')
        .in('id', products.map(p => p.id))
        .then(async ({ data: productIds, error: productsError }) => {
          if (productsError) throw productsError;
          
          console.log('Fetching prices for products:', productIds);
          
          const prices = await Promise.all(
            productIds.map(({ id }) =>
              supabase
                .rpc('get_product_price_at_date', {
                  product_id: id,
                  target_date: formattedDate,
                  client_id: clientId
                })
                .then(({ data, error }) => {
                  console.log('Price result for product', id, ':', { data, error });
                  return { id, data, error };
                })
            )
          );
          
          return { data: prices };
        });

      if (error) throw error;

      // Create a map of product prices
      const priceMap = {};
      data.forEach(({ id, data: priceData, error: priceError }) => {
        if (priceError) {
          console.error('Error fetching price for product', id, ':', priceError);
          return;
        }
        
        if (priceData && priceData[0]) {
          priceMap[id] = {
            price: parseFloat(priceData[0].price),
            isClientPrice: priceData[0].price_type === 'client'
          };
        }
      });

      console.log('Final price map:', priceMap);
      setProductPrices(priceMap);

      // Update unit prices for existing items
      setFormData(prev => ({
        ...prev,
        items: prev.items.map(item => {
          const priceInfo = priceMap[item.productId];
          if (priceInfo) {
            return {
              ...item,
              unitPrice: priceInfo.price,
              priceType: priceInfo.isClientPrice ? 'client' : 'regular',
              totalPrice: item.quantity * priceInfo.price
            };
          }
          return item;
        })
      }));
    } catch (error) {
      console.error('Error in fetchProductPrices:', error);
    }
  };

  const fetchClientAddresses = async (clientId) => {
    if (!clientId) return;
    
    console.log('Fetching addresses for client:', clientId);
    try {
      const { data, error } = await supabase
        .from('client_addresses')
        .select(`
          id,
          street_address,
          is_default,
          borough_id,
          neighborhood_id,
          boroughs (
            id,
            name
          ),
          neighborhoods (
            id,
            name
          )
        `)
        .eq('client_id', clientId)
        .order('is_default', { ascending: false });

      if (error) {
        console.error('Error fetching client addresses:', error);
        setClientAddresses([]);
        return;
      }

      console.log('Fetched addresses:', data);
      setClientAddresses(data || []);
      
      // Auto-select default address if available
      const defaultAddress = data?.find(addr => addr.is_default);
      if (defaultAddress) {
        console.log('Setting default address:', defaultAddress.id);
        setFormData(prev => ({
          ...prev,
          deliveryAddressId: defaultAddress.id
        }));
      }
    } catch (error) {
      console.error('Unexpected error fetching client addresses:', error);
      setClientAddresses([]);
    }
  };

  const handleClientSelect = async (client) => {
    console.log('Client selected:', client);
    setSelectedClient(client);
    setFormData(prev => ({ 
      ...prev, 
      clientId: client.id,
      deliveryAddressId: '' // Reset address ID before fetching new addresses
    }));
    setClientSearch(client.name);
    setShowClientDropdown(false);
    
    // First fetch addresses, then fetch prices
    await fetchClientAddresses(client.id);
    await fetchProductPrices(formData.saleDate, client.id);
  };

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

  const updateItem = (index, field, value) => {
    setFormData(prev => {
      const newItems = [...prev.items]
      const item = { ...newItems[index] }

      if (field === 'productId') {
        const priceInfo = productPrices[value]
        
        console.log('Updating product:', value);
        console.log('Price info:', priceInfo);
        
        item.productId = value
        item.unitPrice = priceInfo?.price || 0
        item.totalPrice = (priceInfo?.price || 0) * (item.quantity || 0)
        item.priceType = priceInfo?.isClientPrice ? 'client' : 'regular'
      } else if (field === 'quantity') {
        item.quantity = value
        item.totalPrice = item.unitPrice * value
      }

      newItems[index] = item
      return { ...prev, items: newItems }
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

  const handleSaleDateChange = (newSaleDate) => {
    console.log('Sale date changed to:', newSaleDate);
    setFormData(prev => {
      // If delivery date is before the new sale date, update it to the sale date
      const updatedDeliveryDate = prev.deliveryDate < newSaleDate 
        ? newSaleDate 
        : prev.deliveryDate;
      
      return { 
        ...prev, 
        saleDate: newSaleDate,
        deliveryDate: updatedDeliveryDate
      };
    });
    
    // Refresh prices if we have a client selected
    if (formData.clientId) {
      fetchProductPrices(newSaleDate, formData.clientId);
    }
  };

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

  useEffect(() => {
    if (clientAddresses.length > 0) {
      const defaultAddress = clientAddresses.find(addr => addr.is_default)
      if (defaultAddress) {
        setFormData(prev => ({
          ...prev,
          deliveryAddressId: defaultAddress.id
        }))
      }
    }
  }, [clientAddresses])

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-4xl max-h-[90vh] overflow-y-auto relative">
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

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Client Search */}
          <div className="mb-4 relative" ref={dropdownRef}>
            <label className="block mb-2">Client</label>
            <div className="relative">
              <Input
                type="text"
                value={clientSearch}
                onChange={(e) => {
                  if (!editingSale) { // Only allow changes if not editing
                    setClientSearch(e.target.value)
                    setShowClientDropdown(true)
                    if (!e.target.value) {
                      setSelectedClient(null)
                      setFormData(prev => ({ ...prev, clientId: '' }))
                    }
                  }
                }}
                onFocus={() => setShowClientDropdown(true)}
                placeholder="Search clients..."
                required
                className="pr-8"
                readOnly={!!editingSale} // Make read-only when editing
              />
              <Search className="absolute right-2 top-2.5 h-4 w-4 text-gray-500" />
            </div>
            {showClientDropdown && (
              <div className="absolute z-10 w-full mt-1 bg-white border rounded-md shadow-lg max-h-60 overflow-auto">
                {filteredClients.map(client => (
                  <div
                    key={client.id}
                    className="px-4 py-2 hover:bg-gray-100 cursor-pointer"
                    onClick={() => handleClientSelect(client)}
                  >
                    {client.name}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Delivery Address Selection */}
          {selectedClient && (
            <div className="mb-4">
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
                <option value="">Select delivery address</option>
                {clientAddresses.map(address => {
                  // Build address parts, filtering out empty values
                  const addressParts = [
                    address.street_address,
                    address.neighborhoods?.name,
                    address.boroughs?.name
                  ].filter(Boolean);

                  return (
                    <option key={address.id} value={address.id}>
                      {addressParts.join(', ')}
                      {address.is_default ? ' (Default)' : ''}
                    </option>
                  );
                })}
              </select>
            </div>
          )}

          {/* Dates */}
          <div className="grid grid-cols-2 gap-4 mb-4">
            <div>
              <label className="block mb-2">Sale Date</label>
              <Input
                type="date"
                value={formData.saleDate}
                onChange={(e) => handleSaleDateChange(e.target.value)}
                required
              />
            </div>
            <div>
              <label className="block mb-2">Delivery Date</label>
              <Input
                type="date"
                value={formData.deliveryDate}
                min={formData.saleDate}
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
                    value={item.productId || ''}
                    onChange={(e) => updateItem(index, 'productId', e.target.value)}
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
                    value={item.quantity || ''}
                    onChange={(e) => updateItem(index, 'quantity', parseFloat(e.target.value))}
                    placeholder="Qty"
                    required
                    min="1"
                    step="1"
                  />
                </div>

                <div className="col-span-2">
                  <div className="relative">
                    <Input
                      type="text"
                      value={formatCurrency(item.unitPrice) || ''}
                      readOnly
                      placeholder="Price"
                      className={`bg-gray-50 ${item.priceType === 'client' ? 'border-blue-500' : ''}`}
                    />
                    {item.priceType === 'client' && (
                      <span className="absolute -top-4 right-0 text-xs text-blue-500">Special Price</span>
                    )}
                  </div>
                </div>

                <div className="col-span-2">
                  <Input
                    type="text"
                    value={formatCurrency(item.totalPrice) || ''}
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
                Total: {formatCurrency(calculateTotal())}
              </div>
            )}
          </div>

          {/* Notes */}
          <div>
            <label className="block mb-2">Notas</label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData(prev => ({ 
                ...prev, 
                notes: e.target.value 
              }))}
              className="w-full p-2 border rounded min-h-[100px]"
              placeholder="Agregar notas sobre esta venta..."
            />
          </div>

          {/* Payment Information */}
          <div className="space-y-4 border-t pt-4 mt-4">
            <h3 className="font-medium">Información de Pago</h3>
            
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block mb-2">Estado de Pago</label>
                <select
                  value={formData.paymentStatus}
                  onChange={(e) => setFormData(prev => ({ 
                    ...prev, 
                    paymentStatus: e.target.value,
                    paymentDate: e.target.value === 'paid' ? new Date().toISOString().split('T')[0] : ''
                  }))}
                  className="w-full p-2 border rounded"
                >
                  <option value="pending">Pendiente</option>
                  <option value="paid">Pagado</option>
                  <option value="cancelled">Cancelado</option>
                </select>
              </div>

              {formData.paymentStatus === 'paid' && (
                <div>
                  <label className="block mb-2">Método de Pago</label>
                  <select
                    value={formData.paymentMethodId}
                    onChange={(e) => setFormData(prev => ({ 
                      ...prev, 
                      paymentMethodId: e.target.value 
                    }))}
                    className="w-full p-2 border rounded"
                    required
                  >
                    <option value="">Seleccione el Método de Pago</option>
                    {paymentMethods.map(method => (
                      <option key={method.id} value={method.id}>
                        {method.name}
                      </option>
                    ))}
                  </select>
                </div>
              )}
            </div>

            {formData.paymentStatus === 'paid' && (
              <>
                <div>
                  <label className="block mb-2">Fecha de Pago</label>
                  <Input
                    type="date"
                    value={formData.paymentDate}
                    onChange={(e) => setFormData(prev => ({ 
                      ...prev, 
                      paymentDate: e.target.value 
                    }))}
                    required
                  />
                </div>

                <div>
                  <label className="block mb-2">Notas de Pago</label>
                  <textarea
                    value={formData.paymentNotes}
                    onChange={(e) => setFormData(prev => ({ 
                      ...prev, 
                      paymentNotes: e.target.value 
                    }))}
                    className="w-full p-2 border rounded"
                    placeholder="Agregar notas sobre el pago..."
                  />
                </div>
              </>
            )}
          </div>

          <div className="flex justify-end gap-4">
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit">
              {editingSale ? 'Actualizar Venta' : 'Crear Venta'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
} 