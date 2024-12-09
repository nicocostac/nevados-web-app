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

interface Product {
  id: string;
  name: string;
  description: string;
  unit_of_sale: string;
}

interface BundleItem {
  product_id: string;
  quantity: number;
  product: Product;
}

interface Bundle {
  id: string;
  name: string;
  description: string;
  total_price: number;
  status: string;
  items: BundleItem[];
}

function BundlesPage() {
  const [bundles, setBundles] = useState<Bundle[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [isOpen, setIsOpen] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [selectedBundle, setSelectedBundle] = useState(null);
  const [newBundle, setNewBundle] = useState({
    name: '',
    description: '',
    total_price: 0,
    items: [] as { product_id: string; quantity: number }[],
  });
  const { toast } = useToast();

  useEffect(() => {
    fetchBundles();
    fetchProducts();
  }, []);

  const fetchBundles = async () => {
    try {
      console.log('Fetching bundles...');
      // Fetch bundles with their items in a single query
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

      console.log('Fetched bundles:', bundles);
      if (error) {
        toast({
          title: 'Error',
          description: error.message,
          variant: 'destructive',
        });
        return;
      }

      // Ensure items is always an array
      const bundlesWithItems = bundles.map(bundle => ({
        ...bundle,
        items: bundle.items || []
      }));

      setBundles(bundlesWithItems);
    } catch (error) {
      console.error('Error fetching bundles:', error);
      toast({
        title: 'Error',
        description: error.message,
        variant: 'destructive',
      });
    }
  };

  const fetchProducts = async () => {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .order('name');

    if (error) {
      toast({
        title: 'Error',
        description: error.message,
        variant: 'destructive',
      });
      return;
    }

    setProducts(data);
  };

  const handleAddItem = () => {
    setNewBundle((prev) => ({
      ...prev,
      items: [...prev.items, { product_id: '', quantity: 1 }],
    }));
  };

  const handleItemChange = (index: number, field: string, value: string | number) => {
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

  const handleEdit = (bundle) => {
    setIsEditMode(true);
    setSelectedBundle(bundle);
    // Map the bundle items correctly
    setNewBundle({
      name: bundle.name,
      description: bundle.description,
      total_price: bundle.total_price,
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
      if (!newBundle.name || !newBundle.total_price) {
        toast({
          title: 'Validation Error',
          description: 'Name and total price are required',
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

        if (deleteError) {
          console.error('Error deleting items:', deleteError);
          throw new Error('Failed to delete existing items');
        }

        // Wait a moment to ensure deletion is complete
        await new Promise(resolve => setTimeout(resolve, 500));
      } else {
        // Create new bundle
        console.log('Creating new bundle:', bundleData);
        const { data: newBundleData, error: bundleError } = await supabase
          .from('mixed_bundles')
          .insert([bundleData]) // Ensure we're passing an array with a single item
          .select()
          .single();

        if (bundleError) {
          console.error('Error creating bundle:', bundleError);
          throw new Error('Failed to create bundle');
        }
        if (!newBundleData) throw new Error('Failed to create bundle - no data returned');
        
        bundleId = newBundleData.id;
        console.log('Created bundle with ID:', bundleId);
      }

      // 3. Insert new items if any exist
      const newItems = newBundle.items.map((item) => ({
        bundle_id: bundleId,
        product_id: item.product_id,
        quantity: item.quantity,
      }));
      
      console.log('Inserting bundle items:', newItems);
      const { error: itemsError } = await supabase
        .from('mixed_bundle_items')
        .insert(newItems);

      if (itemsError) {
        console.error('Error inserting items:', itemsError);
        // If items insertion fails and this is a new bundle, delete the bundle
        if (!isEditMode) {
          await supabase
            .from('mixed_bundles')
            .delete()
            .eq('id', bundleId);
        }
        throw new Error('Failed to insert bundle items');
      }

      toast({
        title: 'Success',
        description: `Bundle ${isEditMode ? 'updated' : 'created'} successfully!`,
      });

      // Reset everything
      setNewBundle({
        name: '',
        description: '',
        total_price: 0,
        items: [],
      });
      setSelectedBundle(null);
      setIsEditMode(false);
      setIsOpen(false);
      
      // Refresh the list
      await fetchBundles();
    } catch (error) {
      console.error('Error saving bundle:', error);
      toast({
        title: 'Error',
        description: error.message,
        variant: 'destructive',
      });
    }
  };

  const handleDeleteBundle = async (bundleId: string) => {
    if (!window.confirm('Are you sure you want to delete this bundle? This action cannot be undone.')) {
      return;
    }

    try {
      console.log('Deleting bundle items for bundle:', bundleId);
      // First delete all bundle items
      const { error: itemsError } = await supabase
        .from('mixed_bundle_items')
        .delete()
        .eq('bundle_id', bundleId);

      if (itemsError) {
        console.error('Error deleting bundle items:', itemsError);
        throw new Error('Failed to delete bundle items');
      }

      // Wait a moment to ensure items are deleted
      await new Promise(resolve => setTimeout(resolve, 500));

      console.log('Deleting bundle:', bundleId);
      // Then delete the bundle itself
      const { error: bundleError } = await supabase
        .from('mixed_bundles')
        .delete()
        .eq('id', bundleId);

      if (bundleError) {
        console.error('Error deleting bundle:', bundleError);
        throw new Error('Failed to delete bundle. Please check RLS policies.');
      }

      toast({
        title: 'Success',
        description: 'Bundle deleted successfully',
      });

      // Refresh the bundles list
      await fetchBundles();
    } catch (error) {
      console.error('Error deleting bundle:', error);
      toast({
        title: 'Error',
        description: error.message,
        variant: 'destructive',
      });
    }
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
