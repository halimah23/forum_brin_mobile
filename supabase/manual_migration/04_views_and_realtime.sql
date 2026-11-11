-- ============================================================================
-- 04_VIEWS_AND_REALTIME.SQL
-- BOSDM CONNECT - SISTEM FORUM & LAYANAN TERPADU INSTANSI BRIN
-- Modul: Database Views (FAQ Terstandarisasi, Leaderboard Petugas) & Realtime
-- Target: Supabase PostgreSQL (Fresh / Empty Database)
-- Urutan Eksekusi: #4 (Keempat)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. VIEW: VIEW_FAQ_STANDARDIZED (Direktori Tanya Jawab Terbuka & Terbaku)
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS public.view_faq_standardized CASCADE;

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
    q.target_tim_pusat,
    q.lksdm_kawasan,
    q.tugas_fungsi_nama,
    q.is_public,
    q.is_pinned,
    q.is_anonymized,
    q.rating,
    q.created_at,
    q.updated_at,
    u.id_user AS author_id,
    CASE 
        WHEN q.is_anonymized = TRUE OR q.is_public = TRUE THEN 'Pegawai'
        ELSE COALESCE(u.first_name, 'Pegawai')
    END AS author_name,
    u.role AS author_role,
    u.satuan_kerja AS author_unit,
    u.kawasan AS author_kawasan,
    u.id_tim AS author_tim,
    COALESCE(
        (SELECT COUNT(*) FROM public.answers a WHERE a.question_id = q.id), 
        0
    ) AS total_answers
FROM public.questions q
LEFT JOIN public.users u ON q.user_id = u.id_user
WHERE q.is_public = TRUE
  AND (
    q.original_judul IS NOT NULL 
    OR q.summary_jawaban IS NOT NULL 
    OR q.is_pinned = TRUE
    OR q.status ILIKE '%selesai%'
  )
ORDER BY q.is_pinned DESC, q.created_at DESC;

COMMENT ON VIEW public.view_faq_standardized IS 'View agregasi pertanyaan publik yang telah memiliki rangkuman solusi atau distandardisasi';

-- ----------------------------------------------------------------------------
-- 2. VIEW: VIEW_STAFF_PERFORMANCE_LEADERBOARD (Peringkat Kinerja & CSAT)
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS public.view_staff_performance_leaderboard CASCADE;

CREATE OR REPLACE VIEW public.view_staff_performance_leaderboard AS
WITH official_answers AS (
    SELECT 
        a.question_id,
        a.user_id,
        COALESCE(u.first_name, a.sender_name, 'Petugas Layanan') AS staff_name,
        COALESCE(u.role, a.sender_role, 'Staf Layanan SDM') AS role,
        COALESCE(u.kawasan, q.lksdm_kawasan, q.target_tim_pusat, 'Layanan SDM BRIN') AS team_or_lksdm,
        a.created_at AS answered_at,
        q.created_at AS question_created_at,
        q.rating,
        q.status,
        ROW_NUMBER() OVER (
            PARTITION BY a.question_id, COALESCE(a.user_id, a.sender_name) 
            ORDER BY a.created_at ASC
        ) AS ans_seq
    FROM public.answers a
    JOIN public.questions q ON a.question_id = q.id
    LEFT JOIN public.users u ON a.user_id = u.id_user
    WHERE 
        (
            a.sender_role IN ('admin_lksdm', 'admin_pusat', 'ketua_tim', 'Staff Admin', 'Ketua Tim', 'Super Admin')
            OR a.sender_role_type IN ('admin_lksdm', 'admin_pusat', 'ketua_tim')
            OR a.sender_role ILIKE '%admin%' 
            OR a.sender_role ILIKE '%staf%' 
            OR a.sender_role ILIKE '%ketua%'
        )
        AND a.sender_name NOT ILIKE '%sistem%'
)
SELECT 
    user_id AS staff_id,
    staff_name,
    role,
    team_or_lksdm,
    COUNT(DISTINCT question_id) AS total_tickets_handled,
    COUNT(*) AS total_answers,
    COUNT(DISTINCT CASE WHEN status ILIKE '%selesai%' OR status = 'CLOSED' OR status = 'RESOLVED' THEN question_id END) AS total_closed_tickets,
    ROUND(COALESCE(AVG(rating) FILTER (WHERE rating IS NOT NULL AND rating > 0), 0)::numeric, 2) AS avg_rating,
    COUNT(rating) FILTER (WHERE rating IS NOT NULL AND rating > 0) AS rating_count,
    COUNT(DISTINCT CASE 
        WHEN ans_seq = 1 AND EXTRACT(EPOCH FROM (answered_at - question_created_at)) <= 7200 THEN question_id 
    END) AS gercep_count,
    ROUND(
        COALESCE(
            (COUNT(DISTINCT CASE 
                WHEN ans_seq = 1 AND EXTRACT(EPOCH FROM (answered_at - question_created_at)) <= 7200 THEN question_id 
            END)::float / NULLIF(COUNT(DISTINCT question_id), 0) * 100)::numeric, 0
        ), 1
    ) AS gercep_rate
FROM official_answers
GROUP BY user_id, staff_name, role, team_or_lksdm
ORDER BY total_tickets_handled DESC, avg_rating DESC, gercep_count DESC;

COMMENT ON VIEW public.view_staff_performance_leaderboard IS 'View statistik respon cepat (SLA) dan skor kepuasan CSAT petugas layanan';

-- Berikan izin akses SELECT pada kedua View
GRANT SELECT ON public.view_faq_standardized TO anon, authenticated;
GRANT SELECT ON public.view_staff_performance_leaderboard TO anon, authenticated;

-- ----------------------------------------------------------------------------
-- 3. SUPABASE REALTIME REPLICATION
-- ----------------------------------------------------------------------------
-- Mengaktifkan sinkronisasi data seketika (push changes via WebSocket)
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.teams;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tugas_fungsi;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.team_tusi;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.questions;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.answers;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.broadcasts;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.broadcast_recipients;
EXCEPTION
    WHEN duplicate_object THEN
        NULL; -- Lewati jika tabel sudah terdaftar dalam publikasi realtime
END $$;
