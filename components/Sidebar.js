import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/router'
import { useAuth } from '@/lib/context/AuthContext'
import { supabase } from '@/lib/supabaseClient'
import { 
  Home, 
  Users, 
  Package, 
  ShoppingCart,
  Settings,
  ChevronDown,
  ChevronRight,
  BarChart2
} from 'lucide-react'

export default function Sidebar() {
  const router = useRouter()
  const { user } = useAuth()
  const [userRole, setUserRole] = useState(null)
  const [openMenus, setOpenMenus] = useState({
    Settings: true,
    Reports: true,
    Products: true
  })

  // Add effect to fetch user role
  useEffect(() => {
    async function fetchUserRole() {
      if (user?.id) {
        const { data: profile, error } = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single()

        if (error) {
          console.error('Error fetching user role:', error)
        } else {
          setUserRole(profile?.role)
        }
      }
    }
    fetchUserRole()
  }, [user?.id])

  const menuItems = [
    {
      title: 'Dashboard',
      icon: Home,
      href: '/dashboard',
      roles: ['admin', 'manager', 'salesperson']
    },
    {
      title: 'Clients',
      icon: Users,
      href: '/clients',
      roles: ['admin', 'manager', 'salesperson']
    },
    {
      title: 'Products',
      icon: Package,
      roles: ['admin', 'manager', 'salesperson'],
      submenu: [
        {
          title: 'Products List',
          href: '/products',
          roles: ['admin', 'manager', 'salesperson']
        },
        {
          title: 'Bundles',
          href: '/bundles',
          roles: ['admin', 'manager']
        }
      ]
    },
    {
      title: 'Sales',
      icon: ShoppingCart,
      href: '/sales',
      roles: ['admin', 'manager', 'salesperson']
    },
    {
      title: 'Reports',
      icon: BarChart2,
      roles: ['admin', 'manager'],
      submenu: [
        {
          title: 'Delivery Heatmap',
          href: '/heatmap',
          roles: ['admin', 'manager']
        },
        {
          title: 'Sales & Delivery Reports',
          href: '/reports',
          roles: ['admin', 'manager']
        }
      ]
    },
    {
      title: 'Settings',
      icon: Settings,
      roles: ['admin','manager'],
      submenu: [
        {
          title: 'Users',
          href: '/settings/users',
          roles: ['admin']
        },
        {
          title: 'Client Types',
          href: '/clients/types',
          roles: ['admin']
        },
        {
          title: 'Product Categories',
          href: '/products/categories',
          roles: ['admin','manager']
        },
        {
          title: 'Payment Methods',
          href: '/settings/payment-methods',
          roles: ['admin']
        },
        {
          title: 'Locations',
          href: '/settings/locations',
          roles: ['admin']
        }
      ]
    }
  ]

  const toggleMenu = (title) => {
    setOpenMenus(prev => ({
      ...prev,
      [title]: !prev[title]
    }))
  }

  const isMenuItemVisible = (roles) => {
    if (!roles || !userRole) return false
    return roles.includes(userRole)
  }

  // Show loading state while fetching role
  if (!userRole) {
    return (
      <div className="bg-white h-full w-64 border-r">
        <div className="p-4">
          <h1 className="text-xl font-bold">Nevados</h1>
        </div>
        <div className="p-4">Loading...</div>
      </div>
    )
  }

  return (
    <div className="bg-white h-full w-64 border-r">
      <div className="p-4">
        <h1 className="text-xl font-bold">Nevados</h1>
      </div>
      <nav className="mt-4">
        {menuItems.map((item) => {
          const Icon = item.icon
          const isActive = item.href === router.pathname
          const hasSubmenu = !!item.submenu
          const isSubmenuOpen = openMenus[item.title]
          const visibleSubmenuItems = item.submenu?.filter(subItem => 
            isMenuItemVisible(subItem.roles)
          )

          // Skip menu items that user doesn't have access to
          if (!isMenuItemVisible(item.roles)) return null
          // Skip menu items with submenu if user doesn't have access to any submenu items
          if (hasSubmenu && !visibleSubmenuItems?.length) return null

          return (
            <div key={item.title}>
              {hasSubmenu ? (
                <button
                  onClick={() => toggleMenu(item.title)}
                  className={`w-full flex items-center px-4 py-2 text-gray-700 hover:bg-gray-100 ${
                    isActive ? 'bg-gray-100' : ''
                  }`}
                >
                  <Icon className="h-5 w-5 mr-2" />
                  <span>{item.title}</span>
                  {isSubmenuOpen ? (
                    <ChevronDown className="h-4 w-4 ml-auto" />
                  ) : (
                    <ChevronRight className="h-4 w-4 ml-auto" />
                  )}
                </button>
              ) : (
                <Link
                  href={item.href}
                  className={`flex items-center px-4 py-2 text-gray-700 hover:bg-gray-100 ${
                    isActive ? 'bg-gray-100' : ''
                  }`}
                >
                  <Icon className="h-5 w-5 mr-2" />
                  <span>{item.title}</span>
                </Link>
              )}
              {hasSubmenu && isSubmenuOpen && (
                <div className="ml-4">
                  {visibleSubmenuItems.map((subItem) => (
                    <Link
                      key={subItem.href}
                      href={subItem.href}
                      className={`flex items-center px-4 py-2 text-gray-700 hover:bg-gray-100 ${
                        router.pathname === subItem.href ? 'bg-gray-100' : ''
                      }`}
                    >
                      <span>{subItem.title}</span>
                    </Link>
                  ))}
                </div>
              )}
            </div>
          )
        })}
      </nav>
    </div>
  )
} 