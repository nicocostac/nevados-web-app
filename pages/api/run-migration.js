import { supabase } from '@/lib/supabaseClient'

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    // Add is_tj column
    await supabase.rpc('add_is_tj_column')

    return res.status(200).json({ message: 'Migration completed successfully' })
  } catch (error) {
    console.error('Migration error:', error)
    return res.status(500).json({ error: error.message })
  }
}
