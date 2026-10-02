-- ============================================================================
-- MIGRATION: 5 ROLES SUPABASE AUTH & PROFILES TABLE FOR FORUM BRIN
-- ============================================================================

-- 1. Pastikan ekstensi aktif
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Buat tabel profiles jika belum ada
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL DEFAULT 'member',
  unit TEXT,
  tim TEXT,
  jabatan TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Constraint Validasi 5 Role
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS check_valid_5_roles;
ALTER TABLE public.profiles ADD CONSTRAINT check_valid_5_roles 
  CHECK (role IN ('super_admin', 'admin', 'ketua_tim', 'eksekutif', 'member'));

-- 4. Aktifkan RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Public profiles are viewable by authenticated users" 
ON public.profiles FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" 
ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- 5. Trigger Handler saat Register User
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, role, unit, tim, jabatan)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    COALESCE(new.raw_user_meta_data->>'role', 'member'),
    COALESCE(new.raw_user_meta_data->>'unit', 'BRIN'),
    COALESCE(new.raw_user_meta_data->>'tim', 'Umum'),
    COALESCE(new.raw_user_meta_data->>'jabatan', 'Pegawai')
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    role = EXCLUDED.role,
    unit = EXCLUDED.unit,
    tim = EXCLUDED.tim,
    jabatan = EXCLUDED.jabatan;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
