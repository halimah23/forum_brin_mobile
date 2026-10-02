-- ============================================================================
-- ARSITEKTUR DATABASE FORUM KEPEGAWAIAN BRIN (ALUR 3 USER: PEGAWAI + LKSDM + PUSAT)
-- ============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. ENUM ROLE RESMI
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role_type') THEN
        CREATE TYPE public.user_role_type AS ENUM (
            'pegawai',
            'admin_lksdm',
            'admin_pusat',
            'ketua_tim',
            'eksekutif',
            'super_admin'
        );
    END IF;
END $$;

-- 3. TABEL PROFILES (PENGGUNA & ROLE)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  role public.user_role_type NOT NULL DEFAULT 'pegawai',
  unit TEXT NOT NULL DEFAULT 'BRIN',
  tim TEXT NOT NULL DEFAULT 'Umum',
  jabatan TEXT NOT NULL DEFAULT 'Pegawai',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABEL KATALOG TUGAS FUNGSI
CREATE TABLE IF NOT EXISTS public.tugas_fungsi (
  id BIGSERIAL PRIMARY KEY,
  kode TEXT,
  nama TEXT NOT NULL,
  team_name TEXT NOT NULL
);

-- 5. TABEL QUESTIONS (TIKET PERTANYAAN)
CREATE TABLE IF NOT EXISTS public.questions (
  id BIGSERIAL PRIMARY KEY,
  ticket_number TEXT UNIQUE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Konten Pertanyaan
  judul TEXT NOT NULL,
  isi TEXT NOT NULL,
  
  -- Alur & Status
  status TEXT NOT NULL DEFAULT 'menunggu_lksdm' 
    CHECK (status IN ('menunggu_lksdm', 'ditangani_lksdm', 'dialihkan_ke_pusat', 'selesai')),
    
  -- Routing Tim & Kawasan
  lksdm_kawasan TEXT NOT NULL,
  target_tim_pusat TEXT NOT NULL,
  tugas_fungsi_id BIGINT REFERENCES public.tugas_fungsi(id) ON DELETE SET NULL,
  tugas_fungsi_nama TEXT,
  
  -- Penanggung Jawab Aktif
  admin_lksdm_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  admin_pusat_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  closed_at TIMESTAMPTZ
);

