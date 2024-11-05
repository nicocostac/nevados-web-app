import { requireAuth } from '@/lib/auth/requireAuth'
import { useAuth } from '@/lib/context/AuthContext'
import { 
  DollarSign, 
  Users, 
  Package, 
  TrendingUp 
} from 'lucide-react'

function Dashboard() {
  const { user } = useAuth()

  const stats = [
    {
      id: 1,
      name: 'Total Revenue',
      stat: '$0.00',
      icon: DollarSign,
      change: '0%',
      changeType: 'increase'
    },
    {
      id: 2,
      name: 'Active Clients',
      stat: '0',
      icon: Users,
      change: '0%',
      changeType: 'increase'
    },
    {
      id: 3,
      name: 'Products Sold',
      stat: '0',
      icon: Package,
      change: '0%',
      changeType: 'decrease'
    },
    {
      id: 4,
      name: 'Growth Rate',
      stat: '0%',
      icon: TrendingUp,
      change: '0%',
      changeType: 'increase'
    },
  ]

  return (
    <div className="space-y-6">
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

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-semibold mb-4">Recent Sales</h2>
          <p className="text-gray-600">No recent sales</p>
        </div>

        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-semibold mb-4">Top Products</h2>
          <p className="text-gray-600">No products data</p>
        </div>
      </div>
    </div>
  )
}

export default requireAuth(Dashboard)