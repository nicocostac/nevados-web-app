import { useState, useEffect } from 'react'
import { requireAuth } from '@/lib/auth/requireAuth'
import { useAuth } from '@/lib/context/AuthContext'
import { 
  DollarSign, 
  Users, 
  Package, 
  TrendingUp,
  Calendar,
  Filter,
  X 
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { supabase } from '@/lib/supabaseClient'
import { formatCurrency } from '@/lib/utils/format'

function Dashboard() {
  const { user } = useAuth()
  const [timeRange, setTimeRange] = useState('week') // week, month, year
  const [showFilters, setShowFilters] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [dashboardData, setDashboardData] = useState({
    totalRevenue: 0,
    activeClients: 0,
    productsSold: 0,
    growthRate: 0,
    recentSales: [],
    topProducts: []
  })

  // Fetch dashboard data
  const fetchDashboardData = async () => {
    setLoading(true)
    setError(null)
    
    try {
      // Get date range
      const now = new Date()
      let startDate = new Date()
      switch(timeRange) {
        case 'week':
          startDate.setDate(now.getDate() - 7)
          break
        case 'month':
          startDate.setMonth(now.getMonth() - 1)
          break
        case 'year':
          startDate.setFullYear(now.getFullYear() - 1)
          break
      }

      // Fetch total revenue and sales data
      const { data: salesData, error: salesError } = await supabase
        .from('sales')
        .select(`
          id,
          total_amount,
          sale_date,
          client:clients(name),
          payment_status
        `)
        .gte('sale_date', startDate.toISOString())
        .order('sale_date', { ascending: false })

      if (salesError) throw salesError

      // Fetch active clients count
      const { count: clientsCount, error: clientsError } = await supabase
        .from('clients')
        .select('id', { count: true })
        .eq('status', 'active')

      if (clientsError) throw clientsError

      // Calculate metrics
      const totalRevenue = salesData.reduce((sum, sale) => sum + sale.total_amount, 0)
      const productsSold = salesData.length
      
      // Calculate growth rate (comparing with previous period)
      const previousStartDate = new Date(startDate)
      switch(timeRange) {
        case 'week':
          previousStartDate.setDate(previousStartDate.getDate() - 7)
          break
        case 'month':
          previousStartDate.setMonth(previousStartDate.getMonth() - 1)
          break
        case 'year':
          previousStartDate.setFullYear(previousStartDate.getFullYear() - 1)
          break
      }

      const { data: previousSales } = await supabase
        .from('sales')
        .select('total_amount')
        .gte('sale_date', previousStartDate.toISOString())
        .lt('sale_date', startDate.toISOString())

      const previousRevenue = previousSales?.reduce((sum, sale) => sum + sale.total_amount, 0) || 0
      const growthRate = previousRevenue === 0 ? 100 : 
        ((totalRevenue - previousRevenue) / previousRevenue) * 100

      // Update dashboard data
      setDashboardData({
        totalRevenue,
        activeClients: clientsCount,
        productsSold,
        growthRate: Math.round(growthRate * 100) / 100,
        recentSales: salesData.slice(0, 5),
        topProducts: [] // To be implemented with product analytics
      })
    } catch (err) {
      console.error('Error fetching dashboard data:', err)
      setError('Failed to load dashboard data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchDashboardData()
  }, [timeRange])

  const stats = [
    {
      id: 1,
      name: 'Total Revenue',
      stat: formatCurrency(dashboardData.totalRevenue),
      icon: DollarSign,
      change: `${dashboardData.growthRate}%`,
      changeType: dashboardData.growthRate >= 0 ? 'increase' : 'decrease'
    },
    {
      id: 2,
      name: 'Active Clients',
      stat: dashboardData.activeClients,
      icon: Users,
      change: '0%',
      changeType: 'increase'
    },
    {
      id: 3,
      name: 'Products Sold',
      stat: dashboardData.productsSold,
      icon: Package,
      change: '0%',
      changeType: 'increase'
    },
    {
      id: 4,
      name: 'Growth Rate',
      stat: `${dashboardData.growthRate}%`,
      icon: TrendingUp,
      change: `${dashboardData.growthRate}%`,
      changeType: dashboardData.growthRate >= 0 ? 'increase' : 'decrease'
    }
  ]

  return (
    <div className="space-y-6">
      {error && (
        <Alert variant="destructive">
          {error}
        </Alert>
      )}

      {/* Time Range Filter */}
      <div className="flex justify-between items-center">
        <div className="flex gap-2">
          <Button
            variant={timeRange === 'week' ? 'default' : 'outline'}
            onClick={() => setTimeRange('week')}
          >
            Week
          </Button>
          <Button
            variant={timeRange === 'month' ? 'default' : 'outline'}
            onClick={() => setTimeRange('month')}
          >
            Month
          </Button>
          <Button
            variant={timeRange === 'year' ? 'default' : 'outline'}
            onClick={() => setTimeRange('year')}
          >
            Year
          </Button>
        </div>
        <Button
          variant="outline"
          onClick={() => setShowFilters(!showFilters)}
        >
          <Filter className="h-4 w-4 mr-2" />
          Filters
        </Button>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((item) => {
          const Icon = item.icon
          return (
            <div
              key={item.id}
              className="bg-white overflow-hidden shadow rounded-lg"
            >
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <Icon className="h-6 w-6 text-gray-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        {item.name}
                      </dt>
                      <dd className="flex items-baseline">
                        <div className="text-2xl font-semibold text-gray-900">
                          {item.stat}
                        </div>
                        <div className={`ml-2 flex items-baseline text-sm font-semibold ${
                          item.changeType === 'increase' ? 'text-green-600' : 'text-red-600'
                        }`}>
                          {item.change}
                        </div>
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          )
        })}
      </div>

      {/* Recent Sales and Top Products */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-semibold mb-4">Recent Sales</h2>
          {dashboardData.recentSales.length > 0 ? (
            <div className="space-y-4">
              {dashboardData.recentSales.map((sale) => (
                <div key={sale.id} className="flex justify-between items-center">
                  <div>
                    <p className="font-medium">{sale.client?.name}</p>
                    <p className="text-sm text-gray-500">
                      {new Date(sale.sale_date).toLocaleDateString()}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-medium">{formatCurrency(sale.total_amount)}</p>
                    <p className={`text-sm ${
                      sale.payment_status === 'paid' ? 'text-green-500' : 'text-yellow-500'
                    }`}>
                      {sale.payment_status}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-600">No recent sales</p>
          )}
        </div>

        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-semibold mb-4">Top Products</h2>
          <p className="text-gray-600">Coming soon</p>
        </div>
      </div>
    </div>
  )
}

export default requireAuth(Dashboard)