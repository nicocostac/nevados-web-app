import { createServerSupabaseClient } from '@supabase/auth-helpers-nextjs';
import { NextApiRequest, NextApiResponse } from 'next';

interface BundleItem {
  product_id: string;
  quantity: number;
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { id } = req.query;

  // Initialize supabase server client with the request cookies
  const supabaseServerClient = createServerSupabaseClient({
    req,
    res,
  });

  if (req.method === 'PUT') {
    try {
      const { name, description, total_price, items, status } = req.body;

      if (!name || !total_price) {
        return res.status(400).json({ error: 'Name and total price are required' });
      }

      // Get current session
      const { data: { session }, error: sessionError } = await supabaseServerClient.auth.getSession();
      if (sessionError) throw sessionError;
      if (!session) {
        return res.status(401).json({ error: 'Not authenticated' });
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
        console.error('Bundle update error:', bundleError);
        throw bundleError;
      }

      // Delete existing items
      const { error: deleteError } = await supabaseServerClient
        .from('mixed_bundle_items')
        .delete()
        .eq('bundle_id', id);

      if (deleteError) {
        console.error('Delete items error:', deleteError);
        throw deleteError;
      }

      // Insert new items if provided
      if (items && items.length > 0) {
        const bundleItems = items.map((item: BundleItem) => ({
          bundle_id: id,
          product_id: item.product_id,
          quantity: item.quantity
        }));

        const { error: itemsError } = await supabaseServerClient
          .from('mixed_bundle_items')
          .insert(bundleItems);

        if (itemsError) {
          console.error('Bundle items insert error:', itemsError);
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
        console.error('Fetch complete bundle error:', fetchError);
        throw fetchError;
      }

      return res.status(200).json(completeBundle);
    } catch (error: any) {
      console.error('PUT bundle error:', error);
      return res.status(500).json({ error: error.message || 'An unexpected error occurred' });
    }
  }

  if (req.method === 'DELETE') {
    try {
      // Get current session
      const { data: { session }, error: sessionError } = await supabaseServerClient.auth.getSession();
      if (sessionError) throw sessionError;
      if (!session) {
        return res.status(401).json({ error: 'Not authenticated' });
      }

      // Delete bundle items first due to foreign key constraint
      const { error: itemsError } = await supabaseServerClient
        .from('mixed_bundle_items')
        .delete()
        .eq('bundle_id', id);

      if (itemsError) {
        console.error('Delete items error:', itemsError);
        throw itemsError;
      }

      // Delete the bundle
      const { error: bundleError } = await supabaseServerClient
        .from('mixed_bundles')
        .delete()
        .eq('id', id);

      if (bundleError) {
        console.error('Delete bundle error:', bundleError);
        throw bundleError;
      }

      return res.status(200).json({ message: 'Bundle deleted successfully' });
    } catch (error: any) {
      console.error('DELETE bundle error:', error);
      return res.status(500).json({ error: error.message || 'An unexpected error occurred' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}
