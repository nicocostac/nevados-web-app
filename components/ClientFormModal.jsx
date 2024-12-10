import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { X, Plus, MapPin, Edit2, Trash2 } from 'lucide-react'
import { supabase } from '@/lib/supabaseClient'
import { useAuth } from '@/lib/context/AuthContext'
import AddressFormModal from './AddressFormModal'
import ClientPriceFormModal from './ClientPriceFormModal'
import { formatCurrency } from '@/lib/utils/format'

export default function ClientFormModal({ 
  isOpen, 
  onClose, 
  onSubmit, 
  editingClient = null,
  clientTypes = [],
  products = []
}) {
  const { user: currentUser } = useAuth()
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    phone_2: '',
    notes: '',
    type_id: clientTypes.find(type => type.name.toLowerCase() === 'retail')?.id || '',
    communication_preference: 'whatsapp',
    status: 'active',
    is_tj: false
  })
  const [addresses, setAddresses] = useState([])
  const [isAddressModalOpen, setIsAddressModalOpen] = useState(false)
  const [editingAddress, setEditingAddress] = useState(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)
  const [isPriceModalOpen, setIsPriceModalOpen] = useState(false)
  const [editingPrice, setEditingPrice] = useState(null)
  const [specialPrices, setSpecialPrices] = useState([])
  const [tempSpecialPrices, setTempSpecialPrices] = useState([])
  const [currentPrices, setCurrentPrices] = useState({})

  useEffect(() => {
    if (editingClient) {
      setFormData({
        name: editingClient.name || '',
        email: editingClient.email || '',
        phone: formatPhoneNumber(editingClient.phone || ''),
        phone_2: formatPhoneNumber(editingClient.phone_2 || ''),
        notes: editingClient.notes || '',
        type_id: editingClient.type_id || clientTypes.find(type => type.name.toLowerCase() === 'retail')?.id || '',
        communication_preference: editingClient.communication_preference || 'whatsapp',
        status: editingClient.status || 'active',
        is_tj: editingClient.is_tj || false
      })

      // Fetch addresses if editing a client
      fetchAddresses(editingClient.id)

      // Fetch special prices if editing a client
      fetchSpecialPrices(editingClient.id)
      setTempSpecialPrices([])
    } else {
      setFormData({
        name: '',
        email: '',
        phone: '',
        phone_2: '',
        notes: '',
        type_id: clientTypes.find(type => type.name.toLowerCase() === 'retail')?.id || '',
        communication_preference: 'whatsapp',
        status: 'active',
        is_tj: false
      })
      setAddresses([])
      setSpecialPrices([])
      setTempSpecialPrices([])
    }
  }, [editingClient, clientTypes])

  useEffect(() => {
    // Fetch current prices for all products
    const fetchCurrentPrices = async () => {
      const today = new Date().toISOString().split('T')[0]
      const promises = products.map(async (product) => {
        const { data, error } = await supabase.rpc('get_product_price_at_date', {
          product_id: product.id,
          target_date: today
        })
        
        if (error) {
          console.error('Error fetching current price:', error)
          return
        }

        if (data && data[0]) {
          return { productId: product.id, price: data[0].price }
        }
      })

      const results = await Promise.all(promises)
      const pricesMap = {}
      results.forEach(result => {
        if (result) {
          pricesMap[result.productId] = result.price
        }
      })
      setCurrentPrices(pricesMap)
    }

    fetchCurrentPrices()
  }, [products])

  const fetchAddresses = async (clientId) => {
    const { data, error } = await supabase
      .from('client_addresses')
      .select(`
        *,
        boroughs:boroughs(name),
        neighborhoods:neighborhoods(name)
      `)
      .eq('client_id', clientId)
      .order('is_default', { ascending: false })

    if (error) {
      console.error('Error fetching addresses:', error)
    } else {
      setAddresses(data || [])
    }
  }

  const fetchSpecialPrices = async (clientId) => {
    try {
      // First, get the client prices with basic product info
      const { data: clientPrices, error: clientPricesError } = await supabase
        .from('client_prices')
        .select(`
          *,
          products (
            id,
            name
          )
        `)
        .eq('client_id', clientId)
        .order('created_at', { ascending: false });

      if (clientPricesError) {
        console.error('Error fetching special prices:', clientPricesError);
        return;
      }

      // For each product in client prices, get its current regular price
      const today = new Date().toISOString().split('T')[0];
      const pricePromises = clientPrices.map(async (price) => {
        const { data: priceData, error: priceError } = await supabase.rpc('get_product_price_at_date', {
          product_id: price.product_id,
          target_date: today,
          client_id: null // Pass null to get regular price
        });

        if (priceError) {
          console.error('Error fetching product price:', priceError);
          return price;
        }

        // Calculate the final price based on the discount percentage
        const regularPrice = priceData[0]?.price || 0;
        const discountPercentage = price.discount_percentage || 0;
        const finalPrice = regularPrice * (1 - discountPercentage / 100);

        return {
          ...price,
          current_regular_price: regularPrice,
          final_price: finalPrice
        };
      });

      const pricesWithRegularPrices = await Promise.all(pricePromises);
      setSpecialPrices(pricesWithRegularPrices);
    } catch (error) {
      console.error('Error in fetchSpecialPrices:', error);
    }
  };

  const handleAddressSubmit = async (addressData) => {
    try {
      const isFirstAddress = addresses.length === 0;
      const newAddress = {
        ...addressData,
        is_default: isFirstAddress ? true : addressData.is_default,
        client_id: editingClient?.id
      };

      if (editingAddress) {
        if (editingClient?.id) {
          // For existing client, update in database
          const { error } = await supabase
            .from('client_addresses')
            .update(newAddress)
            .eq('id', editingAddress.id);

          if (error) throw error;
          
          // Update the address in the local state
          setAddresses(prev => prev.map(addr => 
            addr.id === editingAddress.id ? { ...addr, ...newAddress } : addr
          ));
        } else {
          // For new client, update in local state only
          // Get borough and neighborhood data
          const [{ data: boroughData }, { data: neighborhoodData }] = await Promise.all([
            supabase
              .from('boroughs')
              .select('name')
              .eq('id', addressData.borough_id)
              .single(),
            addressData.neighborhood_id ? 
              supabase
                .from('neighborhoods')
                .select('name')
                .eq('id', addressData.neighborhood_id)
                .single() :
              Promise.resolve({ data: null })
          ]);

          // Update the temporary address
          const updatedAddress = {
            ...newAddress,
            id: editingAddress.id, // Keep the same temporary ID
            boroughs: { name: boroughData?.name },
            neighborhoods: neighborhoodData ? { name: neighborhoodData.name } : null
          };

          setAddresses(prev => prev.map(addr => 
            addr.id === editingAddress.id ? updatedAddress : addr
          ));
        }
      } else {
        if (editingClient?.id) {
          // For existing client, insert to database
          const { data, error } = await supabase
            .from('client_addresses')
            .insert([newAddress])
            .select(`
              *,
              boroughs:boroughs(name),
              neighborhoods:neighborhoods(name)
            `);

          if (error) throw error;
          
          // Add the new address to the local state
          setAddresses(prev => [...prev, data[0]]);
        } else {
          // For new client, fetch borough and neighborhood data
          const [{ data: boroughData }, { data: neighborhoodData }] = await Promise.all([
            supabase
              .from('boroughs')
              .select('name')
              .eq('id', addressData.borough_id)
              .single(),
            addressData.neighborhood_id ? 
              supabase
                .from('neighborhoods')
                .select('name')
                .eq('id', addressData.neighborhood_id)
                .single() :
              Promise.resolve({ data: null })
          ]);

          // Create temporary address with borough and neighborhood data
          const tempAddress = {
            ...newAddress,
            id: `temp_${Date.now()}`,
            boroughs: { name: boroughData?.name },
            neighborhoods: neighborhoodData ? { name: neighborhoodData.name } : null
          };
          setAddresses(prev => [...prev, tempAddress]);
        }
      }
    } catch (error) {
      console.error('Error handling address:', error);
      throw error;
    }
  }

  const handleDeleteAddress = async (addressId) => {
    if (!window.confirm('Are you sure you want to delete this address?')) {
      return
    }

    const { error } = await supabase
      .from('client_addresses')
      .delete()
      .eq('id', addressId)

    if (error) {
      console.error('Error deleting address:', error)
    } else {
      setAddresses(addresses.filter(a => a.id !== addressId))
    }
  }

  const handlePriceSubmit = async (priceData) => {
    if (editingClient) {
      // Existing client - save to database
      const newPrice = {
        ...priceData,
        client_id: editingClient.id
      }

      if (editingPrice) {
        const { error } = await supabase
          .from('client_prices')
          .update(newPrice)
          .eq('id', editingPrice.id)

        if (error) throw error
      } else {
        const { error } = await supabase
          .from('client_prices')
          .insert([newPrice])

        if (error) throw error
      }

      // Refresh special prices list
      await fetchSpecialPrices(editingClient.id)
    } else {
      // New client - store in temporary state
      if (editingPrice) {
        // Update existing temporary price
        setTempSpecialPrices(prev => 
          prev.map(p => p.tempId === editingPrice.tempId ? { ...priceData, tempId: p.tempId } : p)
        )
      } else {
        // Add new temporary price
        setTempSpecialPrices(prev => [...prev, { ...priceData, tempId: Date.now() }])
      }
    }
  }

  const handleDeletePrice = async (priceId) => {
    if (!window.confirm('Are you sure you want to delete this special price?')) {
      return
    }

    if (editingClient) {
      // Delete from database
      const { error } = await supabase
        .from('client_prices')
        .delete()
        .eq('id', priceId)

      if (error) {
        console.error('Error deleting special price:', error)
      } else {
        setSpecialPrices(specialPrices.filter(p => p.id !== priceId))
      }
    } else {
      // Delete from temporary state
      setTempSpecialPrices(prev => prev.filter(p => p.tempId !== priceId))
    }
  }

  const formatPhoneNumber = (phone) => {
    // Remove all spaces and any other non-essential characters
    return phone.replace(/\s+/g, '');
  };

  const handlePhoneChange = (e, field) => {
    const formattedPhone = formatPhoneNumber(e.target.value);
    setFormData(prev => ({ ...prev, [field]: formattedPhone }));
  };

  const openInGoogleMaps = (address) => {
    // Construct full address string
    const fullAddress = `${address.street_address}, ${address.boroughs?.name}${address.neighborhoods?.name ? `, ${address.neighborhoods.name}` : ''}, Santiago, Chile`;
    const encodedAddress = encodeURIComponent(fullAddress);

    if (address.latitude && address.longitude) {
      // Open using coordinates with address label for the pin
      window.open(`https://www.google.com/maps/search/${encodedAddress}/@${address.latitude},${address.longitude},17z`, '_blank');
    } else {
      // Fallback to address search if coordinates are not available
      window.open(`https://www.google.com/maps/search/?api=1&query=${encodedAddress}`, '_blank');
    }
  };

  const handleNewAddress = async (addressData) => {
    try {
      // For new clients, store addresses in state to be saved after client creation
      if (!editingClient) {
        // Set is_default to true if this is the first address
        const isFirstAddress = addresses.length === 0;
        
        // Get borough and neighborhood data for display purposes only
        const [{ data: boroughData }, { data: neighborhoodData }] = await Promise.all([
          supabase
            .from('boroughs')
            .select('name')
            .eq('id', addressData.borough_id)
            .single(),
          addressData.neighborhood_id ? 
            supabase
              .from('neighborhoods')
              .select('name')
              .eq('id', addressData.neighborhood_id)
              .single() :
            Promise.resolve({ data: null })
        ]);

        // Create temporary address
        const newAddress = {
          ...addressData,
          id: editingAddress?.id || `temp_${Date.now()}`,
          is_default: isFirstAddress,
          contact_person: addressData.contact_person || formData.name,
          // Store display data separately from the actual data
          _boroughName: boroughData?.name,
          _neighborhoodName: neighborhoodData?.name
        };

        if (editingAddress) {
          // Update existing address
          setAddresses(prev => prev.map(addr => 
            addr.id === editingAddress.id ? newAddress : addr
          ));
        } else {
          // Add new address
          setAddresses(prev => [...prev, newAddress]);
        }
      } else {
        // For existing clients, save address directly to database
        await handleAddressSubmit({
          ...addressData,
          contact_person: addressData.contact_person || editingClient.name
        });
      }
    } catch (error) {
      console.error('Error handling address:', error);
      throw error;
    }
  };

  if (!isOpen) return null

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)

    try {
      let clientId;
      
      if (editingClient) {
        // Update existing client
        const { error } = await supabase
          .from('clients')
          .update({
            name: formData.name,
            email: formData.email,
            phone: formData.phone,
            phone_2: formData.phone_2,
            notes: formData.notes,
            type_id: formData.type_id,
            communication_preference: formData.communication_preference,
            status: formData.status,
            is_tj: formData.is_tj
          })
          .eq('id', editingClient.id)

        if (error) throw error
        clientId = editingClient.id
      } else {
        // Create new client
        const { data, error } = await supabase
          .from('clients')
          .insert([
            {
              name: formData.name,
              email: formData.email,
              phone: formData.phone,
              phone_2: formData.phone_2,
              notes: formData.notes,
              type_id: formData.type_id,
              communication_preference: formData.communication_preference,
              status: formData.status,
              is_tj: formData.is_tj,
              created_by: currentUser.id
            }
          ])
          .select()

        if (error) throw error
        clientId = data?.[0]?.id

        // If we have addresses to add for a new client
        if (clientId && addresses.length > 0) {
          const addressesWithClientId = addresses.map(({ _boroughName, _neighborhoodName, id, ...address }) => ({
            ...address,
            client_id: clientId
          }))

          const { error: addressError } = await supabase
            .from('client_addresses')
            .insert(addressesWithClientId)

          if (addressError) throw addressError
        }

        // If we have special prices to add for a new client
        if (clientId && tempSpecialPrices.length > 0) {
          const pricesWithClientId = tempSpecialPrices.map(({ tempId, ...price }) => ({
            ...price,
            client_id: clientId
          }))

          const { error: pricesError } = await supabase
            .from('client_prices')
            .insert(pricesWithClientId)

          if (pricesError) throw pricesError
        }
      }

      // Reset all form data
      setFormData({
        name: '',
        email: '',
        phone: '',
        phone_2: '',
        notes: '',
        type_id: clientTypes.find(type => type.name.toLowerCase() === 'retail')?.id || '',
        communication_preference: 'whatsapp',
        status: 'active',
        is_tj: false
      })
      setAddresses([])
      setTempSpecialPrices([])
      
      // Call onSubmit only once with success flag
      await onSubmit(true)
      onClose()
    } catch (error) {
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
          {editingClient ? 'Edit Client' : 'Create New Client'}
        </h2>

        {error && (
          <Alert variant="destructive" className="mb-4">{error}</Alert>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Basic Information */}
          <div className="space-y-4">
            <h3 className="text-lg font-medium">Basic Information</h3>
            <Input
              name="name"
              placeholder="Client Name"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              required
            />

            <div className="grid grid-cols-3 gap-4">
              <Input
                type="email"
                name="email"
                placeholder="Email"
                value={formData.email}
                onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
              />

              <Input
                type="tel"
                name="phone"
                placeholder="Primary Phone"
                value={formData.phone}
                onChange={(e) => handlePhoneChange(e, 'phone')}
              />

              <Input
                type="tel"
                name="phone_2"
                placeholder="Secondary Phone"
                value={formData.phone_2}
                onChange={(e) => handlePhoneChange(e, 'phone_2')}
              />
            </div>
          </div>

          {/* Addresses Section */}
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h3 className="text-lg font-medium">Addresses</h3>
              <Button
                type="button"
                onClick={() => {
                  setEditingAddress(null)
                  setIsAddressModalOpen(true)
                }}
              >
                <Plus className="h-4 w-4 mr-2" />
                Add Address
              </Button>
            </div>

            <div className="space-y-2">
              {addresses.map((address) => (
                <div
                  key={address.id || `temp_${address.street_address}_${Date.now()}`}
                  className="flex items-start justify-between p-3 border rounded"
                >
                  <div className="flex items-start space-x-3">
                    <MapPin className="h-5 w-5 mt-1 text-gray-400" />
                    <div>
                      <div className="font-medium">
                        {address.street_address}
                        {address.is_default && (
                          <span className="ml-2 text-sm text-blue-600">(Default)</span>
                        )}
                      </div>
                      <div className="text-sm text-gray-500">
                        {/* Use the display names for temporary addresses, fall back to relationship data for saved addresses */}
                        {address._boroughName || address.boroughs?.name}
                        {(address._neighborhoodName || address.neighborhoods?.name) && 
                          `, ${address._neighborhoodName || address.neighborhoods?.name}`}
                      </div>
                      {address.additional_info && (
                        <div className="text-sm text-gray-500">{address.additional_info}</div>
                      )}
                    </div>
                  </div>
                  <div className="flex space-x-2">
                    {(address.latitude || address.longitude) && (
                      <button
                        type="button"
                        onClick={() => openInGoogleMaps(address)}
                        className="text-blue-600 hover:text-blue-800"
                        title="Open in Google Maps"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
                          <path d="M12 0C7.802 0 4 3.403 4 7.602C4 11.8 7.469 16.812 12 24C16.531 16.812 20 11.8 20 7.602C20 3.403 16.199 0 12 0ZM12 11C10.343 11 9 9.657 9 8C9 6.343 10.343 5 12 5C13.657 5 15 6.343 15 8C15 9.657 13.657 11 12 11Z"/>
                        </svg>
                      </button>
                    )}
                    <button
                      type="button"
                      onClick={() => {
                        setEditingAddress(address)
                        setIsAddressModalOpen(true)
                      }}
                      className="text-blue-600 hover:text-blue-800"
                    >
                      <Edit2 className="h-5 w-5" />
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDeleteAddress(address.id)}
                      className="text-red-600 hover:text-red-800"
                    >
                      <Trash2 className="h-5 w-5" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Special Prices Section - Show for both new and existing clients */}
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h3 className="text-lg font-medium">Special Prices</h3>
              <Button
                type="button"
                onClick={() => {
                  setEditingPrice(null)
                  setIsPriceModalOpen(true)
                }}
              >
                <Plus className="h-4 w-4 mr-2" />
                Add Special Price
              </Button>
            </div>

            <div className="space-y-2">
              {/* Show saved prices for existing clients */}
              {editingClient && specialPrices.map((price) => (
                <div
                  key={price.id || `temp_price_${price.product_id}_${Date.now()}`}
                  className="flex items-start justify-between p-3 border rounded"
                >
                  <div>
                    <div className="font-medium">{price.products.name}</div>
                    <div className="text-sm text-gray-500">
                      <span>Valid from: {new Date(price.start_date).toLocaleDateString()}</span>
                      <span className="ml-2">Valid until: {price.end_date ? new Date(price.end_date).toLocaleDateString() : 'No end date'}</span>
                    </div>
                    <div className="text-sm text-gray-500">
                      Regular: {formatCurrency(price.current_regular_price || 0)} | 
                      Special: {formatCurrency(price.final_price || 0)} ({(price.discount_percentage || 0).toFixed(1)}% off)
                    </div>
                    {price.notes && (
                      <div className="text-sm text-gray-500">{price.notes}</div>
                    )}
                  </div>
                  <div className="flex gap-2">
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => {
                        setEditingPrice(price)
                        setIsPriceModalOpen(true)
                      }}
                    >
                      <Edit2 className="h-4 w-4" />
                    </Button>
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => handleDeletePrice(price.id)}
                    >
                      <Trash2 className="h-4 w-4 text-red-500" />
                    </Button>
                  </div>
                </div>
              ))}

              {/* Show temporary prices for new clients */}
              {!editingClient && tempSpecialPrices.map((price) => (
                <div
                  key={price.tempId || `temp_price_${price.product_id}_${Date.now()}`}
                  className="flex items-start justify-between p-3 border rounded"
                >
                  <div>
                    <div className="font-medium">
                      {products.find(p => p.id === price.product_id)?.name}
                    </div>
                    <div className="text-sm text-gray-500">
                      <span>Valid from: {new Date(price.start_date).toLocaleDateString()}</span>
                      <span className="ml-2">Valid until: {price.end_date ? new Date(price.end_date).toLocaleDateString() : 'No end date'}</span>
                    </div>
                    <div className="text-sm text-gray-500">
                      Current: {formatCurrency(currentPrices[price.product_id] || 0)} | 
                      Special: {formatCurrency(price.price)} ({price.discount_percentage}% off)
                    </div>
                    {price.notes && (
                      <div className="text-sm text-gray-500">{price.notes}</div>
                    )}
                  </div>
                  <div className="flex gap-2">
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => {
                        setEditingPrice({ ...price, tempId: price.tempId })
                        setIsPriceModalOpen(true)
                      }}
                    >
                      <Edit2 className="h-4 w-4" />
                    </Button>
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => handleDeletePrice(price.tempId)}
                    >
                      <Trash2 className="h-4 w-4 text-red-500" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Other Information */}
          <div className="space-y-4">
            <h3 className="text-lg font-medium">Other Information</h3>
            <textarea
              name="notes"
              placeholder="Notes"
              value={formData.notes}
              onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
              className="w-full p-2 border rounded min-h-[100px]"
            />

            <div className="grid grid-cols-2 gap-4">
              <select
                name="type_id"
                value={formData.type_id}
                onChange={(e) => setFormData(prev => ({ ...prev, type_id: e.target.value }))}
                className="w-full p-2 border rounded"
                required
              >
                <option value="">Select Type</option>
                {clientTypes.map(type => (
                  <option key={type.id} value={type.id}>
                    {type.name.charAt(0).toUpperCase() + type.name.slice(1)}
                  </option>
                ))}
              </select>

              <select
                name="communication_preference"
                value={formData.communication_preference}
                onChange={(e) => setFormData(prev => ({ ...prev, communication_preference: e.target.value }))}
                className="w-full p-2 border rounded"
                required
              >
                <option value="email">Email</option>
                <option value="phone">Phone</option>
                <option value="whatsapp">WhatsApp</option>
              </select>
            </div>

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

            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="is_tj"
                checked={formData.is_tj}
                onChange={(e) => setFormData({ ...formData, is_tj: e.target.checked })}
                className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <label htmlFor="is_tj" className="text-sm font-medium text-gray-700">
                Is TJ
              </label>
            </div>
          </div>

          <div className="flex gap-2">
            <Button type="submit" disabled={isLoading}>
              {isLoading ? 'Saving...' : editingClient ? 'Update' : 'Create'}
            </Button>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
          </div>
        </form>
      </div>

      <AddressFormModal
        isOpen={isAddressModalOpen}
        onClose={() => {
          setIsAddressModalOpen(false)
          setEditingAddress(null)
        }}
        onSubmit={handleNewAddress}
        editingAddress={editingAddress}
      />

      <ClientPriceFormModal
        isOpen={isPriceModalOpen}
        onClose={() => {
          setIsPriceModalOpen(false)
          setEditingPrice(null)
        }}
        onSubmit={handlePriceSubmit}
        editingPrice={editingPrice}
        products={products}
      />
    </div>
  )
} 