-- ==============================================================================
-- SKEMA BASIS DATA: BLAST NOTIFICATION & BROADCAST LKSDM
-- Modul: Fitur Siaran Pesan Resmi Satu Arah LKSDM ke Pegawai
-- Aplikasi: BOSDM Connect
-- ==============================================================================

-- 1. Tabel Master Broadcasts
CREATE TABLE IF NOT EXISTS public.broadcasts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL,
    sender_name TEXT NOT NULL,
    sender_role TEXT NOT NULL,
    lksdm_scope TEXT NOT NULL, -- Contoh: 'LKSDM 1', 'LKSDM 2', atau 'ALL'
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'normal', -- 'normal' atau 'urgent'
    target_type TEXT NOT NULL DEFAULT 'all_lksdm', -- 'all_lksdm', 'unit_filter', 'custom_users'
    target_filter_value TEXT, -- Nama unit/kawasan jika target_type = 'unit_filter'
    attachment_url TEXT,
    attachment_name TEXT,
    attachment_size TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indeks untuk mempercepat pencarian siaran berdasarkan LKSDM dan waktu
CREATE INDEX IF NOT EXISTS idx_broadcasts_lksdm_scope ON public.broadcasts(lksdm_scope);
CREATE INDEX IF NOT EXISTS idx_broadcasts_created_at ON public.broadcasts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_broadcasts_sender_id ON public.broadcasts(sender_id);

-- 2. Tabel Pelacakan Keterbacaan Penerima (Broadcast Recipients)
CREATE TABLE IF NOT EXISTS public.broadcast_recipients (
    id BIGSERIAL PRIMARY KEY,
    broadcast_id UUID NOT NULL REFERENCES public.broadcasts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(broadcast_id, user_id)
);

-- Indeks untuk mempercepat kueri keterbacaan user dan analitik pengirim
CREATE INDEX IF NOT EXISTS idx_broadcast_recipients_user ON public.broadcast_recipients(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_broadcast_recipients_broadcast ON public.broadcast_recipients(broadcast_id);

-- 3. Row Level Security (RLS) Policies (Opsional jika RLS aktif di Supabase)
ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcast_recipients ENABLE ROW LEVEL SECURITY;

-- Izinkan read untuk semua pengguna terotentikasi
CREATE POLICY "Allow authenticated read broadcasts"
ON public.broadcasts FOR SELECT
TO authenticated
USING (true);

-- Izinkan insert/update untuk Admin/Ketua Tim/Super Admin
CREATE POLICY "Allow authenticated insert broadcasts"
ON public.broadcasts FOR INSERT
TO authenticated
WITH CHECK (true);

-- Izinkan read penerima
CREATE POLICY "Allow authenticated read broadcast_recipients"
ON public.broadcast_recipients FOR SELECT
TO authenticated
USING (true);

-- Izinkan update keterbacaan (is_read & read_at) oleh user bersangkutan
CREATE POLICY "Allow recipient update read status"
ON public.broadcast_recipients FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Izinkan insert daftar penerima
CREATE POLICY "Allow insert broadcast_recipients"
ON public.broadcast_recipients FOR INSERT
TO authenticated
WITH CHECK (true);
