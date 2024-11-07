-- Drop existing triggers and function if they exist
DROP TRIGGER IF EXISTS update_client_types_updated_at ON client_types;
DROP FUNCTION IF EXISTS handle_client_type_update() CASCADE;

-- Drop existing table if it exists
DROP TABLE IF EXISTS client_types;

-- Create client types table
CREATE TABLE IF NOT EXISTS client_types (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS
ALTER TABLE client_types ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Everyone can view client types" 
    ON client_types FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Admins and managers can manage client types" 
    ON client_types FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'manager')
        )
    );

-- Function to handle updates
CREATE OR REPLACE FUNCTION handle_client_type_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for updating updated_at
CREATE TRIGGER update_client_types_updated_at
    BEFORE UPDATE ON client_types
    FOR EACH ROW
    EXECUTE FUNCTION handle_client_type_update();

-- Create index
CREATE INDEX IF NOT EXISTS idx_client_types_name ON client_types(name);

-- Insert default client types
INSERT INTO client_types (name, description) VALUES
    ('retail', 'Individual retail customers'),
    ('wholesale', 'Wholesale business customers'),
    ('corporate', 'Corporate accounts'); 