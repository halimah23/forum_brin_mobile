-- ====================================================================
-- MANUAL MIGRATION: 01_operational_hours_and_soft_delete.sql
-- Proyek: BOSDM Connect (Forum BRIN Mobile)
-- Deskripsi:
--   1. Menambahkan kolom audit Soft Delete & Edit pada tabel questions dan answers
--   2. Menambahkan kolom penanda Jam Operasional & SLA pada tabel questions
--   3. Menambahkan status 'antrean_luar_jam_kerja' dan 'dibatalkan'
--   4. Membuat indeks performa untuk kuota tiket aktif dan filter off-hours
-- ====================================================================

-- 1. Tambah kolom soft delete & edit pada tabel questions
ALTER TABLE public.questions
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS deleted_by VARCHAR(100),
ADD COLUMN IF NOT EXISTS is_edited BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS is_off_hours BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sla_start_at TIMESTAMPTZ;

-- 2. Tambah kolom soft delete & edit pada tabel answers
ALTER TABLE public.answers
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS deleted_by VARCHAR(100),
ADD COLUMN IF NOT EXISTS is_edited BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ;

-- 3. Perbarui Enum / Constraint status pada tabel questions (jika constraint ada)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage 
        WHERE table_name = 'questions' AND constraint_name = 'questions_status_check'
    ) THEN
        ALTER TABLE public.questions DROP CONSTRAINT questions_status_check;
        ALTER TABLE public.questions ADD CONSTRAINT questions_status_check 
        CHECK (status IN (
            'menunggu_lksdm', 
            'ditangani_lksdm', 
            'dialihkan_ke_pusat', 
            'selesai', 
            'dibatalkan',
            'antrean_luar_jam_kerja',
            'tiket_mandiri_lksdm'
        ));
    END IF;
END $$;

-- 4. Indeks performa untuk pengecekan kuota tiket aktif dan filter jam operasional
CREATE INDEX IF NOT EXISTS idx_questions_user_active_quota 
ON public.questions(user_id, status) 
WHERE is_deleted = FALSE;

CREATE INDEX IF NOT EXISTS idx_questions_is_off_hours 
ON public.questions(is_off_hours);

CREATE INDEX IF NOT EXISTS idx_answers_question_deleted 
ON public.answers(question_id, is_deleted);
