-- Drop existing triggers and function if they exist
DROP TRIGGER IF EXISTS update_clients_updated_at ON clients;
DROP TRIGGER IF EXISTS update_addresses_updated_at ON client_addresses;
DROP FUNCTION IF EXISTS handle_client_update() CASCADE;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Everyone can view active clients" ON clients;
DROP POLICY IF EXISTS "Admins and managers can manage clients" ON clients;

-- Drop existing tables if they exist (in correct order due to dependencies)
DROP TABLE IF EXISTS client_addresses CASCADE;
DROP TABLE IF EXISTS clients CASCADE;

-- Create clients table
CREATE TABLE IF NOT EXISTS clients (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    contact_person TEXT,
    email TEXT,
    phone TEXT,
    notes TEXT,
    type_id UUID REFERENCES client_types(id),
    communication_preference TEXT DEFAULT 'email', -- 'email', 'phone', 'whatsapp'
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    created_by UUID REFERENCES auth.users(id)
);

-- Create client addresses table
CREATE TABLE IF NOT EXISTS client_addresses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    street_address TEXT NOT NULL,
    borough TEXT NOT NULL,
    neighborhood TEXT NOT NULL,
    additional_info TEXT,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_addresses ENABLE ROW LEVEL SECURITY;

-- Create policies for clients
CREATE POLICY "Everyone can view active clients" 
    ON clients FOR SELECT
    USING (status = 'active');

CREATE POLICY "Admins and managers can manage clients" 
    ON clients FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'manager')
        )
    );

-- Create policies for addresses
CREATE POLICY "Everyone can view client addresses" 
    ON client_addresses FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM clients
            WHERE clients.id = client_addresses.client_id
            AND clients.status = 'active'
        )
    );

CREATE POLICY "Admins and managers can manage addresses" 
    ON client_addresses FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'manager')
        )
    );

-- Function to handle updates
CREATE OR REPLACE FUNCTION handle_client_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers for updating updated_at
CREATE TRIGGER update_clients_updated_at
    BEFORE UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION handle_client_update();

CREATE TRIGGER update_addresses_updated_at
    BEFORE UPDATE ON client_addresses
    FOR EACH ROW
    EXECUTE FUNCTION handle_client_update();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_clients_type ON clients(type_id);
CREATE INDEX IF NOT EXISTS idx_clients_status ON clients(status);
CREATE INDEX IF NOT EXISTS idx_client_addresses_client ON client_addresses(client_id);
CREATE INDEX IF NOT EXISTS idx_client_addresses_borough ON client_addresses(borough);
CREATE INDEX IF NOT EXISTS idx_client_addresses_neighborhood ON client_addresses(neighborhood);

-- Function to ensure only one default address per client
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default THEN
        UPDATE client_addresses
        SET is_default = false
        WHERE client_id = NEW.client_id
        AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for default address management
CREATE TRIGGER manage_default_address
    BEFORE INSERT OR UPDATE ON client_addresses
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_default_address();