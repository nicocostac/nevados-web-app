import { supabase } from '@/lib/supabaseClient';
import { NextApiRequest, NextApiResponse } from 'next';
import { createServerSupabaseClient } from '@supabase/auth-helpers-nextjs';
import { Bundle, BundleItem } from '@/types/models';
import { ApiError, handleError } from '@/types/error';

interface CreateBundleRequest {
  name: string;
  description: string;
  total_price: number;
  start_date: string;
  end_date?: string | null;
  items: Omit<BundleItem, 'product' | 'bundle_id' | 'created_at' | 'updated_at'>[];
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // Initialize supabase server client with the request cookies
  const supabaseServerClient = createServerSupabaseClient({
    req,
    res,
  });

  if (req.method === 'GET') {
    try {
      const { data: bundles, error } = await supabaseServerClient
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
        .order('created_at', { ascending: false });

      if (error) {
        throw error;
      }

      if (!bundles) {
        return res.status(404).json({ 
          error: {
            message: 'No bundles found',
            code: 'NOT_FOUND'
          } as ApiError 
        });
      }

      const completeBundles = bundles.map(bundle => ({
        ...bundle,
        items: bundle.items || []
      }));

      return res.status(200).json(completeBundles);
    } catch (error) {
      const apiError = handleError(error);
      console.error('GET bundles error:', apiError);
      return res.status(500).json({ error: apiError });
    }
  }

  if (req.method === 'POST') {
    try {
      const { name, description, total_price, start_date, end_date, items } = req.body as CreateBundleRequest;

      // Validate required fields
      if (!name || !total_price || !start_date || !items) {
        return res.status(400).json({ 
          error: {
            message: 'Missing required fields: name, total_price, start_date, items',
            code: 'INVALID_PARAMETER'
          } as ApiError 
        });
      }

      // Validate items array
      if (!Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ 
          error: {
            message: 'Bundle must have at least one item',
            code: 'INVALID_PARAMETER'
          } as ApiError 
        });
      }

      // Check if all items have required fields
      const hasInvalidItems = items.some(item => !item.product_id || !item.quantity);
      if (hasInvalidItems) {
        return res.status(400).json({ 
          error: {
            message: 'All items must have product_id and quantity',
            code: 'INVALID_PARAMETER'
          } as ApiError 
        });
      }

      // Get current session
      const { data: { session }, error: sessionError } = await supabaseServerClient.auth.getSession();
      if (sessionError) throw sessionError;
      if (!session) {
        return res.status(401).json({ error: 'Not authenticated' });
      }

      // Create the bundle
      const { data: bundle, error: bundleError } = await supabaseServerClient
        .from('mixed_bundles')
        .insert([{
          name,
          description,
          total_price,
          start_date,
          end_date,
          status: 'active',
          created_by: session.user.id,
          updated_by: session.user.id
        }])
        .select()
        .single();

      if (bundleError) {
        throw bundleError;
      }

      if (!bundle) {
        throw new Error('Failed to create bundle');
      }

      // Create bundle items
      const bundleItems = items.map(item => ({
        bundle_id: bundle.id,
        product_id: item.product_id,
        quantity: item.quantity
      }));

      const { error: itemsError } = await supabaseServerClient
        .from('mixed_bundle_items')
        .insert(bundleItems);

      if (itemsError) {
        // If items creation fails, delete the bundle
        await supabaseServerClient
          .from('mixed_bundles')
          .delete()
          .eq('id', bundle.id);
        throw itemsError;
      }

      // Fetch the complete bundle with items
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
        .eq('id', bundle.id)
        .single();

      if (fetchError) {
        throw fetchError;
      }

      return res.status(201).json(completeBundle);
    } catch (error) {
      const apiError = handleError(error);
      console.error('POST bundle error:', apiError);
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
