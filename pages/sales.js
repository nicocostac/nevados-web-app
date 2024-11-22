import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Plus, Filter, X } from 'lucide-react'
import { Alert } from '@/components/ui/alert'
import SaleFormModal from '@/components/SaleFormModal'
import { Input } from '@/components/ui/input'
import { Calendar } from 'lucide-react'

const formatCurrency = (amount) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'CLP',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(amount)
    .replace('CLP', '$')
    .trim();
};

function SalesManagement() {
  const [sales, setSales] = useState([])
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [message, setMessage] = useState('')
  const [editingSale, setEditingSale] = useState(null)
  const [clients, setClients] = useState([])
  const [products, setProducts] = useState([])
  const [paymentMethods, setPaymentMethods] = useState([])
  const [filters, setFilters] = useState({
    borough: '',
    neighborhood: '',
    clientId: '',
    saleStartDate: '',
    saleEndDate: '',
    deliveryStartDate: '',
    deliveryEndDate: '',
    paymentStatus: ''
  })
  const [showFilters, setShowFilters] = useState(false)
  const [uniqueLocations, setUniqueLocations] = useState({
    boroughs: [],
    neighborhoods: []
  })
  const [selectedClient, setSelectedClient] = useState(null);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [price, setPrice] = useState(0);
  const [formData, setFormData] = useState({
    product_id: '',
    quantity: 1,
    unit_price: 0,
    total: 0,
    deliveryStartDate: '',
    deliveryEndDate: '',
    paymentStatus: ''
  });
  const [error, setError] = useState('');

  useEffect(() => {
    fetchSales()
    fetchClients()
    fetchProducts()
    fetchPaymentMethods()
    fetchUniqueLocations()
  }, [])

  useEffect(() => {
    fetchSales()
  }, [filters])

  const fetchSales = async () => {
    let query = supabase
      .from('sales')
      .select(`
        id,
        client_id,
        delivery_address_id,
        sale_date,
        delivery_date,
        total_amount,
        status,
        payment_status,
        payment_method:payment_methods(name),
        payment_date,
        notes,
        client:clients(name),
        delivery_address:client_addresses!left(
          id,
          street_address,
          additional_info,
          borough_id,
          neighborhood_id,
          boroughs:boroughs!left(name),
          neighborhoods:neighborhoods!left(name)
        )
      `)

    if (filters.borough) {
      query = query.filter('delivery_address.boroughs.name', 'eq', filters.borough)
    }
    if (filters.neighborhood) {
      query = query.filter('delivery_address.neighborhoods.name', 'eq', filters.neighborhood)
    }
    if (filters.clientId) {
      query = query.eq('client_id', filters.clientId)
    }
    if (filters.saleStartDate) {
      query = query.gte('sale_date', filters.saleStartDate)
    }
    if (filters.saleEndDate) {
      query = query.lte('sale_date', filters.saleEndDate)
    }
    if (filters.deliveryStartDate) {
      query = query.gte('delivery_date', filters.deliveryStartDate)
    }
    if (filters.deliveryEndDate) {
      query = query.lte('delivery_date', filters.deliveryEndDate)
    }
    if (filters.paymentStatus) {
      query = query.eq('payment_status', filters.paymentStatus)
    }

    const { data: salesData, error: salesError } = await query
      .order('sale_date', { ascending: false })
      .order('id', { ascending: false })

    if (salesError) {
      console.error('Error fetching sales:', salesError)
    } else {
      const { data: itemsData, error: itemsError } = await supabase
        .from('sale_items')
        .select('*')
        .in('sale_id', salesData.map(sale => sale.id))

      if (itemsError) {
        console.error('Error fetching sale items:', itemsError)
      } else {
        const salesWithItems = salesData.map(sale => ({
          ...sale,
          sale_items: itemsData.filter(item => item.sale_id === sale.id)
        }))
        setSales(salesWithItems)
      }
    }
  }

  const fetchClients = async () => {
    const { data, error } = await supabase
      .from('clients')
      .select('id, name')
      .eq('status', 'active')

    if (error) {
      console.error('Error fetching clients:', error)
    } else {
      setClients(data || [])
    }
  }

  const fetchProducts = async () => {
    const { data, error } = await supabase
      .from('products')
      .select('id, name, default_price')
      .eq('status', 'active')

    if (error) {
      console.error('Error fetching products:', error)
    } else {
      setProducts(data || [])
    }
  }

  const fetchPaymentMethods = async () => {
    const { data, error } = await supabase
      .from('payment_methods')
      .select('*')
      .order('name')

    if (error) {
      console.error('Error fetching payment methods:', error)
    } else {
      setPaymentMethods(data || [])
    }
  }

  const fetchUniqueLocations = async () => {
    const { data: boroughsData, error: boroughsError } = await supabase
      .from('boroughs')
      .select('name')
      .eq('status', 'active')
      .order('name')

    const { data: neighborhoodsData, error: neighborhoodsError } = await supabase
      .from('neighborhoods')
      .select('name')
      .eq('status', 'active')
      .order('name')

    if (boroughsError || neighborhoodsError) {
      console.error('Error fetching locations:', boroughsError || neighborhoodsError)
    } else {
      setUniqueLocations({
        boroughs: boroughsData.map(b => b.name),
        neighborhoods: neighborhoodsData.map(n => n.name)
      })
    }
  }

  const handleSubmit = async (formData) => {
    try {
      const { data: userData, error: userError } = await supabase.auth.getUser()
      if (userError) throw new Error('Could not get user data')

      if (editingSale) {
        // Update existing sale
        const { error: saleError } = await supabase
          .from('sales')
          .update({
            total_amount: formData.totalAmount,
            sale_date: formData.saleDate,
            delivery_date: formData.deliveryDate,
            delivery_address_id: formData.deliveryAddressId,
            notes: formData.notes,
            payment_status: formData.paymentStatus,
            payment_method_id: formData.paymentMethodId,
            payment_date: formData.paymentDate,
            payment_notes: formData.paymentNotes,
            updated_at: new Date().toISOString()
          })
          .eq('id', editingSale.id)

        if (saleError) {
          console.error('Sale update error:', saleError)
          throw new Error(`Failed to update sale: ${saleError.message}`)
        }

        // Update sale items maintaining order
        const saleItems = formData.items.map((item, index) => ({
          sale_id: editingSale.id,
          product_id: item.productId,
          item_number: index + 1, // Sequential item numbers
          quantity: item.quantity,
          unit_price: item.unitPrice,
          total_price: item.totalPrice,
          discount_percentage: item.discountPercentage
        }))

        // Update each item individually
        for (const item of saleItems) {
          const { error: itemError } = await supabase
            .from('sale_items')
            .upsert(item, { 
              onConflict: 'sale_id,product_id,item_number',
              ignoreDuplicates: false 
            })

          if (itemError) {
            console.error('Sale item update error:', itemError)
            throw new Error(`Failed to update sale item: ${itemError.message}`)
          }
        }

        // Delete any items that are no longer in the form
        const maxItemNumber = saleItems.length
        const { error: deleteError } = await supabase
          .from('sale_items')
          .delete()
          .eq('sale_id', editingSale.id)
          .gt('item_number', maxItemNumber)

        if (deleteError) {
          console.error('Error deleting old items:', deleteError)
          throw new Error(`Failed to clean up old items: ${deleteError.message}`)
        }

        setMessage('Sale updated successfully')
      } else {
        // Create new sale
        const { data: sale, error: saleError } = await supabase
          .from('sales')
          .insert([{
            client_id: formData.clientId,
            created_by: userData.user.id,
            total_amount: formData.totalAmount,
            sale_date: formData.saleDate,
            delivery_date: formData.deliveryDate,
            delivery_address_id: formData.deliveryAddressId,
            status: 'active',
            notes: formData.notes,
            payment_status: formData.paymentStatus,
            payment_method_id: formData.paymentMethodId,
            payment_date: formData.paymentDate,
            payment_notes: formData.paymentNotes
          }])
          .select()
          .single()

        if (saleError) {
          console.error('Sale creation error:', saleError)
          throw new Error(`Failed to create sale: ${saleError.message}`)
        }

        const saleItems = formData.items.map((item, index) => ({
          sale_id: sale.id,
          product_id: item.productId,
          item_number: index + 1,
          quantity: item.quantity,
          unit_price: item.unitPrice,
          total_price: item.totalPrice,
          discount_percentage: item.discountPercentage
        }))

        const { error: itemsError } = await supabase
          .from('sale_items')
          .insert(saleItems)

        if (itemsError) {
          console.error('Sale items error:', itemsError)
          throw new Error(`Failed to create sale items: ${itemsError.message}`)
        }

        setMessage('Sale created successfully')
      }

      fetchSales()
      setEditingSale(null)
      setIsModalOpen(false)
    } catch (error) {
      console.error('Error in handleSubmit:', error)
      throw error
    }
  }

  // Add the formatDate helper function
  const formatDate = (dateString) => {
    const date = new Date(dateString)
    // Add timezone offset to get correct local date
    date.setMinutes(date.getMinutes() + date.getTimezoneOffset())
    return date.toLocaleDateString()
  }

  const clearFilters = () => {
    setFilters({
      borough: '',
      neighborhood: '',
      clientId: '',
      saleStartDate: '',
      saleEndDate: '',
      deliveryStartDate: '',
      deliveryEndDate: '',
      paymentStatus: ''
    })
  }

  const handleProductSelect = async (productId) => {
    try {
      if (!productId) return;

      setSelectedProduct(productId);
      
      // Get the current date in YYYY-MM-DD format
      const today = new Date().toISOString().split('T')[0];
      
      // Call the function with the updated parameters
      const { data, error } = await supabase.rpc('get_product_price_at_date', {
        product_id: productId,
        target_date: today,
        client_id: selectedClient?.id || null
      });

      if (error) {
        console.error('Error fetching product price:', error);
        return;
      }

      // Log the response for debugging
      console.log('Price response:', data);

      // The data will be an array with one row containing price and price_type
      const priceInfo = Array.isArray(data) && data.length > 0 ? data[0] : { price: 0, price_type: 'none' };
      
      // Update the form data with the returned price
      setFormData(prev => ({
        ...prev,
        product_id: productId,
        unit_price: Number(priceInfo.price || 0),
        total: Number(priceInfo.price || 0) * prev.quantity
      }));
      
    } catch (error) {
      console.error('Error in handleProductSelect:', error);
      setFormData(prev => ({
        ...prev,
        unit_price: 0,
        total: 0
      }));
    }
  };

  return (
    <div className="space-y-6">
      {message && (
        <Alert className="mb-4">{message}</Alert>
      )}

      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Sales</h2>
        <div className="flex gap-2">
          <Button 
            variant="outline" 
            onClick={() => setShowFilters(!showFilters)}
          >
            <Filter className="h-4 w-4 mr-2" />
            Filters
          </Button>
          <Button onClick={() => {
            setEditingSale(null)
            setIsModalOpen(true)
          }}>
            <Plus className="h-4 w-4 mr-2" />
            New Sale
          </Button>
        </div>
      </div>

      {/* Filters Section */}
      {showFilters && (
        <div className="bg-white shadow rounded-lg p-6 space-y-4">
          <div className="flex justify-between items-center mb-4">
            <h3 className="font-medium">Filters</h3>
            <Button 
              variant="ghost" 
              size="sm" 
              onClick={clearFilters}
            >
              <X className="h-4 w-4 mr-2" />
              Clear Filters
            </Button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {/* Location Filters */}
            <select
              value={filters.borough}
              onChange={(e) => setFilters(prev => ({ ...prev, borough: e.target.value }))}
              className="w-full p-2 border rounded"
            >
              <option value="">All Boroughs</option>
              {uniqueLocations.boroughs.map(borough => (
                <option key={borough} value={borough}>{borough}</option>
              ))}
            </select>

            <select
              value={filters.neighborhood}
              onChange={(e) => setFilters(prev => ({ ...prev, neighborhood: e.target.value }))}
              className="w-full p-2 border rounded"
            >
              <option value="">All Neighborhoods</option>
              {uniqueLocations.neighborhoods.map(neighborhood => (
                <option key={neighborhood} value={neighborhood}>{neighborhood}</option>
              ))}
            </select>

            <select
              value={filters.clientId}
              onChange={(e) => setFilters(prev => ({ ...prev, clientId: e.target.value }))}
              className="w-full p-2 border rounded"
            >
              <option value="">All Clients</option>
              {clients.map(client => (
                <option key={client.id} value={client.id}>{client.name}</option>
              ))}
            </select>

            {/* Date Filters */}
            <div className="space-y-2">
              <label className="text-sm text-gray-600">Sale Date Range</label>
              <div className="flex gap-2">
                <Input
                  type="date"
                  value={filters.saleStartDate}
                  onChange={(e) => setFilters(prev => ({ 
                    ...prev, 
                    saleStartDate: e.target.value 
                  }))}
                  className="w-full"
                />
                <Input
                  type="date"
                  value={filters.saleEndDate}
                  onChange={(e) => setFilters(prev => ({ 
                    ...prev, 
                    saleEndDate: e.target.value 
                  }))}
                  className="w-full"
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm text-gray-600">Delivery Date Range</label>
              <div className="flex gap-2">
                <Input
                  type="date"
                  value={filters.deliveryStartDate}
                  onChange={(e) => setFilters(prev => ({ 
                    ...prev, 
                    deliveryStartDate: e.target.value 
                  }))}
                  className="w-full"
                />
                <Input
                  type="date"
                  value={filters.deliveryEndDate}
                  onChange={(e) => setFilters(prev => ({ 
                    ...prev, 
                    deliveryEndDate: e.target.value 
                  }))}
                  className="w-full"
                />
              </div>
            </div>

            <select
              value={filters.paymentStatus}
              onChange={(e) => setFilters(prev => ({ ...prev, paymentStatus: e.target.value }))}
              className="w-full p-2 border rounded"
            >
              <option value="">All Payment Status</option>
              <option value="pending">Pending</option>
              <option value="paid">Paid</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>
        </div>
      )}

      {/* Sales Table */}
      <div className="bg-white shadow rounded-lg p-6">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead>
              <tr>
                <th className="px-6 py-3 text-left">Sale Date</th>
                <th className="px-6 py-3 text-left">Client</th>
                <th className="px-6 py-3 text-left">Delivery Address</th>
                <th className="px-6 py-3 text-left">Delivery Date</th>
                <th className="px-6 py-3 text-left">Total</th>
                <th className="px-6 py-3 text-left">Status</th>
                <th className="px-6 py-3 text-left">Payment</th>
                <th className="px-6 py-3 text-left">Actions</th>
              </tr>
            </thead>
            <tbody>
              {sales.map((sale) => (
                <tr key={sale.id} className="border-t">
                  <td className="px-6 py-4">
                    {formatDate(sale.sale_date)}
                  </td>
                  <td className="px-6 py-4">{sale.client?.name}</td>
                  <td className="px-6 py-4">
                    {[
                      sale.delivery_address?.street_address,
                      sale.delivery_address?.neighborhood,
                      sale.delivery_address?.borough
                    ].filter(Boolean).join(' - ')}
                  </td>
                  <td className="px-6 py-4">
                    {formatDate(sale.delivery_date)}
                  </td>
                  <td className="px-6 py-4">
                    {formatCurrency(sale.total_amount)}
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 rounded text-sm ${
                      sale.status === 'completed' 
                        ? 'bg-green-100 text-green-800' 
                        : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {sale.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 rounded text-sm ${
                      sale.payment_status === 'paid' 
                        ? 'bg-green-100 text-green-800'
                        : sale.payment_status === 'cancelled'
                        ? 'bg-red-100 text-red-800'
                        : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {sale.payment_status}
                    </span>
                    {sale.payment_method && (
                      <div className="text-sm text-gray-500 mt-1">
                        {sale.payment_method.name}
                      </div>
                    )}
                  </td>
                  <td className="px-6 py-4">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => {
                        setEditingSale(sale)
                        setIsModalOpen(true)
                      }}
                    >
                      View Details
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <SaleFormModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false)
          setEditingSale(null)
        }}
        onSubmit={handleSubmit}
        editingSale={editingSale}
        clients={clients}
        products={products}
        paymentMethods={paymentMethods}
      />
    </div>
  )
}

export default SalesManagement 