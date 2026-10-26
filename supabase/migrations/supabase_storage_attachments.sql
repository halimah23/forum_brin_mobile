-- ============================================================================
-- MIGRASI SUPABASE STORAGE: BUCKET ATTACHMENTS & ATTACHMENT SUPPORT
-- Fitur: Unggah dan Buka Berkas Lampiran Tiket / Obrolan
-- Jalankan skrip ini di: Supabase Dashboard -> SQL Editor
-- ============================================================================

-- 1. Buat bucket 'attachments' di storage.buckets jika belum ada
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'attachments',
  'attachments',
  true,
  10485760, -- Batas 10 MB per berkas
  ARRAY[
    'image/png',
    'image/jpeg',
    'image/jpg',
    'image/webp',
    'image/gif',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain',
    'application/zip',
    'application/x-zip-compressed'
  ]
)
ON CONFLICT (id) DO UPDATE 
SET public = true,
    file_size_limit = 10485760;

-- 2. Aktifkan Row Level Security (RLS) pada tabel storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Kebijakan (Policy) agar semua orang dapat membaca / mengunduh lampiran (SELECT)
DROP POLICY IF EXISTS "Public Read Access for Attachments" ON storage.objects;
CREATE POLICY "Public Read Access for Attachments"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'attachments');

-- 4. Kebijakan (Policy) agar pengguna (anonim maupun terautentikasi) dapat mengunggah berkas (INSERT)
DROP POLICY IF EXISTS "Public Upload Access for Attachments" ON storage.objects;
CREATE POLICY "Public Upload Access for Attachments"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'attachments');

-- 5. Kebijakan (Policy) pembaruan berkas (UPDATE)
DROP POLICY IF EXISTS "Public Update Access for Attachments" ON storage.objects;
CREATE POLICY "Public Update Access for Attachments"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'attachments');

-- 6. Pastikan kolom pendukung lampiran tersedia di tabel questions dan answers
ALTER TABLE IF EXISTS public.questions
  ADD COLUMN IF NOT EXISTS attachment_url TEXT,
  ADD COLUMN IF NOT EXISTS attachment_name TEXT;

ALTER TABLE IF EXISTS public.answers
  ADD COLUMN IF NOT EXISTS attachment_url TEXT,
  ADD COLUMN IF NOT EXISTS attachment_name TEXT;
