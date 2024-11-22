import { supabase } from '@/lib/supabaseClient';

export default async function handler(req, res) {
  try {
    // Get all client addresses with their order counts
    const { data, error } = await supabase
      .from('client_addresses')
      .select(`
        id,
        latitude,
        longitude,
        street_address,
        contact_person,
        boroughs (
          name
        ),
        neighborhoods (
          name
        ),
        client:clients (
          name,
          sales (count)
        )
      `);

    if (error) throw error;

    // Format data for the heatmap
    const heatmapData = data
      .filter(address => address.latitude && address.longitude && address.client) // Only include addresses with coordinates and client data
      .map(address => {
        // Build the full address string, handling optional neighborhood
        const addressParts = [
          address.street_address,
          address.neighborhoods?.name,
          address.boroughs?.name
        ].filter(Boolean); // Remove empty/null/undefined values

        return {
          lat: address.latitude,
          lng: address.longitude,
          intensity: address.client.sales?.[0]?.count || 1, // Use order count as intensity
          name: address.client.name,
          address: {
            street: address.street_address,
            borough: address.boroughs?.name,
            neighborhood: address.neighborhoods?.name,
            contact: address.contact_person,
            full: addressParts.join(', ')
          }
        };
      });

    res.status(200).json(heatmapData);
  } catch (error) {
    console.error('Heatmap data error:', error);
    res.status(500).json({ error: error.message });
  }
}