-- 6. TABEL ANSWERS (BUBBLE CHAT THREAD 3 USER + SYSTEM)
CREATE TABLE IF NOT EXISTS public.answers (
  id BIGSERIAL PRIMARY KEY,
  question_id BIGINT NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  sender_name TEXT NOT NULL,
  sender_role TEXT NOT NULL 
    CHECK (sender_role IN ('pegawai', 'admin_lksdm', 'admin_pusat', 'ketua_tim', 'system')),
  isi_pesan TEXT NOT NULL,
  attachment_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. TRIGGER TICKET NUMBER
CREATE OR REPLACE FUNCTION public.generate_ticket_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ticket_number IS NULL OR NEW.ticket_number = '' THEN
        NEW.ticket_number := 'TKT-' || TO_CHAR(NOW(), 'YYYYMM') || '-' || LPAD(COALESCE(NEW.id, 1)::TEXT, 4, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_ticket_number ON public.questions;
CREATE TRIGGER trg_generate_ticket_number
BEFORE INSERT ON public.questions
FOR EACH ROW EXECUTE FUNCTION public.generate_ticket_number();

-- 8. ROW LEVEL SECURITY (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tugas_fungsi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.answers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Profiles read" ON public.profiles;
CREATE POLICY "Profiles read" ON public.profiles FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Profiles update" ON public.profiles;
CREATE POLICY "Profiles update" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "Tugas fungsi read" ON public.tugas_fungsi;
CREATE POLICY "Tugas fungsi read" ON public.tugas_fungsi FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Questions read" ON public.questions;
CREATE POLICY "Questions read" ON public.questions FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Questions insert" ON public.questions;
CREATE POLICY "Questions insert" ON public.questions FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Questions update" ON public.questions;
CREATE POLICY "Questions update" ON public.questions FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "Answers read" ON public.answers;
CREATE POLICY "Answers read" ON public.answers FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Answers insert" ON public.answers;
CREATE POLICY "Answers insert" ON public.answers FOR INSERT TO authenticated WITH CHECK (true);

-- 9. DATA SEEDER RESMI (5 ROLE / 6 AKUN PENGUJIAN)
DO $$
DECLARE
  pwd_hash TEXT := crypt('Password123!', gen_salt('bf'));
BEGIN
  -- 1. Pegawai (Ahmad - Kawasan Thamrin I)
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES ('77777777-7777-7777-7777-777777777777'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'pegawai@brin.go.id', pwd_hash, NOW(), '{"provider":"email"}', '{"name":"Ahmad Syahputra"}', NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET encrypted_password = pwd_hash, email_confirmed_at = NOW();

  -- 2. Staf Admin LKSDM Kawasan Thamrin (Budi)
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES ('44444444-4444-4444-4444-444444444444'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'admin.lksdm1@brin.go.id', pwd_hash, NOW(), '{"provider":"email"}', '{"name":"Budi Handoko"}', NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET encrypted_password = pwd_hash, email_confirmed_at = NOW();

  -- 3. Staf Admin Pusat BOSDM (Rina - Tim Ortala / Mutasi Pusat)
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES ('55555555-5555-5555-5555-555555555555'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'admin.pusat@brin.go.id', pwd_hash, NOW(), '{"provider":"email"}', '{"name":"Rina Wati"}', NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET encrypted_password = pwd_hash, email_confirmed_at = NOW();

  -- 4. Ketua Tim Layanan SDM
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES ('33333333-3333-3333-3333-333333333333'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'ketuatim@brin.go.id', pwd_hash, NOW(), '{"provider":"email"}', '{"name":"Dr. Irwan Setiawan"}', NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET encrypted_password = pwd_hash, email_confirmed_at = NOW();

  -- 5. Eksekutif
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES ('66666666-6666-6666-6666-666666666666'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'eksekutif@brin.go.id', pwd_hash, NOW(), '{"provider":"email"}', '{"name":"Prof. Dr. Hendra Wijaya"}', NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET encrypted_password = pwd_hash, email_confirmed_at = NOW();

  -- 6. Super Admin
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES ('11111111-1111-1111-1111-111111111111'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'superadmin@brin.go.id', pwd_hash, NOW(), '{"provider":"email"}', '{"name":"Super Admin"}', NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET encrypted_password = pwd_hash, email_confirmed_at = NOW();
END $$;

-- 10. SINKRONISASI PROFILES RESMI
INSERT INTO public.profiles (id, name, email, role, unit, tim, jabatan) VALUES
  ('77777777-7777-7777-7777-777777777777', 'Ahmad Syahputra', 'pegawai@brin.go.id', 'pegawai', 'Kawasan Thamrin', 'Layanan Kawasan SDM 1 : Thamrin I', 'Peneliti Ahli Muda'),
  ('44444444-4444-4444-4444-444444444444', 'Budi Handoko', 'admin.lksdm1@brin.go.id', 'admin_lksdm', 'Kawasan Thamrin', 'Layanan Kawasan SDM 1 : Thamrin I', 'Staf Admin LKSDM Kawasan'),
  ('55555555-5555-5555-5555-555555555555', 'Rina Wati', 'admin.pusat@brin.go.id', 'admin_pusat', 'BOSDM Pusat', 'Tim Ortala', 'Staf Admin Layanan Pusat'),
  ('33333333-3333-3333-3333-333333333333', 'Dr. Irwan Setiawan', 'ketuatim@brin.go.id', 'ketua_tim', 'BOSDM Pusat', 'Tim Ortala', 'Ketua Tim Ortala'),
  ('66666666-6666-6666-6666-666666666666', 'Prof. Dr. Hendra Wijaya', 'eksekutif@brin.go.id', 'eksekutif', 'BOSDM Pusat', 'Pimpinan', 'Kepala Biro Organisasi dan SDM'),
  ('11111111-1111-1111-1111-111111111111', 'Super Admin BOSDM', 'superadmin@brin.go.id', 'super_admin', 'PUSDATIN BRIN', 'Tim Pengelolaan Data dan Informasi SDM', 'Administrator Utama')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name, email = EXCLUDED.email, role = EXCLUDED.role, unit = EXCLUDED.unit, tim = EXCLUDED.tim, jabatan = EXCLUDED.jabatan;

-- 11. CONTOH TIKET CHAT 3 PIHAK
INSERT INTO public.questions (
  id, ticket_number, user_id, judul, isi, status, lksdm_kawasan, target_tim_pusat, tugas_fungsi_nama, admin_lksdm_id, admin_pusat_id, created_at
) VALUES (
  101, 'TKT-202610-0001', '77777777-7777-7777-7777-777777777777', 
  'Kendala Penyetaraan Ijazah S3 Luar Negeri',
  'Ijazah doktoral saya telah disetarakan Kemendikbud, namun belum muncul di profil SIMPEG kawasan Thamrin.',
  'dialihkan_ke_pusat',
  'Layanan Kawasan SDM 1 : Thamrin I',
  'Tim Ortala',
  'BRIN-04.03.01.04 - Penyusunan Evaluasi Jabatan',
  '44444444-4444-4444-4444-444444444444',
  '55555555-5555-5555-5555-555555555555',
  NOW() - INTERVAL '3 hours'
) ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status;

-- 12. RIWAYAT PERCAKAPAN BUBBLE CHAT (3 USER DALAM 1 THREAD)
INSERT INTO public.answers (question_id, user_id, sender_name, sender_role, isi_pesan, created_at) VALUES
  (101, '77777777-7777-7777-7777-777777777777', 'Ahmad Syahputra', 'pegawai', 'Halo admin kawasan, mohon dibantu terkait penyetaraan ijazah S3 saya.', NOW() - INTERVAL '2 hours 50 mins'),
  (101, '44444444-4444-4444-4444-444444444444', 'Budi Handoko', 'admin_lksdm', 'Halo Mas Ahmad, berkas kawasan sudah kami periksa. Namun untuk verifikasi SK penyetaraan pusat membutuhkan validasi langsung dari Tim Ortala/Bangkom Pusat. Tiket ini saya teruskan ke Admin Pusat ya.', NOW() - INTERVAL '2 hours 30 mins'),
  (101, NULL, 'Sistem', 'system', 'Tiket telah dialihkan oleh Budi Handoko (LKSDM) ke Tim Ortala Pusat.', NOW() - INTERVAL '2 hours 28 mins'),
  (101, '55555555-5555-5555-5555-555555555555', 'Rina Wati', 'admin_pusat', 'Halo Mas Ahmad dan Mas Budi. Berkas penyesuaian gelar sudah kami validasi di basis data pusat dan akan sinkron ke SIMPEG kawasan dalam 1x24 jam.', NOW() - INTERVAL '1 hour');
