-- First, create the user_role enum type if it doesn't exist
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('admin', 'manager', 'salesperson', 'support');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Disable RLS temporarily to avoid policy conflicts
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies first (before any column modifications)
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins and managers can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins and managers can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Admin view access" ON profiles;
DROP POLICY IF EXISTS "Admin update access" ON profiles;
DROP POLICY IF EXISTS "Admin insert access" ON profiles;
DROP POLICY IF EXISTS "Manager update salesperson" ON profiles;
DROP POLICY IF EXISTS "Manager insert salesperson" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Managers can manage salesperson profiles" ON profiles;

-- Drop existing triggers and functions with CASCADE
DROP TRIGGER IF EXISTS create_profile_on_signup ON auth.users CASCADE;
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_profile_update() CASCADE;

-- Add new columns if they don't exist
DO $$ BEGIN
    ALTER TABLE profiles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW());
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Make updated_at NOT NULL after adding it
ALTER TABLE profiles ALTER COLUMN updated_at SET NOT NULL;

-- Add other new columns
DO $$ BEGIN
    ALTER TABLE profiles ADD COLUMN first_name TEXT;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE profiles ADD COLUMN last_name TEXT;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE profiles ADD COLUMN phone TEXT;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE profiles ADD COLUMN is_active BOOLEAN DEFAULT true;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Create a temporary column for the new role type
ALTER TABLE profiles ADD COLUMN new_role user_role;

-- Update the new_role column based on existing role values
UPDATE profiles
SET new_role = CASE 
    WHEN role = 'admin' THEN 'admin'::user_role
    WHEN role = 'manager' THEN 'manager'::user_role
    ELSE 'salesperson'::user_role
END;

-- Drop the old role column with CASCADE to remove dependent objects
ALTER TABLE profiles DROP COLUMN role CASCADE;
ALTER TABLE profiles RENAME COLUMN new_role TO role;

-- Set NOT NULL and default value for role
ALTER TABLE profiles 
    ALTER COLUMN role SET NOT NULL,
    ALTER COLUMN role SET DEFAULT 'salesperson'::user_role;

-- Create function to handle profile updates
CREATE OR REPLACE FUNCTION handle_profile_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for updating updated_at
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION handle_profile_update();

-- Re-enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop ALL policies again before creating new ones (to be safe)
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins and managers can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can manage all profiles" ON profiles;
DROP POLICY IF EXISTS "Managers can manage salesperson profiles" ON profiles;
DROP POLICY IF EXISTS "profile_select_own" ON profiles;
DROP POLICY IF EXISTS "profile_update_own" ON profiles;
DROP POLICY IF EXISTS "profile_select_admin_manager" ON profiles;
DROP POLICY IF EXISTS "profile_all_admin" ON profiles;
DROP POLICY IF EXISTS "profile_all_manager_for_salesperson" ON profiles;

-- Create new RLS policies with proper operation-specific checks
CREATE POLICY "profile_select_own" 
    ON profiles FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "profile_update_own" 
    ON profiles FOR UPDATE 
    USING (auth.uid() = id);

CREATE POLICY "profile_select_admin_manager" 
    ON profiles FOR SELECT 
    USING (auth.jwt()->>'role' IN ('admin', 'manager'));

CREATE POLICY "profile_all_admin" 
    ON profiles FOR ALL 
    USING (auth.jwt()->>'role' = 'admin');

-- Separate policies for managers based on operation
CREATE POLICY "profile_select_manager" 
    ON profiles FOR SELECT 
    USING (auth.jwt()->>'role' = 'manager');

CREATE POLICY "profile_insert_manager" 
    ON profiles FOR INSERT 
    WITH CHECK (
        auth.jwt()->>'role' = 'manager' 
        AND role = 'salesperson'::user_role
    );

CREATE POLICY "profile_update_manager" 
    ON profiles FOR UPDATE 
    USING (
        auth.jwt()->>'role' = 'manager' 
        AND role = 'salesperson'::user_role
    )
    WITH CHECK (
        auth.jwt()->>'role' = 'manager' 
        AND role = 'salesperson'::user_role
    );

CREATE POLICY "profile_delete_manager" 
    ON profiles FOR DELETE 
    USING (
        auth.jwt()->>'role' = 'manager' 
        AND role = 'salesperson'::user_role
    );

-- Set the first user as admin if no admin exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE role = 'admin'::user_role
    ) THEN
        UPDATE profiles 
        SET role = 'admin'::user_role 
        WHERE id = (SELECT id FROM profiles LIMIT 1);
    END IF;
END $$;

-- Function to sync email updates
CREATE OR REPLACE FUNCTION sync_user_email()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.profiles
    SET email = NEW.email
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to sync email on update
CREATE TRIGGER update_user_email
    AFTER UPDATE OF email ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION sync_user_email();