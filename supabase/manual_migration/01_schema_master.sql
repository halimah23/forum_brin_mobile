-- ============================================================================
-- 01_SCHEMA_MASTER.SQL
-- BOSDM CONNECT - SISTEM FORUM & LAYANAN TERPADU INSTANSI BRIN
-- Modul: Struktur Master Data (Teams, Tugas Fungsi, Relasi, Users)
-- Target: Supabase PostgreSQL (Fresh / Empty Database)
-- Urutan Eksekusi: #1 (Pertama)
-- ============================================================================

-- Pastikan extension UUID dan Crypto aktif
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. TABEL: TEAMS (22 Tim Resmi BRIN: 14 Tim Pusat + 8 Kawasan LKSDM)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS public.team_tusi CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.tugas_fungsi CASCADE;
DROP TABLE IF EXISTS public.teams CASCADE;

CREATE TABLE public.teams (
    id_tim VARCHAR(50) PRIMARY KEY,
    tim VARCHAR(100) NOT NULL,
    detail_nama_tim TEXT NOT NULL,
    coverage TEXT,
    sebaran_hbp TEXT,
    catatan TEXT,
    eskalasi VARCHAR(50) NOT NULL -- 'PUSAT' atau 'LKSDM'
);

COMMENT ON TABLE public.teams IS 'Daftar 22 Tim Resmi BRIN (14 Tim Pusat dan 8 Wilayah Kawasan LKSDM)';

-- ----------------------------------------------------------------------------
-- 2. TABEL: TUGAS_FUNGSI (91 Tugas & Fungsi Resmi Sesuai SOP Instansi)
-- ----------------------------------------------------------------------------
CREATE TABLE public.tugas_fungsi (
    id_tusi VARCHAR(50) PRIMARY KEY,
    tugas_fungsi TEXT NOT NULL
);

COMMENT ON TABLE public.tugas_fungsi IS 'Daftar master 91 Tugas dan Fungsi resmi instansi BRIN';

-- ----------------------------------------------------------------------------
-- 3. TABEL RELASI: TEAM_TUSI (Mapping Many-to-Many Antara Tim dan Tusi)
-- ----------------------------------------------------------------------------
CREATE TABLE public.team_tusi (
    id_tim VARCHAR(50) NOT NULL REFERENCES public.teams(id_tim) ON DELETE CASCADE,
    id_tusi VARCHAR(50) NOT NULL REFERENCES public.tugas_fungsi(id_tusi) ON DELETE CASCADE,
    PRIMARY KEY (id_tim, id_tusi)
);

COMMENT ON TABLE public.team_tusi IS 'Tabel relasi penugasan tugas & fungsi kepada masing-masing tim kerja';

-- ----------------------------------------------------------------------------
-- 4. TABEL: USERS (Akun & Profil Pegawai Resmi BRIN)
-- ----------------------------------------------------------------------------
CREATE TABLE public.users (
    id_user VARCHAR(50) PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    external_email VARCHAR(255),
    phone VARCHAR(50),
    sex VARCHAR(20),
    satuan_kerja VARCHAR(100),
    id_tim VARCHAR(50) REFERENCES public.teams(id_tim) ON DELETE SET NULL,
    jabatan TEXT,
    kawasan VARCHAR(100), -- Contoh: 'LKSDM 1', 'LKSDM 6', dst.
    role VARCHAR(50) NOT NULL, -- 'Sivitas', 'Staff Admin', 'Ketua Tim', 'Eksekutif', 'Super Admin'
    password VARCHAR(255) DEFAULT 'BRINpop2026!',
    photo_url TEXT,
    fcm_token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.users IS 'Daftar akun dan profil kepegawaian resmi seluruh pegawai instansi BRIN';

-- Indeks performa untuk tabel users
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_id_tim ON public.users(id_tim);
CREATE INDEX IF NOT EXISTS idx_users_kawasan ON public.users(kawasan);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- ----------------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ----------------------------------------------------------------------------
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tugas_fungsi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_tusi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Kebijakan Akses Teams & Tusi (Dapat dibaca oleh semua pengguna)
DROP POLICY IF EXISTS "Allow read teams" ON public.teams;
CREATE POLICY "Allow read teams" ON public.teams 
    FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow write teams" ON public.teams;
CREATE POLICY "Allow write teams" ON public.teams 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow read tugas_fungsi" ON public.tugas_fungsi;
CREATE POLICY "Allow read tugas_fungsi" ON public.tugas_fungsi 
    FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow write tugas_fungsi" ON public.tugas_fungsi;
CREATE POLICY "Allow write tugas_fungsi" ON public.tugas_fungsi 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow read team_tusi" ON public.team_tusi;
CREATE POLICY "Allow read team_tusi" ON public.team_tusi 
    FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow write team_tusi" ON public.team_tusi;
CREATE POLICY "Allow write team_tusi" ON public.team_tusi 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- Kebijakan Akses Users (Autentikasi & Profil)
DROP POLICY IF EXISTS "Allow read users" ON public.users;
CREATE POLICY "Allow read users" ON public.users 
    FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow write users" ON public.users;
CREATE POLICY "Allow write users" ON public.users 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
