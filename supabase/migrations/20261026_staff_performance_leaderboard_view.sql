-- ====================================================================
-- MIGRASI DATABASE SUPABASE: VIEW LEADERBOARD KINERJA PETUGAS & STAF ADMIN
-- ====================================================================

-- 1. Buat / Perbarui View Dinamis untuk Leaderboard Kinerja Petugas
CREATE OR REPLACE VIEW public.view_staff_performance_leaderboard AS
WITH official_answers AS (
  SELECT 
    a.question_id,
    a.user_id,
    COALESCE(p.name, a.sender_name, a.penjawab_nama, 'Petugas Layanan') AS staff_name,
    COALESCE(p.role::text, a.sender_role, a.penjawab_role, 'Staf Layanan SDM') AS role,
    COALESCE(p.tim, p.unit, q.lksdm_kawasan, q.target_tim_pusat, 'Layanan SDM BRIN') AS team_or_lksdm,
    a.created_at AS answered_at,
    q.created_at AS question_created_at,
    q.rating,
    q.status,
    ROW_NUMBER() OVER (
      PARTITION BY a.question_id, COALESCE(a.user_id::text, a.sender_name, a.penjawab_nama) 
      ORDER BY a.created_at ASC
    ) AS ans_seq
  FROM public.answers a
  JOIN public.questions q ON a.question_id = q.id
  LEFT JOIN public.profiles p ON a.user_id = p.id
  WHERE 
    (
      a.sender_role IN ('admin_lksdm', 'admin_pusat', 'ketua_tim', 'admin', 'super_admin')
      OR a.penjawab_role ILIKE '%admin%' 
      OR a.penjawab_role ILIKE '%staf%' 
      OR a.penjawab_role ILIKE '%ketua%'
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

-- 2. Hak Akses Query
GRANT SELECT ON public.view_staff_performance_leaderboard TO authenticated;
GRANT SELECT ON public.view_staff_performance_leaderboard TO anon;
