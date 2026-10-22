-- MIGRATION: PHOTO PROFILE & CHAT BUBBLE ATTACHMENTS
-- Tanggal: 22 Oktober 2026

-- 1. Tambah kolom photo_url pada tabel users dan profiles
ALTER TABLE IF EXISTS public.users
  ADD COLUMN IF NOT EXISTS photo_url TEXT;

ALTER TABLE IF EXISTS public.profiles
  ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- 2. Tambah kolom pendukung lampiran dan pengirim pada tabel answers
ALTER TABLE IF EXISTS public.answers
  ADD COLUMN IF NOT EXISTS attachment_url TEXT,
  ADD COLUMN IF NOT EXISTS attachment_name TEXT,
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
