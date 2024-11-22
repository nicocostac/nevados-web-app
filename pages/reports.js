import { useState } from 'react'
import { supabase } from '@/lib/supabaseClient'
import { format } from 'date-fns'
import { Button } from '@/components/ui/button'
import { Input } from "@/components/ui/input"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover"
import { Calendar } from "@/components/ui/calendar"
import { cn } from "@/lib/utils"
import { CalendarIcon } from "lucide-react"

export default function Reports() {
  const [date, setDate] = useState(new Date())
  const [reportData, setReportData] = useState(null)
  const [loading, setLoading] = useState(false)

  const fetchSalesReport = async () => {
    setLoading(true)
    try {
      const formattedDate = format(date, 'yyyy-MM-dd')
      const { data, error } = await supabase
        .from('sales')
        .select(`
          id,
          created_at,
          total_amount,
          clients (
            name
          ),
          payment_methods (
            name
          )
        `)
        .eq('sale_date', formattedDate)
        .order('created_at', { ascending: false })

      if (error) throw error
      setReportData(data)
    } catch (error) {
      console.error('Error fetching report:', error)
      alert('Error fetching report. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const fetchDeliveryReport = async () => {
    setLoading(true)
    try {
      const formattedDate = format(date, 'yyyy-MM-dd')
      console.log('Fetching delivery report for date:', formattedDate) // Debug log
      
      // First, let's check if we have any sales for this date
      const { data: salesCheck, error: salesCheckError } = await supabase
        .from('sales')
        .select('id')
        .eq('delivery_date', formattedDate)
      
      if (salesCheckError) {
        console.error('Error checking sales:', salesCheckError)
        throw salesCheckError
      }
      
      console.log('Found sales for date:', salesCheck?.length || 0) // Debug log
      
      const { data, error } = await supabase
        .from('sales')
        .select(`
          id,
          created_at,
          delivery_date,
          delivery_address_id,
          payment_status,
          payment_method_id,
          total_amount,
          clients!left (
            name
          ),
          client_addresses!left (
            street_address,
            additional_info,
            contact_person,
            boroughs!left (
              name
            ),
            neighborhoods!left (
              name
            )
          ),
          payment_methods!left (
            name
          ),
          sale_items!left (
            id,
            quantity,
            unit_price,
            products!left (
              name
            )
          )
        `)
        .eq('delivery_date', formattedDate)
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Supabase error:', error) // Debug log
        throw error
      }
      
      console.log('Full query response:', data) // Debug log
      
      if (data && data.length > 0) {
        console.log('Sample sale:', {
          id: data[0].id,
          delivery_date: data[0].delivery_date,
          client: data[0].clients?.name,
          address: data[0].client_addresses?.street_address,
          items: data[0].sale_items?.length
        })
      }
      
      setReportData(data)
    } catch (error) {
      console.error('Error fetching report:', error)
      alert('Error fetching report. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const renderReport = () => {
    if (!reportData) return null

    return (
      <div className="mt-6">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  #
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Location
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Client
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Address
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Items
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Total
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Payment Status
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {reportData.map((item, index) => (
                <tr key={item.id}>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {index + 1}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {item.client_addresses?.neighborhoods?.name || item.client_addresses?.boroughs?.name || 'N/A'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    {item.clients?.name}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {[
                      item.client_addresses?.street_address,
                      item.client_addresses?.additional_info,
                      item.client_addresses?.contact_person
                    ]
                      .filter(Boolean)
                      .join(', ')}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <div className="space-y-1">
                      {item.sale_items?.map((saleItem, index) => (
                        <div key={index} className="flex justify-between">
                          <span>{saleItem.products.name}</span>
                          <div className="text-right">
                            <span className="text-gray-500 ml-4">×{saleItem.quantity}</span>
                            <span className="text-gray-500 ml-4">${saleItem.unit_price}</span>
                            <span className="text-gray-900 ml-4">${(saleItem.quantity * saleItem.unit_price).toFixed(2)}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    ${item.total_amount}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm">
                    {item.payment_status === 'paid' ? (
                      <div>
                        <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                          Paid
                        </span>
                        {item.payment_methods && (
                          <div className="text-gray-500 mt-1">
                            via {item.payment_methods.name}
                          </div>
                        )}
                      </div>
                    ) : (
                      <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">
                        Pending
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
            <tfoot className="bg-gray-50">
              <tr>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900" colSpan="5">
                  Total Deliveries: {reportData.length}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                  ${reportData.reduce((sum, item) => sum + parseFloat(item.total_amount || 0), 0).toFixed(2)}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                  {reportData.filter(item => item.payment_status === 'paid').length} Paid / {reportData.filter(item => item.payment_status !== 'paid').length} Pending
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>
    )
  }

  return (
    <div className="p-6">
      <h2 className="text-2xl font-bold mb-6">Reports</h2>
      
      <div className="flex flex-col space-y-4 sm:flex-row sm:space-x-4 sm:space-y-0 items-end">
        <div className="flex-1 max-w-sm">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Select Date
          </label>
          <Popover>
            <PopoverTrigger asChild>
              <Button
                variant={"outline"}
                className={cn(
                  "w-full justify-start text-left font-normal",
                  !date && "text-muted-foreground"
                )}
              >
                <CalendarIcon className="mr-2 h-4 w-4" />
                {date ? format(date, "PPP") : <span>Pick a date</span>}
              </Button>
            </PopoverTrigger>
            <PopoverContent className="w-auto p-0" align="start">
              <Calendar
                mode="single"
                selected={date}
                onSelect={setDate}
                initialFocus
              />
            </PopoverContent>
          </Popover>
        </div>

        <div className="flex space-x-4">
          <Button 
            onClick={fetchSalesReport}
            disabled={loading}
            variant="default"
          >
            Sales Report
          </Button>
          <Button 
            onClick={fetchDeliveryReport}
            disabled={loading}
            variant="default"
          >
            Delivery Report
          </Button>
        </div>
      </div>

      {loading && <div className="mt-4">Loading...</div>}
      {renderReport()}
    </div>
  )
}
