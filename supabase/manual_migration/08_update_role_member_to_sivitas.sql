-- ============================================================================
-- SCRIPT PEMBARUAN ROLE: 'Member' / 'Pegawai' -> 'Sivitas' DI SUPABASE
-- ============================================================================
-- Jalankan query ini di SQL Editor dashboard Supabase Anda.
-- Script ini aman (idempotent), memeriksa keberadaan tabel sebelum eksekusi,
-- serta memperbarui seluruh tabel master, pesan chat/tiket, profil, dan Auth.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. UPDATE TABEL UTAMA: public.users
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') THEN
    -- Update data role di tabel users
    UPDATE public.users
    SET role = 'Sivitas'
    WHERE role ILIKE 'member' OR role ILIKE 'pegawai';

    RAISE NOTICE 'Berhasil memperbarui role di public.users menjadi Sivitas.';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 2. UPDATE TABEL: public.profiles (jika ada skema profiles lama/auth)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') THEN
    -- Hapus check constraint lama jika ada
    ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS check_valid_5_roles;
    ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

    -- Update nilai role lama menjadi 'sivitas'
    UPDATE public.profiles
    SET role = 'sivitas'
    WHERE role ILIKE 'member' OR role ILIKE 'pegawai';

    -- Tambahkan constraint baru yang mengizinkan 'sivitas'
    ALTER TABLE public.profiles ADD CONSTRAINT check_valid_5_roles 
      CHECK (role IN ('super_admin', 'admin', 'ketua_tim', 'eksekutif', 'sivitas', 'Staff Admin', 'Ketua Tim', 'Eksekutif', 'Super Admin', 'Sivitas'));

    -- Set default kolom role menjadi 'sivitas'
    ALTER TABLE public.profiles ALTER COLUMN role SET DEFAULT 'sivitas';

    RAISE NOTICE 'Berhasil memperbarui role & constraint di public.profiles.';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 3. UPDATE TRIGGER: public.handle_new_user() (Supabase Auth Register)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') THEN
    CREATE OR REPLACE FUNCTION public.handle_new_user()
    RETURNS trigger AS $fn$
    BEGIN
      INSERT INTO public.profiles (id, email, name, role, unit, tim, jabatan)
      VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
        COALESCE(new.raw_user_meta_data->>'role', 'sivitas'),
        COALESCE(new.raw_user_meta_data->>'unit', 'BRIN'),
        COALESCE(new.raw_user_meta_data->>'tim', 'Umum'),
        COALESCE(new.raw_user_meta_data->>'jabatan', 'Sivitas')
      )
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        role = EXCLUDED.role,
        unit = EXCLUDED.unit,
        tim = EXCLUDED.tim,
        jabatan = EXCLUDED.jabatan;
      RETURN new;
    END;
    $fn$ LANGUAGE plpgsql SECURITY DEFINER;

    RAISE NOTICE 'Trigger function handle_new_user() diperbarui dengan default role sivitas.';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 4. UPDATE HISTORI PESAN & JAWABAN TIKET (public.answers & public.ticket_messages)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  -- Tabel answers
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'answers') THEN
    UPDATE public.answers
    SET sender_role = 'Sivitas'
    WHERE sender_role ILIKE 'member' OR sender_role ILIKE 'pegawai';

    IF EXISTS (
      SELECT FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'answers' AND column_name = 'sender_role_type'
    ) THEN
      UPDATE public.answers
      SET sender_role_type = 'sivitas'
      WHERE sender_role_type ILIKE 'member' OR sender_role_type ILIKE 'pegawai';
    END IF;

    RAISE NOTICE 'Histori role pada public.answers berhasil diselaraskan.';
  END IF;

  -- Tabel ticket_messages (jika ada)
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'ticket_messages') THEN
    UPDATE public.ticket_messages
    SET sender_role = 'Sivitas'
    WHERE sender_role ILIKE 'member' OR sender_role ILIKE 'pegawai';

    RAISE NOTICE 'Histori role pada public.ticket_messages berhasil diselaraskan.';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 5. UPDATE METADATA AUTH: auth.users (Jika menggunakan Auth Supabase)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'auth' AND tablename = 'users') THEN
    UPDATE auth.users
    SET raw_user_meta_data = jsonb_set(
      COALESCE(raw_user_meta_data, '{}'::jsonb), 
      '{role}', 
      '"sivitas"'
    )
    WHERE raw_user_meta_data->>'role' ILIKE 'member' 
       OR raw_user_meta_data->>'role' ILIKE 'pegawai';

    RAISE NOTICE 'Metadata role pada auth.users berhasil diselaraskan ke sivitas.';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Lewati auth.users: %', SQLERRM;
END $$;

COMMIT;

-- ----------------------------------------------------------------------------
-- 6. QUERY CEK HASIL PERUBAHAN (VERIFIKASI)
-- ----------------------------------------------------------------------------
-- Cek distribusi role saat ini di tabel public.users:
SELECT role, COUNT(*) AS jumlah_pengguna
FROM public.users
GROUP BY role
ORDER BY jumlah_pengguna DESC;
