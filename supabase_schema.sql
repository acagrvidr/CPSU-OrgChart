-- Enable Row Level Security (RLS) is recommended for all tables
-- Create organizations table
CREATE TABLE organizations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL, -- 'Government', 'Private', 'NGO', etc.
  color TEXT NOT NULL,
  icon TEXT NOT NULL,
  is_locked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create employees table (for officials/members)
CREATE TABLE employees (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  department TEXT, -- Added department
  photo TEXT, -- URL to image
  parent_id UUID REFERENCES employees(id) ON DELETE SET NULL, -- Self-reference for hierarchy
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create pictures table (for galleries or additional images)
CREATE TABLE pictures (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  url TEXT NOT NULL,
  caption TEXT,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT single_owner CHECK (
    (organization_id IS NOT NULL AND employee_id IS NULL) OR 
    (organization_id IS NULL AND employee_id IS NOT NULL)
  )
);

-- Create subjects table
CREATE TABLE subjects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE NOT NULL,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create skills table
CREATE TABLE skills (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE pictures ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE skills ENABLE ROW LEVEL SECURITY;

-- Create policies (Simplistic for now: Public read, Authenticated write)
-- Note: In a real app, you'd want tighter controls based on user roles.

-- Organizations: Everyone can read, only authenticated users can modify
CREATE POLICY "Public organizations are viewable by everyone" 
ON organizations FOR SELECT USING (true);

CREATE POLICY "Users can insert organizations" 
ON organizations FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update organizations" 
ON organizations FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete organizations" 
ON organizations FOR DELETE USING (auth.role() = 'authenticated');

-- Employees: Everyone can read, only authenticated users can modify
CREATE POLICY "Public employees are viewable by everyone" 
ON employees FOR SELECT USING (true);

CREATE POLICY "Users can insert employees" 
ON employees FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update employees" 
ON employees FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete employees" 
ON employees FOR DELETE USING (auth.role() = 'authenticated');

-- Subjects: Everyone can read, only authenticated users can modify
CREATE POLICY "Public subjects are viewable by everyone" 
ON subjects FOR SELECT USING (true);

CREATE POLICY "Users can insert subjects" 
ON subjects FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update subjects" 
ON subjects FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete subjects" 
ON subjects FOR DELETE USING (auth.role() = 'authenticated');

-- Skills: Everyone can read, only authenticated users can modify
CREATE POLICY "Public skills are viewable by everyone" 
ON skills FOR SELECT USING (true);

CREATE POLICY "Users can insert skills" 
ON skills FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update skills" 
ON skills FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete skills" 
ON skills FOR DELETE USING (auth.role() = 'authenticated');

-- Pictures: Everyone can read, only authenticated users can modify
CREATE POLICY "Public pictures are viewable by everyone" 
ON pictures FOR SELECT USING (true);

CREATE POLICY "Users can insert pictures" 
ON pictures FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update pictures" 
ON pictures FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete pictures" 
ON pictures FOR DELETE USING (auth.role() = 'authenticated');

-- Storage buckets Setup
-- Note: You might need to run this in the Supabase SQL Editor if the bucket doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies
CREATE POLICY "Avatar images are publicly accessible" 
ON storage.objects FOR SELECT 
USING ( bucket_id = 'avatars' );

CREATE POLICY "Authenticated users can upload avatars" 
ON storage.objects FOR INSERT 
WITH CHECK ( bucket_id = 'avatars' AND auth.role() = 'authenticated' );

CREATE POLICY "Authenticated users can update avatars" 
ON storage.objects FOR UPDATE 
USING ( bucket_id = 'avatars' AND auth.role() = 'authenticated' );

CREATE POLICY "Authenticated users can delete avatars" 
ON storage.objects FOR DELETE 
USING ( bucket_id = 'avatars' AND auth.role() = 'authenticated' );
