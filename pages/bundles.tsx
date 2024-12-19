'use client';

import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { useToast } from '@/components/ui/use-toast';
import { supabase } from '@/lib/supabaseClient';
import { requireAuth } from '@/lib/auth/requireAuth';
import { X } from 'lucide-react';
import { Bundle, BundleItem, Product } from '@/types/models';
import { handleError } from '@/types/error';

interface NewBundle {
  name: string;
  description: string;
  total_price: number;
  start_date: string;
  end_date: string | null;
  items: Omit<BundleItem, 'product' | 'bundle_id' | 'created_at' | 'updated_at'>[];
}

function BundlesPage() {
  const [bundles, setBundles] = useState<Bundle[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [isOpen, setIsOpen] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [selectedBundle, setSelectedBundle] = useState<Bundle | null>(null);
  const [newBundle, setNewBundle] = useState<NewBundle>({
    name: '',
    description: '',
    total_price: 0,
    start_date: new Date().toISOString().split('T')[0],
    end_date: null,
    items: [],
  });
  const { toast } = useToast();

  useEffect(() => {
    fetchBundles();
    fetchProducts();
  }, []);

  const fetchBundles = async () => {
    try {
      console.log('Fetching bundles...');
      const { data: bundles, error } = await supabase
        .from('mixed_bundles')
        .select(`
          *,
          items:mixed_bundle_items (
            *,
            product:products (*)
          )
        `)
        .order('created_at', { ascending: false });

      if (error) {
        throw error;
      }

      if (!bundles) {
        console.error('No bundles data returned');
        return;
      }

      // Ensure items is always an array
      const bundlesWithItems = bundles.map(bundle => ({
        ...bundle,
        items: bundle.items || []
      }));

      setBundles(bundlesWithItems);
    } catch (error) {
      const apiError = handleError(error);
      console.error('Error fetching bundles:', apiError);
      toast({
        title: 'Error',
        description: apiError.message,
        variant: 'destructive',
      });
    }
  };

  const fetchProducts = async () => {
    try {
      const { data, error } = await supabase
        .from('products')
        .select('*')
        .order('name');

      if (error) {
        throw error;
      }

      if (!data) {
        console.error('No products data returned');
        return;
      }

      setProducts(data);
    } catch (error) {
      const apiError = handleError(error);
      console.error('Error fetching products:', apiError);
      toast({
        title: 'Error',
        description: apiError.message,
        variant: 'destructive',
      });
    }
  };

  const handleAddItem = () => {
    setNewBundle((prev) => ({
      ...prev,
      items: [...prev.items, { product_id: '', quantity: 1 }],
    }));
  };

  const handleItemChange = (index: number, field: keyof Pick<BundleItem, 'product_id' | 'quantity'>, value: string | number) => {
    const updatedItems = [...newBundle.items];
    // Ensure quantity is at least 1
    if (field === 'quantity' && typeof value === 'number' && value < 1) {
      value = 1;
    }
    updatedItems[index] = {
      ...updatedItems[index],
      [field]: value,
    };
    setNewBundle((prev) => ({ ...prev, items: updatedItems }));
  };

  const handleRemoveItem = (index: number) => {
    if (!window.confirm('Are you sure you want to remove this item?')) {
      return;
    }
    setNewBundle((prev) => ({
      ...prev,
      items: prev.items.filter((_, i) => i !== index)
    }));
  };

  const handleEdit = (bundle: Bundle) => {
    setIsEditMode(true);
    setSelectedBundle(bundle);
    setNewBundle({
      name: bundle.name,
      description: bundle.description,
      total_price: bundle.total_price,
      start_date: formatDateFromDB(bundle.start_date),
      end_date: bundle.end_date ? formatDateFromDB(bundle.end_date) : null,
      items: bundle.items.map(item => ({
        product_id: item.product.id,
        quantity: item.quantity
      }))
    });
    setIsOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      // Validate required fields
      if (!newBundle.name || !newBundle.total_price || !newBundle.start_date) {
        toast({
          title: 'Validation Error',
          description: 'Name, total price, and start date are required',
          variant: 'destructive',
        });
        return;
      }

      // Validate items
      if (!newBundle.items.length) {
        toast({
          title: 'Validation Error',
          description: 'Bundle must have at least one item',
          variant: 'destructive',
        });
        return;
      }

      if (newBundle.items.some(item => !item.product_id || !item.quantity)) {
        toast({
          title: 'Validation Error',
          description: 'All items must have a product and quantity',
          variant: 'destructive',
        });
        return;
      }

      const bundleData = {
        name: newBundle.name,
        description: newBundle.description,
        total_price: newBundle.total_price,
        start_date: formatDateForDB(newBundle.start_date),
        end_date: newBundle.end_date ? formatDateForDB(newBundle.end_date) : null,
        status: 'active',
      };

      let bundleId: string;

      if (isEditMode && selectedBundle) {
        bundleId = selectedBundle.id;
        console.log('Updating bundle:', bundleId, bundleData);
        
        // 1. Update bundle details
        const { error: bundleError } = await supabase
          .from('mixed_bundles')
          .update(bundleData)
          .eq('id', bundleId);

        if (bundleError) throw bundleError;

        // 2. Delete all existing items
        console.log('Deleting existing items for bundle:', bundleId);
        const { error: deleteError } = await supabase
          .from('mixed_bundle_items')
          .delete()
          .eq('bundle_id', bundleId);

        if (deleteError) throw deleteError;

        // Wait a moment to ensure deletion is complete
        await new Promise(resolve => setTimeout(resolve, 500));
      } else {
        // Create new bundle
        console.log('Creating new bundle:', bundleData);
        const { data: newBundleData, error: bundleError } = await supabase
          .from('mixed_bundles')
          .insert([bundleData])
          .select()
          .single();

        if (bundleError) throw bundleError;
        if (!newBundleData) throw new Error('Failed to create bundle - no data returned');
        
        bundleId = newBundleData.id;
        console.log('Created bundle with ID:', bundleId);
      }

      // 3. Insert new items
      const bundleItems = newBundle.items.map(item => ({
        bundle_id: bundleId,
        product_id: item.product_id,
        quantity: item.quantity,
      }));
      
      console.log('Inserting bundle items:', bundleItems);
      const { error: itemsError } = await supabase
        .from('mixed_bundle_items')
        .insert(bundleItems);

      if (itemsError) throw itemsError;

      toast({
        title: 'Success',
        description: `Bundle ${isEditMode ? 'updated' : 'created'} successfully!`,
      });

      // Reset form
      setNewBundle({
        name: '',
        description: '',
        total_price: 0,
        start_date: new Date().toISOString().split('T')[0],
        end_date: null,
        items: [],
      });
      setSelectedBundle(null);
      setIsEditMode(false);
      setIsOpen(false);
      
      // Refresh the list
      await fetchBundles();
    } catch (error) {
      const apiError = handleError(error);
      console.error('Error saving bundle:', apiError);
      toast({
        title: 'Error',
        description: apiError.message,
        variant: 'destructive',
      });
    }
  };

  const handleDeleteBundle = async (bundleId: string) => {
    if (!window.confirm('Are you sure you want to delete this bundle? This action cannot be undone.')) {
      return;
    }

    try {
      // First delete all bundle items
      const { error: itemsError } = await supabase
        .from('mixed_bundle_items')
        .delete()
        .eq('bundle_id', bundleId);

      if (itemsError) throw itemsError;

      // Then delete the bundle itself
      const { error: bundleError } = await supabase
        .from('mixed_bundles')
        .delete()
        .eq('id', bundleId);

      if (bundleError) throw bundleError;

      toast({
        title: 'Success',
        description: 'Bundle deleted successfully',
      });

      // Refresh the bundles list
      await fetchBundles();
    } catch (error) {
      const apiError = handleError(error);
      console.error('Error deleting bundle:', apiError);
      toast({
        title: 'Error',
        description: apiError.message,
        variant: 'destructive',
      });
    }
  };

  const formatDateForDB = (date: string) => {
    // Add time to make it noon UTC to avoid timezone issues
    return `${date}T12:00:00Z`;
  };

  const formatDateFromDB = (dateStr: string) => {
    // Parse the date and return only the date part
    return dateStr.split('T')[0];
  };

  const formatDisplayDate = (dateStr: string) => {
    // Format date for display in table
    const date = new Date(dateStr);
    return date.toLocaleDateString('es-CL', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      timeZone: 'UTC'
    });
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('es-CL', {
      style: 'currency',
      currency: 'CLP',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  return (
    <div className="container mx-auto py-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Product Bundles</h1>
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
          <DialogTrigger asChild>
            <Button>Create New Bundle</Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>{isEditMode ? 'Edit Bundle' : 'Create New Bundle'}</DialogTitle>
              <DialogDescription>
                {isEditMode ? 'Edit the bundle by updating its details and items.' : 'Create a new bundle by adding products and their quantities.'}
              </DialogDescription>
            </DialogHeader>
            <form onSubmit={handleSubmit}>
              <div className="grid gap-4 py-4">
                <div className="grid gap-2">
                  <Label htmlFor="name">Name</Label>
                  <Input
                    id="name"
                    value={newBundle.name}
                    onChange={(e) =>
                      setNewBundle((prev) => ({ ...prev, name: e.target.value }))
                    }
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="description">Description</Label>
                  <Input
                    id="description"
                    value={newBundle.description}
                    onChange={(e) =>
                      setNewBundle((prev) => ({ ...prev, description: e.target.value }))
                    }
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="total_price">Total Price</Label>
                  <Input
                    id="total_price"
                    type="number"
                    value={newBundle.total_price}
                    onChange={(e) =>
                      setNewBundle((prev) => ({ ...prev, total_price: parseFloat(e.target.value) }))
                    }
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="start_date">Start Date</Label>
                  <Input
                    id="start_date"
                    type="date"
                    value={newBundle.start_date}
                    onChange={(e) =>
                      setNewBundle((prev) => ({ ...prev, start_date: e.target.value }))
                    }
                    required
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="end_date">End Date (Optional)</Label>
                  <Input
                    id="end_date"
                    type="date"
                    value={newBundle.end_date || ''}
                    onChange={(e) =>
                      setNewBundle((prev) => ({ ...prev, end_date: e.target.value || null }))
                    }
                  />
                </div>
                <div className="grid gap-2">
                  <div className="flex justify-between items-center">
                    <Label>Items</Label>
                    <Button onClick={handleAddItem} variant="outline" size="sm">
                      Add Item
                    </Button>
                  </div>
                  {newBundle.items.map((item, index) => (
                    <div key={`${selectedBundle?.id}-${item.product_id}-${index}`} className="flex gap-2">
                      <select
                        className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
                        value={item.product_id}
                        onChange={(e) => handleItemChange(index, 'product_id', e.target.value)}
                      >
                        <option value="">Select a product</option>
                        {products.map((product) => (
                          <option key={product.id} value={product.id}>
                            {product.name}
                          </option>
                        ))}
                      </select>
                      <Input
                        type="number"
                        min="1"
                        value={item.quantity}
                        onChange={(e) => handleItemChange(index, 'quantity', parseInt(e.target.value) || 1)}
                        className="w-24"
                      />
                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => handleRemoveItem(index)}
                      >
                        Delete
                      </Button>
                    </div>
                  ))}
                </div>
              </div>
              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => setIsOpen(false)}>
                  Cancel
                </Button>
                <Button type="submit">{isEditMode ? 'Update' : 'Create'} Bundle</Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Description</TableHead>
              <TableHead>Total Price</TableHead>
              <TableHead>Date Range</TableHead>
              <TableHead>Items</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {bundles.map((bundle) => (
              <TableRow key={bundle.id}>
                <TableCell>{bundle.name}</TableCell>
                <TableCell>{bundle.description}</TableCell>
                <TableCell>{formatCurrency(bundle.total_price)}</TableCell>
                <TableCell>
                  {formatDisplayDate(bundle.start_date)}
                  {bundle.end_date && ` - ${formatDisplayDate(bundle.end_date)}`}
                </TableCell>
                <TableCell>
                  <ul className="list-disc list-inside">
                    {bundle.items?.map((item, index) => (
                      <li key={`${bundle.id}-${item.product_id}-${index}`}>
                        {item.product?.name} ({item.quantity})
                      </li>
                    ))}
                  </ul>
                </TableCell>
                <TableCell>
                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleEdit(bundle)}
                    >
                      Edit
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      onClick={() => handleDeleteBundle(bundle.id)}
                    >
                      Delete
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}

export default requireAuth(BundlesPage);
