import Link from 'next/link'
import { useRouter } from 'next/router'
import { 
  LayoutDashboard, 
  Users, 
  Package, 
  Receipt, 
  BarChart3, 
  Settings,
  UserPlus 
} from 'lucide-react'

const menuItems = [
  { icon: LayoutDashboard, label: 'Dashboard', href: '/dashboard' },
  { icon: Users, label: 'Clients', href: '/clients' },
  { icon: Package, label: 'Products', href: '/products' },
  { icon: Receipt, label: 'Sales', href: '/sales' },
  { icon: BarChart3, label: 'Reports', href: '/reports' },
  { 
    icon: Settings, 
    label: 'Settings', 
    href: '/settings',
    subItems: [
      { icon: UserPlus, label: 'Users', href: '/settings/users' }
    ]
  },
]

export default function Sidebar() {
  const router = useRouter()
  const currentPath = router.pathname

  return (
    <div className="flex flex-col w-64 bg-white border-r border-gray-200">
      <div className="flex flex-col flex-grow pt-5 pb-4 overflow-y-auto">
        <div className="flex items-center flex-shrink-0 px-4">
          <h1 className="text-xl font-semibold text-gray-800">Nevados App</h1>
        </div>
        <nav className="mt-5 flex-1 px-2 space-y-1">
          {menuItems.map((item) => {
            const isActive = currentPath === item.href || 
              (item.subItems && item.subItems.some(sub => currentPath === sub.href))
            const Icon = item.icon
            
            return (
              <div key={item.href}>
                <Link
                  href={item.href}
                  className={`group flex items-center px-2 py-2 text-sm font-medium rounded-md ${
                    isActive
                      ? 'bg-gray-100 text-gray-900'
                      : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                  }`}
                >
                  <Icon
                    className={`mr-3 h-5 w-5 ${
                      isActive
                        ? 'text-gray-500'
                        : 'text-gray-400 group-hover:text-gray-500'
                    }`}
                  />
                  {item.label}
                </Link>

                {item.subItems && (
                  <div className="ml-8 space-y-1">
                    {item.subItems.map((subItem) => {
                      const isSubActive = currentPath === subItem.href
                      const SubIcon = subItem.icon

                      return (
                        <Link
                          key={subItem.href}
                          href={subItem.href}
                          className={`group flex items-center px-2 py-2 text-sm font-medium rounded-md ${
                            isSubActive
                              ? 'bg-gray-100 text-gray-900'
                              : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                          }`}
                        >
                          <SubIcon
                            className={`mr-3 h-4 w-4 ${
                              isSubActive
                                ? 'text-gray-500'
                                : 'text-gray-400 group-hover:text-gray-500'
                            }`}
                          />
                          {subItem.label}
                        </Link>
                      )
                    })}
                  </div>
                )}
              </div>
            )
          })}
        </nav>
      </div>
    </div>
  )
}