-- ============================================================================
-- 02_SCHEMA_TICKETING_AND_CHAT.SQL
-- BOSDM CONNECT - SISTEM FORUM & LAYANAN TERPADU INSTANSI BRIN
-- Modul: Layanan Tiket, Chat Thread Multi-Pihak, dan Notifikasi
-- Target: Supabase PostgreSQL (Fresh / Empty Database)
-- Catatan: Tabel dibuat kosongan (siap menerima data tiket baru)
-- Urutan Eksekusi: #2 (Kedua)
-- ============================================================================

-- Bersihkan tabel jika sebelumnya sudah pernah dibuat
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.answers CASCADE;
DROP TABLE IF EXISTS public.questions CASCADE;

-- ----------------------------------------------------------------------------
-- 1. TABEL: QUESTIONS (Tiket Pertanyaan & Layanan Kepegawaian)
-- ----------------------------------------------------------------------------
CREATE TABLE public.questions (
    id BIGSERIAL PRIMARY KEY,
    ticket_number TEXT UNIQUE,
    user_id VARCHAR(50) NOT NULL REFERENCES public.users(id_user) ON DELETE CASCADE,
    judul TEXT NOT NULL,
    isi TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'menunggu_lksdm',
    lksdm_kawasan TEXT,             -- Otomatis terdeteksi dari profil kawasan pegawai (misal: 'LKSDM 6')
    target_tim_pusat TEXT,          -- Tim Pusat yang dituju jika dieskalasi (misal: 'PKSPU', 'MUKESRA')
    id_tusi VARCHAR(50) REFERENCES public.tugas_fungsi(id_tusi) ON DELETE SET NULL,
    tugas_fungsi_nama TEXT,
    admin_lksdm_id VARCHAR(50) REFERENCES public.users(id_user) ON DELETE SET NULL,
    admin_pusat_id VARCHAR(50) REFERENCES public.users(id_user) ON DELETE SET NULL,
    is_public BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    is_anonymized BOOLEAN DEFAULT false,
    original_judul TEXT,            -- Menyimpan judul asli sebelum dibakukan oleh superadmin/staf
    original_isi TEXT,              -- Menyimpan isi asli sebelum dibakukan
    summary_jawaban TEXT,           -- Rangkuman solusi resmi untuk direktori FAQ
    attachment_url TEXT,            -- URL berkas lampiran yang diunggah ke Supabase Storage
    attachment_name TEXT,           -- Nama berkas asli lampiran
    rating INT,                     -- Skor CSAT (1-5 bintang)
    rating_feedback TEXT,           -- Ulasan / testimoni kepuasan pegawai
    rating_tags TEXT,               -- Tag kepuasan (misal: 'Cepat & Tanggap, Solutif')
    rating_submitted_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,        -- Waktu saat tiket dikonfirmasi tuntas/selesai
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.questions IS 'Tabel transaksi tiket konsultasi dan pertanyaan pegawai BRIN';

-- Indeks performa untuk kueri cepat & dashboard pelacakan
CREATE INDEX IF NOT EXISTS idx_questions_user_id ON public.questions(user_id);
CREATE INDEX IF NOT EXISTS idx_questions_status ON public.questions(status);
CREATE INDEX IF NOT EXISTS idx_questions_lksdm_kawasan ON public.questions(lksdm_kawasan);
CREATE INDEX IF NOT EXISTS idx_questions_target_tim_pusat ON public.questions(target_tim_pusat);
CREATE INDEX IF NOT EXISTS idx_questions_is_public ON public.questions(is_public);
CREATE INDEX IF NOT EXISTS idx_questions_is_pinned ON public.questions(is_pinned);
CREATE INDEX IF NOT EXISTS idx_questions_created_at ON public.questions(created_at DESC);

-- ----------------------------------------------------------------------------
-- 2. TABEL: ANSWERS (Bubble Chat Thread & Pesan Multi-Pihak)
-- ----------------------------------------------------------------------------
CREATE TABLE public.answers (
    id BIGSERIAL PRIMARY KEY,
    question_id BIGINT NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    user_id VARCHAR(50) REFERENCES public.users(id_user) ON DELETE SET NULL,
    sender_name TEXT NOT NULL,
    sender_role TEXT NOT NULL,
    sender_role_type TEXT,          -- 'pegawai', 'admin_lksdm', 'admin_pusat', 'ketua_tim', 'system'
    isi_pesan TEXT NOT NULL,
    attachment_url TEXT,            -- Lampiran dalam percakapan chat
    attachment_name TEXT,
    sender_photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.answers IS 'Tabel thread percakapan tiga pihak antara Pegawai, Tim LKSDM, dan Tim Pusat';

CREATE INDEX IF NOT EXISTS idx_answers_question_id ON public.answers(question_id);
CREATE INDEX IF NOT EXISTS idx_answers_user_id ON public.answers(user_id);
CREATE INDEX IF NOT EXISTS idx_answers_created_at ON public.answers(created_at ASC);

-- ----------------------------------------------------------------------------
-- 3. TABEL: NOTIFICATIONS (Pemberitahuan Lonceng Real-Time Aplikasi)
-- ----------------------------------------------------------------------------
CREATE TABLE public.notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL REFERENCES public.users(id_user) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'status_update', -- 'status_update', 'chat_reply', 'escalation', 'broadcast'
    question_id BIGINT REFERENCES public.questions(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.notifications IS 'Tabel notifikasi in-app untuk pembaruan status tiket dan pesan baru';

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- ----------------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ----------------------------------------------------------------------------
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Kebijakan Akses Questions
DROP POLICY IF EXISTS "Allow read questions" ON public.questions;
CREATE POLICY "Allow read questions" ON public.questions 
    FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow write questions" ON public.questions;
CREATE POLICY "Allow write questions" ON public.questions 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- Kebijakan Akses Answers
DROP POLICY IF EXISTS "Allow read answers" ON public.answers;
CREATE POLICY "Allow read answers" ON public.answers 
    FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow write answers" ON public.answers;
CREATE POLICY "Allow write answers" ON public.answers 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- Kebijakan Akses Notifications
DROP POLICY IF EXISTS "Allow read notifications" ON public.notifications;
CREATE POLICY "Allow read notifications" ON public.notifications 
    FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow write notifications" ON public.notifications;
CREATE POLICY "Allow write notifications" ON public.notifications 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
