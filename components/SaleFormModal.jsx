import { useState, useEffect, useRef } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert } from '@/components/ui/alert'
import { X, Plus, Minus, Search } from 'lucide-react'
import { supabase } from '@/lib/supabaseClient'
import { formatCurrency } from '@/lib/utils/format'

// Add this helper function at the top of the component, after the imports
const formatDate = (date) => {
  if (!date) return null;
  // Ensure we're working with a Date object
  const d = new Date(date);
  // Format as YYYY-MM-DD HH:mm:ss in UTC
  return d.toISOString();
};

const formatDateForInput = (date) => {
  if (!date) return '';
  const d = new Date(date);
  return d.toISOString().split('T')[0]; // Returns YYYY-MM-DD
};

const formatDateForDB = (date) => {
  if (!date) return null;
  const d = new Date(date);
  return d.toISOString(); // Returns full ISO string for DB
};

export default function SaleFormModal({ 
  isOpen, 
  onClose, 
  onSubmit, 
  onSuccess = () => {}, 
  editingSale = null,
  clients = [],
  products = [],
  paymentMethods = []
}) {
  const [error, setError] = useState('')
  const [formData, setFormData] = useState({
    clientId: '',
    deliveryAddressId: '',
    saleDate: formatDateForInput(new Date()),
    deliveryDate: formatDateForInput(new Date()),
    items: [],
    notes: '',
    paymentStatus: 'pending',
    paymentMethodId: '',
    paymentDate: '',
    paymentNotes: ''
  })
  const [clientSearch, setClientSearch] = useState('')
  const [filteredClients, setFilteredClients] = useState(clients)
  const [specialPrices, setSpecialPrices] = useState({})
  const [showClientDropdown, setShowClientDropdown] = useState(false)
  const [selectedClient, setSelectedClient] = useState(null)
  const [clientAddresses, setClientAddresses] = useState([])
  const [productPrices, setProductPrices] = useState({})
  const [bundleDiscount, setBundleDiscount] = useState(0);
  const dropdownRef = useRef(null)
  const [loading, setLoading] = useState(false)

  const calculateItemTotal = (quantity, priceInfo) => {
    if (!priceInfo) return 0;
    
    const qty = Math.max(1, Number(quantity));
    console.log('Calculating total for:', { qty, priceInfo });
    
    // Special prices (client) apply to all quantities
    if (priceInfo.price_type === 'client') {
      console.log('Using client price:', priceInfo.price);
      return qty * Number(priceInfo.price);
    }
    
    // Check quantity bundles
    if (priceInfo.quantity_bundles && priceInfo.quantity_bundles.length > 0) {
      // Sort bundles by quantity in descending order to get the best price
      const sortedBundles = [...priceInfo.quantity_bundles].sort((a, b) => 
        Number(b.bundle_quantity) - Number(a.bundle_quantity)
      );

      // Find the first bundle that applies
      const applicableBundle = sortedBundles.find(bundle => 
        qty >= Number(bundle.bundle_quantity)
      );
      
      if (applicableBundle) {
        console.log('Using quantity bundle price:', applicableBundle);
        // Calculate unit price from bundle (total bundle price / bundle quantity)
        const bundleQuantity = Number(applicableBundle.bundle_quantity);
        const unitPrice = Number(applicableBundle.price) / bundleQuantity;
        const total = qty * unitPrice;
        console.log('Bundle calculation:', { 
          bundlePrice: applicableBundle.price,
          bundleQuantity,
          unitPrice,
          qty,
          total
        });
        return total;
      }
    }
    
    // Regular price if no special pricing applies
    console.log('Using regular price:', priceInfo.price);
    return qty * Number(priceInfo.price);
  };

  const handleQuantityChange = (index, value) => {
    const newQuantity = Math.max(1, Number(value) || 1);
    console.log('Handling quantity change:', { index, newQuantity });

    setFormData(prev => {
      const newItems = [...prev.items];
      const item = newItems[index];
      const priceInfo = productPrices[item.productId];

      // Default to regular price
      let unitPrice = Number(priceInfo?.price) || 0;

      // Special prices (client) apply to all quantities
      if (priceInfo?.price_type === 'client') {
        unitPrice = Number(priceInfo.price);
        console.log('Using client special price:', unitPrice);
      }
      // Then check for bundle prices
      else if (priceInfo?.quantity_bundles && priceInfo.quantity_bundles.length > 0) {
        // Sort bundles by quantity in descending order
        const sortedBundles = [...priceInfo.quantity_bundles].sort((a, b) => 
          Number(b.bundle_quantity) - Number(a.bundle_quantity)
        );
        
        // Find the first (largest) bundle that applies
        const applicableBundle = sortedBundles.find(bundle => 
          newQuantity >= Number(bundle.bundle_quantity)
        );

        if (applicableBundle) {
          unitPrice = Number(applicableBundle.price) / Number(applicableBundle.bundle_quantity);
          console.log('Using bundle price:', { 
            bundlePrice: applicableBundle.price,
            bundleQuantity: applicableBundle.bundle_quantity,
            calculatedUnitPrice: unitPrice
          });
        }
      }

      const newTotal = unitPrice * newQuantity; // Calculate total based on unit price
      console.log('New total calculated:', { newQuantity, priceInfo, newTotal });

      newItems[index] = {
        ...item,
        quantity: newQuantity,
        unitPrice: unitPrice,
        totalPrice: newTotal,
        price_type: priceInfo ? priceInfo.price_type : null
      };

      console.log('Updated item:', newItems[index]);

      return {
        ...prev,
        items: newItems
      };
    });
  };

  const checkForCompleteBundles = (items) => {
    if (!items || items.length === 0) return 0;
    
    // Find all mixed bundle definitions
    const bundles = Object.values(productPrices).filter(
      price => price.price_type === 'bundle' && 
      price.bundle_products && 
      price.bundle_products.length > 0
    );
    
    console.log('Found mixed bundles:', bundles);
    
    let totalDiscount = 0;
    
    bundles.forEach(bundle => {
      if (!bundle.bundle_products) return;
      
      // Group items by product ID to handle multiple quantities
      const itemsByProduct = items.reduce((acc, item) => {
        acc[item.productId] = {
          quantity: (acc[item.productId]?.quantity || 0) + Number(item.quantity || 0),
          unitPrice: item.unitPrice || 0
        };
        return acc;
      }, {});
      
      // Check if we have all products in the bundle with sufficient quantities
      const bundleRequirements = bundle.bundle_products.reduce((acc, bp) => {
        acc[bp.product_id] = Number(bp.quantity || 1);
        return acc;
      }, {});
      
      // Calculate how many complete bundles we can make
      let bundleCount = Infinity;
      for (const [productId, requiredQty] of Object.entries(bundleRequirements)) {
        const availableQty = itemsByProduct[productId]?.quantity || 0;
        bundleCount = Math.min(bundleCount, Math.floor(availableQty / requiredQty));
      }
      
      if (bundleCount > 0 && bundleCount !== Infinity) {
        // Calculate current total for bundle items
        let bundleItemTotal = 0;
        for (const [productId, requiredQty] of Object.entries(bundleRequirements)) {
          const itemPrice = itemsByProduct[productId]?.unitPrice || 0;
          bundleItemTotal += itemPrice * requiredQty * bundleCount;
        }
        
        const bundleDiscount = Math.max(0, bundleItemTotal - (bundle.price * bundleCount));
        console.log('Mixed bundle discount calculation:', {
          bundleItemTotal,
          bundlePrice: bundle.price,
          bundleCount,
          bundleDiscount
        });
        totalDiscount += bundleDiscount;
      }
    });
    
    console.log('Total mixed bundle discount:', totalDiscount);
    return totalDiscount;
  };

  const getPriceLabel = (item, priceInfo) => {
    if (!priceInfo) return 'Regular';
    
    // Special prices (client) show first
    if (priceInfo.price_type === 'client') {
      return 'Client';
    }
    
    const qty = Math.max(1, Number(item.quantity));
    
    // Then show quantity bundle labels
    if (priceInfo.quantity_bundles && priceInfo.quantity_bundles.length > 0) {
      // Sort bundles by quantity in descending order
      const sortedBundles = [...priceInfo.quantity_bundles].sort((a, b) => 
        Number(b.bundle_quantity) - Number(a.bundle_quantity)
      );
      
      // Find the first bundle that applies
      const applicableBundle = sortedBundles.find(bundle => 
        qty >= Number(bundle.bundle_quantity)
      );
      
      if (applicableBundle) {
        return `Bundle ${applicableBundle.bundle_quantity}+`;
      }
    }
    
    return 'Regular';
  };

  const calculateTotal = () => {
    // Calculate the sum of all item totals
    const regularTotal = formData.items.reduce((sum, item) => {
      const itemTotal = Number(item.totalPrice) || 0;
      return sum + itemTotal;
    }, 0);
    
    // Apply any bundle discounts
    const finalDiscount = Number(bundleDiscount) || 0;
    const total = Math.max(0, regularTotal - finalDiscount);
    
    console.log('Total calculation:', { regularTotal, finalDiscount, total });
    return total;
  };

  useEffect(() => {
    // Recalculate bundle discounts whenever items change
    if (formData.items.length > 0) {
      const bundleDiscounts = checkForCompleteBundles(formData.items);
      console.log('Recalculating bundle discounts:', bundleDiscounts);
      setBundleDiscount(bundleDiscounts);
    }
  }, [formData.items, productPrices]);

  const updateItem = (index, field, value) => {
    setFormData(prev => {
      const newItems = [...prev.items];
      const item = { ...newItems[index] };
      
      if (field === 'productId') {
        const product = products.find(p => p.id === value);
        const priceInfo = productPrices[value];
        
        if (priceInfo) {
          item.productId = value;
          item.productName = product?.name || '';
          item.unitPrice = priceInfo.price;
          item.quantity = item.quantity || 1;
          
          // Check quantity bundles
          if (priceInfo.quantity_bundles && priceInfo.quantity_bundles.length > 0) {
            const qty = Math.max(1, Number(item.quantity));
            const sortedBundles = [...priceInfo.quantity_bundles].sort((a, b) => 
              Number(b.bundle_quantity) - Number(a.bundle_quantity)
            );
            
            const applicableBundle = sortedBundles.find(bundle => 
              qty >= Number(bundle.bundle_quantity)
            );
            
            if (applicableBundle) {
              item.unitPrice = applicableBundle.price / Number(applicableBundle.bundle_quantity);
            }
          }
          
          item.totalPrice = item.unitPrice * item.quantity;
          
          // Update the item
          newItems[index] = item;
          
          // Check for mixed bundle discounts
          checkForCompleteBundles(newItems);
        }
      } else if (field === 'quantity') {
        item.quantity = value;
        const priceInfo = productPrices[item.productId];
        if (priceInfo) {
          // Check quantity bundles
          if (priceInfo.quantity_bundles && priceInfo.quantity_bundles.length > 0) {
            const qty = Math.max(1, Number(value));
            const sortedBundles = [...priceInfo.quantity_bundles].sort((a, b) => 
              Number(b.bundle_quantity) - Number(a.bundle_quantity)
            );
            
            const applicableBundle = sortedBundles.find(bundle => 
              qty >= Number(bundle.bundle_quantity)
            );
            
            if (applicableBundle) {
              item.unitPrice = applicableBundle.price / Number(applicableBundle.bundle_quantity);
            } else {
              item.unitPrice = priceInfo.price;
            }
          }
          
          item.totalPrice = Number(value) * item.unitPrice;
          
          // Update the item
          newItems[index] = item;
          
          // Check for mixed bundle discounts
          checkForCompleteBundles(newItems);
        }
      }
      
      return { ...prev, items: newItems };
    });
  };

  useEffect(() => {
    console.log('Product Prices Updated:', productPrices);
    console.log('Form Items:', formData.items);
  }, [productPrices, formData.items]);

  useEffect(() => {
    if (editingSale) {
      const items = editingSale.sale_items.map(item => ({
        productId: item.product_id,
        quantity: item.quantity,
        unitPrice: item.unit_price,
        totalPrice: item.total_price,
        discountPercentage: item.discount_percentage
      }))

      // For editing, use the dates directly from the database
      setFormData({
        clientId: editingSale.client_id || '',
        saleDate: formatDateForInput(editingSale.sale_date),
        deliveryDate: formatDateForInput(editingSale.delivery_date),
        deliveryAddressId: editingSale.delivery_address_id,
        items: items || [],
        notes: editingSale.notes || '',
        paymentStatus: editingSale.payment_status || 'pending',
        paymentMethodId: editingSale.payment_method_id || '',
        paymentDate: editingSale.payment_date ? formatDateForInput(editingSale.payment_date) : '',
        paymentNotes: editingSale.payment_notes || ''
      })

      const client = clients.find(client => client.id === editingSale.client_id)
      setSelectedClient(client)
      setClientSearch(client?.name || '')
      if (client) {
        fetchClientAddresses(client.id)
        fetchSpecialPrices(client.id)
      }
    } else {
      // For new sales, reset everything
      const today = new Date()
      setFormData({
        clientId: '',
        deliveryAddressId: '',
        saleDate: formatDateForInput(today),
        deliveryDate: formatDateForInput(today),
        items: [],
        notes: '',
        paymentStatus: 'pending',
        paymentMethodId: '',
        paymentDate: '',
        paymentNotes: ''
      })
      setSelectedClient(null)
      setClientAddresses([])
      setSpecialPrices({})
      setBundleDiscount(0)
    }
  }, [editingSale, clients])

  // Filter clients based on search
  useEffect(() => {
    const filtered = clients.filter(client =>
      client.name.toLowerCase().includes(clientSearch.toLowerCase())
    )
    setFilteredClients(filtered)
  }, [clientSearch, clients])

  // Fetch special prices when client is selected
  useEffect(() => {
    if (formData.clientId) {
      fetchSpecialPrices(formData.clientId)
    }
  }, [formData.clientId])

  // Fetch product prices when client or sale date changes
  useEffect(() => {
    if (formData.saleDate && formData.clientId) {
      fetchProductPrices(formData.saleDate, formData.clientId)
    }
  }, [formData.saleDate, formData.clientId])

  // Add useEffect to fetch prices when component mounts with initial data
  useEffect(() => {
    if (formData.clientId && formData.saleDate) {
      console.log('Initial fetch of product prices');
      fetchProductPrices(formData.saleDate, formData.clientId);
    }
  }, []);

  const fetchSpecialPrices = async (clientId) => {
    if (!clientId) return;
    
    const currentDate = formatDateForDB(new Date());
    
    const { data, error } = await supabase
      .from('client_prices')
      .select('*')
      .eq('client_id', clientId)
      .lte('start_date', currentDate)
      .or(`end_date.is.null,end_date.gt.${currentDate}`);

    if (error) {
      console.error('Error fetching special prices:', error);
    } else {
      console.log('Fetched special prices:', data);
      const pricesMap = {};
      data.forEach(price => {
        pricesMap[price.product_id] = {
          price: price.final_price,
          isClientPrice: true,
          validFrom: price.start_date,
          validUntil: price.end_date
        };
      });
      setSpecialPrices(pricesMap);
    }
  };

  const fetchProductPrices = async (saleDate, clientId) => {
    if (!saleDate || !clientId) {
      console.log('Missing required data:', { saleDate, clientId });
      return;
    }
    
    const formattedDate = formatDateForDB(saleDate);
    console.log('Fetching prices for date:', formattedDate, 'client:', clientId);

    try {
      // Get prices for all products
      const allIds = [...new Set(products.map(p => p.id))];
      const pricePromises = allIds.map(id =>
        supabase
          .rpc('get_product_price_at_date', {
            product_id: id,
            target_date: formattedDate,
            client_id: clientId
          })
          .then(({ data, error }) => {
            console.log('Price data for product', id, ':', data, error);
            return { id, data, error };
          })
      );

      const priceResults = await Promise.all(pricePromises);
      console.log('All price results:', priceResults);

      const priceMap = {};
      for (const { id, data, error } of priceResults) {
        if (error) {
          console.error('Error fetching price for', id, ':', error);
          continue;
        }
        
        if (data && data[0]) {
          const priceInfo = data[0];
          console.log('Processing price info for', id, ':', priceInfo);
          
          priceMap[id] = {
            id,
            price: parseFloat(priceInfo.price || 0),
            price_type: priceInfo.price_type,
            bundle_id: priceInfo.bundle_id,
            bundle_quantity: priceInfo.bundle_quantity,
            bundle_products: priceInfo.bundle_products || [],
            quantity_bundles: priceInfo.quantity_bundles || []
          };
        }
      }

      console.log('Final price map:', priceMap);
      setProductPrices(priceMap);

      // Update existing items with new prices
      setFormData(prev => ({
        ...prev,
        items: prev.items.map(item => {
          const priceInfo = priceMap[item.productId];
          if (priceInfo) {
            return {
              ...item,
              unitPrice: priceInfo.price,
              totalPrice: calculateItemTotal(item.quantity, priceInfo)
            };
          }
          return item;
        })
      }));
    } catch (error) {
      console.error('Error fetching product prices:', error);
    }
  };

  const getRegularPrice = async (productId, date) => {
    const { data, error } = await supabase
      .from('product_prices')
      .select('price')
      .eq('product_id', productId)
      .lte('start_date', date)
      .or(`end_date.is.null,end_date.gt.${date}`)
      .order('start_date', { ascending: false })
      .limit(1);

    if (error) {
      console.error('Error fetching regular price:', error);
      return null;
    }

    return data?.[0] || null;
  };

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      // Validate required fields
      if (!formData.clientId || !formData.deliveryAddressId || !formData.saleDate || !formData.deliveryDate) {
        throw new Error('Please fill in all required fields')
      }

      if (formData.items.length === 0) {
        throw new Error('Please add at least one item to the sale')
      }

      const total = calculateTotal()
      console.log('Submitting sale with total:', total)

      // Format dates for database
      const saleDate = formatDateForDB(formData.saleDate)
      const deliveryDate = formatDateForDB(formData.deliveryDate)
      const paymentDate = formData.paymentDate ? formatDateForDB(formData.paymentDate) : null

      // Format items for database
      const items = formData.items.map(item => ({
        productId: item.productId,
        quantity: Number(item.quantity),
        unitPrice: Number(item.unitPrice || 0),
        totalPrice: Number(item.totalPrice || 0),
        discountPercentage: Number(item.discountPercentage || 0)
      }))

      let result;
      
      if (editingSale) {
        // Update existing sale
        const { data, error } = await supabase.rpc('update_sale_with_items', {
          p_sale_id: editingSale.id,
          p_client_id: formData.clientId,
          p_sale_date: saleDate,
          p_delivery_date: deliveryDate,
          p_delivery_address_id: formData.deliveryAddressId,
          p_total_amount: total,
          p_notes: formData.notes,
          p_items: items,
          p_payment_status: formData.paymentStatus,
          p_payment_method_id: formData.paymentMethodId || null,
          p_payment_date: paymentDate,
          p_payment_notes: formData.paymentNotes
        })

        if (error) throw error
        result = data
      } else {
        // Create new sale
        const { data, error } = await supabase.rpc('create_sale_with_items', {
          p_client_id: formData.clientId,
          p_sale_date: saleDate,
          p_delivery_date: deliveryDate,
          p_delivery_address_id: formData.deliveryAddressId,
          p_total_amount: total,
          p_notes: formData.notes,
          p_items: items,
          p_payment_status: formData.paymentStatus,
          p_payment_method_id: formData.paymentMethodId || null,
          p_payment_date: paymentDate,
          p_payment_notes: formData.paymentNotes
        })

        if (error) throw error
        result = data
      }

      onSuccess(result)
      onClose()
    } catch (error) {
      console.error('Error submitting sale:', error)
      setError(error.message)
    } finally {
      setLoading(false)
    }
  };

  const handleSaleDateChange = (newSaleDate) => {
    console.log('Sale date changed to:', newSaleDate);
    
    setFormData(prev => {
      // If delivery date is before the new sale date, update it to the sale date
      const currentDeliveryDate = prev.deliveryDate ? new Date(prev.deliveryDate) : null;
      const newSaleDateObj = new Date(newSaleDate);
      
      let updatedDeliveryDate = prev.deliveryDate;
      if (!currentDeliveryDate || currentDeliveryDate < newSaleDateObj) {
        updatedDeliveryDate = newSaleDate;
      }
      
      return { 
        ...prev, 
        saleDate: newSaleDate,
        deliveryDate: updatedDeliveryDate
      };
    });

    // Fetch prices for the new date
    if (formData.clientId) {
      fetchProductPrices(newSaleDate, formData.clientId);
    }
  };

  const handleDeliveryDateChange = (newDeliveryDate) => {
    const saleDate = new Date(formData.saleDate);
    const deliveryDate = new Date(newDeliveryDate);

    if (deliveryDate < saleDate) {
      setError('La fecha de entrega no puede ser anterior a la fecha de venta');
      return;
    }

    setFormData(prev => ({ 
      ...prev, 
      deliveryDate: newDeliveryDate
    }));
  };

  useEffect(() => {
    if (isOpen) {
      const today = formatDateForInput(new Date());
      if (editingSale) {
        // For editing, use the dates from the sale but ensure they're in the right format
        setFormData(prev => ({
          ...prev,
          clientId: editingSale.client_id,
          deliveryAddressId: editingSale.delivery_address_id,
          saleDate: formatDateForInput(editingSale.sale_date),
          deliveryDate: formatDateForInput(editingSale.delivery_date),
          notes: editingSale.notes || '',
          items: editingSale.sale_items?.map(item => ({
            productId: item.product_id,
            quantity: item.quantity,
            unitPrice: item.unit_price,
            totalPrice: item.total_price,
            discountPercentage: item.discount_percentage || 0
          })) || []
        }));
      } else {
        // For new sale, reset all state
        setFormData({
          clientId: '',
          deliveryAddressId: '',
          saleDate: today,
          deliveryDate: today,
          items: [],
          notes: '',
          paymentStatus: 'pending',
          paymentMethodId: '',
          paymentDate: '',
          paymentNotes: ''
        });
        setSelectedClient(null);
        setProductPrices({});
        setError('');
      }
    }
  }, [isOpen, editingSale]);

  const addItem = () => {
    setFormData(prev => ({
      ...prev,
      items: [...prev.items, { 
        productId: '', 
        quantity: 1,
        unitPrice: 0,
        totalPrice: 0,
        discountPercentage: 0
      }]
    }))
  }

  const removeItem = (index) => {
    setFormData(prev => ({
      ...prev,
      items: prev.items.filter((_, i) => i !== index)
    }))
  }

  const fetchClientAddresses = async (clientId) => {
    if (!clientId) return;
    
    console.log('Fetching addresses for client:', clientId);
    try {
      const { data, error } = await supabase
        .from('client_addresses')
        .select(`
          id,
          street_address,
          is_default,
          borough_id,
          neighborhood_id,
          boroughs (
            id,
            name
          ),
          neighborhoods (
            id,
            name
          )
        `)
        .eq('client_id', clientId)
        .order('is_default', { ascending: false });

      if (error) {
        console.error('Error fetching client addresses:', error);
        setClientAddresses([]);
        return;
      }

      console.log('Fetched addresses:', data);
      setClientAddresses(data || []);
      
      // Auto-select default address if available
      const defaultAddress = data?.find(addr => addr.is_default);
      if (defaultAddress) {
        console.log('Setting default address:', defaultAddress.id);
        setFormData(prev => ({
          ...prev,
          deliveryAddressId: defaultAddress.id
        }));
      }
    } catch (error) {
      console.error('Unexpected error fetching client addresses:', error);
      setClientAddresses([]);
    }
  };

  const handleClientSelect = async (client) => {
    console.log('Client selected:', client);
    setSelectedClient(client);
    setFormData(prev => ({ 
      ...prev, 
      clientId: client.id,
      deliveryAddressId: '' // Reset address ID before fetching new addresses
    }));
    setClientSearch(client.name);
    setShowClientDropdown(false);
    
    // First fetch addresses, then fetch prices
    await fetchClientAddresses(client.id);
    await fetchProductPrices(formData.saleDate, client.id);
  };

  useEffect(() => {
    function handleClickOutside(event) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setShowClientDropdown(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [])

  useEffect(() => {
    if (clientAddresses.length > 0) {
      const defaultAddress = clientAddresses.find(addr => addr.is_default)
      if (defaultAddress) {
        console.log('Setting default address:', defaultAddress.id);
        setFormData(prev => ({
          ...prev,
          deliveryAddressId: defaultAddress.id
        }));
      }
    }
  }, [clientAddresses])

  const renderPriceWithType = (item) => {
    const priceText = `$${item.unitPrice.toFixed(2)}`;
    
    switch (item.price_type) {
      case 'client':
        return <span className="text-blue-600 font-medium">{priceText} (Cliente)</span>;
      case 'bundle_unit':
        return (
          <span className="text-purple-600 font-medium">
            {priceText} (Bundle {item.bundleQuantity}+)
          </span>
        );
      case 'bundle':
        return <span className="text-green-600 font-medium">{priceText} (Bundle Mixto)</span>;
      default:
        return priceText;
    }
  };

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-4xl max-h-[90vh] overflow-y-auto relative">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">
            {editingSale ? 'Sale Details' : 'New Sale'}
          </h2>
          <button onClick={onClose}>
            <X className="h-5 w-5" />
          </button>
        </div>

        {error && (
          <Alert variant="destructive" className="mb-4">
            <div className="flex justify-between items-center">
              <span>{error}</span>
              {error.includes('no addresses') && (
                <Button
                  type="button"
                  size="sm"
                  onClick={() => {
                    window.location.href = `/clients?search=${encodeURIComponent(selectedClient.name)}&highlight=${selectedClient.id}`
                  }}
                  className="ml-4 whitespace-nowrap bg-white border-2 border-red-200 text-red-600 hover:bg-red-50 hover:border-red-300 transition-all duration-200 flex items-center gap-2"
                >
                  <svg
                    className="w-4 h-4"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                  Manage Client
                </Button>
              )}
            </div>
          </Alert>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Client Search */}
          <div className="mb-4 relative" ref={dropdownRef}>
            <label className="block mb-2">Client</label>
            <div className="relative">
              <Input
                type="text"
                value={clientSearch}
                onChange={(e) => {
                  if (!editingSale) { // Only allow changes if not editing
                    setClientSearch(e.target.value)
                    setShowClientDropdown(true)
                    if (!e.target.value) {
                      setSelectedClient(null)
                      setFormData(prev => ({ ...prev, clientId: '' }))
                    }
                  }
                }}
                onFocus={() => setShowClientDropdown(true)}
                placeholder="Search clients..."
                required
                className="pr-8"
                readOnly={!!editingSale} // Make read-only when editing
              />
              <Search className="absolute right-2 top-2.5 h-4 w-4 text-gray-500" />
            </div>
            {showClientDropdown && (
              <div className="absolute z-10 w-full mt-1 bg-white border rounded-md shadow-lg max-h-60 overflow-auto">
                {filteredClients.map(client => (
                  <div
                    key={client.id}
                    className="px-4 py-2 hover:bg-gray-100 cursor-pointer"
                    onClick={() => handleClientSelect(client)}
                  >
                    {client.name}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Delivery Address Selection */}
          {selectedClient && (
            <div className="mb-4">
              <label className="block mb-2">Delivery Address</label>
              <select
                value={formData.deliveryAddressId || ''}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  deliveryAddressId: e.target.value
                }))}
                className="w-full p-2 border rounded"
                required
              >
                <option value="">Select delivery address</option>
                {clientAddresses.map(address => {
                  // Build address parts, filtering out empty values
                  const addressParts = [
                    address.street_address,
                    address.neighborhoods?.name,
                    address.boroughs?.name
                  ].filter(Boolean);

                  return (
                    <option key={address.id} value={address.id}>
                      {addressParts.join(', ')}
                      {address.is_default ? ' (Default)' : ''}
                    </option>
                  );
                })}
              </select>
            </div>
          )}

          {/* Dates */}
          <div className="grid grid-cols-2 gap-4 mb-4">
            <div className="flex flex-col">
              <label className="block mb-2" htmlFor="saleDate">Fecha de Venta</label>
              <Input
                id="saleDate"
                type="date"
                value={formData.saleDate}
                onChange={(e) => handleSaleDateChange(e.target.value)}
                required
              />
            </div>

            <div className="flex flex-col">
              <label className="block mb-2" htmlFor="deliveryDate">Fecha de Entrega</label>
              <Input
                id="deliveryDate"
                type="date"
                value={formData.deliveryDate}
                min={formData.saleDate}
                onChange={(e) => handleDeliveryDateChange(e.target.value)}
                required
              />
            </div>
          </div>

          {/* Items */}
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h3 className="font-medium">Items</h3>
              <Button type="button" onClick={addItem}>
                <Plus className="h-4 w-4 mr-2" />
                Add Item
              </Button>
            </div>

            {formData.items.map((item, index) => (
              <div key={index} className="grid grid-cols-12 gap-4 items-end">
                <div className="col-span-5">
                  <select
                    value={item.productId || ''}
                    onChange={(e) => updateItem(index, 'productId', e.target.value)}
                    className="w-full p-2 border rounded"
                    required
                  >
                    <option value="">Select Product</option>
                    {products.map(product => (
                      <option key={product.id} value={product.id}>
                        {product.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="col-span-2">
                  <Input
                    type="number"
                    value={item.quantity || ''}
                    onChange={(e) => handleQuantityChange(index, parseFloat(e.target.value))}
                    placeholder="Qty"
                    required
                    min="1"
                    step="1"
                  />
                </div>

                <div className="col-span-2 relative mt-1">
                  <div className="text-xs text-gray-500 absolute -top-4 left-0">
                    {getPriceLabel(item, productPrices[item.productId])}
                  </div>
                  <Input
                    type="text"
                    value={formatCurrency(item.unitPrice)}
                    readOnly
                    placeholder="Price"
                    className={`bg-gray-50 ${
                      item.price_type === 'client' ? 'border-blue-500' : 
                      (item.price_type === 'bundle' || 
                       (item.price_type === 'bundle_unit' && item.quantity >= item.bundleQuantity)) 
                        ? 'border-green-500' : ''
                    }`}
                  />
                </div>

                <div className="col-span-2">
                  <div className="relative">
                    <label className="absolute -top-6 left-0 text-xs font-medium text-gray-500">
                      Total
                    </label>
                    <Input
                      type="text"
                      value={formatCurrency(item.totalPrice) || ''}
                      readOnly
                      placeholder="Total"
                      className={`bg-gray-50 ${
                        item.price_type === 'client' ? 'border-blue-500' : 
                        (item.price_type === 'bundle' || 
                         (item.price_type === 'bundle_unit' && item.quantity >= item.bundleQuantity)) 
                          ? 'border-green-500' : ''
                      }`}
                    />
                  </div>
                </div>

                <div className="col-span-1">
                  <Button 
                    type="button"
                    variant="ghost"
                    onClick={() => removeItem(index)}
                  >
                    <Minus className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            ))}

            {formData.items.length > 0 && (
              <div className="mt-6 space-y-2">
                <div className="flex justify-end text-lg font-semibold">
                  Subtotal: {formatCurrency(formData.items.reduce((sum, item) => sum + (item.totalPrice || 0), 0))}
                </div>
                {bundleDiscount > 0 && (
                  <div className="flex justify-end text-lg font-semibold text-green-600">
                    Bundle Discount: -{formatCurrency(bundleDiscount)}
                  </div>
                )}
                <div className="flex justify-end text-lg font-semibold">
                  Total: {formatCurrency(calculateTotal())}
                </div>
              </div>
            )}
          </div>

          {/* Notes */}
          <div>
            <label className="block mb-2">Notas</label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData(prev => ({ 
                ...prev, 
                notes: e.target.value 
              }))}
              className="w-full p-2 border rounded min-h-[100px]"
              placeholder="Agregar notas sobre esta venta..."
            />
          </div>

          {/* Payment Information */}
          <div className="space-y-4 border-t pt-4 mt-4">
            <h3 className="font-medium">Información de Pago</h3>
            
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block mb-2">Estado de Pago</label>
                <select
                  value={formData.paymentStatus}
                  onChange={(e) => setFormData(prev => ({ 
                    ...prev, 
                    paymentStatus: e.target.value,
                    paymentDate: e.target.value === 'paid' ? new Date().toISOString().split('T')[0] : ''
                  }))}
                  className="w-full p-2 border rounded"
                >
                  <option value="pending">Pendiente</option>
                  <option value="paid">Pagado</option>
                  <option value="cancelled">Cancelado</option>
                </select>
              </div>

              {formData.paymentStatus === 'paid' && (
                <div>
                  <label className="block mb-2">Método de Pago</label>
                  <select
                    value={formData.paymentMethodId}
                    onChange={(e) => setFormData(prev => ({ 
                      ...prev, 
                      paymentMethodId: e.target.value 
                    }))}
                    className="w-full p-2 border rounded"
                    required
                  >
                    <option value="">Seleccione el Método de Pago</option>
                    {paymentMethods.map(method => (
                      <option key={method.id} value={method.id}>
                        {method.name}
                      </option>
                    ))}
                  </select>
                </div>
              )}
            </div>

            {formData.paymentStatus === 'paid' && (
              <>
                <div>
                  <label className="block mb-2">Fecha de Pago</label>
                  <Input
                    type="date"
                    value={formData.paymentDate}
                    onChange={(e) => setFormData(prev => ({ 
                      ...prev, 
                      paymentDate: e.target.value 
                    }))}
                    required
                  />
                </div>

                <div>
                  <label className="block mb-2">Notas de Pago</label>
                  <textarea
                    value={formData.paymentNotes}
                    onChange={(e) => setFormData(prev => ({ 
                      ...prev, 
                      paymentNotes: e.target.value 
                    }))}
                    className="w-full p-2 border rounded"
                    placeholder="Agregar notas sobre el pago..."
                  />
                </div>
              </>
            )}
          </div>

          <div className="flex justify-end gap-4">
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" disabled={loading}>
              {editingSale ? 'Actualizar Venta' : 'Crear Venta'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
} 