-- ==============================================================================
-- MIGRASI SUPABASE: SISTEM FAQ PERTANYAAN DIBAKUKAN & RANGKUMAN SOLUSI RESMI
-- BOSDM CONNECT BRIN
-- ==============================================================================

-- 1. Tambah kolom summary_jawaban pada tabel questions jika belum ada
ALTER TABLE public.questions 
ADD COLUMN IF NOT EXISTS summary_jawaban TEXT;

-- 2. Buat index untuk pencarian dan pemfilteran cepat
CREATE INDEX IF NOT EXISTS idx_questions_is_public ON public.questions (is_public);
CREATE INDEX IF NOT EXISTS idx_questions_is_pinned ON public.questions (is_pinned);

-- 3. View FAQ Terstandarisasi Dinamis
-- Mengambil tiket yang telah di-up ke publik dan memiliki teks baku atau rangkuman solusi resmi
CREATE OR REPLACE VIEW public.view_faq_standardized AS
SELECT 
    q.id,
    q.ticket_number,
    q.judul,
    q.isi,
    q.original_judul,
    q.original_isi,
    q.summary_jawaban,
    q.status,
    q.target_tim,
    q.target_tim_pusat,
    q.lksdm_kawasan,
    q.tugas_fungsi_nama,
    q.is_public,
    q.is_pinned,
    q.is_anonymized,
    q.rating,
    q.created_at,
    q.updated_at,
    p.id AS author_id,
    CASE 
        WHEN q.is_anonymized = TRUE OR q.is_public = TRUE THEN 'Pegawai'
        ELSE COALESCE(p.name, 'Pegawai')
    END AS author_name,
    p.role AS author_role,
    p.unit AS author_unit,
    p.tim AS author_tim,
    COALESCE(
        (SELECT COUNT(*) FROM public.answers a WHERE a.question_id = q.id), 
        0
    ) AS total_answers
FROM public.questions q
LEFT JOIN public.profiles p ON q.user_id = p.id
WHERE q.is_public = TRUE
  AND (
    q.original_judul IS NOT NULL 
    OR q.summary_jawaban IS NOT NULL 
    OR q.is_pinned = TRUE
  )
ORDER BY q.is_pinned DESC, q.created_at DESC;

-- 4. Berikan izin baca kepada semua pengguna terautentikasi dan tamu/anonim
GRANT SELECT ON public.view_faq_standardized TO authenticated, anon;
