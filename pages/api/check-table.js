import { supabase } from '@/lib/supabaseClient'

export default async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    const { data, error } = await supabase
      .from('product_prices')
      .select('*')
      .limit(1)

    if (error) throw error

    return res.status(200).json({ 
      message: 'Table exists',
      columns: Object.keys(data[0] || {})
    })
  } catch (error) {
    console.error('Error:', error)
    return res.status(500).json({ error: error.message })
  }
}
