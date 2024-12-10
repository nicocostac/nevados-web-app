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
  const [error, setError] = useState('')
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
    clientId: '',
    items: [],
    deliveryDate: '',
    paymentMethodId: '',
    notes: '',
    status: 'pending',
    paymentStatus: 'pending'
  });
  const [finalPriceMap, setFinalPriceMap] = useState({});
  const [currentPage, setCurrentPage] = useState(1)
  const [totalPages, setTotalPages] = useState(0)
  const [totalRecords, setTotalRecords] = useState(0)
  const [isLoading, setIsLoading] = useState(true)
  const [sortConfig, setSortConfig] = useState({
    key: 'sale_date',
    direction: 'desc'
  });
  const rowsPerPage = 10

  useEffect(() => {
    fetchSales()
    fetchClients()
    fetchProducts()
    fetchPaymentMethods()
    fetchUniqueLocations()
  }, [])

  useEffect(() => {
    fetchSales()
  }, [filters, currentPage, sortConfig])

  const fetchSales = async () => {
    try {
      setIsLoading(true);
      console.log('Starting fetchSales for page', currentPage);
      console.log('Current sort config:', sortConfig);

      // First, get total count
      const countQuery = supabase
        .from('sales')
        .select('id', { count: 'exact' });

      // Apply filters to count query
      if (filters.borough) {
        countQuery.filter('delivery_address.boroughs.name', 'eq', filters.borough);
      }
      if (filters.neighborhood) {
        countQuery.filter('delivery_address.neighborhoods.name', 'eq', filters.neighborhood);
      }
      if (filters.clientId) {
        countQuery.eq('client_id', filters.clientId);
      }
      if (filters.saleStartDate) {
        countQuery.gte('sale_date', filters.saleStartDate);
      }
      if (filters.saleEndDate) {
        countQuery.lte('sale_date', filters.saleEndDate);
      }
      if (filters.deliveryStartDate) {
        countQuery.gte('delivery_date', filters.deliveryStartDate);
      }
      if (filters.deliveryEndDate) {
        countQuery.lte('delivery_date', filters.deliveryEndDate);
      }
      if (filters.paymentStatus) {
        countQuery.eq('payment_status', filters.paymentStatus);
      }

      const { count, error: countError } = await countQuery;
      
      if (countError) throw countError;
      
      console.log('Total records:', count);
      const totalPages = Math.max(1, Math.ceil(count / rowsPerPage));
      console.log('Total pages:', totalPages);
      
      setTotalRecords(count);
      setTotalPages(totalPages);

      // Adjust current page if it's out of bounds
      if (currentPage > totalPages) {
        console.log('Current page out of bounds, adjusting to', totalPages);
        setCurrentPage(totalPages);
        return; // The useEffect will trigger another fetch with the correct page
      }

      // Now fetch the actual data for the current page
      const start = (currentPage - 1) * rowsPerPage;
      const end = start + rowsPerPage - 1;

      console.log(`Fetching records ${start + 1} to ${end + 1} of ${count} for page ${currentPage}`);

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
        `);

      // Apply filters
      if (filters.borough) {
        query = query.filter('delivery_address.boroughs.name', 'eq', filters.borough);
      }
      if (filters.neighborhood) {
        query = query.filter('delivery_address.neighborhoods.name', 'eq', filters.neighborhood);
      }
      if (filters.clientId) {
        query = query.eq('client_id', filters.clientId);
      }
      if (filters.saleStartDate) {
        query = query.gte('sale_date', filters.saleStartDate);
      }
      if (filters.saleEndDate) {
        query = query.lte('sale_date', filters.saleEndDate);
      }
      if (filters.deliveryStartDate) {
        query = query.gte('delivery_date', filters.deliveryStartDate);
      }
      if (filters.deliveryEndDate) {
        query = query.lte('delivery_date', filters.deliveryEndDate);
      }
      if (filters.paymentStatus) {
        query = query.eq('payment_status', filters.paymentStatus);
      }

      // Add sorting
      const ascending = sortConfig.direction === 'asc';
      
      // Handle special cases for foreign key relationships
      switch (sortConfig.key) {
        case 'client':
          query = query.order('client(name)', { ascending });
          break;
        case 'delivery_address':
          query = query.order('delivery_address(street_address)', { ascending });
          break;
        case 'total_amount':
          query = query.order('total_amount', { ascending, nullsFirst: false });
          break;
        case 'sale_date':
          query = query.order('sale_date', { ascending, nullsFirst: false });
          break;
        case 'delivery_date':
          query = query.order('delivery_date', { ascending, nullsFirst: false });
          break;
        case 'status':
          query = query.order('status', { ascending, nullsFirst: false });
          break;
        case 'payment_status':
          query = query.order('payment_status', { ascending, nullsFirst: false });
          break;
        default:
          query = query.order('sale_date', { ascending: false });
          break;
      }

      // Always add a secondary sort by ID to maintain consistent order
      query = query.order('id', { ascending: false });

      // Add pagination
      query = query.range(start, end);

      console.log('Executing query with sort:', sortConfig);
      const { data: salesData, error: salesError } = await query;

      if (salesError) {
        console.error('Error fetching sales:', salesError);
        throw salesError;
      }
      if (!salesData) throw new Error('No sales data received');

      console.log(`Received ${salesData.length} records for page ${currentPage}`);

      if (salesData.length === 0) {
        console.log('No sales found for current page');
        setSales([]);
        setIsLoading(false);
        return;
      }

      // Fetch items for the sales
      const { data: itemsData, error: itemsError } = await supabase
        .from('sale_items')
        .select('*')
        .in('sale_id', salesData.map(sale => sale.id));

      if (itemsError) throw itemsError;

      const salesWithItems = salesData.map(sale => ({
        ...sale,
        sale_items: itemsData.filter(item => item.sale_id === sale.id)
      }));

      console.log(`Setting ${salesWithItems.length} sales for page ${currentPage}`);
      setSales(salesWithItems);
      setIsLoading(false);
    } catch (error) {
      console.error('Error in fetchSales:', error);
      setError('Failed to fetch sales data. Please try reloading the page.');
      setSales([]);
      setTotalRecords(0);
      setTotalPages(1);
      setIsLoading(false);
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
    // Fetch regular products
    const { data: productsData, error: productsError } = await supabase
      .from('products')
      .select(`
        id,
        name,
        unit_of_sale,
        status,
        product_prices (
          id,
          price,
          start_date,
          end_date
        )
      `)
      .eq('status', 'active')
      .order('name');

    // Fetch bundles
    const { data: bundlesData, error: bundlesError } = await supabase
      .from('mixed_bundles')
      .select(`
        id,
        name,
        description,
        total_price,
        items:mixed_bundle_items(
          id,
          product_id,
          quantity
        )
      `)
      .eq('status', 'active')
      .order('name');

    if (productsError) {
      console.error('Error fetching products:', productsError)
    } else if (bundlesError) {
      console.error('Error fetching bundles:', bundlesError)
    } else {
      // Process products to include current price and find single-product bundles
      const currentDate = new Date();
      const singleProductBundles = new Map(); // Map to store bundles by product ID

      // Group single-product bundles by their product ID
      bundlesData.forEach(bundle => {
        if (bundle.items.length === 1) {
          const productId = bundle.items[0].product_id;
          if (!singleProductBundles.has(productId)) {
            singleProductBundles.set(productId, []);
          }
          singleProductBundles.get(productId).push({
            ...bundle,
            bundleQuantity: bundle.items[0].quantity,
            pricePerUnit: bundle.total_price / bundle.items[0].quantity
          });
        }
      });

      const processedProducts = productsData.map(product => {
        const currentPrice = product.product_prices
          .sort((a, b) => new Date(b.start_date) - new Date(a.start_date))
          .find(price => {
            const startDate = new Date(price.start_date);
            const endDate = price.end_date ? new Date(price.end_date) : null;
            return startDate <= currentDate && (!endDate || endDate >= currentDate);
          });

        // Add single-product bundles to the product
        const productBundles = singleProductBundles.get(product.id) || [];
        
        return {
          ...product,
          default_price: currentPrice?.price || 0,
          is_bundle: false,
          product_prices: product.product_prices,
          single_product_bundles: productBundles.sort((a, b) => a.bundleQuantity - b.bundleQuantity)
        };
      });

      // Process multi-product bundles
      const multiProductBundles = bundlesData
        .filter(bundle => bundle.items.length > 1)
        .map(bundle => ({
          id: bundle.id,
          bundle_id: bundle.id,
          name: `${bundle.name} (Bundle)`,
          unit_of_sale: 'bundle',
          status: 'active',
          default_price: bundle.total_price,
          is_bundle: true,
          bundle_items: bundle.items,
          description: bundle.description
        }));

      // Combine products and bundles
      setProducts([...processedProducts, ...multiProductBundles] || [])
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

      // Start a transaction
      const saleData = {
        client_id: formData.clientId,
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
      };

      let saleId;
      if (editingSale) {
        // Update existing sale
        const { error: saleError } = await supabase
          .from('sales')
          .update(saleData)
          .eq('id', editingSale.id)

        if (saleError) throw new Error(`Failed to update sale: ${saleError.message}`);
        saleId = editingSale.id;
      } else {
        // Create new sale
        const { data: newSale, error: saleError } = await supabase
          .from('sales')
          .insert([saleData])
          .select()
          .single()

        if (saleError) throw new Error(`Failed to create sale: ${saleError.message}`);
        saleId = newSale.id;
      }

      // Process items, expanding bundles into their individual products
      const expandedItems = [];
      let itemNumber = 1;

      for (const item of formData.items) {
        const product = products.find(p => p.id === item.productId);
        
        if (product?.is_bundle) {
          // This is a multi-product bundle
          if (product.bundle_items) {
            // Add each bundle item as a separate sale item
            for (const bundleItem of product.bundle_items) {
              expandedItems.push({
                sale_id: saleId,
                product_id: bundleItem.product_id,
                item_number: itemNumber++,
                quantity: bundleItem.quantity * item.quantity,
                unit_price: (product.default_price / product.bundle_items.length) / bundleItem.quantity,
                total_price: product.default_price * item.quantity,
                discount_percentage: item.discountPercentage,
                is_from_bundle: true,
                bundle_id: product.bundle_id
              });
            }
          }
        } else {
          // Regular product or single-product bundle
          expandedItems.push({
            sale_id: saleId,
            product_id: item.productId,
            item_number: itemNumber++,
            quantity: item.quantity,
            unit_price: item.unitPrice,
            total_price: item.totalPrice,
            discount_percentage: item.discountPercentage,
            is_from_bundle: item.bundleId ? true : false,
            bundle_id: item.bundleId || null
          });
        }
      }

      // Delete existing items if updating
      if (editingSale) {
        const { error: deleteError } = await supabase
          .from('sale_items')
          .delete()
          .eq('sale_id', saleId);

        if (deleteError) throw new Error(`Failed to clean up old items: ${deleteError.message}`);
      }

      // Insert all new items
      const { error: itemsError } = await supabase
        .from('sale_items')
        .insert(expandedItems);

      if (itemsError) throw new Error(`Failed to create sale items: ${itemsError.message}`);

      setMessage('Sale saved successfully!');
      setIsModalOpen(false);
      setEditingSale(null);
      
      // Add a longer delay and error handling for fetching updated sales
      setTimeout(async () => {
        try {
          await fetchSales();
        } catch (error) {
          console.error('Error refreshing sales table:', error);
          setError('Sale was saved but table refresh failed. Please reload the page.');
        }
      }, 1000);
    } catch (error) {
      console.error('Error saving sale:', error);
      setError(error.message);
    }
  };

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

      const product = products.find(p => p.id === productId);
      if (!product) return;

      const today = new Date().toISOString().split('T')[0];
      
      const { data, error } = await supabase.rpc('get_product_price_at_date', {
        product_id: productId,
        target_date: today,
        client_id: formData.clientId || null
      });

      if (error) {
        console.error('Error fetching price:', error);
        return;
      }

      const priceInfo = Array.isArray(data) && data.length > 0 ? data[0] : { 
        price: 0, 
        price_type: 'none',
        bundle_id: null,
        bundle_quantity: null
      };

      const finalPrice = Number(priceInfo.price || 0);
      const isBundle = priceInfo.price_type === 'bundle';
      const isBundleUnit = priceInfo.price_type === 'bundle_unit';

      // Store price info for later use
      setFinalPriceMap(prev => ({
        ...prev,
        [productId]: {
          price: finalPrice,
          isBundle,
          isBundleUnit,
          bundleId: priceInfo.bundle_id,
          bundleQuantity: priceInfo.bundle_quantity ? Number(priceInfo.bundle_quantity) : null,
          regularPrice: product.default_price || finalPrice
        }
      }));

      // Add new item to form
      setFormData(prev => ({
        ...prev,
        items: [
          ...prev.items,
          {
            productId,
            productName: product.name,
            quantity: 1,
            unitPrice: finalPrice,
            totalPrice: finalPrice,
            isBundle,
            isBundleUnit,
            bundleId: priceInfo.bundle_id,
            bundleQuantity: priceInfo.bundle_quantity ? Number(priceInfo.bundle_quantity) : null
          }
        ]
      }));
    } catch (error) {
      console.error('Error in handleProductSelect:', error);
      setError('Failed to get product pricing');
    }
  };

  const handleItemChange = (index, field, value) => {
    const updatedItems = [...formData.items];
    const item = updatedItems[index];
    const priceInfo = finalPriceMap[item.productId];

    if (!priceInfo) {
      console.error('No price info found for product:', item.productId);
      return;
    }

    if (field === 'quantity') {
      const newQuantity = Math.max(1, Number(value));
      
      if (priceInfo.isBundleUnit && priceInfo.bundleQuantity) {
        const bundleQuantity = priceInfo.bundleQuantity;
        const bundleUnitPrice = priceInfo.price;
        const regularPrice = priceInfo.regularPrice;

        if (newQuantity >= bundleQuantity) {
          const bundleSets = Math.floor(newQuantity / bundleQuantity);
          const remainingUnits = newQuantity % bundleQuantity;
          const totalPrice = (bundleSets * bundleQuantity * bundleUnitPrice) + (remainingUnits * regularPrice);
          
          item.quantity = newQuantity;
          item.unitPrice = totalPrice / newQuantity; // Average unit price
          item.totalPrice = totalPrice;
        } else {
          item.quantity = newQuantity;
          item.unitPrice = regularPrice;
          item.totalPrice = newQuantity * regularPrice;
        }
      } else if (priceInfo.isBundle) {
        // For complete bundles, always use bundle price
        item.quantity = newQuantity;
        item.unitPrice = priceInfo.price;
        item.totalPrice = newQuantity * priceInfo.price;
      } else {
        // Regular product
        item.quantity = newQuantity;
        item.unitPrice = priceInfo.price;
        item.totalPrice = newQuantity * priceInfo.price;
      }

      // If there's a discount, reapply it
      if (item.discountPercentage) {
        item.totalPrice *= (1 - item.discountPercentage / 100);
      }
    } else if (field === 'discountPercentage') {
      const discountPercentage = Math.min(100, Math.max(0, Number(value)));
      item.discountPercentage = discountPercentage;
      // Recalculate total price with discount
      const originalTotal = item.quantity * item.unitPrice;
      item.totalPrice = originalTotal * (1 - discountPercentage / 100);
    }

    setFormData(prev => ({
      ...prev,
      items: updatedItems
    }));
  };

  const handlePageChange = (pageNumber) => {
    console.log('Changing to page:', pageNumber, 'from current page:', currentPage);
    // Validate page number
    if (pageNumber < 1 || pageNumber > totalPages) {
      console.log('Invalid page number:', pageNumber, 'total pages:', totalPages);
      return;
    }
    
    if (pageNumber === currentPage) {
      console.log('Already on page', pageNumber);
      return;
    }

    setCurrentPage(pageNumber);
  };

  const handleSort = (key) => {
    setSortConfig(prevConfig => {
      if (prevConfig.key === key) {
        // If clicking the same column, toggle direction
        return {
          key,
          direction: prevConfig.direction === 'asc' ? 'desc' : 'asc'
        }
      }
      // If clicking a new column, default to ascending
      return {
        key,
        direction: 'asc'
      }
    })
  }

  const getSortIcon = (columnKey) => {
    if (sortConfig.key !== columnKey) return '↕️'
    return sortConfig.direction === 'asc' ? '↑' : '↓'
  }

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
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full bg-white">
            <thead className="bg-gray-50">
              <tr>
                <th 
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                  onClick={() => handleSort('client')}
                >
                  Cliente {getSortIcon('client')}
                </th>
                <th 
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                  onClick={() => handleSort('delivery_address')}
                >
                  Dirección {getSortIcon('delivery_address')}
                </th>
                <th 
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                  onClick={() => handleSort('sale_date')}
                >
                  Fecha de Venta {getSortIcon('sale_date')}
                </th>
                <th 
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                  onClick={() => handleSort('delivery_date')}
                >
                  Fecha de Entrega {getSortIcon('delivery_date')}
                </th>
                <th 
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                  onClick={() => handleSort('total_amount')}
                >
                  Total {getSortIcon('total_amount')}
                </th>
                <th 
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                  onClick={() => handleSort('payment_status')}
                >
                  Estado de Pago {getSortIcon('payment_status')}
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Acciones
                </th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan="7" className="px-6 py-4 text-center">
                    <div className="flex justify-center items-center space-x-2">
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-gray-900"></div>
                      <span>Cargando...</span>
                    </div>
                  </td>
                </tr>
              ) : sales.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-6 py-4 text-center">
                    No se encontraron ventas
                  </td>
                </tr>
              ) : (
                sales.map((sale) => (
                  <tr key={sale.id} className="border-t">
                    <td className="px-6 py-4">{sale.client?.name}</td>
                    <td className="px-6 py-4">
                      {[
                        sale.delivery_address?.street_address,
                        sale.delivery_address?.boroughs?.name,
                        sale.delivery_address?.neighborhoods?.name
                      ].filter(Boolean).join(' - ')}
                    </td>
                    <td className="px-6 py-4">
                      {formatDate(sale.sale_date)}
                    </td>
                    <td className="px-6 py-4">
                      {formatDate(sale.delivery_date)}
                    </td>
                    <td className="px-6 py-4">
                      {formatCurrency(sale.total_amount)}
                    </td>
                    <td className="px-6 py-4">
                      <span className={`px-2 py-1 rounded text-sm ${
                        sale.payment_status === 'paid' 
                          ? 'bg-green-100 text-green-800'
                          : sale.payment_status === 'pending'
                          ? 'bg-yellow-100 text-yellow-800'
                          : 'bg-red-100 text-red-800'
                      }`}>
                        {sale.payment_status}
                      </span>
                    </td>
                    <td className="px-6 py-4 space-x-2">
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
                ))
              )}
            </tbody>
          </table>
        </div>
        
        {/* Pagination Controls */}
        {totalRecords > 0 && (
          <div className="flex justify-between items-center p-4 border-t">
            <div className="text-sm text-gray-600">
              Showing {(currentPage - 1) * rowsPerPage + 1} to {Math.min(currentPage * rowsPerPage, totalRecords)} of {totalRecords} records
            </div>
            <div className="flex items-center gap-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => handlePageChange(1)}
                disabled={currentPage === 1 || isLoading}
              >
                First
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => handlePageChange(currentPage - 1)}
                disabled={currentPage === 1 || isLoading}
              >
                Previous
              </Button>
              <span className="px-4 py-2 text-sm">
                Page {currentPage} of {totalPages}
              </span>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => handlePageChange(currentPage + 1)}
                disabled={currentPage === totalPages || isLoading}
              >
                Next
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => handlePageChange(totalPages)}
                disabled={currentPage === totalPages || isLoading}
              >
                Last
              </Button>
            </div>
          </div>
        )}
      </div>

      <SaleFormModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false)
          setEditingSale(null)
        }}
        onSubmit={handleSubmit}
        onSuccess={async () => {
          console.log('Sale saved successfully, initiating table refresh...');
          try {
            await fetchSales();
            console.log('Table refresh completed');
          } catch (error) {
            console.error('Error refreshing sales table:', error);
            // Force a refresh after a short delay as a fallback
            setTimeout(() => {
              console.log('Attempting fallback refresh...');
              fetchSales().catch(e => console.error('Fallback refresh failed:', e));
            }, 2000);
          }
        }}
        editingSale={editingSale}
        clients={clients}
        products={products}
        paymentMethods={paymentMethods}
      />
    </div>
  )
}

export default SalesManagement