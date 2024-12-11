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
  X,
  BoxIcon,
  AlertTriangle,
  ChevronLeft,
  ChevronRight
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { supabase } from '@/lib/supabaseClient'
import { formatCurrency } from '@/lib/utils/format'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  ComposedChart,
  Bar,
  Legend
} from 'recharts'
import { Card, ProgressBar } from '@tremor/react'
import { 
  format, 
  startOfDay, 
  endOfDay, 
  subDays, 
  subMonths, 
  subYears, 
  addDays, 
  addMonths, 
  addYears,
  startOfWeek,
  endOfWeek,
  eachDayOfInterval,
  isSameMonth,
  lastDayOfMonth
} from 'date-fns'

function Dashboard() {
  const { user } = useAuth()
  const [timeRange, setTimeRange] = useState('week') // week, month, year
  const [currentDate, setCurrentDate] = useState(startOfWeek(new Date(), { weekStartsOn: 1 }))
  const [showFilters, setShowFilters] = useState(false)
  const [filters, setFilters] = useState({
    minAmount: '',
    maxAmount: '',
    paymentStatus: 'all'
  })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [dashboardData, setDashboardData] = useState({
    totalRevenue: 0,
    activeClients: 0,
    activeClientsGrowth: 0,
    productsSold: 0,
    productsGrowthRate: 0,
    growthRate: 0,
    recentSales: [],
    salesTrends: [],
    topProducts: []
  })

  // Helper function to get week of the month
  const getWeekOfMonth = (date) => {
    return Math.ceil((date.getUTCDate() + (new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1)).getUTCDay())) / 7)
  }

  // Helper function to format date based on time range
  const formatDateForRange = (dateStr, range) => {
    // Parse the date string and create a UTC date
    const [year, month, day] = dateStr.split('-').map(Number)
    
    console.log('Formatting date:', {
      input: dateStr,
      year,
      month,
      day,
      range
    })
    
    let result
    switch (range) {
      case 'week': {
        // Get day name directly from date components
        const date = new Date(Date.UTC(year, month - 1, day))
        const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        const dayOfWeek = date.getUTCDay()
        const dayName = dayNames[dayOfWeek]
        
        // Format the day number with leading zero
        const dayNum = day.toString().padStart(2, '0')
        result = `${dayNum}/${month}`
        break;
      }
      case 'month': {
        // Get the start and end date of the week
        const weekDate = new Date(Date.UTC(year, month - 1, day))
        const weekStart = startOfWeek(weekDate, { weekStartsOn: 1 })
        const weekEnd = endOfWeek(weekDate, { weekStartsOn: 1 })
        const currentMonth = month

        // Adjust start date if it's in previous month
        const startDay = isSameMonth(weekStart, weekDate) 
          ? format(weekStart, 'dd')
          : '01'
        
        // Adjust end date if it's in next month
        const endDay = isSameMonth(weekEnd, weekDate)
          ? format(weekEnd, 'dd')
          : format(lastDayOfMonth(weekDate), 'dd')

        result = `${startDay}-${endDay}/${currentMonth}`
        break;
      }
      case 'year': {
        const monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ]
        result = monthNames[month - 1]
        break;
      }
      default:
        result = dateStr
    }
    
    console.log('Format result:', {
      input: dateStr,
      result,
      range
    })
    
    return result
  }

  // Helper function to get moving average window size based on time range
  const getWindowSize = (range) => {
    switch (range) {
      case 'week':
        return 3 // 3-day moving average
      case 'month':
        return 2 // 2-week moving average
      case 'year':
        return 3 // 3-month moving average
      default:
        return 3
    }
  }

  // Helper function to get previous period start date
  const getPreviousPeriodStart = (date, range) => {
    const d = new Date(date)
    switch (range) {
      case 'week':
        return subDays(d, 7)
      case 'month':
        return subMonths(d, 1)
      case 'year':
        return subYears(d, 1)
      default:
        return d
    }
  }

  // Helper function to format the current period label
  const getCurrentPeriodLabel = () => {
    switch (timeRange) {
      case 'week': {
        const weekStart = startOfWeek(currentDate, { weekStartsOn: 1 })
        const weekEnd = endOfWeek(currentDate, { weekStartsOn: 1 })
        return `${format(weekStart, 'MMM d')} - ${format(weekEnd, 'MMM d, yyyy')}`
      }
      case 'month':
        return format(currentDate, 'MMMM yyyy')
      case 'year':
        return format(currentDate, 'yyyy')
      default:
        return format(currentDate, 'MMM d, yyyy')
    }
  }

  // Navigation handlers
  const handlePrevPeriod = () => {
    switch (timeRange) {
      case 'week':
        setCurrentDate(prev => {
          const prevWeekStart = startOfWeek(subDays(prev, 7), { weekStartsOn: 1 })
          return prevWeekStart
        })
        break
      case 'month':
        setCurrentDate(prev => subMonths(prev, 1))
        break
      case 'year':
        setCurrentDate(prev => subYears(prev, 1))
        break
    }
  }

  const handleNextPeriod = () => {
    switch (timeRange) {
      case 'week':
        setCurrentDate(prev => {
          const nextWeekStart = startOfWeek(addDays(prev, 7), { weekStartsOn: 1 })
          return nextWeekStart
        })
        break
      case 'month':
        setCurrentDate(prev => addMonths(prev, 1))
        break
      case 'year':
        setCurrentDate(prev => addYears(prev, 1))
        break
    }
  }

  const handleToday = () => {
    setCurrentDate(startOfWeek(new Date(), { weekStartsOn: 1 }))
  }

  // Fetch dashboard data
  const fetchDashboardData = async () => {
    setLoading(true)
    setError(null)
    
    try {
      // Get date range based on currentDate
      let startDate, endDate
      
      switch(timeRange) {
        case 'week':
          startDate = startOfWeek(currentDate, { weekStartsOn: 1 }) // Start on Monday
          endDate = endOfWeek(currentDate, { weekStartsOn: 1 }) // End on Sunday
          break
        case 'month':
          startDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1) // Start of month
          endDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0) // End of month
          break
        case 'year':
          startDate = new Date(currentDate.getFullYear(), 0, 1) // Start of year
          endDate = new Date(currentDate.getFullYear(), 11, 31) // End of year
          break
      }

      console.log('Date range calculation:', {
        timeRange,
        currentDate: format(currentDate, 'yyyy-MM-dd'),
        startDate: format(startDate, 'yyyy-MM-dd'),
        endDate: format(endDate, 'yyyy-MM-dd')
      })

      // Format dates for query
      const formattedStartDate = format(startDate, 'yyyy-MM-dd')
      const formattedEndDate = format(endDate, 'yyyy-MM-dd')

      console.log('Final formatted dates:', {
        formattedStartDate,
        formattedEndDate
      })

      // Build the sales query with filters
      let query = supabase
        .from('sales')
        .select(`
          id,
          total_amount,
          sale_date,
          payment_status,
          client:clients(name),
          items:sale_items(
            id,
            quantity,
            unit_price,
            total_price,
            product:products(
              id,
              name,
              category:product_categories(name)
            )
          )
        `)
        .gte('sale_date', formattedStartDate)
        .lte('sale_date', formattedEndDate)

      // Apply filters
      if (filters.minAmount) {
        query = query.gte('total_amount', parseFloat(filters.minAmount))
      }
      if (filters.maxAmount) {
        query = query.lte('total_amount', parseFloat(filters.maxAmount))
      }
      if (filters.paymentStatus !== 'all') {
        query = query.eq('payment_status', filters.paymentStatus)
      }

      // Execute the query
      const { data: salesData, error: salesError } = await query.order('sale_date', { ascending: false })

      console.log('Query results:', {
        startDate: formattedStartDate,
        endDate: formattedEndDate,
        salesCount: salesData?.length,
        sampleDates: salesData?.slice(0, 3).map(s => ({
          id: s.id,
          sale_date: s.sale_date
        }))
      })

      if (salesError) throw salesError

      // Fetch active clients with their sales in the selected period
      const { data: activeClientsData, error: activeClientsError } = await supabase
        .from('clients')
        .select(`
          id,
          name,
          sales:sales(
            id,
            sale_date
          )
        `)
        .eq('status', 'active')

      if (activeClientsError) throw activeClientsError

      // Count clients with sales in the selected period
      const activeClientsCount = activeClientsData.filter(client => {
        const hasRecentSales = client.sales?.some(sale => 
          new Date(sale.sale_date) >= startDate
        )
        return hasRecentSales
      }).length

      // Calculate client activity change compared to previous period
      const previousPeriodStart = getPreviousPeriodStart(startDate, timeRange)

      const previousActiveClientsCount = activeClientsData.filter(client => {
        const hasPreviousSales = client.sales?.some(sale => {
          const saleDate = new Date(sale.sale_date)
          return saleDate >= previousPeriodStart && saleDate < startDate
        })
        return hasPreviousSales
      }).length

      const clientsGrowthRate = previousActiveClientsCount === 0 ? 100 :
        ((activeClientsCount - previousActiveClientsCount) / previousActiveClientsCount) * 100

      // Process sales data for trends
      const salesByDate = {}
      console.log('Processing sales data:', {
        totalSales: salesData.length,
        timeRange,
        sampleSales: salesData.slice(0, 3).map(sale => ({
          id: sale.id,
          sale_date: sale.sale_date,
          formatted_date: formatDateForRange(sale.sale_date, timeRange)
        }))
      })

      salesData.forEach(sale => {
        const groupKey = formatDateForRange(sale.sale_date, timeRange)
        
        console.log('Processing sale:', {
          sale_id: sale.id,
          sale_date: sale.sale_date,
          groupKey,
          amount: sale.total_amount
        })
        
        salesByDate[groupKey] = (salesByDate[groupKey] || 0) + sale.total_amount
      })

      console.log('Sales grouped by date:', salesByDate)

      // Convert to array and sort by date
      const salesTrendsArray = Object.entries(salesByDate)
        .map(([date, amount]) => ({
          date,
          amount,
          trend: 0 // Initialize trend value
        }))

      console.log('Sales trends array before sorting:', salesTrendsArray)

      console.log('Sorting array:', {
        timeRange,
        before: salesTrendsArray.map(item => ({
          date: item.date,
          amount: item.amount
        }))
      })

      salesTrendsArray.sort((a, b) => {
        if (timeRange === 'week') {
          // Extract day number from "Day, DD" format
          const aDay = parseInt(a.date.split(', ')[1])
          const bDay = parseInt(b.date.split(', ')[1])
          console.log('Week sorting:', {
            a: a.date,
            b: b.date,
            aDay,
            bDay
          })
          return aDay - bDay
        } else if (timeRange === 'month') {
          return parseInt(a.date.split('-')[0]) - parseInt(b.date.split('-')[0])
        } else {
          // For year view, convert month abbreviations to numbers (Jan=1, Feb=2, etc)
          const monthToNumber = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
          }
          console.log('Month comparison:', {
            a: a.date,
            b: b.date,
            aNum: monthToNumber[a.date],
            bNum: monthToNumber[b.date]
          })
          return monthToNumber[a.date] - monthToNumber[b.date]
        }
      })

      console.log('Sorting result:', {
        timeRange,
        after: salesTrendsArray.map(item => ({
          date: item.date,
          amount: item.amount
        }))
      })

      console.log('Sales trends array after sorting:', salesTrendsArray)

      // Calculate moving average for trend line
      const windowSize = getWindowSize(timeRange)
      for (let i = 0; i < salesTrendsArray.length; i++) {
        let sum = 0
        let count = 0
        
        // Look back up to windowSize periods
        for (let j = Math.max(0, i - windowSize + 1); j <= i; j++) {
          sum += salesTrendsArray[j].amount
          count++
        }
        
        salesTrendsArray[i].trend = Math.round(sum / count)
      }

      const salesTrends = salesTrendsArray

      // Calculate metrics
      const totalRevenue = salesData.reduce((sum, sale) => sum + sale.total_amount, 0)
      const productsSold = salesData.reduce((sum, sale) => 
        sum + sale.items.reduce((itemSum, item) => itemSum + item.quantity, 0), 0)

      // Fetch previous period sales
      const { data: previousSales } = await supabase
        .from('sales')
        .select(`
          total_amount,
          items:sale_items(
            quantity
          )
        `)
        .gte('sale_date', previousPeriodStart.toISOString())
        .lt('sale_date', startDate.toISOString())

      const previousRevenue = previousSales?.reduce((sum, sale) => sum + sale.total_amount, 0) || 0
      const previousProductsSold = previousSales?.reduce((sum, sale) => 
        sum + sale.items.reduce((itemSum, item) => itemSum + item.quantity, 0), 0) || 0

      const growthRate = previousRevenue === 0 ? 100 : 
        ((totalRevenue - previousRevenue) / previousRevenue) * 100

      const productsGrowthRate = previousProductsSold === 0 ? 100 :
        ((productsSold - previousProductsSold) / previousProductsSold) * 100

      // Calculate top products
      const productSales = {}
      salesData.forEach(sale => {
        sale.items.forEach(item => {
          const productId = item.product.id
          if (!productSales[productId]) {
            productSales[productId] = {
              id: productId,
              name: item.product.name,
              category: item.product.category?.name || 'Uncategorized',
              quantity: 0,
              revenue: 0
            }
          }
          productSales[productId].quantity += item.quantity
          productSales[productId].revenue += item.total_price
        })
      })

      const topProducts = Object.values(productSales)
        .sort((a, b) => b.revenue - a.revenue)
        .slice(0, 5)

      // Update dashboard data
      setDashboardData({
        totalRevenue,
        activeClients: activeClientsCount,
        activeClientsGrowth: Math.round(clientsGrowthRate * 100) / 100,
        productsSold,
        productsGrowthRate: Math.round(productsGrowthRate * 100) / 100,
        growthRate: Math.round(growthRate * 100) / 100,
        recentSales: salesData.slice(0, 5),
        salesTrends,
        topProducts
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
  }, [timeRange, currentDate])

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
      description: timeRange === 'week' ? 'Clients with purchases this week' :
                  timeRange === 'month' ? 'Clients with purchases this month' :
                  'Clients with purchases this year',
      change: `${dashboardData.activeClientsGrowth}%`,
      changeType: dashboardData.activeClientsGrowth >= 0 ? 'increase' : 'decrease'
    },
    {
      id: 3,
      name: 'Products Sold',
      stat: dashboardData.productsSold,
      icon: Package,
      description: timeRange === 'week' ? 'Units sold this week' :
                  timeRange === 'month' ? 'Units sold this month' :
                  'Units sold this year',
      change: `${dashboardData.productsGrowthRate}%`,
      changeType: dashboardData.productsGrowthRate >= 0 ? 'increase' : 'decrease'
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

      {/* Date Navigation */}
      <div className="flex items-center justify-between bg-white rounded-lg shadow p-4 mb-6">
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="icon"
            onClick={handlePrevPeriod}
            className="hover:bg-gray-100"
          >
            <ChevronLeft className="h-5 w-5" />
          </Button>
          <div className="flex flex-col items-center min-w-[200px]">
            <span className="text-xl font-semibold">{getCurrentPeriodLabel()}</span>
            <span className="text-sm text-gray-500 capitalize">{timeRange} view</span>
          </div>
          <Button
            variant="outline"
            size="icon"
            onClick={handleNextPeriod}
            className="hover:bg-gray-100"
          >
            <ChevronRight className="h-5 w-5" />
          </Button>
        </div>
        <div className="flex items-center gap-4">
          <Button
            variant="outline"
            size="sm"
            onClick={handleToday}
            className="hover:bg-gray-100"
          >
            <Calendar className="h-4 w-4 mr-2" />
            Today
          </Button>
          <div className="flex items-center rounded-md border border-gray-200">
            <Button
              variant={timeRange === 'week' ? 'secondary' : 'ghost'}
              size="sm"
              onClick={() => setTimeRange('week')}
              className="rounded-r-none border-r"
            >
              Week
            </Button>
            <Button
              variant={timeRange === 'month' ? 'secondary' : 'ghost'}
              size="sm"
              onClick={() => setTimeRange('month')}
              className="rounded-none border-r"
            >
              Month
            </Button>
            <Button
              variant={timeRange === 'year' ? 'secondary' : 'ghost'}
              size="sm"
              onClick={() => setTimeRange('year')}
              className="rounded-l-none"
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
      </div>

      {/* Filters Panel */}
      {showFilters && (
        <div className="bg-white shadow rounded-lg p-6 mb-6">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-lg font-semibold">Filters</h2>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setShowFilters(false)}
            >
              <X className="h-4 w-4" />
            </Button>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Min Amount
              </label>
              <Input
                type="number"
                value={filters.minAmount}
                onChange={(e) => setFilters({ ...filters, minAmount: e.target.value })}
                placeholder="Min amount"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Max Amount
              </label>
              <Input
                type="number"
                value={filters.maxAmount}
                onChange={(e) => setFilters({ ...filters, maxAmount: e.target.value })}
                placeholder="Max amount"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Payment Status
              </label>
              <select
                className="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                value={filters.paymentStatus}
                onChange={(e) => setFilters({ ...filters, paymentStatus: e.target.value })}
              >
                <option value="all">All Statuses</option>
                <option value="paid">Paid</option>
                <option value="pending">Pending</option>
                <option value="overdue">Overdue</option>
              </select>
            </div>
          </div>
          
          <div className="mt-4 flex justify-end space-x-2">
            <Button
              variant="outline"
              onClick={() => {
                setFilters({
                  minAmount: '',
                  maxAmount: '',
                  paymentStatus: 'all'
                })
              }}
            >
              Reset Filters
            </Button>
            <Button
              onClick={() => {
                fetchDashboardData()
                setShowFilters(false)
              }}
            >
              Apply Filters
            </Button>
          </div>
        </div>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {[
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
            description: timeRange === 'week' ? 'Clients with purchases this week' :
                        timeRange === 'month' ? 'Clients with purchases this month' :
                        'Clients with purchases this year',
            change: `${dashboardData.activeClientsGrowth}%`,
            changeType: dashboardData.activeClientsGrowth >= 0 ? 'increase' : 'decrease'
          },
          {
            id: 3,
            name: 'Products Sold',
            stat: dashboardData.productsSold,
            icon: Package,
            description: timeRange === 'week' ? 'Units sold this week' :
                        timeRange === 'month' ? 'Units sold this month' :
                        'Units sold this year',
            change: `${dashboardData.productsGrowthRate}%`,
            changeType: dashboardData.productsGrowthRate >= 0 ? 'increase' : 'decrease'
          },
          {
            id: 4,
            name: 'Growth Rate',
            stat: `${dashboardData.growthRate}%`,
            icon: TrendingUp,
            change: `${dashboardData.growthRate}%`,
            changeType: dashboardData.growthRate >= 0 ? 'increase' : 'decrease'
          }
        ].map((item) => (
          <div
            key={item.id}
            className="bg-white overflow-hidden shadow rounded-lg"
          >
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <item.icon className="h-6 w-6 text-gray-400" />
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
                      {item.description && (
                        <div className="ml-2 text-sm text-gray-500">{item.description}</div>
                      )}
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
        ))}
      </div>

      {/* Sales Trends */}
      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-lg font-semibold mb-4">
          Sales Trends
          <span className="text-sm font-normal text-gray-500 ml-2">
            {timeRange === 'week' ? '(3-day average)' :
             timeRange === 'month' ? '(2-week average)' :
             '(3-month average)'}
          </span>
        </h2>
        <div className="w-full h-[400px] relative">
          {dashboardData.salesTrends.length > 0 ? (
            <ResponsiveContainer width="100%" height="100%">
              <ComposedChart 
                data={timeRange === 'week' ? [...dashboardData.salesTrends].reverse() : dashboardData.salesTrends}
                margin={{ top: 20, right: 30, bottom: 20, left: 60 }}
                height={400}
              >
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis 
                  dataKey="date" 
                  tick={{ fontSize: 12 }}
                  interval={0}
                  tickMargin={10}
                  height={40}
                />
                <YAxis 
                  tick={{ fontSize: 12 }}
                  tickFormatter={(value) => formatCurrency(value)}
                  width={80}
                />
                <Tooltip 
                  formatter={(value) => formatCurrency(value)}
                  labelFormatter={(label) => {
                    switch(timeRange) {
                      case 'week':
                        return `Sales for ${label}`
                      case 'month':
                        return `Week ${label}`
                      case 'year':
                        return `${label} Sales`
                      default:
                        return label
                    }
                  }}
                />
                <Legend />
                <Bar 
                  dataKey="amount" 
                  fill="#8884d8" 
                  name={timeRange === 'week' ? 'Daily Sales' :
                        timeRange === 'month' ? 'Weekly Sales' :
                        'Monthly Sales'}
                  barSize={20}
                />
                <Line
                  type="monotone"
                  dataKey="trend"
                  stroke="#ff7300"
                  name="Trend"
                  strokeWidth={2}
                  dot={false}
                />
              </ComposedChart>
            </ResponsiveContainer>
          ) : (
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="text-center">
                <p className="text-gray-500 text-lg">No sales data available for this period</p>
                <p className="text-gray-400 text-sm mt-1">Try selecting a different time range</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Recent Sales and Top Products */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Recent Sales */}
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
            <p className="text-gray-500">No recent sales</p>
          )}
        </div>

        {/* Top Products */}
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-semibold mb-4">Top Products</h2>
          {dashboardData.topProducts.length > 0 ? (
            <div className="space-y-4">
              {dashboardData.topProducts.map((product) => (
                <div key={product.id} className="flex justify-between items-center">
                  <div>
                    <p className="font-medium">{product.name}</p>
                    <p className="text-sm text-gray-500">
                      {product.category} • Sold: {product.quantity}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-medium">{formatCurrency(product.revenue)}</p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500">No product data available</p>
          )}
        </div>
      </div>
    </div>
  )
}

export default requireAuth(Dashboard)