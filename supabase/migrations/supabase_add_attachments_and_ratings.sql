-- ============================================================================
-- SKRIP MIGRASI TAMBAHAN SUPABASE (OPSIONAL)
-- Forum Kepegawaian BRIN: Menambahkan kolom lampiran, CSAT rating, dan timestamp
-- Jalankan skrip ini di Supabase Dashboard -> SQL Editor
-- ============================================================================

-- 1. Tambahkan kolom lampiran, rating, dan timestamp jika belum ada di tabel questions
ALTER TABLE public.questions 
  ADD COLUMN IF NOT EXISTS attachment_url TEXT,
  ADD COLUMN IF NOT EXISTS attachment_name TEXT,
  ADD COLUMN IF NOT EXISTS rating INT,
  ADD COLUMN IF NOT EXISTS rating_feedback TEXT,
  ADD COLUMN IF NOT EXISTS rating_submitted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 2. Tambahkan kolom user_id pada tabel answers jika ingin mencatat foreign key profil pengirim
ALTER TABLE public.answers
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 3. Aktifkan Realtime Replication untuk tabel answers dan questions (agar sinkron otomatis multi-role)
ALTER PUBLICATION supabase_realtime ADD TABLE public.answers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.questions;
