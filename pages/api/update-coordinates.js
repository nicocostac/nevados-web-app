import { supabase } from '@/lib/supabaseClient'
import { updateMissingCoordinates } from '@/lib/utils/geocoding'

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    console.log('Starting coordinate update process...')
    const result = await updateMissingCoordinates(supabase)
    console.log('Coordinate update process completed:', result)
    res.status(200).json({ message: 'Coordinates update process completed', result })
  } catch (error) {
    console.error('Error in update-coordinates:', error)
    res.status(500).json({ error: error.message })
  }
}
