import { createServerSupabaseClient } from '@supabase/auth-helpers-nextjs';
import { NextApiRequest, NextApiResponse } from 'next';
import { Bundle, BundleItem } from '@/types/models';
import { ApiError, handleError } from '@/types/error';

interface BundleItemInput {
  product_id: string;
  quantity: number;
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { id } = req.query;

  if (!id || typeof id !== 'string') {
    return res.status(400).json({ 
      error: {
        message: 'Invalid bundle ID',
        code: 'INVALID_PARAMETER'
      } as ApiError 
    });
  }

  // Initialize supabase server client with the request cookies
  const supabaseServerClient = createServerSupabaseClient({
    req,
    res,
  });

  if (req.method === 'PUT') {
    try {
      const { name, description, total_price, items, status } = req.body;

      if (!name || !total_price) {
        return res.status(400).json({ 
          error: {
            message: 'Name and total price are required',
            code: 'INVALID_PARAMETER'
          } as ApiError 
        });
      }

      // Get current session
      const { data: { session }, error: sessionError } = await supabaseServerClient.auth.getSession();
      if (sessionError) throw sessionError;
      if (!session) {
        return res.status(401).json({ 
          error: {
            message: 'Not authenticated',
            code: 'UNAUTHORIZED'
          } as ApiError 
        });
      }

      // Update the bundle
      const { data: bundle, error: bundleError } = await supabaseServerClient
        .from('mixed_bundles')
        .update({
          name,
          description: description || '',
          total_price,
          status,
          updated_by: session.user.id,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .select()
        .single();

      if (bundleError) {
        throw bundleError;
      }

      // Delete existing items
      const { error: deleteError } = await supabaseServerClient
        .from('mixed_bundle_items')
        .delete()
        .eq('bundle_id', id);

      if (deleteError) {
        throw deleteError;
      }

      // Insert new items if provided
      if (items && items.length > 0) {
        const bundleItems = items.map((item: BundleItemInput) => ({
          bundle_id: id,
          product_id: item.product_id,
          quantity: item.quantity
        }));

        const { error: itemsError } = await supabaseServerClient
          .from('mixed_bundle_items')
          .insert(bundleItems);

        if (itemsError) {
          throw itemsError;
        }
      }

      // Fetch the complete updated bundle with items
      const { data: completeBundle, error: fetchError } = await supabaseServerClient
        .from('mixed_bundles')
        .select(`
          *,
          items:mixed_bundle_items (
            *,
            product:products (
              id,
              name,
              description,
              unit_of_sale
            )
          )
        `)
        .eq('id', id)
        .single();

      if (fetchError) {
        throw fetchError;
      }

      const apiError = handleError(fetchError);
      console.error('GET bundle error:', apiError);
      return res.status(200).json(completeBundle);
    } catch (error: any) {
      const apiError = handleError(error);
      console.error('PUT bundle error:', apiError);
      return res.status(500).json({ error: apiError });
    }
  }

  if (req.method === 'DELETE') {
    try {
      // Get current session
      const { data: { session }, error: sessionError } = await supabaseServerClient.auth.getSession();
      if (sessionError) throw sessionError;
      if (!session) {
        return res.status(401).json({ 
          error: {
            message: 'Not authenticated',
            code: 'UNAUTHORIZED'
          } as ApiError 
        });
      }

      // Delete bundle items first due to foreign key constraint
      const { error: itemsError } = await supabaseServerClient
        .from('mixed_bundle_items')
        .delete()
        .eq('bundle_id', id);

      if (itemsError) {
        throw itemsError;
      }

      // Delete the bundle
      const { error: bundleError } = await supabaseServerClient
        .from('mixed_bundles')
        .delete()
        .eq('id', id);

      if (bundleError) {
        throw bundleError;
      }

      return res.status(200).json({ message: 'Bundle deleted successfully' });
    } catch (error: any) {
      const apiError = handleError(error);
      console.error('DELETE bundle error:', apiError);
      return res.status(500).json({ error: apiError });
    }
  }

  return res.status(405).json({ 
    error: {
      message: 'Method not allowed',
      code: 'METHOD_NOT_ALLOWED'
    } as ApiError 
  });
}
