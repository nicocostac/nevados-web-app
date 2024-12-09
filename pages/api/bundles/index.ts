import { supabase } from '@/lib/supabaseClient';
import { NextApiRequest, NextApiResponse } from 'next';
import { createServerSupabaseClient } from '@supabase/auth-helpers-nextjs';

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

      if (error) throw error;
      return res.status(200).json(bundles);
    } catch (error) {
      console.error('GET bundles error:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  if (req.method === 'POST') {
    try {
      const { name, description, total_price, items } = req.body;

      if (!name || !total_price) {
        return res.status(400).json({ error: 'Name and total price are required' });
      }

      // Get current session
      const { data: { session }, error: sessionError } = await supabaseServerClient.auth.getSession();
      if (sessionError) throw sessionError;
      if (!session) {
        return res.status(401).json({ error: 'Not authenticated' });
      }

      // Insert the bundle
      const { data: bundle, error: bundleError } = await supabaseServerClient
        .from('mixed_bundles')
        .insert({
          name,
          description: description || '',
          total_price,
          status: 'active',
          created_by: session.user.id,
          updated_by: session.user.id
        })
        .select()
        .single();

      if (bundleError) {
        console.error('Bundle insert error:', bundleError);
        throw bundleError;
      }

      // Insert bundle items if provided
      if (items && items.length > 0) {
        const bundleItems = items.map(item => ({
          bundle_id: bundle.id,
          product_id: item.product_id,
          quantity: item.quantity
        }));

        const { error: itemsError } = await supabaseServerClient
          .from('mixed_bundle_items')
          .insert(bundleItems);

        if (itemsError) {
          console.error('Bundle items insert error:', itemsError);
          // If adding items fails, delete the bundle
          await supabaseServerClient.from('mixed_bundles').delete().eq('id', bundle.id);
          throw itemsError;
        }
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
        console.error('Fetch complete bundle error:', fetchError);
        throw fetchError;
      }

      return res.status(200).json(completeBundle);
    } catch (error) {
      console.error('POST bundle error:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}
