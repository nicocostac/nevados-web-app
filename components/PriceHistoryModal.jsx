import { useState } from 'react'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog"
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { formatCurrency } from '@/lib/utils/format'
import { Edit2, Trash2 } from 'lucide-react'

export default function PriceHistoryModal({ isOpen, onClose, product, onSave, onSubmit, setError, supabase }) {
  const [prices, setPrices] = useState(
    [...(product.product_prices || [])]
      .sort((a, b) => new Date(b.start_date) - new Date(a.start_date))
  )

  const handlePriceChange = (index, field, value) => {
    const newPrices = [...prices]
    newPrices[index] = {
      ...newPrices[index],
      [field]: value
    }
    setPrices(newPrices)
  }

  const handleDeletePrice = async (priceId) => {
    if (!window.confirm('Are you sure you want to delete this price?')) {
      return;
    }

    try {
      // Find the price we're deleting and the current price
      const priceToDelete = prices.find(p => p.id === priceId);
      const currentPrice = prices.find(p => isCurrentPrice(p));

      // Delete the future price
      const { error: deleteError } = await supabase
        .from('product_prices')
        .delete()
        .eq('id', priceId);

      if (deleteError) throw deleteError;

      // If we deleted a future price and there's a current price with an end date
      if (priceToDelete && isFuturePrice(priceToDelete) && currentPrice && currentPrice.end_date) {
        // Remove the end date from the current price
        const { error: updateError } = await supabase
          .from('product_prices')
          .update({ 
            end_date: null,
            updated_at: new Date().toISOString()
          })
          .eq('id', currentPrice.id);

        if (updateError) throw updateError;
      }

      // Update local state
      setPrices(prevPrices => {
        const newPrices = prevPrices.filter(p => p.id !== priceId);
        // Also update the current price's end date in local state
        if (currentPrice) {
          const currentPriceIndex = newPrices.findIndex(p => p.id === currentPrice.id);
          if (currentPriceIndex !== -1) {
            newPrices[currentPriceIndex] = {
              ...newPrices[currentPriceIndex],
              end_date: null
            };
          }
        }
        return newPrices;
      });
      
      // Refresh the product data
      await onSubmit();
    } catch (error) {
      console.error('Error deleting price:', error);
      setError(error.message);
    }
  };

  const handleSave = () => {
    // Sort prices by start date for validation
    const sortedPrices = [...prices].sort((a, b) => 
      new Date(a.start_date) - new Date(b.start_date)
    );

    // Validate dates are in sequence
    for (let i = 0; i < sortedPrices.length - 1; i++) {
      const currentPrice = sortedPrices[i];
      const nextPrice = sortedPrices[i + 1];
      
      if (!currentPrice.start_date || !nextPrice.start_date) {
        alert('All prices must have a start date');
        return;
      }

      const currentStart = new Date(currentPrice.start_date);
      const currentEnd = currentPrice.end_date ? new Date(currentPrice.end_date) : null;
      const nextStart = new Date(nextPrice.start_date);

      // If current price has an end date, it must be before the next start date
      if (currentEnd && currentEnd >= nextStart) {
        alert('Price dates must not overlap. Please check the dates.');
        return;
      }

      // If current price has no end date but next price starts in the past,
      // that would create an overlap
      if (!currentEnd && currentStart >= nextStart) {
        alert('Price dates must be in chronological order.');
        return;
      }
    }

    onSave(sortedPrices);
  };

  // Helper to check if a price is current
  const isCurrentPrice = (price) => {
    const now = new Date();
    const startDate = new Date(price.start_date);
    const endDate = price.end_date ? new Date(price.end_date) : null;
    return startDate <= now && (!endDate || endDate >= now);
  }

  // Helper to check if a price is future
  const isFuturePrice = (price) => {
    const now = new Date();
    const startDate = new Date(price.start_date);
    return startDate > now;
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>Price History for {product.name}</DialogTitle>
          <DialogDescription>
            View and edit historical prices for this product. The most recent price with no end date is the current active price.
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4 max-h-[60vh] overflow-y-auto">
          {prices.map((price, index) => (
            <div key={price.id} className="border p-4 rounded-lg">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <div className="font-medium text-lg">{formatCurrency(price.price)}</div>
                  <div className="text-sm text-gray-500">
                    From: {price.start_date?.split('T')[0]}
                    {price.end_date && ` To: ${price.end_date?.split('T')[0]}`}
                  </div>
                  {isCurrentPrice(price) && (
                    <div className="text-green-600 text-sm mt-1">
                      This is the current active price
                    </div>
                  )}
                  {isFuturePrice(price) && (
                    <div className="text-blue-600 text-sm mt-1">
                      This price will be active in the future
                    </div>
                  )}
                </div>
                <div className="flex items-center gap-2">
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => handlePriceChange(index, 'price', price.price)} // This is a placeholder, you should replace it with the actual edit functionality
                    className="h-8 w-8 p-0 hover:bg-gray-100"
                  >
                    <Edit2 className="h-4 w-4" />
                    <span className="sr-only">Edit price</span>
                  </Button>
                  {isFuturePrice(price) && (
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleDeletePrice(price.id)}
                      className="h-8 w-8 p-0 hover:bg-red-50 hover:text-red-600"
                    >
                      <Trash2 className="h-4 w-4" />
                      <span className="sr-only">Delete price</span>
                    </Button>
                  )}
                </div>
              </div>
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Price
                  </label>
                  <Input
                    type="number"
                    value={price.price}
                    onChange={(e) => handlePriceChange(index, 'price', parseInt(e.target.value))}
                    className="mt-1"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Start Date
                  </label>
                  <Input
                    type="date"
                    value={price.start_date?.split('T')[0]}
                    onChange={(e) => handlePriceChange(index, 'start_date', e.target.value)}
                    className="mt-1"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    End Date
                  </label>
                  <Input
                    type="date"
                    value={price.end_date?.split('T')[0] || ''}
                    onChange={(e) => handlePriceChange(index, 'end_date', e.target.value || null)}
                    className="mt-1"
                    disabled={index === 0 && !price.end_date} // Can't edit end date of current price
                  />
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-6 flex justify-end gap-2">
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleSave}>
            Save Changes
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
