-- ============================================================
-- MIGRASI FITUR ESENSIAL HELPDESK BOSDM CONNECT
-- 1. Penambahan Kolom Lampiran Berkas, SLA & CSAT Rating pada questions
-- 2. Pembuatan Tabel notifications untuk In-App Notification Center
-- ============================================================

-- 1. Kolom tambahan pada tabel questions
ALTER TABLE public.questions
  ADD COLUMN IF NOT EXISTS attachment_url TEXT,
  ADD COLUMN IF NOT EXISTS attachment_name TEXT,
  ADD COLUMN IF NOT EXISTS rating INT CHECK (rating >= 1 AND rating <= 5),
  ADD COLUMN IF NOT EXISTS rating_feedback TEXT,
  ADD COLUMN IF NOT EXISTS rating_submitted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;

-- 2. Pembuatan tabel notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  question_id BIGINT REFERENCES public.questions(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'status_update', -- 'disposisi', 'jawaban_baru', 'tiket_selesai'
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index untuk mempercepat query notifikasi user
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Policy RLS
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own notification read status" ON public.notifications;
CREATE POLICY "Users can update their own notification read status"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Staff and system can insert notifications" ON public.notifications;
CREATE POLICY "Staff and system can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (true);
