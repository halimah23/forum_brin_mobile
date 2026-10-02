-- ==============================================================
-- SKEMA LENGKAP: TRI-PARTY CHAT & MULTI-ROLE (IDEMPOTENT & AMAN DIJALANKAN ULANG)
-- ==============================================================

-- 1. Tipe ENUM Role Pengguna
DO $$ BEGIN
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

-- 2. Tabel Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role public.user_role_type NOT NULL DEFAULT 'pegawai',
  unit TEXT,
  tim TEXT,
  jabatan TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS unit TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS tim TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS jabatan TEXT;

-- 3. Tabel Questions
CREATE TABLE IF NOT EXISTS public.questions (
  id BIGSERIAL PRIMARY KEY,
  ticket_number TEXT UNIQUE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  judul TEXT NOT NULL,
  isi TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'menunggu_lksdm',
  lksdm_kawasan TEXT NOT NULL DEFAULT 'LKSDM 1 (Kawasan Jakarta & Sekitarnya)',
  target_tim_pusat TEXT,
  target_tim TEXT,
  assigned_to TEXT,
  admin_lksdm_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  admin_pusat_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  tugas_fungsi_id BIGINT,
  tugas_fungsi_nama TEXT,
  is_public BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS ticket_number TEXT;
ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS lksdm_kawasan TEXT DEFAULT 'LKSDM 1 (Kawasan Jakarta & Sekitarnya)';
ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS target_tim_pusat TEXT;
ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS admin_lksdm_id UUID;
ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS admin_pusat_id UUID;
ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT true;

-- 4. Tabel Answers (Tri-Party Chat)
CREATE TABLE IF NOT EXISTS public.answers (
  id BIGSERIAL PRIMARY KEY,
  question_id BIGINT NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  sender_name TEXT NOT NULL DEFAULT 'Pengguna',
  sender_role TEXT NOT NULL DEFAULT 'Pegawai',
  sender_role_type TEXT NOT NULL DEFAULT 'pegawai',
  isi_pesan TEXT NOT NULL DEFAULT '-',
  penjawab_nama TEXT,
  penjawab_role TEXT,
  isi_jawaban TEXT,
  attachment_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.answers ADD COLUMN IF NOT EXISTS sender_name TEXT DEFAULT 'Pengguna';
ALTER TABLE public.answers ADD COLUMN IF NOT EXISTS sender_role TEXT DEFAULT 'Pegawai';
ALTER TABLE public.answers ADD COLUMN IF NOT EXISTS sender_role_type TEXT DEFAULT 'pegawai';
ALTER TABLE public.answers ADD COLUMN IF NOT EXISTS isi_pesan TEXT DEFAULT '-';
ALTER TABLE public.answers ADD COLUMN IF NOT EXISTS penjawab_nama TEXT;
ALTER TABLE public.answers ADD COLUMN IF NOT EXISTS penjawab_role TEXT;
ALTER TABLE public.answers ADD COLUMN IF NOT EXISTS isi_jawaban TEXT;
ALTER TABLE public.answers ADD COLUMN IF NOT EXISTS attachment_url TEXT;

-- 5. Trigger Sinkronisasi Kolom Alias
CREATE OR REPLACE FUNCTION sync_answer_aliases()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.penjawab_nama IS NULL THEN
    NEW.penjawab_nama := NEW.sender_name;
  END IF;
  IF NEW.penjawab_role IS NULL THEN
    NEW.penjawab_role := NEW.sender_role;
  END IF;
  IF NEW.isi_jawaban IS NULL THEN
    NEW.isi_jawaban := NEW.isi_pesan;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_answer_aliases ON public.answers;
CREATE TRIGGER trg_sync_answer_aliases
BEFORE INSERT OR UPDATE ON public.answers
FOR EACH ROW EXECUTE FUNCTION sync_answer_aliases();

-- 6. Aturan Keamanan Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.answers ENABLE ROW LEVEL SECURITY;

-- Hapus policy lama jika ada untuk mencegah error 42710 (already exists)
DROP POLICY IF EXISTS "Semua user terotentikasi dapat membaca profiles" ON public.profiles;
DROP POLICY IF EXISTS "Semua user terotentikasi dapat membaca questions" ON public.questions;
DROP POLICY IF EXISTS "Pegawai dapat membuat pertanyaan" ON public.questions;
DROP POLICY IF EXISTS "Staf Admin & Penjawab dapat update status questions" ON public.questions;
DROP POLICY IF EXISTS "Semua user terkait dapat membaca dan kirim pesan answers" ON public.answers;

-- Buat ulang policy dengan bersih
CREATE POLICY "Semua user terotentikasi dapat membaca profiles" 
  ON public.profiles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Semua user terotentikasi dapat membaca questions" 
  ON public.questions FOR SELECT TO authenticated USING (true);

CREATE POLICY "Pegawai dapat membuat pertanyaan" 
  ON public.questions FOR INSERT TO authenticated 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Staf Admin & Penjawab dapat update status questions" 
  ON public.questions FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Semua user terkait dapat membaca dan kirim pesan answers" 
  ON public.answers FOR ALL TO authenticated USING (true);
