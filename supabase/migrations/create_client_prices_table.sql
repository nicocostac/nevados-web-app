-- Drop existing triggers and function if they exist
DROP TRIGGER IF EXISTS update_client_prices_updated_at ON client_prices;
DROP FUNCTION IF EXISTS handle_client_price_update() CASCADE;

-- Drop existing table if it exists
DROP TABLE IF EXISTS client_prices;

-- Create client prices table
CREATE TABLE IF NOT EXISTS client_prices (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    discount_percentage DECIMAL(5,2),
    final_price DECIMAL(10,2) NOT NULL,
    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_until DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    CONSTRAINT valid_date_range CHECK (valid_until IS NULL OR valid_until >= valid_from),
    CONSTRAINT valid_discount CHECK (discount_percentage >= 0 AND discount_percentage <= 100)
);

-- Enable RLS
ALTER TABLE client_prices ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Everyone can view active client prices" 
    ON client_prices FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM clients
            WHERE clients.id = client_prices.client_id
            AND clients.status = 'active'
        )
    );

CREATE POLICY "Admins and managers can manage client prices" 
    ON client_prices FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'manager')
        )
    );

-- Function to handle updates
CREATE OR REPLACE FUNCTION handle_client_price_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for updating updated_at
CREATE TRIGGER update_client_prices_updated_at
    BEFORE UPDATE ON client_prices
    FOR EACH ROW
    EXECUTE FUNCTION handle_client_price_update();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_client_prices_client ON client_prices(client_id);
CREATE INDEX IF NOT EXISTS idx_client_prices_product ON client_prices(product_id);
CREATE INDEX IF NOT EXISTS idx_client_prices_dates ON client_prices(valid_from, valid_until); 