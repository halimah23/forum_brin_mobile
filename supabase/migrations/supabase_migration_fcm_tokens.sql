-- Migrasi Penambahan Tabel user_fcm_tokens untuk Push Notification FCM
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL REFERENCES public.users(id_user) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_type VARCHAR(20) DEFAULT 'android',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_user_fcm UNIQUE (user_id, fcm_token)
);

CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON public.user_fcm_tokens(user_id);

ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anon and auth user_fcm_tokens" 
ON public.user_fcm_tokens 
FOR ALL TO anon, authenticated 
USING (true) 
WITH CHECK (true);
