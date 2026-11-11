-- ============================================================================
-- 03_SCHEMA_BROADCASTS_AND_STORAGE.SQL
-- BOSDM CONNECT - SISTEM FORUM & LAYANAN TERPADU INSTANSI BRIN
-- Modul: Blast Notification LKSDM, Pelacakan Penerima, dan Supabase Storage
-- Target: Supabase PostgreSQL (Fresh / Empty Database)
-- Catatan: Tabel dibuat kosongan (siap menerima siaran pesan baru)
-- Urutan Eksekusi: #3 (Ketiga)
-- ============================================================================

-- Bersihkan tabel jika sebelumnya sudah pernah dibuat
DROP TABLE IF EXISTS public.broadcast_recipients CASCADE;
DROP TABLE IF EXISTS public.broadcasts CASCADE;

-- ----------------------------------------------------------------------------
-- 1. TABEL: BROADCASTS (Siaran Pesan Resmi / Blast Notification LKSDM)
-- ----------------------------------------------------------------------------
CREATE TABLE public.broadcasts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id VARCHAR(50) NOT NULL REFERENCES public.users(id_user) ON DELETE CASCADE,
    sender_name TEXT NOT NULL,
    sender_role TEXT NOT NULL,
    lksdm_scope TEXT NOT NULL,          -- 'LKSDM 1', 'LKSDM 2', ..., atau 'ALL'
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'normal', -- 'normal' atau 'urgent'
    target_type TEXT NOT NULL DEFAULT 'all_lksdm', -- 'all_lksdm', 'unit_filter', 'custom_users'
    target_filter_value TEXT,           -- Nama unit / satuan kerja jika target_type = 'unit_filter'
    attachment_url TEXT,
    attachment_name TEXT,
    attachment_size TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.broadcasts IS 'Tabel siaran pengumuman dan blast pemberitahuan resmi dari LKSDM / Pusat kepada pegawai';

CREATE INDEX IF NOT EXISTS idx_broadcasts_lksdm_scope ON public.broadcasts(lksdm_scope);
CREATE INDEX IF NOT EXISTS idx_broadcasts_priority ON public.broadcasts(priority);
CREATE INDEX IF NOT EXISTS idx_broadcasts_created_at ON public.broadcasts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_broadcasts_sender_id ON public.broadcasts(sender_id);

-- ----------------------------------------------------------------------------
-- 2. TABEL: BROADCAST_RECIPIENTS (Pelacakan Keterbacaan Tiap Pegawai)
-- ----------------------------------------------------------------------------
CREATE TABLE public.broadcast_recipients (
    id BIGSERIAL PRIMARY KEY,
    broadcast_id UUID NOT NULL REFERENCES public.broadcasts(id) ON DELETE CASCADE,
    user_id VARCHAR(50) NOT NULL REFERENCES public.users(id_user) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(broadcast_id, user_id)
);

COMMENT ON TABLE public.broadcast_recipients IS 'Tabel pelacakan tanda terima dan status baca siaran untuk setiap pegawai';

CREATE INDEX IF NOT EXISTS idx_broadcast_recipients_user ON public.broadcast_recipients(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_broadcast_recipients_broadcast ON public.broadcast_recipients(broadcast_id);

-- ----------------------------------------------------------------------------
-- 3. ROW LEVEL SECURITY (RLS) POLICIES UNTUK BROADCAST
-- ----------------------------------------------------------------------------
ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcast_recipients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow read broadcasts" ON public.broadcasts;
CREATE POLICY "Allow read broadcasts" ON public.broadcasts 
    FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow write broadcasts" ON public.broadcasts;
CREATE POLICY "Allow write broadcasts" ON public.broadcasts 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow read broadcast_recipients" ON public.broadcast_recipients;
CREATE POLICY "Allow read broadcast_recipients" ON public.broadcast_recipients 
    FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow write broadcast_recipients" ON public.broadcast_recipients;
CREATE POLICY "Allow write broadcast_recipients" ON public.broadcast_recipients 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- ----------------------------------------------------------------------------
-- 4. SUPABASE STORAGE: BUCKET 'attachments' & AKSES DOKUMEN LAMPIRAN
-- ----------------------------------------------------------------------------
-- Membuat atau memperbarui konfigurasi bucket attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'attachments',
    'attachments',
    true,
    10485760, -- Maksimal 10 MB per berkas
    NULL      -- Mengizinkan format dokumen PDF, DOCX, XLSX, PNG, JPG, ZIP
)
ON CONFLICT (id) DO UPDATE 
SET public = true,
    file_size_limit = 10485760,
    allowed_mime_types = NULL;

-- Kebijakan Public Read Access untuk Storage Objects
DROP POLICY IF EXISTS "Public Read Access for Attachments" ON storage.objects;
CREATE POLICY "Public Read Access for Attachments"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'attachments');

-- Kebijakan Public Upload Access untuk Storage Objects
DROP POLICY IF EXISTS "Public Upload Access for Attachments" ON storage.objects;
CREATE POLICY "Public Upload Access for Attachments"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'attachments');

-- Kebijakan Public Update Access untuk Storage Objects
DROP POLICY IF EXISTS "Public Update Access for Attachments" ON storage.objects;
CREATE POLICY "Public Update Access for Attachments"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'attachments');
