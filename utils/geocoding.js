export async function geocodeAddress(address) {
  const API_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY;
  
  try {
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${API_KEY}`;
    const response = await fetch(url);
    const data = await response.json();

    if (data.status === 'OK' && data.results.length > 0) {
      const { lat, lng } = data.results[0].geometry.location;
      return { lat, lng };
    }
    
    throw new Error('No results found');
  } catch (error) {
    console.error('Geocoding error:', error);
    throw error;
  }
}

export async function updateClientCoordinates(client) {
  try {
    const { lat, lng } = await geocodeAddress(client.address);
    
    const { error } = await supabase
      .from('clients')
      .update({ lat, lng })
      .eq('id', client.id);

    if (error) throw error;
    
    return { lat, lng };
  } catch (error) {
    console.error('Update coordinates error:', error);
    throw error;
  }
}
