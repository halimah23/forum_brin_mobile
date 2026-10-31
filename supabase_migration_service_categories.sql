-- ====================================================================
-- MIGRATION: Kategori Layanan Dinamis (BOSDM Connect)
-- Tanggal: 2026-10-28
-- ====================================================================

-- 1. Buat Tabel Master service_categories
CREATE TABLE IF NOT EXISTS public.service_categories (
    id SERIAL PRIMARY KEY,
    nama VARCHAR(100) NOT NULL UNIQUE,
    kode VARCHAR(50) NOT NULL UNIQUE,
    deskripsi TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Aktifkan Row Level Security (RLS)
ALTER TABLE public.service_categories ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'service_categories' 
        AND policyname = 'Allow read active service_categories for authenticated users'
    ) THEN
        CREATE POLICY "Allow read active service_categories for authenticated users" 
        ON public.service_categories FOR SELECT 
        TO authenticated 
        USING (is_active = true);
    END IF;
END $$;

-- 3. Isi 9 Data Awal Kategori Layanan Kepegawaian
INSERT INTO public.service_categories (nama, kode, deskripsi, sort_order) VALUES
('Kehadiran', 'KEHADIRAN', 'Presensi, absensi, cuti, dinas luar, dan jam kerja pegawai', 1),
('Mutasi Unit', 'MUTASI_UNIT', 'Perpindahan penempatan kerja antar unit / satuan kerja di BRIN', 2),
('Mutasi Jabatan', 'MUTASI_JABATAN', 'Pengalihan, pelantikan, penugasan, atau pergeseran jabatan', 3),
('Mutasi Golongan', 'MUTASI_GOLONGAN', 'Kenaikan pangkat dan penyesuaian ijazah / golongan ruang', 4),
('Talenta', 'TALENTA', 'Manajemen talenta, pemetaan suksesi, penilaian potensi dan kinerja', 5),
('Disiplin', 'DISIPLIN', 'Penegakan disiplin ASN, kode etik, sanksi, dan pemeriksaan integritas', 6),
('Ukom', 'UKOM', 'Uji kompetensi perpindahan jabatan fungsional atau jenjang karir', 7),
('KGB', 'KGB', 'Kenaikan Gaji Berkala pegawai berkala 2 tahunan', 8),
('Lainnya', 'LAINNYA', 'Layanan kepegawaian umum atau pertanyaan yang belum tercantum spesifik', 9)
ON CONFLICT (kode) DO UPDATE SET 
    nama = EXCLUDED.nama,
    deskripsi = EXCLUDED.deskripsi,
    sort_order = EXCLUDED.sort_order;

-- 4. Tambahkan kolom relasi kategori layanan pada tabel questions
ALTER TABLE public.questions 
ADD COLUMN IF NOT EXISTS service_category_id INT REFERENCES public.service_categories(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS kategori_layanan VARCHAR(100);

-- 5. Tambahkan indeks performa query filter
CREATE INDEX IF NOT EXISTS idx_questions_kategori_layanan ON public.questions(kategori_layanan);
CREATE INDEX IF NOT EXISTS idx_questions_service_category_id ON public.questions(service_category_id);
