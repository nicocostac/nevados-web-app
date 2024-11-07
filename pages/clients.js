import { useState, useEffect } from 'react'
import { requireAuth } from '@/lib/auth/requireAuth'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { Edit2, Trash2, Plus, Search, Filter, X } from 'lucide-react'
import { useAuth } from '@/lib/context/AuthContext'
import ClientFormModal from '@/components/ClientFormModal'
import { useRouter } from 'next/router'

function ClientManagement() {
  const { user: currentUser } = useAuth()
  const [clients, setClients] = useState([])
  const [filteredClients, setFilteredClients] = useState([])
  const [clientTypes, setClientTypes] = useState([])
  const [userRole, setUserRole] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingClient, setEditingClient] = useState(null)
  const [message, setMessage] = useState(null)
  const [products, setProducts] = useState([])
  
  // Search and filter states
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedType, setSelectedType] = useState('')
  const [selectedStatus, setSelectedStatus] = useState('')
  const [selectedBorough, setSelectedBorough] = useState('')
  const [selectedNeighborhood, setSelectedNeighborhood] = useState('')
  const [sortBy, setSortBy] = useState('name')
  const [sortOrder, setSortOrder] = useState('asc')
  const [boroughs, setBoroughs] = useState([])
  const [neighborhoods, setNeighborhoods] = useState([])
  const [showFilters, setShowFilters] = useState(false)

  const router = useRouter()
  const { search, highlight } = router.query

  // Fetch current user's role and clients list
  useEffect(() => {
    async function fetchData() {
      if (currentUser?.id) {
        // Get user's role
        const { data: profile, error } = await supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single()

        if (error) {
          console.error('Error fetching profile:', error)
        } else {
          setUserRole(profile.role)
          
          // Fetch client types
          const { data: types, error: typesError } = await supabase
            .from('client_types')
            .select('*')
            .order('name')

          if (typesError) {
            console.error('Error fetching client types:', typesError)
          } else {
            setClientTypes(types)
          }

          // Fetch clients with all related data
          const { data: clients, error: clientsError } = await supabase
            .from('clients')
            .select(`
              *,
              client_types!clients_type_id_fkey (
                id,
                name
              ),
              client_addresses!client_addresses_client_id_fkey (
                id,
                street_address,
                borough,
                neighborhood,
                is_default
              )
            `)
            .order('name')

          if (clientsError) {
            console.error('Error fetching clients:', clientsError)
          } else {
            setClients(clients)
            setFilteredClients(clients)

            // Extract unique boroughs and neighborhoods from all addresses
            const uniqueBoroughs = new Set()
            const uniqueNeighborhoods = new Set()
            
            clients.forEach(client => {
              if (client.client_addresses) {
                client.client_addresses.forEach(address => {
                  if (address.borough) uniqueBoroughs.add(address.borough)
                  if (address.neighborhood) uniqueNeighborhoods.add(address.neighborhood)
                })
              }
            })

            setBoroughs(Array.from(uniqueBoroughs).sort())
            setNeighborhoods(Array.from(uniqueNeighborhoods).sort())
          }

          // Fetch products for special prices
          const { data: products, error: productsError } = await supabase
            .from('products')
            .select('*')
            .eq('status', 'active')
            .order('name')

          if (productsError) {
            console.error('Error fetching products:', productsError)
          } else {
            setProducts(products)
          }
        }
      }
    }
    fetchData()
  }, [currentUser?.id])

  // Apply filters and search
  useEffect(() => {
    let filtered = [...clients]

    // Search term filter
    if (searchTerm) {
      const search = searchTerm.toLowerCase()
      filtered = filtered.filter(client => 
        client.name?.toLowerCase().includes(search) ||
        client.contact_person?.toLowerCase().includes(search) ||
        client.email?.toLowerCase().includes(search) ||
        client.phone?.toLowerCase().includes(search) ||
        // Update address search to match actual fields
        client.client_addresses?.some(address => 
          address.street_address?.toLowerCase().includes(search) ||
          address.borough?.toLowerCase().includes(search) ||
          address.neighborhood?.toLowerCase().includes(search)
        )
      )
    }

    // Type filter
    if (selectedType) {
      filtered = filtered.filter(client => client.type_id === selectedType)
    }

    // Status filter
    if (selectedStatus) {
      filtered = filtered.filter(client => client.status === selectedStatus)
    }

    // Borough filter
    if (selectedBorough) {
      filtered = filtered.filter(client => 
        client.client_addresses?.some(address => 
          address.borough?.toLowerCase() === selectedBorough.toLowerCase()
        )
      )
    }

    // Neighborhood filter
    if (selectedNeighborhood) {
      filtered = filtered.filter(client => 
        client.client_addresses?.some(address => 
          address.neighborhood?.toLowerCase() === selectedNeighborhood.toLowerCase()
        )
      )
    }

    // Sort
    filtered.sort((a, b) => {
      let comparison = 0
      switch (sortBy) {
        case 'name':
          comparison = a.name.localeCompare(b.name)
          break
        case 'type':
          comparison = (a.client_types?.name || '').localeCompare(b.client_types?.name || '')
          break
        case 'status':
          comparison = a.status.localeCompare(b.status)
          break
        default:
          comparison = a.name.localeCompare(b.name)
      }
      return sortOrder === 'asc' ? comparison : -comparison
    })

    setFilteredClients(filtered)
  }, [clients, searchTerm, selectedType, selectedStatus, selectedBorough, selectedNeighborhood, sortBy, sortOrder])

  // Add to the existing imports
  useEffect(() => {
    if (search) {
      setSearchTerm(decodeURIComponent(search))
    }
  }, [search])

  // Add this effect to highlight the client row
  useEffect(() => {
    if (highlight) {
      const element = document.getElementById(`client-${highlight}`)
      if (element) {
        element.scrollIntoView({ behavior: 'smooth', block: 'center' })
        element.classList.add('bg-yellow-50')
        setTimeout(() => {
          element.classList.remove('bg-yellow-50')
          element.classList.add('bg-white', 'transition-colors', 'duration-1000')
        }, 2000)
      }
    }
  }, [highlight, clients])

  const handleSubmit = async (success) => {
    if (success) {
      // Refresh clients list with type details
      const { data: updatedClients, error: refreshError } = await supabase
        .from('clients')
        .select(`
          *,
          client_types!clients_type_id_fkey (
            id,
            name
          )
        `)
        .order('name')

      if (refreshError) {
        console.error('Error refreshing clients:', refreshError)
      } else {
        setClients(updatedClients)
        setMessage(editingClient ? 'Client updated successfully' : 'Client created successfully')
      }

      // Close modal and reset editing state
      setIsModalOpen(false)
      setEditingClient(null)
    }
  }

  const handleDelete = async (clientId) => {
    if (!window.confirm('Are you sure you want to delete this client?')) {
      return
    }

    try {
      const { error } = await supabase
        .from('clients')
        .delete()
        .eq('id', clientId)

      if (error) throw error

      setClients(clients.filter(c => c.id !== clientId))
      setMessage('Client deleted successfully')
    } catch (error) {
      console.error('Error deleting client:', error)
    }
  }

  // Show loading state while role is being fetched
  if (!userRole) {
    return <div className="p-4">Loading...</div>
  }

  return (
    <div className="space-y-6">
      {message && (
        <Alert className="mb-4">{message}</Alert>
      )}

      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Clients</h2>
        <Button onClick={() => {
          setEditingClient(null)
          setIsModalOpen(true)
        }}>
          <Plus className="h-4 w-4 mr-2" />
          Add Client
        </Button>
      </div>

      {/* Search and Filters */}
      <div className="bg-white shadow rounded-lg p-4 space-y-4">
        <div className="flex gap-4">
          <div className="flex-1 relative">
            <Input
              type="text"
              placeholder="Search clients..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10"
            />
            <Search className="h-4 w-4 absolute left-3 top-3 text-gray-400" />
          </div>
          <Button
            variant="outline"
            onClick={() => setShowFilters(!showFilters)}
          >
            <Filter className="h-4 w-4 mr-2" />
            Filters
          </Button>
        </div>

        {showFilters && (
          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
            <select
              value={selectedType}
              onChange={(e) => setSelectedType(e.target.value)}
              className="w-full p-2 border rounded"
            >
              <option value="">All Types</option>
              {clientTypes.map(type => (
                <option key={type.id} value={type.id}>
                  {type.name.charAt(0).toUpperCase() + type.name.slice(1)}
                </option>
              ))}
            </select>

            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="w-full p-2 border rounded"
            >
              <option value="">All Status</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>

            <select
              value={selectedBorough}
              onChange={(e) => setSelectedBorough(e.target.value)}
              className="w-full p-2 border rounded"
            >
              <option value="">All Boroughs</option>
              {boroughs.map(borough => (
                <option key={borough} value={borough}>{borough}</option>
              ))}
            </select>

            <select
              value={selectedNeighborhood}
              onChange={(e) => setSelectedNeighborhood(e.target.value)}
              className="w-full p-2 border rounded"
            >
              <option value="">All Neighborhoods</option>
              {neighborhoods.map(neighborhood => (
                <option key={neighborhood} value={neighborhood}>{neighborhood}</option>
              ))}
            </select>

            <div className="flex gap-2">
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
                className="flex-1 p-2 border rounded"
              >
                <option value="name">Sort by Name</option>
                <option value="type">Sort by Type</option>
                <option value="status">Sort by Status</option>
              </select>
              <Button
                variant="outline"
                onClick={() => setSortOrder(order => order === 'asc' ? 'desc' : 'asc')}
              >
                {sortOrder === 'asc' ? '↑' : '↓'}
              </Button>
            </div>
          </div>
        )}

        {(searchTerm || selectedType || selectedStatus || selectedBorough || selectedNeighborhood) && (
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-500">
              {filteredClients.length} results found
            </span>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSearchTerm('')
                setSelectedType('')
                setSelectedStatus('')
                setSelectedBorough('')
                setSelectedNeighborhood('')
                setSortBy('name')
                setSortOrder('asc')
              }}
            >
              <X className="h-4 w-4 mr-1" />
              Clear Filters
            </Button>
          </div>
        )}
      </div>

      {/* Clients Table */}
      <div className="bg-white shadow rounded-lg p-6">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead>
              <tr>
                <th className="px-6 py-3 text-left">Name</th>
                <th className="px-6 py-3 text-left">Contact</th>
                <th className="px-6 py-3 text-left">Type</th>
                <th className="px-6 py-3 text-left">Status</th>
                <th className="px-6 py-3 text-left">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredClients.map((client) => (
                <tr 
                  key={client.id} 
                  id={`client-${client.id}`}
                  className="border-t transition-colors duration-300"
                >
                  <td className="px-6 py-4">{client.name}</td>
                  <td className="px-6 py-4">
                    <div>{client.contact_person}</div>
                    <div className="text-sm text-gray-500">{client.email}</div>
                    <div className="text-sm text-gray-500">{client.phone}</div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="capitalize">{client.client_types?.name}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 rounded text-sm ${
                      client.status === 'active' 
                        ? 'bg-green-100 text-green-800' 
                        : 'bg-red-100 text-red-800'
                    }`}>
                      {client.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setEditingClient(client)
                          setIsModalOpen(true)
                        }}
                      >
                        <Edit2 className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDelete(client.id)}
                      >
                        <Trash2 className="h-4 w-4 text-red-500" />
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <ClientFormModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false)
          setEditingClient(null)
        }}
        onSubmit={handleSubmit}
        editingClient={editingClient}
        clientTypes={clientTypes}
        products={products}
      />
    </div>
  )
}

export default requireAuth(ClientManagement) 