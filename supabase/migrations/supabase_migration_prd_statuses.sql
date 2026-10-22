-- ============================================================================
-- MIGRASI DATABASE FORUM BRIN: 7 STATUS RESMI TIKET PRD
-- ============================================================================

-- 1. Hapus constraint lama pada tabel questions
ALTER TABLE public.questions DROP CONSTRAINT IF EXISTS questions_status_check;

-- 2. Tambahkan constraint status baru yang mendukung 7 status PRD + status legacy
ALTER TABLE public.questions ADD CONSTRAINT questions_status_check
  CHECK (status IN (
    'OPEN',
    'IN_PROGRESS',
    'WAITING_USER',
    'ESCALATED',
    'IN_PROGRESS_CENTER',
    'RESOLVED',
    'CLOSED',
    -- Legacy fallbacks
    'menunggu_lksdm',
    'ditangani_lksdm',
    'dialihkan_ke_pusat',
    'selesai'
  ));

-- 3. Opsional: Update data lama ke 7 status huruf kapital PRD
UPDATE public.questions SET status = 'OPEN' WHERE status = 'menunggu_lksdm';
UPDATE public.questions SET status = 'IN_PROGRESS' WHERE status = 'ditangani_lksdm';
UPDATE public.questions SET status = 'ESCALATED' WHERE status = 'dialihkan_ke_pusat';
UPDATE public.questions SET status = 'CLOSED' WHERE status = 'selesai';
