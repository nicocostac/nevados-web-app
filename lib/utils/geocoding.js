/**
 * Geocodes an address using Google Maps Geocoding API
 * @param {Object} address - The address object containing street_address, borough, and neighborhood
 * @returns {Promise<{latitude: number, longitude: number} | null>}
 */
export async function geocodeAddress(address) {
  try {
    const { street_address, boroughs, neighborhoods } = address;
    
    // Construct full address string with Chile, handle optional neighborhood
    const addressParts = [
      street_address,
      neighborhoods?.name,
      boroughs?.name,
      'Santiago Metropolitan Region',
      'Chile'
    ].filter(Boolean); // Remove empty/null/undefined values
    
    const fullAddress = addressParts.join(', ');
    console.log('Geocoding address:', fullAddress);
    
    // Create the geocoding URL with region biasing for Chile
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(fullAddress)}&region=cl&components=country:CL&key=${process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY}`;
    
    const response = await fetch(url);
    const data = await response.json();
    
    console.log('Geocoding response status:', data.status);
    if (data.status === 'OK' && data.results[0]) {
      const { lat, lng } = data.results[0].geometry.location;
      // Verify the result is in Chile
      const isInChile = data.results[0].address_components.some(
        component => component.types.includes('country') && component.short_name === 'CL'
      );
      
      if (!isInChile) {
        console.log('Result was not in Chile, skipping');
        return null;
      }
      
      console.log('Found coordinates in Chile:', { lat, lng });
      return {
        latitude: lat,
        longitude: lng
      };
    }
    
    console.log('No coordinates found for address');
    return null;
  } catch (error) {
    console.error('Geocoding error:', error);
    return null;
  }
}

/**
 * Updates coordinates for addresses missing them
 * @param {Object} supabase - Supabase client instance
 * @returns {Promise<{updated: number, failed: number, total: number}>}
 */
export async function updateMissingCoordinates(supabase) {
  try {
    console.log('Starting coordinate update process...');
    // Get all addresses missing coordinates - use left join for neighborhoods
    const { data: addresses, error } = await supabase
      .from('client_addresses')
      .select(`
        id,
        street_address,
        boroughs(name),
        neighborhoods(name)
      `)
      .or('latitude.is.null,longitude.is.null');

    if (error) {
      console.error('Error fetching addresses:', error);
      throw error;
    }
    
    console.log(`Found ${addresses?.length || 0} addresses missing coordinates`);
    
    if (!addresses || addresses.length === 0) {
      return { updated: 0, failed: 0, total: 0 };
    }

    let updated = 0;
    let failed = 0;

    // Process addresses in batches to avoid rate limits
    for (const address of addresses) {
      try {
        console.log(`Processing address ID: ${address.id}`);
        const coordinates = await geocodeAddress(address);
        
        if (coordinates) {
          console.log(`Attempting to update address ${address.id} with coordinates:`, coordinates);
          
          // Try to update using upsert first
          const { error: updateError } = await supabase
            .from('client_addresses')
            .upsert({
              id: address.id,
              latitude: coordinates.latitude,
              longitude: coordinates.longitude,
              updated_at: new Date().toISOString()
            });

          if (updateError) {
            console.log(`Direct update failed, trying RPC method for address ${address.id}`);
            
            // Try RPC method if upsert fails
            const { error: rpcError } = await supabase.rpc(
              'update_address_coordinates',
              { 
                address_id: address.id,
                lat: coordinates.latitude,
                lng: coordinates.longitude
              }
            );

            if (rpcError) {
              console.error(`Both update methods failed for address ${address.id}:`, rpcError);
              failed++;
            } else {
              console.log(`Successfully updated coordinates using RPC for address ${address.id}`);
              updated++;
            }
          } else {
            console.log(`Successfully updated coordinates using direct update for address ${address.id}`);
            updated++;
          }
        } else {
          console.log(`No coordinates found for address ${address.id}`);
          failed++;
        }
      } catch (addressError) {
        console.error(`Error processing address ${address.id}:`, addressError);
        failed++;
      }
      
      // Add a small delay to avoid hitting rate limits
      await new Promise(resolve => setTimeout(resolve, 200));
    }

    const result = { updated, failed, total: addresses.length };
    console.log('Update process completed:', result);
    return result;
  } catch (error) {
    console.error('Error updating missing coordinates:', error);
    throw error;
  }
}
