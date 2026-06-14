-- Drop existing policies if any
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create ALL-ACCESS policy for authenticated users on their own data
CREATE POLICY "Users can manage their own profile" 
ON profiles 
FOR ALL 
TO authenticated 
USING (auth.uid() = id) 
WITH CHECK (auth.uid() = id);

-- Create policy for public viewing (needed for catalog/other features)
CREATE POLICY "Profiles are viewable by everyone" 
ON profiles 
FOR SELECT 
TO public 
USING (true);

-- Ensure other tables also have proper permissions for the app to function
ALTER TABLE borrows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own borrows" ON borrows FOR ALL TO authenticated USING (auth.uid() = user_id);

ALTER TABLE reserves ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own reserves" ON reserves FOR ALL TO authenticated USING (auth.uid() = user_id);

ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own wishlist" ON wishlist FOR ALL TO authenticated USING (auth.uid() = user_id);
