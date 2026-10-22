-- ============================================================================
-- SKRIP MIGRASI TAMBAHAN SUPABASE: CSAT RATING TAGS
-- Forum Kepegawaian BRIN: Menambahkan kolom rating_tags di tabel questions
-- ============================================================================

ALTER TABLE public.questions 
  ADD COLUMN IF NOT EXISTS rating_tags TEXT;
