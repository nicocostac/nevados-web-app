-- Drop existing triggers and function if they exist
DROP TRIGGER IF EXISTS update_products_updated_at ON products;
DROP TRIGGER IF EXISTS update_categories_updated_at ON product_categories;
DROP FUNCTION IF EXISTS handle_product_update() CASCADE;

-- Drop existing tables if they exist (in correct order due to dependencies)
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS product_categories;

-- Create product categories table first
CREATE TABLE IF NOT EXISTS product_categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Then create products table with category reference
CREATE TABLE IF NOT EXISTS products (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    default_price DECIMAL(10,2) NOT NULL,
    unit_of_sale TEXT NOT NULL DEFAULT 'unit',
    category_id UUID REFERENCES product_categories(id),
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;

-- Create policies for products
CREATE POLICY "Everyone can view active products" 
    ON products FOR SELECT
    USING (status = 'active');

CREATE POLICY "Admins and managers can manage products" 
    ON products FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'manager')
        )
    );

-- Create policies for categories
CREATE POLICY "Everyone can view categories" 
    ON product_categories FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Admins and managers can manage categories" 
    ON product_categories FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'manager')
        )
    );

-- Function to handle updates
CREATE OR REPLACE FUNCTION handle_product_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers for updating updated_at
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION handle_product_update();

CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON product_categories
    FOR EACH ROW
    EXECUTE FUNCTION handle_product_update();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id); 