-- ====================================================================
-- MANUAL MIGRATION: 09_auto_transition_off_hours_queue.sql
-- Proyek: BOSDM Connect (Forum BRIN Mobile)
-- Deskripsi:
--   1. Fungsi helper pengecekan jam operasional resmi BOSDM Connect:
--      Senin s/d Jumat, Pukul 08:00 s/d 16:00 WIB (Asia/Jakarta)
--   2. Fungsi proses transisi otomatis:
--      Mentransisikan tiket 'antrean_luar_jam_kerja' menjadi:
--      - 'tiket_mandiri_lksdm' (jika konsultasi mandiri staf LKSDM ke Pusat)
--      - 'menunggu_lksdm' (tiket reguler pegawai)
--      saat waktu telah memasuki jam dinas operasional resmi atau melewati sla_start_at.
--   3. One-time query update untuk menormalkan tiket yang tertahan di status antrean luar jam kerja.
-- ====================================================================

-- 1. Helper function: Memeriksa apakah waktu tertentu berada dalam jam kerja resmi (Asia/Jakarta)
CREATE OR REPLACE FUNCTION public.is_bosdm_working_hours(check_time TIMESTAMPTZ DEFAULT NOW())
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    wib_time TIMESTAMP;
    day_of_week INT;
    wib_hour INT;
BEGIN
    -- Konversi ke zona waktu WIB (UTC+7 / Asia/Jakarta)
    wib_time := check_time AT TIME ZONE 'Asia/Jakarta';
    day_of_week := EXTRACT(ISODOW FROM wib_time); -- 1 = Senin, 7 = Minggu
    wib_hour := EXTRACT(HOUR FROM wib_time);

    -- Senin s/d Jumat (1 - 5) dan jam 08:00 s/d sebelum 16:00
    IF day_of_week >= 1 AND day_of_week <= 5 AND wib_hour >= 8 AND wib_hour < 16 THEN
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$;

-- 2. Fungsi Eksekusi Transisi Tiket Antrean Luar Jam Kerja
CREATE OR REPLACE FUNCTION public.process_off_hours_ticket_transitions()
RETURNS TABLE (
    affected_count INT,
    transitioned_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INT := 0;
    v_now TIMESTAMPTZ := NOW();
    v_is_working_hours BOOLEAN;
BEGIN
    v_is_working_hours := public.is_bosdm_working_hours(v_now);

    -- Perbarui tiket yang berstatus 'antrean_luar_jam_kerja'
    WITH updated AS (
        UPDATE public.questions
        SET 
            status = CASE 
                WHEN (target_tim_pusat IS NOT NULL AND target_tim_pusat <> '' AND target_tim_pusat NOT ILIKE '%LKSDM%')
                     OR status ILIKE '%mandiri%'
                THEN 'tiket_mandiri_lksdm'
                ELSE 'menunggu_lksdm'
            END,
            updated_at = v_now
        WHERE 
            is_deleted = FALSE
            AND status IN ('antrean_luar_jam_kerja', 'luar_jam_kerja', 'off_hours')
            AND (
                -- Transisikan jika saat ini sudah dalam jam kerja resmi
                v_is_working_hours = TRUE
                -- Atau jika batas sla_start_at sudah terlewati
                OR (sla_start_at IS NOT NULL AND v_now >= sla_start_at)
            )
        RETURNING id
    )
    SELECT COUNT(*) INTO v_count FROM updated;

    RETURN QUERY SELECT v_count, v_now;
END;
$$;

-- 3. Eksekusi transisi langsung (One-Time Run) saat migrasi ini dijalankan
SELECT * FROM public.process_off_hours_ticket_transitions();

-- 4. Opsi Penjadwalan Otomatis dengan pg_cron (Aktif jika ekstensi pg_cron terinstal di Supabase)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
    ) THEN
        -- Jalankan setiap hari kerja (Senin-Jumat) pukul 08:00 WIB (01:00 UTC)
        PERFORM cron.schedule(
            'bosdm_open_off_hours_queue_morning',
            '0 1 * * 1-5',
            'SELECT public.process_off_hours_ticket_transitions();'
        );
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'pg_cron tidak aktif di database ini. Transisi runtime pada aplikasi seluler & service berjalan sebagai fallback aktif.';
END $$;
