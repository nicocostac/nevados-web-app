-- Create enum for user roles if it doesn't exist
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('admin', 'manager', 'salesperson', 'support');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Drop existing triggers and functions with CASCADE
DROP TRIGGER IF EXISTS create_profile_on_signup ON auth.users CASCADE;
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_profile_update() CASCADE;

-- Create or update profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    role user_role NOT NULL DEFAULT 'salesperson',
    first_name TEXT,
    last_name TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    is_active BOOLEAN DEFAULT true
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can access all profiles" ON profiles;

-- Create new policies without subqueries on 'profiles'

-- Allow users to select and update their own profiles
CREATE POLICY "Users can access their own profile" 
    ON profiles FOR SELECT, UPDATE
    USING (auth.uid() = id);

-- Allow admins and managers to access all profiles
CREATE POLICY "Admins and managers can access all profiles" 
    ON profiles FOR ALL 
    USING (auth.role() IN ('admin', 'manager'));

-- Function to handle profile updates
CREATE OR REPLACE FUNCTION handle_profile_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for updating updated_at
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION handle_profile_update();

-- Function to handle new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, role, first_name, last_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'salesperson')::user_role,
        NEW.raw_user_meta_data->>'first_name',
        NEW.raw_user_meta_data->>'last_name'
    )
    ON CONFLICT (id) DO UPDATE
    SET
        email = EXCLUDED.email,
        role = EXCLUDED.role,
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for creating profile on user creation
CREATE TRIGGER create_profile_on_signup
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- Insert initial admin user if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE role = 'admin'
    ) THEN
        -- You can add an initial admin user here if needed
        -- Make sure to create the auth.users entry first
        NULL;
    END IF;
END $$; 