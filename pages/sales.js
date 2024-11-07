import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Plus } from 'lucide-react'
import { Alert } from '@/components/ui/alert'
import SaleFormModal from '@/components/SaleFormModal'

function SalesManagement() {
  const [sales, setSales] = useState([])
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [message, setMessage] = useState('')
  const [editingSale, setEditingSale] = useState(null)
  const [clients, setClients] = useState([])
  const [products, setProducts] = useState([])

  useEffect(() => {
    fetchSales()
    fetchClients()
    fetchProducts()
  }, [])

  const fetchSales = async () => {
    const { data, error } = await supabase
      .from('sales')
      .select(`
        *,
        client:clients(name),
        sale_items(
          quantity,
          unit_price,
          total_price,
          product:products(name)
        ),
        created_by:profiles(first_name, last_name)
      `)
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error fetching sales:', error)
    } else {
      setSales(data || [])
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

  const handleSubmit = async (formData) => {
    try {
      const { data: userData, error: userError } = await supabase.auth.getUser()
      if (userError) throw new Error('Could not get user data')

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
          notes: formData.notes
        }])
        .select()
        .single()

      if (saleError) {
        console.error('Sale creation error:', saleError)
        throw new Error(`Failed to create sale: ${saleError.message}`)
      }

      const saleItems = formData.items.map(item => ({
        sale_id: sale.id,
        product_id: item.productId,
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
      fetchSales()
    } catch (error) {
      console.error('Error in handleSubmit:', error)
      throw error
    }
  }

  return (
    <div className="space-y-6">
      {message && (
        <Alert className="mb-4">{message}</Alert>
      )}

      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Sales</h2>
        <Button onClick={() => {
          setEditingSale(null)
          setIsModalOpen(true)
        }}>
          <Plus className="h-4 w-4 mr-2" />
          New Sale
        </Button>
      </div>

      <div className="bg-white shadow rounded-lg p-6">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead>
              <tr>
                <th className="px-6 py-3 text-left">Date</th>
                <th className="px-6 py-3 text-left">Client</th>
                <th className="px-6 py-3 text-left">Items</th>
                <th className="px-6 py-3 text-left">Total</th>
                <th className="px-6 py-3 text-left">Status</th>
                <th className="px-6 py-3 text-left">Actions</th>
              </tr>
            </thead>
            <tbody>
              {sales.map((sale) => (
                <tr key={sale.id} className="border-t">
                  <td className="px-6 py-4">
                    {new Date(sale.created_at).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4">{sale.client?.name}</td>
                  <td className="px-6 py-4">
                    {sale.sale_items?.length || 0} items
                  </td>
                  <td className="px-6 py-4">
                    ${sale.total_amount?.toFixed(2)}
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
      />
    </div>
  )
}

export default SalesManagement 