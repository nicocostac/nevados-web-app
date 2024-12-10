import { useState, useEffect } from 'react'
import { requireAuth } from '@/lib/auth/requireAuth'
import { supabase } from '@/lib/supabaseClient'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { Edit2, Trash2, Plus, Search, Filter, X, Mail, Phone } from 'lucide-react'
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
  const [selectedTj, setSelectedTj] = useState('')
  const [selectedBorough, setSelectedBorough] = useState('')
  const [selectedNeighborhood, setSelectedNeighborhood] = useState('')
  const [boroughs, setBoroughs] = useState([])
  const [neighborhoods, setNeighborhoods] = useState([])
  const [showFilters, setShowFilters] = useState(false)

  const [currentPage, setCurrentPage] = useState(1)
  const [totalPages, setTotalPages] = useState(0)
  const [totalRecords, setTotalRecords] = useState(0)
  const [isLoading, setIsLoading] = useState(true)
  const rowsPerPage = 10

  const [sortBy, setSortBy] = useState('name')
  const [sortOrder, setSortOrder] = useState('asc')

  const router = useRouter()
  const { search, highlight } = router.query

  // Add this function before the useEffect
  const fetchClients = async () => {
    try {
      setIsLoading(true)
      console.log('Starting fetchClients for page', currentPage)

      // First, get total count with filters
      let countQuery = supabase
        .from('clients')
        .select('id', { count: 'exact' })

      // Apply filters to count query
      if (selectedType) {
        countQuery = countQuery.eq('type_id', selectedType)
      }
      if (selectedStatus) {
        countQuery = countQuery.eq('status', selectedStatus)
      }
      if (selectedTj) {
        countQuery = countQuery.eq('tj', selectedTj)
      }
      if (searchTerm) {
        countQuery = countQuery.ilike('name', `%${searchTerm}%`)
      }

      const { count, error: countError } = await countQuery

      if (countError) throw countError

      console.log('Total records:', count)
      const totalPages = Math.max(1, Math.ceil(count / rowsPerPage))
      console.log('Total pages:', totalPages)

      setTotalRecords(count)
      setTotalPages(totalPages)

      // Adjust current page if it's out of bounds
      if (currentPage > totalPages) {
        console.log('Current page out of bounds, adjusting to', totalPages)
        setCurrentPage(totalPages)
        return // The useEffect will trigger another fetch with the correct page
      }

      // Now fetch the actual data for the current page
      const start = (currentPage - 1) * rowsPerPage
      const end = start + rowsPerPage - 1

      console.log(`Fetching records ${start + 1} to ${end + 1} of ${count} for page ${currentPage}`)

      let query = supabase
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
            additional_info,
            borough_id,
            neighborhood_id,
            boroughs:boroughs!inner(name),
            neighborhoods:neighborhoods!inner(name),
            is_default
          )
        `)

      // Helper function to get proper sort column
      const getSortColumn = () => {
        switch (sortBy) {
          case 'name':
            return 'name'
          case 'contact':
            return 'phone' // Primary sort by phone
          case 'type':
            return 'client_types(name)'
          case 'tj':
            return 'is_tj'
          case 'status':
            return 'status'
          default:
            return 'name'
        }
      }

      // Apply primary sort
      query = query.order(getSortColumn(), { ascending: sortOrder === 'asc' })
      
      // Add secondary sort by name to maintain consistent order
      if (sortBy !== 'name') {
        query = query.order('name', { ascending: true })
      }

      // Apply range for pagination
      query = query.range(start, end)

      // Apply filters to data query
      if (selectedType) {
        query = query.eq('type_id', selectedType)
      }
      if (selectedStatus) {
        query = query.eq('status', selectedStatus)
      }
      if (selectedTj) {
        query = query.eq('tj', selectedTj)
      }
      if (searchTerm) {
        query = query.ilike('name', `%${searchTerm}%`)
      }

      const { data: clients, error: clientsError } = await query

      if (clientsError) throw clientsError

      setClients(clients || [])
      setFilteredClients(clients || [])

      // Extract unique boroughs and neighborhoods
      const uniqueBoroughs = new Set()
      const uniqueNeighborhoods = new Set()
      
      clients.forEach(client => {
        if (client.client_addresses) {
          client.client_addresses.forEach(address => {
            if (address.boroughs?.name) uniqueBoroughs.add(address.boroughs.name)
            if (address.neighborhoods?.name) uniqueNeighborhoods.add(address.neighborhoods.name)
          })
        }
      })

      setBoroughs(Array.from(uniqueBoroughs).sort())
      setNeighborhoods(Array.from(uniqueNeighborhoods).sort())
      
    } catch (error) {
      console.error('Error in fetchClients:', error)
      setMessage('Failed to fetch clients data. Please try reloading the page.')
    } finally {
      setIsLoading(false)
    }
  }

  // Add pagination handler
  const handlePageChange = (pageNumber) => {
    console.log('Changing to page:', pageNumber, 'from current page:', currentPage)
    // Validate page number
    if (pageNumber < 1 || pageNumber > totalPages) {
      console.log('Invalid page number:', pageNumber, 'total pages:', totalPages)
      return
    }
    
    if (pageNumber === currentPage) {
      console.log('Already on page', pageNumber)
      return
    }

    setCurrentPage(pageNumber)
  }

  // Add sort handler
  const handleSort = (column) => {
    if (sortBy === column) {
      // If clicking the same column, toggle order
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')
    } else {
      // If clicking a new column, set it with ascending order
      setSortBy(column)
      setSortOrder('asc')
    }
  }

  // Helper function to render sort indicator
  const renderSortIndicator = (column) => {
    if (sortBy !== column) return null
    return sortOrder === 'asc' ? ' ↑' : ' ↓'
  }

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

          // Fetch clients
          await fetchClients()

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
        client.email?.toLowerCase().includes(search) ||
        client.phone?.toLowerCase().includes(search)
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

    // TJ filter
    if (selectedTj) {
      filtered = filtered.filter(client => client.is_tj === (selectedTj === 'true'))
    }

    // Borough filter
    if (selectedBorough) {
      filtered = filtered.filter(client => 
        client.client_addresses?.some(address => 
          address.boroughs?.name?.toLowerCase() === selectedBorough.toLowerCase()
        )
      )
    }

    // Neighborhood filter
    if (selectedNeighborhood) {
      filtered = filtered.filter(client => 
        client.client_addresses?.some(address => 
          address.neighborhoods?.name?.toLowerCase() === selectedNeighborhood.toLowerCase()
        )
      )
    }

    setFilteredClients(filtered)
  }, [clients, searchTerm, selectedType, selectedStatus, selectedTj, selectedBorough, selectedNeighborhood])

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

  useEffect(() => {
    fetchClients()
  }, [currentPage, searchTerm, selectedType, selectedStatus, selectedTj, selectedBorough, selectedNeighborhood, sortBy, sortOrder])

  const handleSubmit = async (success) => {
    if (success) {
      // Refresh clients list using the fetchClients function which handles pagination
      await fetchClients()
      
      setMessage(editingClient ? 'Client updated successfully' : 'Client created successfully')

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
        .update({ status: 'inactive' })
        .eq('id', clientId)

      if (error) {
        console.error('Error deactivating client:', error)
        setMessage('Error deactivating client')
      } else {
        setMessage('Client deactivated successfully')
        fetchClients() // Refresh the clients list
      }
    } catch (error) {
      console.error('Error:', error)
      setMessage(error.message)
    }
  }

  const handleEdit = (client) => {
    setEditingClient(client)
    setIsModalOpen(true)
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
          <div className="mb-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Type
              </label>
              <select
                value={selectedType}
                onChange={(e) => setSelectedType(e.target.value)}
                className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="">All</option>
                {clientTypes.map((type) => (
                  <option key={type.id} value={type.id}>
                    {type.name}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Status
              </label>
              <select
                value={selectedStatus}
                onChange={(e) => setSelectedStatus(e.target.value)}
                className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="">All</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                TJ
              </label>
              <select
                value={selectedTj}
                onChange={(e) => setSelectedTj(e.target.value)}
                className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="">All</option>
                <option value="true">Yes</option>
                <option value="false">No</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Borough
              </label>
              <select
                value={selectedBorough}
                onChange={(e) => setSelectedBorough(e.target.value)}
                className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="">All</option>
                {boroughs.map((borough) => (
                  <option key={borough} value={borough}>
                    {borough}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Neighborhood
              </label>
              <select
                value={selectedNeighborhood}
                onChange={(e) => setSelectedNeighborhood(e.target.value)}
                className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="">All</option>
                {neighborhoods.map((neighborhood) => (
                  <option key={neighborhood} value={neighborhood}>
                    {neighborhood}
                  </option>
                ))}
              </select>
            </div>
          </div>
        )}

        {(searchTerm || selectedType || selectedStatus || selectedTj || selectedBorough || selectedNeighborhood) && (
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
                setSelectedTj('')
                setSelectedBorough('')
                setSelectedNeighborhood('')
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
            <thead className="bg-gray-50">
              <tr>
                <th 
                  scope="col" 
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                  onClick={() => handleSort('name')}
                >
                  Name{renderSortIndicator('name')}
                </th>
                <th 
                  scope="col" 
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                  onClick={() => handleSort('contact')}
                >
                  Contact{renderSortIndicator('contact')}
                </th>
                <th 
                  scope="col" 
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                  onClick={() => handleSort('type')}
                >
                  Type{renderSortIndicator('type')}
                </th>
                <th 
                  scope="col" 
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                  onClick={() => handleSort('status')}
                >
                  Status{renderSortIndicator('status')}
                </th>
                <th 
                  scope="col" 
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                  onClick={() => handleSort('tj')}
                >
                  TJ{renderSortIndicator('tj')}
                </th>
                <th scope="col" className="relative px-6 py-3">
                  <span className="sr-only">Actions</span>
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredClients.map((client) => (
                <tr key={client.id}>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {client.name}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex flex-col">
                      {client.phone && (
                        <div className="flex items-center text-sm text-gray-900">
                          <Phone className="h-4 w-4 mr-1" />
                          {client.phone}
                        </div>
                      )}
                      {client.email && (
                        <div className="flex items-center text-sm text-gray-900">
                          <Mail className="h-4 w-4 mr-1" />
                          {client.email}
                        </div>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {client.client_types?.name}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                      client.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                    }`}>
                      {client.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                      client.is_tj ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'
                    }`}>
                      {client.is_tj ? 'Yes' : 'No'}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleEdit(client)}
                      >
                        <Edit2 className="h-4 w-4" />
                      </Button>
                      {userRole === 'admin' && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleDelete(client.id)}
                        >
                          <Trash2 className="h-4 w-4 text-red-500" />
                        </Button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="flex justify-between items-center p-4">
          <div className="flex items-center">
            <span className="text-sm text-gray-500">
              Showing {filteredClients.length} of {totalRecords} records
            </span>
          </div>
          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => handlePageChange(1)}
              disabled={currentPage === 1}
            >
              First
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => handlePageChange(currentPage - 1)}
              disabled={currentPage === 1}
            >
              Previous
            </Button>
            <div className="flex items-center">
              <span className="text-sm text-gray-500">
                Page {currentPage} of {totalPages}
              </span>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => handlePageChange(currentPage + 1)}
              disabled={currentPage === totalPages}
            >
              Next
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => handlePageChange(totalPages)}
              disabled={currentPage === totalPages}
            >
              Last
            </Button>
          </div>
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