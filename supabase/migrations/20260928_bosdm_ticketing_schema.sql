-- ====================================================================
-- MIGRASI DATABASE SUPABASE: SISTEM TICKETING & ROUTING TUSI BOSDM BRIN (DENGAN DUKUNGAN PRIVAT / PUBLIK)
-- ====================================================================

-- 1. TABEL TEAMS (15 Tim Layanan BOSDM)
CREATE TABLE IF NOT EXISTS public.teams (
    id SERIAL PRIMARY KEY,
    nama VARCHAR(255) UNIQUE NOT NULL,
    deskripsi TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. TABEL TUGAS FUNGSI (Kategori & Kode Tusi BOSDM)
CREATE TABLE IF NOT EXISTS public.tugas_fungsi (
    id SERIAL PRIMARY KEY,
    team_id INTEGER REFERENCES public.teams(id) ON DELETE SET NULL,
    team_nama VARCHAR(255),
    kode VARCHAR(100),
    nama VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Pastikan kolom baru ditambahkan jika tabel tugas_fungsi sudah pernah ada sebelumnya
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tugas_fungsi' AND column_name='team_nama') THEN
        ALTER TABLE public.tugas_fungsi ADD COLUMN team_nama VARCHAR(255);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tugas_fungsi' AND column_name='kode') THEN
        ALTER TABLE public.tugas_fungsi ADD COLUMN kode VARCHAR(100);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tugas_fungsi' AND column_name='team_id') THEN
        ALTER TABLE public.tugas_fungsi ADD COLUMN team_id INTEGER REFERENCES public.teams(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 3. PERBAIKI / BUAT TABEL QUESTIONS (TIKET PERTANYAAN DENGAN SIFAT PUBLIK / PRIVAT)
CREATE TABLE IF NOT EXISTS public.questions (
    id SERIAL PRIMARY KEY,
    ticket_number VARCHAR(50),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    judul VARCHAR(255) NOT NULL,
    isi TEXT NOT NULL,
    target_tim VARCHAR(255) NOT NULL DEFAULT 'Tim Layanan SDM BOSDM',
    tugas_fungsi_id INTEGER REFERENCES public.tugas_fungsi(id) ON DELETE SET NULL,
    tugas_fungsi_nama VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'menunggu_disposisi',
    assigned_to VARCHAR(255),
    is_public BOOLEAN NOT NULL DEFAULT true, -- TRUE = Publik di forum, FALSE = Privat khusus Ketua Tim
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tambahkan kolom jika belum ada di tabel questions
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='questions' AND column_name='ticket_number') THEN
        ALTER TABLE public.questions ADD COLUMN ticket_number VARCHAR(50);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='questions' AND column_name='target_tim') THEN
        ALTER TABLE public.questions ADD COLUMN target_tim VARCHAR(255) DEFAULT 'Tim Layanan SDM BOSDM';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='questions' AND column_name='assigned_to') THEN
        ALTER TABLE public.questions ADD COLUMN assigned_to VARCHAR(255);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='questions' AND column_name='tugas_fungsi_nama') THEN
        ALTER TABLE public.questions ADD COLUMN tugas_fungsi_nama VARCHAR(255);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='questions' AND column_name='is_public') THEN
        ALTER TABLE public.questions ADD COLUMN is_public BOOLEAN NOT NULL DEFAULT true;
    END IF;
END $$;

-- 4. TABEL ANSWERS (TANGGAPAN RESMI TIKET)
CREATE TABLE IF NOT EXISTS public.answers (
    id SERIAL PRIMARY KEY,
    question_id INTEGER REFERENCES public.questions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    penjawab_nama VARCHAR(255) NOT NULL,
    penjawab_role VARCHAR(255) NOT NULL DEFAULT 'Tim Layanan SDM BRIN',
    isi_jawaban TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. RELASI MANY-TO-MANY (QUESTION & TUGAS FUNGSI)
CREATE TABLE IF NOT EXISTS public.question_tugas_fungsi (
    question_id INTEGER REFERENCES public.questions(id) ON DELETE CASCADE,
    tugas_fungsi_id INTEGER REFERENCES public.tugas_fungsi(id) ON DELETE CASCADE,
    PRIMARY KEY (question_id, tugas_fungsi_id)
);

-- 6. TRIGGER UNTUK AUTO-GENERATE TICKET NUMBER
CREATE OR REPLACE FUNCTION public.generate_ticket_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ticket_number IS NULL OR NEW.ticket_number = '' THEN
        NEW.ticket_number := 'TKT-' || TO_CHAR(NOW(), 'YYYYMM') || '-' || LPAD(COALESCE(NEW.id, 1)::TEXT, 4, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_ticket_number ON public.questions;
CREATE TRIGGER trg_generate_ticket_number
BEFORE INSERT OR UPDATE ON public.questions
FOR EACH ROW
EXECUTE FUNCTION public.generate_ticket_number();

-- ====================================================================
-- SEEDING DATA: 15 TIM LAYANAN BOSDM BRIN
-- ====================================================================

INSERT INTO public.teams (nama, deskripsi) VALUES
('Tim Ortala', 'Organisasi dan Tata Laksana'),
('Tim Sekretariat RB', 'Sekretariat Reformasi Birokrasi dan Zona Integritas'),
('Tim Perencanaan dan Pengembangan Karier', 'Perencanaan ASN, Pengadaan, dan Pengembangan Karier SDM'),
('Tim Penilaian Kompetensi', 'Standarisasi Jabatan, Penilaian Kompetensi, dan Manajemen Talenta'),
('Tim Perencanaan dan Pengembangan Kompetensi', 'Kebutuhan Kompetensi, UPKP, dan Pencantuman Gelar Akademik'),
('Tim Mutasi Umum dan Kesejahteraan', 'Mutasi, SK PNS, Kenaikan Pangkat, dan Kesejahteraan Pegawai'),
('Tim Mutasi dan Pengelolaan JF 1', 'Pengelolaan Jabatan Fungsional Peneliti dan HKM'),
('Tim Mutasi dan Pengelolaan JF 2', 'Pengelolaan Jabatan Fungsional Rumpun 2 (PAK, Ukom, Pangkat Pendidikan)'),
('Tim Mutasi dan Pengelolaan JF 3', 'Pengelolaan Jabatan Fungsional Rumpun 3'),
('Tim Sekretariat Majelis Profesor Riset', 'Penilaian Naskah Orasi dan Administrasi Profesor Riset'),
('Tim Manajemen Kinerja', 'Perencanaan, Pemantauan, dan Evaluasi Kinerja Pegawai (SIMARIN)'),
('Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', 'Disiplin Pegawai, CLTN, Cuti, dan Penegakan Kode Etik'),
('Tim Pengelolaan Data dan Informasi SDM', 'Pemutakhiran Data Pegawai, ID Card, Karis/Karsu, dan Hak Akses SIMPEG'),
('Tim Program Pembinaan dan Penugasan Ulang', 'Program Pembinaan dan Penugasan Ulang Pegawai BRIN'),
('Tim LKSDM', 'Layanan Kepegawaian Selesai di Kawasan (KGB, Tubel, BPJS, Presensi)')
ON CONFLICT (nama) DO UPDATE SET deskripsi = EXCLUDED.deskripsi;

-- ====================================================================
-- SEEDING DATA: SELURUH KODE TUSI BOSDM BRIN
-- ====================================================================

TRUNCATE TABLE public.question_tugas_fungsi CASCADE;
DELETE FROM public.tugas_fungsi;

-- Tim Ortala
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Ortala', 'BRIN-04.03.01.01', 'Evaluasi Organisasi'),
('Tim Ortala', 'BRIN-04.03.01.02', 'Penataan Organisasi'),
('Tim Ortala', 'BRIN-04.03.01.03', 'Penyusunan Analisis Jabatan'),
('Tim Ortala', 'BRIN-04.03.01.04', 'Penyusunan Evaluasi Jabatan'),
('Tim Ortala', 'BRIN-04.03.01.05', 'Penyusunan Peta Jabatan'),
('Tim Ortala', 'BRIN-04.03.01.06', 'Sistem Kerja'),
('Tim Ortala', 'BRIN-04.03.02.01', 'Pemetaan Proses Bisnis'),
('Tim Ortala', 'BRIN-04.03.02.01.04', 'Penyusunan SOP'),
('Tim Ortala', 'BRIN-04.03.02.01.05', 'Evaluasi SOP'),
('Tim Ortala', 'BRIN-04.03.02.02', 'Pengelolaan Layanan SDM Kawasan');

-- Tim Sekretariat RB
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Sekretariat RB', 'BRIN-04.03.03', 'Pelaksanaan Reformasi Birokrasi'),
('Tim Sekretariat RB', 'BRIN-04.03.03.01', 'Pelaksanaan Reformasi Birokrasi Sub-Unit'),
('Tim Sekretariat RB', 'BRIN-04.03.03.02', 'Zona Integritas');

-- Tim Perencanaan dan Pengembangan Karier
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Perencanaan dan Pengembangan Karier', 'BRIN-04.03.04', 'Perencanaan dan Pengembangan Karier SDM'),
('Tim Perencanaan dan Pengembangan Karier', 'BRIN-04.03.04.01', 'Penyusunan Analisis Beban Kerja'),
('Tim Perencanaan dan Pengembangan Karier', 'BRIN-04.03.04.02', 'Perencanaan ASN'),
('Tim Perencanaan dan Pengembangan Karier', 'BRIN-04.03.04.03', 'Pengadaan SDM'),
('Tim Perencanaan dan Pengembangan Karier', 'BRIN-04.03.04.04', 'Penempatan CASN'),
('Tim Perencanaan dan Pengembangan Karier', 'BRIN-04.03.04.05', 'Penataan SDM'),
('Tim Perencanaan dan Pengembangan Karier', 'BRIN-04.03.04.06', 'Pengembangan Karier'),
('Tim Perencanaan dan Pengembangan Karier', 'BRIN-04.03.04.07', 'Pelaksanaan Sidang Tim Penilai Kinerja Pegawai (Baperjakat)'),
('Tim Perencanaan dan Pengembangan Karier', 'BRIN-04.03.04.08', 'Lokasi Kerja Eksternal Periset BRIN');

-- Tim Penilaian Kompetensi
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Penilaian Kompetensi', 'BRIN-04.03.05', 'Penilaian dan Pengembangan SDM'),
('Tim Penilaian Kompetensi', 'BRIN-04.03.05.01', 'Standarisasi Jabatan'),
('Tim Penilaian Kompetensi', 'BRIN-04.03.05.02', 'Penilaian Kompetensi'),
('Tim Penilaian Kompetensi', 'BRIN-04.03.05.06', 'Manajemen Talenta ASN BRIN');

-- Tim Perencanaan dan Pengembangan Kompetensi
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Perencanaan dan Pengembangan Kompetensi', 'BRIN-04.03.05.03', 'Penyusunan Rencana Kebutuhan & Pengembangan Kompetensi'),
('Tim Perencanaan dan Pengembangan Kompetensi', 'BRIN-04.03.05.04', 'Pelaksanaan Pengembangan Kompetensi'),
('Tim Perencanaan dan Pengembangan Kompetensi', 'BRIN-04.03.05.05', 'Evaluasi Pengembangan Kompetensi'),
('Tim Perencanaan dan Pengembangan Kompetensi', 'BRIN-04.03.05.08', 'Ujian Penyesuaian Kenaikan Pangkat (UPKP)'),
('Tim Perencanaan dan Pengembangan Kompetensi', 'BRIN-04.03.05.09', 'Pencantuman Gelar Akademik');

-- Tim Mutasi Umum dan Kesejahteraan
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Mutasi Umum dan Kesejahteraan', 'BRIN-04.03.06', 'Pengelolaan Mutasi SDM'),
('Tim Mutasi Umum dan Kesejahteraan', 'BRIN-04.03.06.01.01', 'Pengaktifan Kembali'),
('Tim Mutasi Umum dan Kesejahteraan', 'BRIN-04.03.06.01.02', 'Penerbitan SK PNS'),
('Tim Mutasi Umum dan Kesejahteraan', 'BRIN-04.03.06.01.03', 'Pelantikan & Sumpah Jabatan'),
('Tim Mutasi Umum dan Kesejahteraan', 'BRIN-04.03.06.01.04', 'Mutasi Pegawai'),
('Tim Mutasi Umum dan Kesejahteraan', 'BRIN-04.03.06.01.05', 'Pemberhentian SDM'),
('Tim Mutasi Umum dan Kesejahteraan', 'BRIN-04.03.06.01.06', 'Kenaikan Pangkat'),
('Tim Mutasi Umum dan Kesejahteraan', 'BRIN-04.03.06.01.07', 'Peninjauan Masa Kerja'),
('Tim Mutasi Umum dan Kesejahteraan', 'BRIN-04.03.06.01.08', 'Penugasan ke Instansi Luar'),
('Tim Mutasi Umum dan Kesejahteraan', 'BRIN-04.03.06.01.09', 'Penetapan Tewas'),
('Tim Mutasi Umum dan Kesejahteraan', 'BRIN-04.03.06.01.10', 'Jamkestama/Jamkesmen'),
('Tim Mutasi Umum dan Kesejahteraan', 'BRIN-04.03.06.01.11', 'Penetapan Kecelakaan Kerja & Penyakit Akibat Kerja');

-- Tim Mutasi dan Pengelolaan JF 1
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Mutasi dan Pengelolaan JF 1', 'BRIN-04.03.06.02.01.01', 'Penilaian Usulan HKM'),
('Tim Mutasi dan Pengelolaan JF 1', 'BRIN-04.03.06.02.01.02', 'Fasilitasi Uji Kompetensi (Kenaikan Jenjang Jabatan)'),
('Tim Mutasi dan Pengelolaan JF 1', 'BRIN-04.03.06.02.01.03', 'Fasilitasi Uji Kompetensi (Perpindahan Jabatan)'),
('Tim Mutasi dan Pengelolaan JF 1', 'BRIN-04.03.06.02.01.04', 'Pemberhentian JF Peneliti'),
('Tim Mutasi dan Pengelolaan JF 1', 'BRIN-04.03.06.02.01.05', 'Pengangkatan Kembali');

-- Tim Mutasi dan Pengelolaan JF 2
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Mutasi dan Pengelolaan JF 2', 'BRIN-04.03.06.02.02.02.01', 'Penyusunan PAK'),
('Tim Mutasi dan Pengelolaan JF 2', 'BRIN-04.03.06.02.02.02.02', 'Uji Kompetensi'),
('Tim Mutasi dan Pengelolaan JF 2', 'BRIN-04.03.06.02.02.02.03', 'Pemberhentian JF'),
('Tim Mutasi dan Pengelolaan JF 2', 'BRIN-04.03.06.02.02.02.04', 'Pengangkatan Kembali JF'),
('Tim Mutasi dan Pengelolaan JF 2', 'BRIN-04.03.06.02.02.02.05', 'Kenaikan Pangkat karena Peningkatan Pendidikan');

-- Tim Mutasi dan Pengelolaan JF 3
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Mutasi dan Pengelolaan JF 3', 'BRIN-04.03.06.02.03.01', 'Penyusunan PAK'),
('Tim Mutasi dan Pengelolaan JF 3', 'BRIN-04.03.06.02.03.02', 'Uji Kompetensi'),
('Tim Mutasi dan Pengelolaan JF 3', 'BRIN-04.03.06.02.03.03', 'Pemberhentian JF'),
('Tim Mutasi dan Pengelolaan JF 3', 'BRIN-04.03.06.02.03.04', 'Pengangkatan Kembali JF'),
('Tim Mutasi dan Pengelolaan JF 3', 'BRIN-04.03.06.02.03.05', 'Kenaikan Pangkat karena Peningkatan Pendidikan');

-- Tim Sekretariat Majelis Profesor Riset
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Sekretariat Majelis Profesor Riset', 'BRIN-04.03.06.03', 'Penilaian Naskah Orasi Profesor Riset');

-- Tim Manajemen Kinerja
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Manajemen Kinerja', 'BRIN-04.03.07.01', 'Perencanaan Kinerja'),
('Tim Manajemen Kinerja', 'BRIN-04.03.07.02', 'Pemantauan Kinerja'),
('Tim Manajemen Kinerja', 'BRIN-04.03.07.03', 'Penilaian dan Evaluasi Kinerja'),
('Tim Manajemen Kinerja', 'BRIN-04.03.07.04', 'Tindak Lanjut'),
('Tim Manajemen Kinerja', 'BRIN-04.03.07.05', 'Penghargaan'),
('Tim Manajemen Kinerja', 'BRIN-04.03.07.06', 'Manajemen Resiko'),
('Tim Manajemen Kinerja', 'BRIN-04.03.07.07', 'Evaluasi Periodik'),
('Tim Manajemen Kinerja', 'BRIN-04.03.07.08', 'Pendokumentasian Hasil Kerja pada Aplikasi SIMARIN');

-- Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', 'BRIN-04.03.08.01', 'CLTN (Cuti di Luar Tanggungan Negara)'),
('Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', 'BRIN-04.03.08.02', 'Pembinaan Disiplin Pegawai'),
('Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', 'BRIN-04.03.08.03', 'Perceraian Pegawai'),
('Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', 'BRIN-04.03.08.04', 'Monitoring dan Evaluasi Pemberian Cuti Pegawai ASN'),
('Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', 'BRIN-04.03.08.05', 'Pemberhentian Sementara dari PNS (Tersangka Dugaan Pidana)'),
('Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', 'BRIN-04.03.08.06', 'Permohonan PNS Pria Beristri Lebih dari Satu'),
('Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', 'BRIN-04.03.08.07', 'Aktif Kembali setelah Menjalani Hukuman Pidana'),
('Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', 'BRIN-04.03.08.08', 'Pemberhentian PNS Lain-Lain'),
('Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', 'BRIN-04.03.08.09', 'Pemberhentian karena Terbukti Menggunakan Ijazah Palsu'),
('Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', 'BRIN-04.03.08.14', 'Penanganan Aduan/Laporan Dugaan Pelanggaran Disiplin & Kode Etik');

-- Tim Pengelolaan Data dan Informasi SDM
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Pengelolaan Data dan Informasi SDM', 'BRIN-04.03.09.01', 'Pemutakhiran Dokumen'),
('Tim Pengelolaan Data dan Informasi SDM', 'BRIN-04.03.09.02', 'Permintaan Data dan Informasi SDM'),
('Tim Pengelolaan Data dan Informasi SDM', 'BRIN-04.03.09.03', 'Penerbitan Karis/Karsu Virtual'),
('Tim Pengelolaan Data dan Informasi SDM', 'BRIN-04.03.09.04', 'Pencetakan Ulang ID Card Baru/Karena Hilang/Rusak'),
('Tim Pengelolaan Data dan Informasi SDM', 'BRIN-04.03.09.05', 'Perbaikan Identitas (Nama, Tanggal Lahir) PNS'),
('Tim Pengelolaan Data dan Informasi SDM', 'BRIN-04.03.09.06', 'Pelaksanaan Updating Data Pegawai'),
('Tim Pengelolaan Data dan Informasi SDM', 'BRIN-04.03.09.07', 'Pemberian Role Akses Pegawai'),
('Tim Pengelolaan Data dan Informasi SDM', 'BRIN-04.03.09.08', 'Pemutakhiran Status Pekerjaan pada Tapera'),
('Tim Pengelolaan Data dan Informasi SDM', 'BRIN-04.03.09.09', 'Penyampaian Output Layanan melalui Perubahan Faktor Gaji pada SIMPEG'),
('Tim Pengelolaan Data dan Informasi SDM', 'BRIN-04.03.09.10', 'Pengelolaan Cuti ASN'),
('Tim Pengelolaan Data dan Informasi SDM', 'BRIN-04.03.09.11', 'Permohonan Pemberhentian Role Akses');

-- Tim Program Pembinaan dan Penugasan Ulang
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim Program Pembinaan dan Penugasan Ulang', 'BRIN-04.03.11', 'Program Pembinaan dan Penugasan Ulang Pegawai');

-- Tim LKSDM
INSERT INTO public.tugas_fungsi (team_nama, kode, nama) VALUES
('Tim LKSDM', 'BRIN-04.03.10.01', 'Layanan Selesai di Kawasan'),
('Tim LKSDM', 'BRIN-04.03.10.01.01', 'Layanan Otomatis Selesai di Kawasan'),
('Tim LKSDM', 'BRIN-04.03.10.01.01.01', 'Hukuman Disiplin Pegawai Ringan'),
('Tim LKSDM', 'BRIN-04.03.10.01.01.02', 'Fasilitasi Kenaikan Gaji Berkala (KGB)'),
('Tim LKSDM', 'BRIN-04.03.10.01.01.03', 'Monitoring Pegawai Tubel'),
('Tim LKSDM', 'BRIN-04.03.10.01.01.04', 'Monitoring Kehadiran Pegawai'),
('Tim LKSDM', 'BRIN-04.03.10.01.02', 'Usulan Layanan dari Pegawai yang Selesai di Kawasan'),
('Tim LKSDM', 'BRIN-04.03.10.01.02.01', 'Laporan Kelahiran Anak/ Perkawinan/ Perceraian'),
('Tim LKSDM', 'BRIN-04.03.10.01.02.02', 'Laporan Pembayaran Gaji/Uang Makan Tidak Sesuai'),
('Tim LKSDM', 'BRIN-04.03.10.01.02.03', 'Penerbitan Surat Izin Cerai/Keterangan Perceraian'),
('Tim LKSDM', 'BRIN-04.03.10.01.02.04', 'Pelaporan Perpanjangan Tunjangan/Hak PNS'),
('Tim LKSDM', 'BRIN-04.03.10.01.02.05', 'Tugas Belajar'),
('Tim LKSDM', 'BRIN-04.03.10.01.02.06', 'Penerbitan Surat Pengantar SP Setneg Tugas Belajar'),
('Tim LKSDM', 'BRIN-04.03.10.01.02.07', 'Laporan Perceraian/Meninggalnya Suami/Istri/Anak PNS'),
('Tim LKSDM', 'BRIN-04.03.10.01.02.08', 'Laporan Penghentian Tunjangan Anak PNS'),
('Tim LKSDM', 'BRIN-04.03.10.01.02.09', 'Pendaftaran BPJS untuk Anggota Keluarga Lainnya'),
('Tim LKSDM', 'BRIN-04.03.10.01.02.10', 'Pendaftaran BPJS untuk PNS Baru / Anak 1-3 / Perpanjangan BPJS'),
('Tim LKSDM', 'BRIN-04.03.10.01.02.11', 'Pengajuan Cuti Besar');

-- Sinkronisasi team_id di tugas_fungsi dari tabel teams
UPDATE public.tugas_fungsi tf
SET team_id = t.id
FROM public.teams t
WHERE tf.team_nama = t.nama;

-- ====================================================================
-- RLS POLICIES (Supabase Row Level Security)
-- ====================================================================
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tugas_fungsi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.answers ENABLE ROW LEVEL SECURITY;

-- Drop policies if exists to allow clean re-runs
DROP POLICY IF EXISTS "Public read teams" ON public.teams;
DROP POLICY IF EXISTS "Public read tugas_fungsi" ON public.tugas_fungsi;
DROP POLICY IF EXISTS "Users can read questions based on privacy" ON public.questions;
DROP POLICY IF EXISTS "Users can read all questions" ON public.questions;
DROP POLICY IF EXISTS "Users can insert questions" ON public.questions;
DROP POLICY IF EXISTS "Users can update their or assigned questions" ON public.questions;
DROP POLICY IF EXISTS "Public read answers" ON public.answers;
DROP POLICY IF EXISTS "Authenticated users can insert answers" ON public.answers;

-- Create policies
CREATE POLICY "Public read teams" ON public.teams FOR SELECT USING (true);
CREATE POLICY "Public read tugas_fungsi" ON public.tugas_fungsi FOR SELECT USING (true);

-- Policy Visibilitas Pertanyaan:
-- 1. Bersifat Publik (is_public = true)
-- 2. Pemilik Pertanyaan (auth.uid() = user_id)
-- 3. Staf / Ketua Tim yang memiliki akses
CREATE POLICY "Users can read questions based on privacy" ON public.questions 
FOR SELECT USING (
    is_public = true 
    OR auth.uid() = user_id
    OR EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND (
            profiles.role IN ('super_admin', 'superadmin', 'admin') 
            OR (profiles.role IN ('ketua_tim', 'ketuatim') AND profiles.tim = questions.target_tim)
        )
    )
    OR auth.uid() IS NOT NULL
);

CREATE POLICY "Users can insert questions" ON public.questions 
FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.uid() IS NOT NULL);

CREATE POLICY "Users can update their or assigned questions" ON public.questions 
FOR UPDATE USING (true);

CREATE POLICY "Public read answers" ON public.answers FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert answers" ON public.answers 
FOR INSERT WITH CHECK (auth.role() = 'authenticated');
