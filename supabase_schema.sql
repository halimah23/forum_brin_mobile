-- ============================================================================
-- MIGRASI DATABASE RESMI INSTANSI BRIN (BOSDM CONNECT)
-- Standar Struktur: teams, tugas_fungsi, team_tusi, users, questions, answers, notifications
-- ============================================================================

-- 1. BERSIHKAN TABEL LAMA & BARU SECARA BERURUTAN (CASCADE)
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.answers CASCADE;
DROP TABLE IF EXISTS public.questions CASCADE;
DROP TABLE IF EXISTS public.question_tugas_fungsi CASCADE;
DROP TABLE IF EXISTS public.team_tusi CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.tugas_fungsi CASCADE;
DROP TABLE IF EXISTS public.teams CASCADE;

-- 2. BUAT STRUKTUR TABEL BARU SESUAI SOP INSTANSI

-- A. TABEL TEAMS
CREATE TABLE public.teams (
    id_tim VARCHAR(50) PRIMARY KEY,
    tim VARCHAR(100) NOT NULL,
    detail_nama_tim TEXT NOT NULL,
    coverage TEXT,
    sebaran_hbp TEXT,
    catatan TEXT,
    eskalasi VARCHAR(50) NOT NULL
);

-- B. TABEL TUGAS FUNGSI
CREATE TABLE public.tugas_fungsi (
    id_tusi VARCHAR(50) PRIMARY KEY,
    tugas_fungsi TEXT NOT NULL
);

-- C. TABEL RELASI TEAM_TUSI
CREATE TABLE public.team_tusi (
    id_tim VARCHAR(50) NOT NULL REFERENCES public.teams(id_tim) ON DELETE CASCADE,
    id_tusi VARCHAR(50) NOT NULL REFERENCES public.tugas_fungsi(id_tusi) ON DELETE CASCADE,
    PRIMARY KEY (id_tim, id_tusi)
);

-- D. TABEL USERS (PROFIL & KEPEGAWAIAN)
CREATE TABLE public.users (
    id_user VARCHAR(50) PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    external_email VARCHAR(255),
    phone VARCHAR(50),
    sex VARCHAR(20),
    satuan_kerja VARCHAR(100),
    id_tim VARCHAR(50) REFERENCES public.teams(id_tim) ON DELETE SET NULL,
    jabatan TEXT,
    kawasan VARCHAR(100),
    role VARCHAR(50) NOT NULL,
    password VARCHAR(255) DEFAULT 'Password123!',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- E. TABEL QUESTIONS (TIKET PERTANYAAN/LAYANAN)
CREATE TABLE public.questions (
    id BIGSERIAL PRIMARY KEY,
    ticket_number TEXT UNIQUE,
    user_id VARCHAR(50) NOT NULL REFERENCES public.users(id_user) ON DELETE CASCADE,
    judul TEXT NOT NULL,
    isi TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'menunggu_lksdm',
    lksdm_kawasan TEXT,
    target_tim_pusat TEXT,
    id_tusi VARCHAR(50) REFERENCES public.tugas_fungsi(id_tusi) ON DELETE SET NULL,
    tugas_fungsi_nama TEXT,
    admin_lksdm_id VARCHAR(50) REFERENCES public.users(id_user) ON DELETE SET NULL,
    admin_pusat_id VARCHAR(50) REFERENCES public.users(id_user) ON DELETE SET NULL,
    is_public BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    attachment_url TEXT,
    attachment_name TEXT,
    rating INT,
    rating_feedback TEXT,
    rating_submitted_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- F. TABEL ANSWERS (BUBBLE CHAT THREAD)
CREATE TABLE public.answers (
    id BIGSERIAL PRIMARY KEY,
    question_id BIGINT NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    user_id VARCHAR(50) REFERENCES public.users(id_user) ON DELETE SET NULL,
    sender_name TEXT NOT NULL,
    sender_role TEXT NOT NULL,
    isi_pesan TEXT NOT NULL,
    attachment_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- G. TABEL NOTIFICATIONS
CREATE TABLE public.notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL REFERENCES public.users(id_user) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    question_id BIGINT REFERENCES public.questions(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. AKTIFKAN RLS DAN KEBIJAKAN AKSES POSTGREST
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tugas_fungsi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_tusi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anon teams" ON public.teams FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon tugas_fungsi" ON public.tugas_fungsi FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon team_tusi" ON public.team_tusi FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon users" ON public.users FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon questions" ON public.questions FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon answers" ON public.answers FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon notifications" ON public.notifications FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- 4. SEED DATA RESMI: TEAMS (22 RECORDS)
INSERT INTO public.teams (id_tim, tim, detail_nama_tim, coverage, sebaran_hbp, catatan, eskalasi) VALUES
  ('tim_001', 'ORTALA', 'Organisasi dan Tata Laksana', NULL, NULL, NULL, 'PUSAT'),
  ('tim_002', 'RENBANGRIR', 'Perencanaan dan Pengembangan Karis SDM', NULL, NULL, NULL, 'PUSAT'),
  ('tim_003', 'MUKESRA', 'Mutasi Umum dan Kesejahteraan', NULL, NULL, NULL, 'PUSAT'),
  ('tim_004', 'JF1', 'Mutasi dan Pengelolaan Jabatan Fungsional I', NULL, NULL, NULL, 'PUSAT'),
  ('tim_005', 'JF2', 'Mutasi dan Pengelolaan Jabatan Fungsional II', NULL, NULL, NULL, 'PUSAT'),
  ('tim_006', 'JF3', 'Mutasi dan Pengelolaan Jabatan Fungsional III', NULL, NULL, NULL, 'PUSAT'),
  ('tim_007', 'RENBANGKOM', 'Perencanaan dan Pengembangan Kompetensi SDM', NULL, NULL, NULL, 'PUSAT'),
  ('tim_008', 'PENKOM', 'Penilaian Kompetensi', NULL, NULL, NULL, 'PUSAT'),
  ('tim_009', 'MANKIN', 'Manajemen Kinerja dan Penghargaan ASN', NULL, NULL, NULL, 'PUSAT'),
  ('tim_010', 'BINDIS', 'Pembinaan dan Penegakan Disiplin ASN', NULL, NULL, NULL, 'PUSAT'),
  ('tim_011', 'PDIS', 'Pengelolaan Data dan Informasi SDM', NULL, NULL, NULL, 'PUSAT'),
  ('tim_012', 'MPR', 'Sekretariat Majelis Profesor Riset', NULL, NULL, NULL, 'PUSAT'),
  ('tim_013', 'RB', 'Sekretariat Reformasi Birokrasi', NULL, NULL, NULL, 'PUSAT'),
  ('tim_014', 'PKSPU', 'Program Pembinaan Karir SDM dan Penugasan Ulang', NULL, NULL, NULL, 'PUSAT'),
  ('tim_015', 'LKSDM 1', 'Layanan Kawasan SDM 1: Thamrin', 'SETTAMA, PUSDATIN, INSPEKTORAT', 'KA Thamrin (Bacharuddin Jusuf Habibie)
KA Rawamangun (Harsono Wiryosumarto)
KA Gunung Sindur (Soedjono Djoened Poesponegoro)
KKB Bogor (Kusnoto Setjodiwirjo)
KKB Denpasar
KKB Magelang (Muhilal)
KKB Makassar
KPP Perumahan Serpong', 'Pengelolaan Kawasan Kerja Bersama (KKB) secara keseluruhan ditarik ke LKSDM 1', 'LKSDM'),
  ('tim_016', 'LKSDM 2', 'Layanan Kawasan SDM 2: Thamrin II', 'DKP, DKRI, DRID, DFRI, DPRI, DSDMI, SESDEP DIRI, DPAKR, DPKIRI, DPLFRKST, DPKI', 'KA Thamrin (Bacharuddin Jusuf Habibie)
KST Pasar Jumat (Gerrit Augustinus Siwabessy)
KKE Wisma Teknologi
KKE Wisma Pulau Pari
KS Ancol (Aprilani Soegiarto)
KST Cibinong', '1. Pengelolaan Kawasan Kerja Eksternal (KKE) secara keseluruhan ditarik ke LKSDM 2.
2. Pengelolaan DPLFRKST KST Cibinong ditarik ke LKSDM 2', 'LKSDM'),
  ('tim_017', 'LKSDM 3', 'Layanan Kawasan SDM 3: Gatot Subroto', 'Settama (OR + KST Gastu), DPLFRKST, OR ABASTRA, OR TPKEKM, OR IPSH', 'KST Gatot Subroto (Sarwono Prawirohardjo)
KS Pasar Minggu (Raden Pandji Soejono)
KS Ambon (Atjep Suwartana)', 'Pengelolaan SDM Settama di OR mengikuti pembagian pengelolaan OR.', 'LKSDM'),
  ('tim_018', 'LKSDM 4', 'Layanan Kawasan SDM 4: Serpong I', 'Settama di OR,  Settama KST Tanjung Bintang, DPLFRKST, KST Tanjung Bintang, OR TN, OR EM', 'KST Serpong (Bacharuddin Jusuf Habibie)
KST Tanjung Bintang (Iskandar Zulkarnain)', 'Pengelolaan SDM Settama di OR mengikuti pembagian pengelolaan OR.', 'LKSDM'),
  ('tim_019', 'LKSDM 5', 'Layanan Kawasan SDM 5: Serpong II', 'Settama (OR, Settama di luar OR (KST Serpong, KST Rumpin, KS Rancabungur, KS Tarogong), DPFK Serpong, DPLFRKST Serpong
OR NM, OR PA', 'KST Serpong (Bacharuddin Jusuf Habibie)
KST Rumpin (Jacob Salatun)
KS Rancabungur (Ibnoe Soebroto)
KS Tarogong (R. Sunaryo)', '1) Pengelolaan DPLFRKST KST Serpong dan DPFK KST Serpong berada dibawah LKSDM 5;
2) Pengelolaan SDM Settama di OR mengikuti pembagian pengelolaan OR;', 'LKSDM'),
  ('tim_020', 'LKSDM 6', 'Layanan Kawasan SDM 6: Cibinong', 'Settama (Pengelola OR + HB Cibinong), OR KES, OR HL', 'KST Cibinong (Soekarno)', '1) Pengelolaan SDM Settama di OR mengikuti pembagian pengelolaan OR;', 'LKSDM'),
  ('tim_021', 'LKSDM 7', 'Layanan Kawasan SDM 7: Bandung', 'Settama (OR + KST Cisitu), DPLFRKST, DPFK
OR EI, ORKM', 'KST Cisitu (Samaun Samadikun)
KS Subang (Muhammadi Siswosudarmo)
KS Tamansari
KSL Observatorium Nasional Gunung Timau
KSL Kebun Percobaan Anak Tuha
KSL Kebun Percobaan Cipanas
KSL Pontianak
KSL Stasiun Bumi Biak
KSL Stasiun Bumi dan Observasi Agam
KSL Stasiun Bumi Parepare
KSL Stasiun Ekskavasi Arkeologi Bumiayu
KSL Stasiun Uji Roket Pamengpeuk
KSL Tilong', '1) Pengelolaan SDM Settama di OR mengikuti pembagian pengelolaan OR;
2) Pengelolaan Kawasan Stasiun Lapangan (KSL) secara keseluruhan ditarik ke LKSDM 7', 'LKSDM'),
  ('tim_022', 'LKSDM 8', 'Layanan Kawasan SDM 8: Cibinong, Yogyakarta, Surabaya', 'POLTEKNUKLIR, Settama (OR + KSTE Babarsari, KST Gunung Kidul, KST Lombok, KST Surabaya), DPLFRKST, DPFK, DPKI, OR PP', 'KSTE Babarsari (Achmad Baiquni)
KST Gunung Kidul (Umar Anggara Jenie)
KST Lombok (Kurnaen Sumadiharga)
KST Surabaya (Said Djauharsjah Jenie)
KST Cibinong (Soekarno)
KS Mlati (Subandono Diposaptono)
KS Salatiga (M.F. Sustriayu Nalim)
KS Tawangmangu (Soetarman)
KKI Kebun Raya Bogor
KKI Kebun Raya Cibinong
KKI Kebun Raya Cibodas
KKI Kebun Raya Eka Karya
KKI Kawasan Geodiversitas (Sukendar Asikin)
KKI Kebun Raya Purwodadi', '1) Pengelolaan SDM DPKI di KST Cibinong dan SDM yang berada di Keseluruhan KKI ditarik ke pengelolaan LKSDM 8;
2) Pengelolaan SDM Settama di OR mengikuti pembagian pengelolaan OR;', 'LKSDM');

-- 5. SEED DATA RESMI: TUGAS_FUNGSI (91 RECORDS)
INSERT INTO public.tugas_fungsi (id_tusi, tugas_fungsi) VALUES
  ('ts_001', 'Melaksanakan evaluasi organisasi'),
  ('ts_002', 'Melaksanakan penataan organisasi'),
  ('ts_003', 'Melaksanakan Analisis Jabatan (Anjab)'),
  ('ts_004', 'Melaksanakan Evaluasi Jabatan (Evjab)'),
  ('ts_005', 'Menyusun Peta Jabatan'),
  ('ts_006', 'Menyusun Pola Karir'),
  ('ts_007', 'Melaksanakan penyusunan dan evaluasi Pedoman Sistem Kerja'),
  ('ts_008', 'Menyusun Proses Bisnis'),
  ('ts_009', 'Melaksanakan evaluasi Proses Bisnis'),
  ('ts_010', 'Menyusun Standar Operasional Prosedur (SOP)'),
  ('ts_011', 'Melaksanakan evaluasi SOP'),
  ('ts_012', 'Melaksanakan input dan penyesuaian Proses Bisnis di SIA SPBE'),
  ('ts_013', 'Melaksanakan pengelolaan Layanan SDM Kawasan'),
  ('ts_014', 'Melaksanakan Analisis Beban Kerja'),
  ('ts_015', 'Melaksanakan perencanaan SDM'),
  ('ts_016', 'Melaksanakan pengadaan ASN (CPNS, PPPK dan Open Call)'),
  ('ts_017', 'Melaksanakan Seleksi Terbuka JPT dan OR'),
  ('ts_018', 'Melaksanakan penempatan CASN (mutasi internal, penempatan aktif tubel, penempatan aktif CLTN)'),
  ('ts_019', 'Melaksanakan pengembangan karier (proyeksi mutasi, rotasi, promosi jabatan, konversi jabatan)'),
  ('ts_020', 'Memproses mutasi internal (pembuatan SK Penempatan)'),
  ('ts_021', 'Memproses pengaktifan kembali penugasan luar BRIN'),
  ('ts_022', 'Melaksanakan penerbitan SK PNS'),
  ('ts_023', 'Melaksanakan pelantikan dan Sumpah Jabatan'),
  ('ts_024', 'Memproses Mutasi Eksternal/Penugasan ke Instansi Luar'),
  ('ts_025', 'Memproses pemberhentian SDM'),
  ('ts_026', 'Memproses kenaikan pangkat'),
  ('ts_027', 'Memproses Peninjauan Masa Kerja'),
  ('ts_028', 'Memproses Penetapan Tewas'),
  ('ts_029', 'Melaksanakan pengurusan Jamkestama/Jasindo'),
  ('ts_030', 'Memproses Penetapan Kecelakaan Kerja dan Penetapan Penyakit Akibat Kerja'),
  ('ts_031', 'Melaksanakan penilaian usulan HKM'),
  ('ts_032', 'Memproses kenaikan jenjang jabatan'),
  ('ts_033', 'Memproses perpindahan jabatan'),
  ('ts_034', 'Memproses pengusulan dan kenaikan jenjang Peneliti Ahli Utama'),
  ('ts_035', 'Memfasilitasi Uji Kompetensi'),
  ('ts_036', 'Memproses pemberhentian JF Peneliti'),
  ('ts_037', 'Memproses pengaktifan kembali menjadi JF Peneliti'),
  ('ts_038', 'Melaksanakan pengusulan dan kenaikan jenjang Ahli Utama'),
  ('ts_039', 'Memfasilitasi Uji Kompetensi JF'),
  ('ts_040', 'Memproses pemberhentian JF'),
  ('ts_041', 'Memproses pengaktifan kembali menjadi JF'),
  ('ts_042', 'Melaksanakan penyertaan diklat'),
  ('ts_043', 'Melaksanakan pengusulan kenaikan jenjang dan/atau pangkat jabatan fungsional'),
  ('ts_044', 'Menyusun kamus kompetensi'),
  ('ts_045', 'Menyusun Rencana Pengembangan Kompetensi'),
  ('ts_046', 'Melaksanakan pengembangan kompetensi'),
  ('ts_047', 'Melaksanakan pengelolaan Tugas Belajar'),
  ('ts_048', 'Melaksanakan evaluasi pengembangan kompetensi'),
  ('ts_049', 'Melaksanakan penilaian kompetensi'),
  ('ts_050', 'Melaksanakan Manajemen Talenta'),
  ('ts_051', 'Menyusun Standar Kompetensi JPT/Kepala OR/Kepala PR/Pejabat Administrator'),
  ('ts_052', 'Memberikan bimbingan dan konseling SDM'),
  ('ts_053', 'Melaksanakan perencanaan kinerja'),
  ('ts_054', 'Melaksanakan pemantauan kinerja'),
  ('ts_055', 'Melaksanakan penilaian dan evaluasi kinerja (SK Tunjangan Kinerja)'),
  ('ts_056', 'Memproses pemberian penghargaan (SLKS, Wirakarya, Pembangunan, Bintang Jasa, Penilaian Kinerja Terbaik, ASN Berprestasi)'),
  ('ts_057', 'Melaksanakan Manajemen Risiko'),
  ('ts_058', 'Melaksanakan evaluasi periodik'),
  ('ts_059', 'Memproses CLTN'),
  ('ts_060', 'Melaksanakan pembinaan disiplin'),
  ('ts_061', 'Melaksanakan monitoring dan evaluasi pembinaan dan penegakan disiplin'),
  ('ts_062', 'Melaksanakan penanganan proses perceraian'),
  ('ts_063', 'Melaksanakan monitoring dan evaluasi pemberian cuti pegawai ASN'),
  ('ts_064', 'Memproses Pemberhentian Sementara PNS (ditahan karena menjadi tersangka tindak pidana)'),
  ('ts_065', 'Melaksanakan penegakan Kode Etik dan Perilaku Pegawai'),
  ('ts_066', 'Melaksanakan penyelesaian kasus kepegawaian (PTUN, KASN, Ombudsman, BPASN)'),
  ('ts_067', 'Melaksanakan penyelesaian LHP BPK'),
  ('ts_068', 'Melaksanakan pengelolaan Tata Naskah Pegawai'),
  ('ts_069', 'Melaksanakan pelayanan informasi'),
  ('ts_070', 'Melaksanakan perbaikan data kehadiran pegawai'),
  ('ts_071', 'Melaksanakan penerbitan Karis/Karsu'),
  ('ts_072', 'Melaksanakan updating data pegawai (inject data pegawai)'),
  ('ts_073', 'Melaksanakan sinkronisasi data pegawai (SIASN, IDIS)'),
  ('ts_074', 'Melaksanakan pemberian Role Akses Pegawai'),
  ('ts_075', 'Melaksanakan updating data Tapera'),
  ('ts_076', 'Menyelenggarakan Orasi Profesor Riset'),
  ('ts_077', 'Menyelenggarakan Sidang Penilaian Naskah Orasi'),
  ('ts_078', 'Memeriksa dan Menyesuaikan Layout Naskah Orasi'),
  ('ts_079', 'Melaksanakan Seleksi Administrasi Orasi'),
  ('ts_080', 'Menyusun Rencana Kerja RB'),
  ('ts_081', 'Menyusun Laporan Pelaksanaan RB'),
  ('ts_082', 'Menyusun Roadmap (5 tahun sekali)'),
  ('ts_083', 'Melaksanakan Monev (per triwulan)'),
  ('ts_084', 'Melaksanakan pembangunan dan pelaksanaan ZI'),
  ('ts_085', 'Melakukan pembinaan karier pada SDM yang dulunya merupakan penempatan sementara, baik dari jalur Re-entry (aktif tubel/CLTN) atau bagi SDM yang belum mendapatkan penempatan'),
  ('ts_086', 'Melaksanakan penegakan hukuman disiplin pegawai kategori ringan sampai sedang'),
  ('ts_087', 'Memfasilitasi pemrosesan kenaikan gaji berkala'),
  ('ts_088', 'Melaksanakan monitoring pegawai tugas belajar'),
  ('ts_089', 'Melaksanakan monitoring kehadiran pegawai'),
  ('ts_090', 'Melaksanakan layanan kepegawaian'),
  ('ts_091', 'Melaksanakan verifikasi layanan kepegawaian yang selesai di pusat');

-- 6. SEED DATA RESMI: TEAM_TUSI (RELASI MANY-TO-MANY)
INSERT INTO public.team_tusi (id_tim, id_tusi) VALUES
  ('tim_001', 'ts_001'),
  ('tim_001', 'ts_002'),
  ('tim_001', 'ts_003'),
  ('tim_001', 'ts_004'),
  ('tim_001', 'ts_005'),
  ('tim_001', 'ts_006'),
  ('tim_001', 'ts_007'),
  ('tim_001', 'ts_008'),
  ('tim_001', 'ts_009'),
  ('tim_001', 'ts_010'),
  ('tim_001', 'ts_011'),
  ('tim_001', 'ts_012'),
  ('tim_001', 'ts_013'),
  ('tim_002', 'ts_014'),
  ('tim_002', 'ts_015'),
  ('tim_002', 'ts_016'),
  ('tim_002', 'ts_017'),
  ('tim_002', 'ts_018'),
  ('tim_002', 'ts_019'),
  ('tim_002', 'ts_020'),
  ('tim_003', 'ts_021'),
  ('tim_003', 'ts_022'),
  ('tim_003', 'ts_023'),
  ('tim_003', 'ts_024'),
  ('tim_003', 'ts_025'),
  ('tim_003', 'ts_026'),
  ('tim_003', 'ts_027'),
  ('tim_003', 'ts_028'),
  ('tim_003', 'ts_029'),
  ('tim_003', 'ts_030'),
  ('tim_004', 'ts_031'),
  ('tim_004', 'ts_032'),
  ('tim_004', 'ts_033'),
  ('tim_004', 'ts_034'),
  ('tim_004', 'ts_035'),
  ('tim_004', 'ts_036'),
  ('tim_004', 'ts_037'),
  ('tim_005', 'ts_031'),
  ('tim_005', 'ts_032'),
  ('tim_005', 'ts_033'),
  ('tim_005', 'ts_038'),
  ('tim_005', 'ts_039'),
  ('tim_005', 'ts_040'),
  ('tim_005', 'ts_041'),
  ('tim_005', 'ts_042'),
  ('tim_006', 'ts_039'),
  ('tim_006', 'ts_040'),
  ('tim_006', 'ts_043'),
  ('tim_006', 'ts_042'),
  ('tim_007', 'ts_044'),
  ('tim_007', 'ts_045'),
  ('tim_007', 'ts_046'),
  ('tim_007', 'ts_047'),
  ('tim_007', 'ts_048'),
  ('tim_008', 'ts_049'),
  ('tim_008', 'ts_050'),
  ('tim_008', 'ts_051'),
  ('tim_008', 'ts_052'),
  ('tim_009', 'ts_053'),
  ('tim_009', 'ts_054'),
  ('tim_009', 'ts_055'),
  ('tim_009', 'ts_056'),
  ('tim_009', 'ts_057'),
  ('tim_009', 'ts_058'),
  ('tim_010', 'ts_059'),
  ('tim_010', 'ts_060'),
  ('tim_010', 'ts_061'),
  ('tim_010', 'ts_062'),
  ('tim_010', 'ts_063'),
  ('tim_010', 'ts_064'),
  ('tim_010', 'ts_065'),
  ('tim_010', 'ts_066'),
  ('tim_010', 'ts_067'),
  ('tim_011', 'ts_068'),
  ('tim_011', 'ts_069'),
  ('tim_011', 'ts_070'),
  ('tim_011', 'ts_071'),
  ('tim_011', 'ts_072'),
  ('tim_011', 'ts_073'),
  ('tim_011', 'ts_074'),
  ('tim_011', 'ts_075'),
  ('tim_012', 'ts_076'),
  ('tim_012', 'ts_077'),
  ('tim_012', 'ts_078'),
  ('tim_012', 'ts_079'),
  ('tim_013', 'ts_080'),
  ('tim_013', 'ts_081'),
  ('tim_013', 'ts_082'),
  ('tim_013', 'ts_083'),
  ('tim_013', 'ts_084'),
  ('tim_014', 'ts_085'),
  ('tim_015', 'ts_086'),
  ('tim_015', 'ts_087'),
  ('tim_015', 'ts_088'),
  ('tim_015', 'ts_089'),
  ('tim_015', 'ts_090'),
  ('tim_015', 'ts_091'),
  ('tim_016', 'ts_086'),
  ('tim_016', 'ts_087'),
  ('tim_016', 'ts_088'),
  ('tim_016', 'ts_089'),
  ('tim_016', 'ts_090'),
  ('tim_016', 'ts_091'),
  ('tim_017', 'ts_086'),
  ('tim_017', 'ts_087'),
  ('tim_017', 'ts_088'),
  ('tim_017', 'ts_089'),
  ('tim_017', 'ts_090'),
  ('tim_017', 'ts_091'),
  ('tim_018', 'ts_086'),
  ('tim_018', 'ts_087'),
  ('tim_018', 'ts_088'),
  ('tim_018', 'ts_089'),
  ('tim_018', 'ts_090'),
  ('tim_018', 'ts_091'),
  ('tim_019', 'ts_086'),
  ('tim_019', 'ts_087'),
  ('tim_019', 'ts_088'),
  ('tim_019', 'ts_089'),
  ('tim_019', 'ts_090'),
  ('tim_019', 'ts_091'),
  ('tim_020', 'ts_086'),
  ('tim_020', 'ts_087'),
  ('tim_020', 'ts_088'),
  ('tim_020', 'ts_089'),
  ('tim_020', 'ts_090'),
  ('tim_020', 'ts_091'),
  ('tim_021', 'ts_086'),
  ('tim_021', 'ts_087'),
  ('tim_021', 'ts_088'),
  ('tim_021', 'ts_089'),
  ('tim_021', 'ts_090'),
  ('tim_021', 'ts_091'),
  ('tim_022', 'ts_086'),
  ('tim_022', 'ts_087'),
  ('tim_022', 'ts_088'),
  ('tim_022', 'ts_089'),
  ('tim_022', 'ts_090'),
  ('tim_022', 'ts_091');

-- 7. SEED DATA RESMI: USERS (240 RECORDS PEGAWAI BRIN)
INSERT INTO public.users (id_user, username, first_name, email, external_email, phone, sex, satuan_kerja, id_tim, jabatan, kawasan, role, password) VALUES
  ('usr_001', 'fath014', 'Fathurrahman Adam Rahadian', 'fathurrahman.adam.rahadian@brin.go.id', 'fathuradam02@gmail.com', '082289895877', 'Laki-Laki', 'BOSDM', 'tim_014', 'Asisten Kerja Sama Internasional', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_002', 'syif007', 'Syifaniar Ramadhanny', 'syifaniar.ramadhanny@brin.go.id', 'syifaniar10@gmail.com', '082231710026', 'Perempuan', 'BOSDM', 'tim_014', 'Asisten Kerja Sama Internasional', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_003', 'mhdg001', 'Mhd Gibran Parawangsa', 'mhd.gibran.parawangsa@brin.go.id', 'gibranparawangsa2003@gmail.com', '082360723874', 'Laki-Laki', 'BOSDM', 'tim_014', 'Asisten Pelaksanaan dan Monev Kerja Sama Nasional', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_004', 'akba006', 'Akbar Rayhan Nugroho', 'akbar.rayhan.nugroho@brin.go.id', 'akbarrayhan2005@gmail.com', '082111066032', 'Laki-Laki', 'BOSDM', 'tim_012', 'Asisten Pendampingan dan Advokasi Hukum', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_005', 'waod004', 'Wa Ode Fithrah Az-Zalia Syamsudin', 'wa.ode.fithrah.az-zalia.syamsudin@brin.go.id', 'waodefithrah@gmail.com', '089529596556', 'Perempuan', 'BOSDM', 'tim_012', 'Asisten Pendampingan dan Advokasi Hukum', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_006', 'amil005', 'Ami Lia Calista', 'ami.lia.calista@brin.go.id', 'amiliacalista91@gmail.com', '082245106639', 'Perempuan', 'BOSDM', 'tim_012', 'Asisten Pengelolaan Kerja Sama dan Hukum (Kawasan I)', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_007', 'mand001', 'Manda Talita Taruli Hasibuan', 'manda.talita.taruli.hasibuan.@brin.go.id', 'hasibuantalita10@gmail.com', '082217971554', 'Perempuan', 'BHKS', NULL, 'Asisten Pengelolaan Kerja Sama Internasional Bilateral I', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_008', 'inay003', 'Inayah Aulia Hijrah', 'inayah.aulia.hijrah@brin.go.id', 'inayah.auliahijrah@gmail.com', '087747590933', 'Perempuan', 'BHKS', NULL, 'Asisten Pengelolaan Kerja Sama Internasional Bilateral I', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_009', 'tega001', 'Tegar Pulung Subhiksa', 'tegar.pulung.subhiksa@brin.go.id', 'tegar.pulung21@gmail.com', '085742011770', 'Laki-Laki', 'BHKS', NULL, 'Asisten Pengelolaan Kerja Sama Internasional Bilateral II', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_010', 'tasy001', 'Tasya Naura Arivia', 'tasya.naura.arivia@brin.go.id', 'achaltasya@gmail.com', '085695870419', 'Perempuan', 'BHKS', NULL, 'Asisten Pengelolaan Kerja Sama Internasional Bilateral II', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_011', 'diaj001', 'Diajeng Dhea Annisa Aura Islami', 'diajeng.dhea.annisa.aura.islami@brin.go.id', 'diajeng731@gmail.com', '081287136243', 'Perempuan', 'BHKS', NULL, 'Asisten Pengelolaan Perjanjian Hibah Riset', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_012', 'rati023', 'Ratih Faisa Nabilah', 'ratih.faisa.nabilah@brin.go.id', 'faisaratih@gmail.com', '0895392231710', 'Perempuan', 'BHKS', NULL, 'Asisten Pengelolaan Perjanjian Hibah Riset', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_013', 'chik001', 'Chika Aurel Rivaldi', 'chika.aurel.rivaldi@brin.go.id', 'chikaarv@gmail.com', '081318866659', 'Perempuan', 'BHKS', NULL, 'Asisten Penyusunan Perjanjian Dalam Negeri', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_014', 'deaj002', 'Dea Jenata Berlianda', 'dea.jenata.berlianda@brin.go.id', 'deajenata4@gmail.com', '085263890017', 'Perempuan', 'BHKS', NULL, 'Asisten Penyusunan Perjanjian Dalam Negeri', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_015', 'tali002', 'Talitha Farah Zalika', 'talitha.farah.zalika@brin.go.id', 'farahzalikaa@gmail.com', '081317973881', 'Perempuan', 'BHKS', NULL, 'Asisten Sekretariat dan Pengelolaan Kerja Sama Multilateral', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_016', 'nabi011', 'Nabila Khoirunnisa Azzahra', 'nabila.khoirunnisa.azzahra@brin.go.id', 'n.sazzra@gmail.com', '082295213442', 'Perempuan', 'BHKS', NULL, 'Asisten Sekretariat dan Pengelolaan Kerja Sama Multilateral', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_017', 'adam009', 'Adam Prameza Anggito', 'adam.prameza.anggito@brin.go.id', 'adampramezaanggito@gmail.com', '081586414005', 'Laki-Laki', 'BHKS', NULL, 'Asisten Pengelolaan Kerja Sama dan Hukum (Kawasan II)', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_018', 'mari063', 'Maria Fernanda De Vega', 'maria.fernanda.de.vega@brin.go.id', 'mariafernandadv03@gmail.com', '089651531101', 'Perempuan', 'BOSDM', 'tim_020', 'Asisten Administrasi Perizinan PDLN', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_019', 'rena008', 'Renata Putri Margareta', 'renata.putri.margareta@brin.go.id', 'remargareta123@gmail.com', '081246120925', 'Perempuan', 'BOSDM', 'tim_020', 'Asisten Administrasi Pimpinan', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_020', 'jeli001', 'Jelita Rahma Arrauufa Okila Putri Utami', 'jelita.rahma.arrauufa.okila.putri.utami@brin.go.id', 'arraufaraa@gmail.com', '082175733221', 'Perempuan', 'BOSDM', 'tim_021', 'Asisten Administrasi Pimpinan', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_021', 'waod005', 'Waode Shafiyah Rahma', 'waode.shafiyah.rahma@brin.go.id', 'waodesr1410@gmail.com', '085173001410', 'Perempuan', 'BOSDM', 'tim_021', 'Asisten Administrasi Pimpinan', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_022', 'inay004', 'Inaya Utami', 'inaya.utami@brin.go.id', 'inayautami9@gmail.com', '085871594997', 'Perempuan', 'BOSDM', 'tim_022', 'Asisten Administrasi Pimpinan', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_023', 'feyz001', 'Feyza Chairunisa Subowo', 'feyza.chairunisa.subowo@brin.go.id', 'chairunisafeyza01@gmail.com', '082115114788', 'Perempuan', 'BOSDM', 'tim_022', 'Asisten Administrasi Pimpinan', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_024', 'audi002', 'Audia Miss Alfatia', 'audia.miss.alfatia@brin.go.id', 'audiaama@gmail.com', '085709725484', 'Perempuan', 'BKPUK', NULL, 'Asisten Administrasi Pimpinan', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_025', 'indr067', 'Indra Emilio Moloku', 'indra.emilio.moloku@brin.go.id', 'indramoloku25@gmail.com', '085796122048', 'Laki-Laki', 'BKPUK', NULL, 'Asisten Administrasi Pimpinan', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_026', 'fach009', 'Fachri Kencana', 'fachri.kencana@brin.go.id', 'fachri.kencana13107@gmail.com', '085695088428', 'Laki-Laki', 'BKPUK', NULL, 'Asisten Administrasi Pimpinan', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_027', 'alif011', 'Alifio Amartya Ramadhan', 'alifio.amartya.ramadhan@brin.go.id', 'fioamartya@gmail.com', '087882314401', 'Laki-Laki', 'BKPUK', NULL, 'Asisten Administrasi Pimpinan', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_028', 'fikr008', 'Fikri Aldi Yansah', 'fikri.aldi.yansah@brin.go.id', 'fikrialdiansyah347@gmail.com', '083878053878', 'Laki-Laki', 'BKPUK', NULL, 'Asisten Administrasi Pimpinan', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_029', 'nast004', 'Nastiti Dyah Lestari', 'nastiti.dyah.lestari@brin.go.id', 'nastitilestari84@gmail.com', '081326163124', 'Perempuan', 'BKPUK', NULL, 'Asisten Distribusi Informasi & Diseminasi', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_030', 'aghn002', 'Aghnia Ulya Musyarrofatul Maula', 'aghnia.ulya.musyarrofatul.maula@brin.go.id', 'aghniaulyam@gmail.com', '085719932035', 'Perempuan', 'BKPUK', NULL, 'Asisten Pengelola Arsip & Dokumentasi', 'LKSDM 1', 'Member', 'Password123!'),
  ('usr_031', 'anis037', 'Anisah Rizki Fadika', 'anisah.rizki.fadika@brin.go.id', 'nisafadicha15@gmail.com', '0895341076789', 'Perempuan', 'BKPUK', NULL, 'Asisten Produksi Audiovisual', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_032', 'dira001', 'Dira Ayu Miranda', 'dira.ayu.miranda@brin.go.id', 'diraayu640@gmail.com', '089519595407', 'Perempuan', 'BKPUK', NULL, 'Asisten Produksi Audiovisual', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_033', 'jaye001', 'Jayeng Sang Pragustu Bagus Rahman', 'jayeng.sang.pragustu.bagus.rahman@brin.go.id', 'ethanbaker878@gmail.com', '085174313268', 'Laki-Laki', 'BKPUK', NULL, 'Asisten Produksi Audiovisual', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_034', 'fisk001', 'Fiska Paragita', 'fiska.paragita@brin.go.id', 'fiskaparagita2002@gmail.com', '089612334300', 'Perempuan', 'BKPUK', NULL, 'Asisten Produksi Media Massa', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_035', 'irfa020', 'Irfan Aditiya Nugraha', 'irfan.aditiya.nugraha@brin.go.id', 'irfanaditiyanugraha2402@gmail.com', '081217881358', 'Laki-Laki', 'BKPUK', NULL, 'Asisten Produksi Media Massa', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_036', 'muti018', 'Mutia Shara', 'mutia.shara@brin.go.id', 'sharamutia785@gmail.com', '085772887320', 'Perempuan', 'BKPUK', NULL, 'Asisten Produksi Media Massa', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_037', 'arkh001', 'Arkhadies Hanif Medina', 'arkhadies.hanif.medina@brin.go.id', 'arkhadiesmedina@gmail.com', '087775712919', 'Perempuan', 'BKPUK', NULL, 'Asisten Produksi Media Sosial', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_038', 'sabr005', 'Sabrina Balqis Siroj', 'sabrina.balqis.siroj@brin.go.id', 'sabrinabals04@gmail.com', '085172304063', 'Perempuan', 'BKPUK', NULL, 'Asisten Produksi Media Sosial', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_039', 'yasm003', 'Yasmine Afiani Gumilar', 'yasmine.afiani.gumilar@brin.go.id', 'yasmineafiani2026@gmail.com', '0895326526877', 'Perempuan', 'BKPUK', NULL, 'Asisten Produksi Media Sosial', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_040', 'habb001', 'Habby Haikal Zulfa S', 'habby.haikal.zulfa.s@brin.go.id', 'habbyhaikal11@gmail.com', '083853106862', 'Laki-Laki', 'BKPUK', NULL, 'Asisten Protokol dan Event Management', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_041', 'imam031', 'Imam Khoeri', 'imam.khoeri@brin.go.id', 'imamkhoeri09@gmail.com', '081214983614', 'Laki-Laki', 'BKPUK', NULL, 'Asisten Protokol dan Event Management', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_042', 'hafi012', 'Hafizhah Ainul Fajar', 'hafizhah.ainul.fajar@brin.go.id', 'hafizah.fajar@gmail.com', '081281140202', 'Perempuan', 'BKPUK', NULL, 'Asisten Protokol dan Event Management', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_043', 'rana002', 'Rana Nurul Anisa', 'rana.nurul.anisa@brin.go.id', 'ranaanisa60@gmail.com', '08978806860', 'Perempuan', 'BKPUK', NULL, 'Asisten Sekretariat International Office', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_044', 'atha004', 'Athaya Farhah Pradita', 'athaya.farhah.pradita@brin.go.id', 'farahhpradita@gmail.com', '085194612521', 'Perempuan', 'BMNP', NULL, 'Asisten Penatausahaan BMN Settama', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_045', 'liya002', 'Liya Puspitasari', 'liya.puspitasari@brin.go.id', 'liyapuspitasari2612@gmail.com', '085807480798', 'Perempuan', 'BMNP', NULL, 'Asisten Pengelolaan Rumah Negara', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_046', 'must017', 'Mustika Ghina Saliyanti', 'mustika.ghina.saliyanti@brin.go.id', 'mustikaghinas@gmail.com', '085878290271', 'Perempuan', 'BMNP', NULL, 'Asisten Pengendalian BMN', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_047', 'ardi019', 'Ardian Saputra', 'ardian.saputra@brin.go.id', 'ardiansaputra239@gmail.com', '087877992153', 'Laki-Laki', 'BMNP', NULL, 'Asisten Pengendalian BMN', 'LKSDM 2', 'Member', 'Password123!'),
  ('usr_048', 'siti127', 'Siti Halimah', 'siti.halimah@brin.go.id', 'halimah.065121145@unpak.ac.id', '081584824312', 'Perempuan', 'BOSDM', NULL, 'Asisten Integrator Data ASN BRIN', 'LKSDM 1', 'Executive', 'Password123!'),
  ('usr_049', 'anis038', 'Anisah Hasratniwati Daeli', 'anisah.hasratniwati.daeli@brin.go.id', 'anisahdaeli@gmail.com', '081396639773', 'Perempuan', 'BOSDM', NULL, 'Asisten Integrator Data ASN BRIN', 'LKSDM 1', 'Executive', 'Password123!'),
  ('usr_050', 'aisy004', 'Aisyah Febrianti Kusmiandini', 'aisyah.febrianti.kusmiandini@brin.go.id', 'afkaisyah@gmail.com', '0895347576342', 'Perempuan', 'BOSDM', NULL, 'Asisten Pengembangan Kompetensi dan Tugas Belajar ASN Riset', 'LKSDM 1', 'Super Admin', 'Password123!'),
  ('usr_051', 'sult001', 'Sulthon Akbar', 'sulthon.akbar@brin.go.id', 'sulthonakbar19@gmail.com', '081282274799', 'Laki-Laki', 'BOSDM', NULL, 'Asisten Pengembangan Kompetensi dan Tugas Belajar ASN Riset', 'LKSDM 1', 'Super Admin', 'Password123!'),
  ('usr_052', 'dina024', 'Dina Aisyah Sahlan Nasution', 'dina.aisyah.sahlan.nasution@brin.go.id', 'dinaaisyahnst03@gmail.com', '081806462537', 'Perempuan', 'BOSDM', 'tim_010', 'Asisten Penguatan Struktur Organisasi dan Tata Kerja BRIN', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_053', 'rais005', 'Raisya Qianisa Nabilla', 'raisya.qianisa.nabilla@brin.go.id', 'raisyanabilla88@gmail.com', '085664355642', 'Perempuan', 'BOSDM', 'tim_011', 'Asisten Perencanaan Kebutuhan dan Karier ASN BRIN', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_054', 'widy018', 'Widya Seriati Saragih', 'widya.seriati.saragih@brin.go.id', 'widyasaragih702@gmail.com', '082163369080', 'Perempuan', 'BOSDM', 'tim_003', 'Asisten Perencanaan Kebutuhan dan Karier ASN BRIN', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_055', 'seft001', 'Seftiana Kurniati', 'seftiana.kurniati@brin.go.id', 'seftianakurniati24@gmail.com', '0895345388127', 'Perempuan', 'BOSDM', 'tim_004', 'Asisten Evaluasi Kinerja dan Risiko Keuangan', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_056', 'diod001', 'Dio Deandra Sunandar', 'dio.deandra.sunandar@brin.go.id', 'diodeandrasunandar@gmail.com', '082278659595', 'Laki-Laki', 'BOSDM', 'tim_005', 'Asisten Pengelolaan Data dan Laporan Kerugian Negara', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_057', 'yuri004', 'Yurianto Pamuji', 'yurianto.pamuji@brin.go.id', 'yuripmj234@gmail.com', '085892142953', 'Laki-Laki', 'BOSDM', 'tim_006', 'Asisten Pengelolaan Data dan Laporan Kerugian Negara', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_058', 'rizk059', 'Rizka Amelia Rahmadhani', 'rizka.amelia.rahmadhani@brin.go.id', 'rizkaamel30@gmail.com', '0895410082395', 'Perempuan', 'BOSDM', 'tim_001', 'Asisten Pengelolaan Keuangan OR Arbastra', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_059', 'rena009', 'Renatha Indah Riski', 'renatha.indah.riski@brin.go.id', 'renathaindahriski@gmail.com', '087882090435', 'Perempuan', 'BOSDM', 'tim_008', 'Asisten Pengelolaan Keuangan OR Arbastra', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_060', 'alvi006', 'Alvin Ardiansyah', 'alvin.ardiansyah@brin.go.id', 'alvinardiansyah253@gmail.com', '085117830569', 'Laki-Laki', 'BOSDM', 'tim_007', 'Asisten Pengelolaan Keuangan OR IPSH', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_061', 'khof002', 'Khofifah Oktharen', 'khofifah.oktharen@brin.go.id', 'khofifahoktharen1910@gmail.com', '082186248577', 'Perempuan', 'BOSDM', 'tim_002', 'Asisten Pengelolaan Keuangan OR IPSH', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_062', 'meli009', 'Melia Erita', 'melia.erita@brin.go.id', 'mliaertaa@gmail.com', '0818521104', 'Perempuan', 'BOSDM', 'tim_009', 'Asisten Pengelolaan Keuangan OR IPSH', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_063', 'mita003', 'Mita Permata Kemuning', 'mita.permata.kemuning@brin.go.id', 'mitapermata1515@gmail.com', '089647012583', 'Perempuan', 'BOSDM', 'tim_013', 'Asisten Pengelolaan Keuangan OR TKPEKM', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_064', 'lutv003', 'Lutvia Restu Putriana', 'lutvia.restu.putriana@brin.go.id', 'lutviaputriana@gmail.com', '081905090986', 'Perempuan', 'BOSDM', 'tim_015', 'Asisten Pengelolaan Keuangan OR TKPEKM', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_065', 'najw002', 'Najwa Aulia Syam', 'najwa.aulia.syam@brin.go.id', 'najwalysymm@gmail.com', '085363811830', 'Perempuan', 'BPK', NULL, 'Asisten Pengelolaan Keuangan OR TKPEKM', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_066', 'zahr007', 'Zahra Annisa Hawdhya', 'zahra.annisa.hawdhya@brin.go.id', 'zannisahawdhya@gmail.com', '0895360449840', 'Perempuan', 'BPK', NULL, 'Asisten Penyusunan Program dan Anggaran Ittama', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_067', 'ange005', 'Angelina Aprilia Sinaga', 'angelina.aprilia.sinaga@brin.go.id', 'angelinaapriliasinaga@gmail.com', '082289764755', 'Perempuan', 'BPK', NULL, 'Asisten Penyusunan Program OR Arbastra', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_068', 'muha394', 'Muhammad Ilham Fauzian', 'muhammad.ilham.fauzian@brin.go.id', 'ilhamfauzian73@gmail.com', '081517077198', 'Laki-Laki', 'BPK', NULL, 'Asisten Penyusunan Program OR Arbastra', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_069', 'indr068', 'Indriana Syafitri', 'indriana.syafitri@brin.go.id', 'indrianasyf@gmail.com', '085891057773', 'Perempuan', 'BPK', NULL, 'Asisten Penyusunan Program OR IPSH', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_070', 'nail007', 'Naila Khairunnissa Br. Ginting', 'naila.khairunnissa.br..ginting@brin.go.id', 'gintingnaila30@gmail.com', '082133634244', 'Perempuan', 'BPK', NULL, 'Asisten Penyusunan Program OR IPSH', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_071', 'fitr065', 'Fitri Puspitaningrum', 'fitri.puspitaningrum@brin.go.id', 'fitripuspitaningrum11@gmail.com', '0882008653691', 'Perempuan', 'BPK', NULL, 'Asisten Penyusunan Program OR TKPEKM', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_072', 'esth004', 'Esther Monicha Kansil', 'esther.monicha.kansil@brin.go.id', 'estherkansil28@gmail.com', '081818996464', 'Perempuan', 'DFLFRKST', NULL, 'Asisten Pengelolaan Layanan Laboratorium Imaging, Iradiasi, dan Kesehatan Radiasi', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_073', 'shel003', 'Shela Sulis Cahyani', 'shela.sulis.cahyani@brin.go.id', 'shelasuliscahyani@gmail.com', '085792128513', 'Perempuan', 'BOSDM', 'tim_016', 'Asisten Administrasi Perizinan', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_074', 'trig001', 'Tri Gunawan Musa', 'tri.gunawan.musa@brin.go.id', 'trignwnmusa@gmail.com', '081243385426', 'Laki-Laki', 'BOSDM', 'tim_017', 'Asisten Kajian Otoritas Ilmiah', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_075', 'amen001', 'Amenis Esra Debora Sihombing', 'amenis.esra.debora.sihombing@brin.go.id', 'amenisesradebora@gmail.com', '089653195369', 'Perempuan', 'BOSDM', 'tim_018', 'Asisten Kajian Otoritas Ilmiah', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_076', 'reva002', 'Reva Anindita Putri', 'reva.anindita.putri@brin.go.id', 'revaaninditaaa1@gmail.com', '081211649920', 'Perempuan', 'BOSDM', 'tim_019', 'Asisten Kebijakan Perizinan Riset', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_077', 'redh003', 'Redho Hasyrahim Fatah', 'redho.hasyrahim.fatah@brin.go.id', 'redhohasyrahimfatah@gmail.com', '089624738992', 'Laki-Laki', 'BOSDM', 'tim_020', 'Asisten Klirens Etik Eksperimen', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_078', 'hani026', 'Hanif Putra Kusuma', 'hanif.putra.kusuma@brin.go.id', 'hanifkusuma7@gmail.com', '085101605433', 'Laki-Laki', 'BOSDM', 'tim_021', 'Asisten Klirens Etik Eksperimen', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_079', 'nura041', 'Nur Aisyah Malau', 'nur.aisyah.malau@brin.go.id', 'aisyahmalau103@gmail.com', '081584451546', 'Perempuan', 'BOSDM', 'tim_022', 'Asisten Klirens Etik Kesehatan', 'LKSDM 1', 'Ketua Tim', 'Password123!'),
  ('usr_080', 'puri002', 'Puri Adzrok Abidah', 'puri.adzrok.abidah@brin.go.id', 'puri.abidah@gmail.com', '083873236141', 'Perempuan', 'BOSDM', 'tim_010', 'Asisten Klirens Etik Pemeliharaan dan Penggunaan Hewan', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_081', 'dhea004', 'Dhea Mutia Kharisma', 'dhea.mutia.kharisma@brin.go.id', 'dhemut15@gmail.com', '089521161819', 'Perempuan', 'DFRI', NULL, 'Asisten Klirens Etik Soshum', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_082', 'aria009', 'Ari Anggun Pramesti', 'ari.anggun.pramesti@brin.go.id', 'arianggunpramesti@gmail.com', '088802559050', 'Perempuan', 'DFRI', NULL, 'Asisten Layanan Fasilitasi dan Pendanaan Risnov untuk Skema RIIM Kolaborasi', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_083', 'yogi015', 'Yogi Purnomo Yusgiantoro', 'yogi.purnomo.yusgiantoro@brin.go.id', 'yogipurnomo046@gmail.com', '083166897996', 'Laki-Laki', 'DFRI', NULL, 'Asisten Layanan Fasilitasi dan Pendanaan Risnov untuk Skema RIIM Kompetisi Eksternal', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_084', 'djul001', 'Djulizah Bonita Lanini', 'djulizah.bonita.lanini@brin.go.id', 'djul.b74123@gmail.com', '081343945547', 'Perempuan', 'DFRI', NULL, 'Asisten Layanan Fasilitasi dan Pendanaan Risnov untuk Skema RIIM Kompetisi Internal BRIN', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_085', 'fitr066', 'Fitrianindita Rahayu Putri', 'fitrianindita.rahayu.putri@brin.go.id', 'ditharahayu67@gmail.com', '089618679600', 'Perempuan', 'DFRI', NULL, 'Asisten Layanan Fasilitasi dan Pendanaan Risnov untuk Skema RIIM Startup', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_086', 'adit036', 'Aditya Yoga Pangestu', 'aditya.yoga.pangestu@brin.go.id', 'yogaaditya253@gmail.com', '085692027495', 'Laki-Laki', 'DFRI', NULL, 'Asisten Layanan Fasilitasi dan Pendanaan Risnov untuk Skema RIIM Startup', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_087', 'anni037', 'Annisa Aulia Furqana Ramzi', 'annisa.aulia.furqana.ramzi@brin.go.id', 'nisaauliafr@gmail.com', '081365324284', 'Perempuan', 'DFRI', NULL, 'Asisten Layanan Kekayaan Intelektual Sektor I', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_088', 'hali006', 'Haliza Fawwaz Ayuningtyas', 'haliza.fawwaz.ayuningtyas@brin.go.id', 'haliza.ayuningtyas@gmail.com', '081383275023', 'Perempuan', 'DFRI', NULL, 'Asisten Layanan Kekayaan Intelektual Sektor II', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_089', 'andr065', 'Andrea Cahya Tiara', 'andrea.cahya.tiara@brin.go.id', 'andreacahya1@gmail.com', '087816336309', 'Perempuan', 'DFRI', NULL, 'Asisten Layanan Kekayaan Intelektual Sektor III', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_090', 'muha395', 'Muhammad Rizky Purwadi', 'muhammad.rizky.purwadi@brin.go.id', 'mrizky.purwadi1@gmail.com', '085779000621', 'Laki-Laki', 'DFRI', NULL, 'Asisten Layanan Pustaka Digital', 'LKSDM 3', 'Member', 'Password123!'),
  ('usr_091', 'davi009', 'Davina Grahita', 'davina.grahita@brin.go.id', 'davinagrahita2707@gmail.com', '087881850543', 'Perempuan', 'DFRI', NULL, 'Asisten Layanan Pustaka Digital', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_092', 'defr005', 'Defryan Aprisandani', 'defryan.aprisandani@brin.go.id', 'dfryan.aprisndani@gmail.com', '082288828631', 'Laki-Laki', 'DFRI', NULL, 'Asisten Pengelolaan Data Ilmiah', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_093', 'anin009', 'Anindya Candrakanti Yusnida', 'anindya.candrakanti.yusnida@brin.go.id', 'acandrakanti@gmail.com', '0895352990279', 'Perempuan', 'DFRI', NULL, 'Asisten Pengembangan Sistem Informasi Pendanaan', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_094', 'fakh006', 'Fakhri Nurrohman', 'fakhri.nurrohman@brin.go.id', 'fakhri.ankunj@gmail.com', '085718916966', 'Laki-Laki', 'DFRI', NULL, 'Asisten Pengembangan Sistem Informasi Pendanaan', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_095', 'nadi012', 'Nadia Nila Farodisa', 'nadia.nila.farodisa@brin.go.id', 'nadianilafarodisa@gmail.com', '085647168646', 'Perempuan', 'DFRI', NULL, 'Asisten Pengembangan Sistem Repositori', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_096', 'muha396', 'Muhammad Ikhsan Budiharta', 'muhammad.ikhsan.budiharta@brin.go.id', 'ikhsanbudiharta01@gmail.com', '081382860723', 'Laki-Laki', 'DFRI', NULL, 'Asisten Pengembangan Sistem Repositori', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_097', 'elsa003', 'Elsa Nisaturrachmah', 'elsa.nisaturrachmah@brin.go.id', 'els.anisa5813@gmail.com', '085649507289', 'Perempuan', 'DFRI', NULL, 'Asisten Produksi & Distribusi Publikasi', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_098', 'dind007', 'Dinda Ayu Lestari', 'dinda.ayu.lestari@brin.go.id', 'dindayu.lestari25@gmail.com', '085879807181', 'Perempuan', 'DFRI', NULL, 'Asisten Valuasi & Analisis KI', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_099', 'selv005', 'Selvi Kumala Widi Hastuti', 'selvi.kumala.widi.hastuti@brin.go.id', 'selvikumalaa28@gmail.com', '081910763593', 'Perempuan', 'DKP', NULL, 'Asisten Analisis Kebijakan Ekonomi & Keuangan', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_100', 'nisr006', 'Nisrina Hanun Latifah', 'nisrina.hanun.latifah@brin.go.id', 'nisrinahnun@gmail.com', '0882005504034', 'Perempuan', 'DKP', NULL, 'Asisten Analisis Kebijakan Energi & SDA', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_101', 'azal002', 'Azalea Ar-Raudah Kirana', 'azalea.ar-raudah.kirana@brin.go.id', 'azaleaarraudah197@gmail.com', '081316458914', 'Perempuan', 'DKP', NULL, 'Asisten Analisis Kebijakan Infrastruktur & Transportasi', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_102', 'zeek001', 'Zeekra Lailla Shafa', 'zeekra.lailla.shafa@brin.go.id', 'shafazeekra@gmail.com', '0895364605603', 'Perempuan', 'DKP', NULL, 'Asisten Analisis Kebijakan Kelautan & Perikanan', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_103', 'anin010', 'Anindya Putri Maharani', 'anindya.putri.maharani@brin.go.id', 'nindyaputri.maharani@gmail.com', '081320060499', 'Perempuan', 'DKP', NULL, 'Asisten Analisis Kebijakan Kependudukan & Perlindungan Sosial', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_104', 'rais006', 'Raissyah Fatika Rahma Dewi', 'raissyah.fatika.rahma.dewi@brin.go.id', 'raissyahfrrd@gmail.com', '081285082225', 'Perempuan', 'DKP', NULL, 'Asisten Analisis Kebijakan Pembangunan Manusia', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_105', 'fath015', 'Fathan Maulana Litty', 'fathan.maulana.litty@brin.go.id', 'fathanmaulana2001@gmail.com', '081316629333', 'Laki-Laki', 'DKP', NULL, 'Asisten Analisis Kebijakan Pertahanan & Keamanan', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_106', 'jesi001', 'Jesin Ananta Vitaloka', 'jesin.ananta.vitaloka@brin.go.id', 'jesinananta1706@gmail.com', '089630839082', 'Perempuan', 'DKP', NULL, 'Asisten Kajian Ekonomi Regional & Pemberdayaan Masyarakat', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_107', 'putr703', 'Putri Ayu Amanda', 'putri.ayu.amanda@brin.go.id', 'ptrayuamanda04@gmail.com', '081313706649', 'Perempuan', 'DKP', NULL, 'Asisten Kajian Kebijakan Hukum & Regulasi', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_108', 'roml002', 'Romli Jamaludin', 'romli.jamaludin@brin.go.id', 'j.romli97@gmail.com', '085859838303', 'Laki-Laki', 'DKP', NULL, 'Asisten Kajian Kebijakan Keantariksaan', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_109', 'atik016', 'Atika Salsabila', 'atika.salsabila@brin.go.id', 'atikasalsabila526@gmail.com', '0895416007964', 'Perempuan', 'DKP', NULL, 'Asisten Kajian Kebijakan Kebudayaan', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_110', 'adli002', 'Adlina Shahrani Nugroho', 'adlina.shahrani.nugroho@brin.go.id', 'adlina.nugroho26@gmail.com', '081282656861', 'Perempuan', 'DKP', NULL, 'Asisten Kajian Kebijakan Lingkungan & Perubahan Iklim', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_111', 'arun004', 'Arundina Wijaya', 'arundina.wijaya@brin.go.id', 'arundina074@gmail.com', '082225649119', 'Perempuan', 'DKP', NULL, 'Asisten Kajian Kebijakan Pertanian & Ketahanan Pangan', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_112', 'yudi023', 'Yudi Ferdiansyah', 'yudi.ferdiansyah@brin.go.id', 'yudi.ferdiansyah12@gmail.com', '089524002365', 'Laki-Laki', 'DKP', NULL, 'Asisten Kajian Ketenagakerjaan & Produktivitas', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_113', 'shei001', 'Sheily Desti Aninda', 'sheily.desti.aninda@brin.go.id', 'sheily24648@gmail.com', '085777508499', 'Perempuan', 'DKP', NULL, 'Asisten Kajian Politik & Reformasi Birokrasi', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_114', 'syar028', 'Syarif Hidayatullah', 'syarif.hidayatullah@brin.go.id', 'hidayatullahsyarif40@gmail.com', '082163265212', 'Laki-Laki', 'DKRI', NULL, 'Asisten Analisis Foresight & Tren Inovasi', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_115', 'putr704', 'Putri Maziya Ikhsanti', 'putri.maziya.ikhsanti@brin.go.id', 'maziyaputri26@gmail.com', '081229905448', 'Perempuan', 'DKRI', NULL, 'Asisten Analisis Perencanaan Data', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_116', 'seka005', 'Sekar Kinanthi Wohing Lohjati', 'sekar.kinanthi.wohing.lohjati@brin.go.id', 'sekarkinanthi0102@gmail.com', '082134897275', 'Perempuan', 'DKRI', NULL, 'Asisten Evaluasi Kebijakan Energi & Ekonomi Sirkular', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_117', 'yusi006', 'Yusi Armelia Putri', 'yusi.armelia.putri@brin.go.id', 'yusiputri43@gmail.com', '083120989374', 'Perempuan', 'DKRI', NULL, 'Asisten Evaluasi Kebijakan Maritim & Manufaktur', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_118', 'mand002', 'M Andika Kartiwa. P', 'm.andika.kartiwa..p@brin.go.id', 'andikakartiwa@gmail.com', '0895603052941', 'Laki-Laki', 'DKRI', NULL, 'Asisten Evaluasi Kebijakan Sosial & Pendidikan', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_119', 'orth001', 'Ortho Wiria Razak', 'ortho.wiria.razak@brin.go.id', 'orthowiria8@gmail.com', '085940774645', 'Laki-Laki', 'DKRI', NULL, 'Asisten Kajian Ekosistem Riset & Inovasi', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_120', 'vion002', 'Viona Phenytania', 'viona.phenytania@brin.go.id', 'vionaphenytania9@gmail.com', '081373196397', 'Perempuan', 'DKRI', NULL, 'Asisten Kajian Kebijakan Keantariksaan', 'LKSDM 4', 'Member', 'Password123!'),
  ('usr_121', 'kelv001', 'Kelvin Yogantara Wibowo', 'kelvin.yogantara.wibowo@brin.go.id', 'kelvin.wibowo06@gmail.com', '089687847256', 'Laki-Laki', 'DKRI', NULL, 'Asisten Kajian Kebijakan Keantariksaan', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_122', 'elea001', 'Eleazar Ghezy Ivanofit Akmal', 'eleazar.ghezy.ivanofit.akmal@brin.go.id', 'eleazar.akmal@gmail.com', '08111857513', 'Laki-Laki', 'DKRI', NULL, 'Asisten Kajian Kebijakan Ketenaganukliran', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_123', 'jala001', 'Jalalludin Mukhtafi', 'jalalludin.mukhtafi@brin.go.id', 'jalalludinmukhtafi740@gmail.com', '082299807366', 'Laki-Laki', 'DKRI', NULL, 'Asisten Kajian Kebijakan Ketenaganukliran', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_124', 'pila001', 'Pilar Bayu Sakti', 'pilar.bayu.sakti@brin.go.id', 'pilarbayu23@gmail.com', '082325064843', 'Laki-Laki', 'DKRI', NULL, 'Asisten Penelitian Indikator RTI', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_125', 'cevi001', 'Cevira Dhiya Ayuni', 'cevira.dhiya.ayuni@brin.go.id', 'ceviradhiyaayuni16@gmail.com', '085278046564', 'Perempuan', 'DKRI', NULL, 'Asisten Pengolahan Data Riset & Inovasi', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_126', 'fair003', 'Fairuz Farah Ikbar', 'fairuz.farah.ikbar@brin.go.id', 'fairuzfarah21@gmail.com', '085715388963', 'Perempuan', 'DP', NULL, 'AKR â Asisten Pengawasan dan Manajemen Kapal Riset', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_127', 'muha397', 'Muhammad Rafi Akbar Askari Putra', 'muhammad.rafi.akbar.askari.putra@brin.go.id', 'muhamadrafi2017@gmail.com', '089629105839', 'Laki-Laki', 'DP', NULL, 'AKR â Asisten Pengawasan dan Manajemen Kapal Riset', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_128', 'balq002', 'Balqis Al Khansa Ayunita', 'balqis.al.khansa.ayunita@brin.go.id', 'balqisalkhansaa@gmail.com', '082319893590', 'Perempuan', 'DP', NULL, 'AKR â Asisten Pengawasan dan Manajemen Kapal Riset', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_129', 'pung003', 'Pungka Star Sihite', 'pungka.star.sihite@brin.go.id', 'pungkastarsihite@gmail.com', '085142327056', 'Laki-Laki', 'DP', NULL, 'AKR â Asisten Perencanaan & Koordinasi Ekspedisi Kapal Riset', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_130', 'saff001', 'Saffana Kasyfa Fakhira', 'saffana.kasyfa.fakhira@brin.go.id', 'saffanakasyfa@gmail.com', '087809959399', 'Perempuan', 'DPKIRI', NULL, 'Asisten Evaluasi dan Kajian Kemitraan Infrastruktur Riset dan Inovasi', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_131', 'tiar008', 'Tiara', 'tiara@brin.go.id', '10tiaraaa@gmail.com', '082387149156', 'Perempuan', 'DPKIRI', NULL, 'Asisten Kemitraan Riset dan Inovasi', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_132', 'darn002', 'Darnell Petra Clement Laowo', 'darnell.petra.clement.laowo@brin.go.id', 'darnellpetra@gmail.com', '087787310830', 'Laki-Laki', 'DPKIRI', NULL, 'Asisten Kemitraan Riset dan Inovasi', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_133', 'riva004', 'Rivana Cahyani', 'rivana.cahyani@brin.go.id', 'rivanava610@gmail.com', '0895323062609', 'Perempuan', 'DPKIRI', NULL, 'Asisten Penguatan Sistem Infrastruktur Riset', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_134', 'salw002', 'Salwa Fadhilah Humairah', 'salwa.fadhilah.humairah@brin.go.id', 'salwahumairah5@gmail.com', '082161885931â€¬', 'Perempuan', 'DPKIRI', NULL, 'Asisten Penguatan Sistem Infrastruktur Riset', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_135', 'diaz001', 'Diaz Syafril Dwi Anggi', 'diaz.syafril.dwi.anggi@brin.go.id', 'anggidiaz27@gmail.com', '082257305748', 'Laki-Laki', 'DPLFRKST', NULL, 'Asisten Pengelolaan Layanan Laboratorium Imaging, Iradiasi, dan Kesehatan Radiasi', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_136', 'zahr008', 'Zahrah Amalia Putri', 'zahrah.amalia.putri@brin.go.id', 'zahrahkapoor@gmail.com', '081283436203', 'Perempuan', 'DPRI', NULL, 'Asisten Analisis Pemanfaatan Riset Industri', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_137', 'satr017', 'Satrio Pramono Aji', 'satrio.pramono.aji@brin.go.id', 'satriopramonoaji@gmail.com', '085746701395', 'Laki-Laki', 'DPRI', NULL, 'Asisten Audit Teknologi Industri', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_138', 'sara014', 'Sarah Mulya Sukma', 'sarah.mulya.sukma@brin.go.id', 'sarahsukma24@gmail.com', '0895401056801', 'Perempuan', 'DPRI', NULL, 'Asisten Audit Teknologi NonIndustri', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_139', 'khai023', 'Khaira Naflah', 'khaira.naflah@brin.go.id', 'khaira0307@gmail.com', '087893316012', 'Perempuan', 'DPRI', NULL, 'Asisten Diseminasi dan Penguatan Kapasitas Pengguna Riset dan Inovasi', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_140', 'evad001', 'Eva Desiana Putri', 'eva.desiana.putri@brin.go.id', 'evadesianap@gmail.com', '087878952342', 'Perempuan', 'DPRI', NULL, 'Asisten Diseminasi Riset Masyarakat', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_141', 'maur004', 'Maura Sabrina Taufiq', 'maura.sabrina.taufiq@brin.go.id', 'maurasabrinataufiq@gmail.com', '085241181039', 'Perempuan', 'DPRI', NULL, 'Asisten Inkubasi Startup Riset', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_142', 'mkha001', 'M. Khawariz Andaristiyan', 'm..khawariz.andaristiyan@brin.go.id', 'khawarizandaristiyan@gmail.com', '085227393748', 'Laki-Laki', 'DPRI', NULL, 'Asisten Kajian Keantariksaan', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_143', 'viko001', 'Viko Pratama Ariva', 'viko.pratama.ariva@brin.go.id', 'vikopratams@gmail.com', '085695936812', 'Laki-Laki', 'DPRI', NULL, 'Asisten Kajian Keantariksaan', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_144', 'nurh048', 'Nur Halimah', 'nur.halimah@brin.go.id', 'nurhlmh1773@gmail.com', '082121243451', 'Perempuan', 'DPRI', NULL, 'Asisten Layanan Katalog Inovasi', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_145', 'draj002', 'Drajat Agung Saputra', 'drajat.agung.saputra@brin.go.id', 'drajatagung104@gmail.com', '085801018488', 'Laki-Laki', 'DPRI', NULL, 'Asisten Manajemen Lisensi I', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_146', 'astr011', 'Astrid Widya Putri', 'astrid.widya.putri@brin.go.id', 'astridwidyaputri095@gmail.com', '082141262122', 'Perempuan', 'DPRI', NULL, 'Asisten Manajemen Lisensi I', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_147', 'muha398', 'Muhammad Fadhli Musaid', 'muhammad.fadhli.musaid@brin.go.id', 'fadhliazis26@gmail.com', '082296932871', 'Laki-Laki', 'DPRI', NULL, 'Asisten Manajemen Lisensi II', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_148', 'putr705', 'Putri Nada Syiva', 'putri.nada.syiva@brin.go.id', 'putrindsyiva@gmail.com', '081268117249', 'Perempuan', 'DPRI', NULL, 'Asisten Manajemen Lisensi II', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_149', 'aufa003', 'Aufa Dhiya Athaya', 'aufa.dhiya.athaya@brin.go.id', 'aufadhiyaathaya2003@gmail.com', '087773111842', 'Laki-Laki', 'DPRI', NULL, 'Asisten Pameran & Komunikasi Riset', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_150', 'shar003', 'Sharla Martiza Isya''Iah Putri', 'sharla.martiza.isya''iah.putri@brin.go.id', 'sharlamartizaip@gmail.com', '081358171550', 'Perempuan', 'DPRI', NULL, 'Asisten Pameran & Komunikasi Riset', 'LKSDM 5', 'Member', 'Password123!'),
  ('usr_151', 'hafi013', 'Hafiz Rifki', 'hafiz.rifki@brin.go.id', 'hafizrifki19@gmail.com', '085156181694', 'Laki-Laki', 'DPRI', NULL, 'Asisten Pemanfaatan Digital & TIK', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_152', 'siti128', 'Siti Sarah Humaira', 'siti.sarah.humaira@brin.go.id', 'sarahhumaira3010@gmail.com', '082391738508', 'Perempuan', 'DPRI', NULL, 'Asisten Pemanfaatan Inovasi Pangan', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_153', 'rizk060', 'Rizka Fazri Lestari', 'rizka.fazri.lestari@brin.go.id', 'rizkafazri04@gmail.com', '087898166859', 'Perempuan', 'DPRI', NULL, 'Asisten Pemanfaatan Riset Kesehatan', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_154', 'sult002', 'Sulthan Farizqi', 'sulthan.farizqi@brin.go.id', 'sulthanfarizqi72@gmail.com', '08131010380', 'Laki-Laki', 'DPRI', NULL, 'Asisten Pengembangan Science Center', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_155', 'silv404', 'Silvia Ayu Lestari', 'silvia.ayu.lestari@brin.go.id', 'silviaayu555@gmail.com', '08999539245', 'Perempuan', 'DPRI', NULL, 'Asisten Program UMKM Berbasis Riset', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_156', 'zabr001', 'Zabrina Ramadhani Aristawati', 'zabrina.ramadhani.aristawati@brin.go.id', 'zabrinaarst@gmail.com', '082240438094', 'Perempuan', 'BOSDM', 'tim_010', 'Asisten Analis Kerja Sama Riset Daerah', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_157', 'abid007', 'Abid Omar Tusta', 'abid.omar.tusta@brin.go.id', 'abidomar772@gmail.com', '082231180938', 'Laki-Laki', 'BOSDM', 'tim_011', 'Asisten Analisis Kebijakan dan Pelaporan Regional VII', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_158', 'rahm209', 'Rahma Puspita Rahayu', 'rahma.puspita.rahayu@brin.go.id', 'rahayurahma67@gmail.com', '081227511374', 'Perempuan', 'BOSDM', 'tim_011', 'Asisten Analisis Kebijakan Riset Daerah Regional I', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_159', 'rist012', 'Rista Yunita Sari', 'rista.yunita.sari@brin.go.id', 'ristayunita14@gmail.com', '087804556645', 'Perempuan', 'BOSDM', 'tim_003', 'Asisten Analisis Kebijakan Riset Daerah Regional II', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_160', 'nian002', 'Niana Fitri Jamilah', 'niana.fitri.jamilah@brin.go.id', 'nianafitrij@gmail.com', '085889064669', 'Perempuan', 'BOSDM', 'tim_003', 'Asisten Diseminasi Hasil Riset Daerah Regional IX', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_161', 'yuli066', 'Yuliana Oktavia', 'yuliana.oktavia@brin.go.id', 'yuliana.oktavia27102000@gmail.com', '081378495918', 'Perempuan', 'BOSDM', 'tim_004', 'Asisten Fasilitasi dan Evaluasi Kebijakan Regional IV', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_162', 'dwir011', 'Dwiratih Ratna Dewi', 'dwiratih.ratna.dewi@brin.go.id', 'ratihratna534@gmail.com', '088212977161', 'Perempuan', 'BOSDM', 'tim_004', 'Asisten Fasilitasi dan Monitoring Riset Daerah', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_163', 'tiar009', 'Tiara Rahany Aulia', 'tiara.rahany.aulia@brin.go.id', 'tiarahany13@gmail.com', '081358814525', 'Perempuan', 'BOSDM', 'tim_005', 'Asisten Fasilitasi Riset Daerah', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_164', 'fadi012', 'Fadilah Suci Kamila Moopio', 'fadilah.suci.kamila.moopio@brin.go.id', 'moopiofadilah@gmail.com', '085939709009', 'Perempuan', 'BOSDM', 'tim_005', 'Asisten Pemanfaatan Riset Daerah', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_165', 'nuru061', 'Nurul Izzah', 'nurul.izzah@brin.go.id', 'nrlizzah05@gmail.com', '085772088454', 'Perempuan', 'DRID', NULL, 'Asisten Pemantauan Program Riset Daerah Regional V', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_166', 'muha399', 'Muhammad Bisma Moya Harum', 'muhammad.bisma.moya.harum@brin.go.id', 'moyabisma@gmail.com', '082135084642', 'Laki-Laki', 'DRID', NULL, 'Asisten Program Inovasi Daerah Regional XI', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_167', 'faiz013', 'Faizal Rahman', 'faizal.rahman@brin.go.id', 'sallfaz101@gmail.com', '0895348116390', 'Laki-Laki', 'BOSDM', 'tim_006', 'Asisten Kebijakan dan Evaluasi Program Talenta', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_168', 'elva001', 'Elvabel Putra Hasmoro', 'elvabel.putra.hasmoro@brin.go.id', 'elvabelhasmoro@gmail.com', '085889180171', 'Laki-Laki', 'BOSDM', 'tim_006', 'Asisten Pengembangan Kompetensi Internasional', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_169', 'dzil001', 'Dzilcarisya Faza Rahma', 'dzilcarisya.faza.rahma@brin.go.id', 'dzilcarisyafr27@gmail.com', '087852130750', 'Perempuan', 'BOSDM', 'tim_001', 'Asisten Pengembangan Kompetensi Nasional', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_170', 'merl001', 'Merlina Meiriyanti', 'merlina.meiriyanti@brin.go.id', 'meiriyantim@gmail.com', '082226207769', 'Perempuan', 'BOSDM', 'tim_001', 'Asisten Pengembangan Kompetensi Nasional', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_171', 'tuti012', 'Tu''Ti Taqwana', 'tu''ti.taqwana@brin.go.id', 'tutiwana19@gmail.com', '085755522550', 'Perempuan', 'BOSDM', 'tim_008', 'Asisten Pengembangan Learning Management System', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_172', 'sani003', 'Sania Della Chasandra', 'sania.della.chasandra@brin.go.id', 'rokrest78@gmail.com', '082124906737', 'Perempuan', 'DSDMI', NULL, 'Asisten Program Talenta I', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_173', 'regi005', 'Regina Jasmine', 'regina.jasmine@brin.go.id', 'reginajasmine42@gmail.com', '081290042890', 'Perempuan', 'DSDMI', NULL, 'Asisten Program Talenta II', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_174', 'hana018', 'Hana Maria Simangunsong', 'hana.maria.simangunsong@brin.go.id', 'hanamariasimangunsong22@gmail.com', '087711132102', 'Perempuan', 'DSDMI', NULL, 'Asisten Program Talenta II', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_175', 'patr002', 'Patresia Bintang Permatasari', 'patresia.bintang.permatasari@brin.go.id', 'patresiapbr@gmail.com', '08386873770', 'Perempuan', 'DSDMI', NULL, 'Asisten Program Talenta III', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_176', 'cind004', 'Cindy Syaura Aksanti', 'cindy.syaura.aksanti@brin.go.id', 'syauraaa27@gmail.com', '081283120506', 'Perempuan', 'DSDMI', NULL, 'Asisten Program Talenta III', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_177', 'tali003', 'Talitha Raisa Yusuf', 'talitha.raisa.yusuf@brin.go.id', 'talitha.raisa11@gmail.com', '089506047011', 'Perempuan', 'DSDMI', NULL, 'Asisten Program Talenta IV', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_178', 'isya003', 'Isya Nurhidayah', 'isya.nurhidayah@brin.go.id', 'isyanurhd24@gmail.com', '085693345461', 'Laki-Laki', 'Ittama', NULL, 'Asisten Monitoring dan Evaluasi Pengawasan', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_179', 'sama002', 'Samantha Elisa Gracia', 'samantha.elisa.gracia@brin.go.id', 'graciae786@gmail.com', '0895330044325', 'Perempuan', 'Ittama', NULL, 'Asisten Program dan Pelaporan', 'LKSDM 6', 'Member', 'Password123!'),
  ('usr_180', 'zaid003', 'Zaidan Nabil Diwangkara', 'zaidan.nabil.diwangkara@brin.go.id', 'znabildiwangkara@gmail.com', '081226799098', 'Laki-Laki', 'BOSDM', 'tim_008', 'Analis Kebijakan TIK Intern', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_181', 'shaf007', 'Shafira Meutia Syahrial', 'shafira.meutia.syahrial@brin.go.id', 'shafirameutia131@gmail.com', '081317465006', 'Perempuan', 'BOSDM', 'tim_007', 'Analis Kebijakan TIK Intern', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_182', 'amel008', 'Amelia Putri Kayla', 'amelia.putri.kayla@brin.go.id', 'ameliaputrikayla47@gmail.com', '0882003066083', 'Perempuan', 'BOSDM', 'tim_007', 'Data Analyst Intern', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_183', 'rahm210', 'Rahma Nur Aisyah', 'rahma.nur.aisyah@brin.go.id', 'rahmanuraisyah0310@gmail.com', '081297590542', 'Perempuan', 'BOSDM', 'tim_002', 'Data Analyst Intern', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_184', 'anan020', 'Ananda Ias Falah Surya Gemilang', 'ananda.ias.falah.surya.gemilang@brin.go.id', 'falahsuryaiyas@gmail.com', '081212348340', 'Laki-Laki', 'BOSDM', 'tim_002', 'Pengelola Layanan TI', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_185', 'muha400', 'Muhammad Arkan Araafkha', 'muhammad.arkan.araafkha@brin.go.id', 'dmckan3@gmail.com', '085162665474', 'Laki-Laki', 'BOSDM', 'tim_009', 'Pengelola Layanan TI', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_186', 'nazh002', 'Nazhif Teggar Ranov', 'nazhif.teggar.ranov@brin.go.id', 'nazhifteggar12345@gmail.com', '089510258462', 'Laki-Laki', 'BOSDM', 'tim_009', 'Pengelola Layanan TI', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_187', 'hafi014', 'Hafizh Mufti Nazar', 'hafizh.mufti.nazar@brin.go.id', 'hafizmufti578@gmail.com', '0895420148020', 'Laki-Laki', 'BOSDM', 'tim_013', 'Pengelola Layanan TI', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_188', 'rean001', 'Rean Elfrianza', 'rean.elfrianza@brin.go.id', 'elfrianzarean82@gmail.com', '081283217783', 'Laki-Laki', 'BOSDM', 'tim_013', 'Pengelola Layanan TI', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_189', 'fari029', 'Faris Setya Aqil Humam', 'faris.setya.aqil.humam@brin.go.id', 'fs.aqilhumam@gmail.com', '088212042352', 'Laki-Laki', 'BOSDM', 'tim_015', 'Pengembang Sistem Informasi 1 (Software Engineer Intern)', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_190', 'abis002', 'Abisakha Saif Alfath', 'abisakha.saif.alfath@brin.go.id', 'abisakhasaif123@gmail.com', '081296063395', 'Laki-Laki', 'BOSDM', 'tim_015', 'Pengembang Sistem Informasi 1 (Software Engineer Intern)', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_191', 'agus205', 'Agus Purwanto', 'agus.purwanto@brin.go.id', 'agguspurwantoo@gmail.com', '082329561105', 'Laki-Laki', 'BOSDM', 'tim_016', 'Pengembang Sistem Informasi 1 (Software Engineer Intern)', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_192', 'ryan009', 'Ryan Hadi Ardhiansyah', 'ryan.hadi.ardhiansyah@brin.go.id', 'ryanhadi412003@gmail.com', '088210464001', 'Laki-Laki', 'BOSDM', 'tim_016', 'Pengembang Sistem Informasi 2 (Software Engineer Intern)', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_193', 'fren007', 'Frengki Josua Purba', 'frengki.josua.purba@brin.go.id', 'frengkipurba2016@gmail.com', '088211434023', 'Laki-Laki', 'BOSDM', 'tim_017', 'Pengembang Sistem Informasi 2 (Software Engineer Intern)', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_194', 'najw003', 'Najwa Khairana Sulistyoningsih', 'najwa.khairana.sulistyoningsih@brin.go.id', 'najwakhairanaa@gmail.com', '087768929958', 'Perempuan', 'BOSDM', 'tim_017', 'Pengembang Sistem Informasi 2 (Software Engineer Intern)', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_195', 'muha401', 'Muhammad Hilmy Fauzi', 'muhammad.hilmy.fauzi@brin.go.id', 'hilmy2602@gmail.com', '085263635591', 'Laki-Laki', 'BOSDM', 'tim_018', 'Pengembang Sistem Informasi 3 (Software Engineer Intern)', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_196', 'moha098', 'Mohammad Rafli Sumaryono', 'mohammad.rafli.sumaryono@brin.go.id', 'raflisumaryono1818@gmail.com', '085173318074', 'Laki-Laki', 'BOSDM', 'tim_018', 'Pengembang Sistem Informasi 3 (Software Engineer Intern)', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_197', 'ahma211', 'Ahmad Fikri Haikal', 'ahmad.fikri.haikal@brin.go.id', 'fikaalm26@gmail.com', '085157888520', 'Laki-Laki', 'BOSDM', 'tim_019', 'Pengembang Sistem Informasi 3 (Software Engineer Intern)', 'LKSDM 1', 'Staff Admin', 'Password123!'),
  ('usr_198', 'putr706', 'Putri Ivana Anggraeni Mumtaz', 'putri.ivana.anggraeni.mumtaz@brin.go.id', 'putrivna@gmail.com', '082126965526', 'Perempuan', 'Pusdatin', NULL, 'Pengembang Sistem Informasi 4 (Software Engineer Intern)', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_199', 'sask002', 'Saskia Lavinsky', 'saskia.lavinsky@brin.go.id', 'saskialvnsky14@gmail.com', '085765024922', 'Perempuan', 'Pusdatin', NULL, 'Pengembang Sistem Informasi 4 (Software Engineer Intern)', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_200', 'rhak002', 'Rhaken Shaquille Akbar Yanuanda', 'rhaken.shaquille.akbar.yanuanda@brin.go.id', 'rhakenss@gmail.com', '085158554365', 'Laki-Laki', 'Pusdatin', NULL, 'Pengembang Sistem Informasi 4 (Software Engineer Intern)', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_201', 'fath016', 'Fathinah Nafisah Azzahra', 'fathinah.nafisah.azzahra@brin.go.id', 'fathinahnafisah@gmail.com', '081294497449', 'Perempuan', 'Sesdep DFRI', NULL, 'Asisten Komunikasi Publik DFRI', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_202', 'vane001', 'Vanessa Aprilia Jelita Sitohang', 'vanessa.aprilia.jelita.sitohang@brin.go.id', 'vanessaapriliajelita2003@gmail.com', '085664083587', 'Perempuan', 'Sesdep DFRI', NULL, 'Asisten Perencanaan Program & Keuangan', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_203', 'nesa001', 'Nesa Indriyani', 'nesa.indriyani@brin.go.id', 'nesaindriyani41@gmail.com', '085150758827', 'Perempuan', 'Sesdep DFRI', NULL, 'Asisten Perencanaan Program & Keuangan', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_204', 'zhaf002', 'Zhafira Krismulyadi', 'zhafira.krismulyadi@brin.go.id', 'zhafirakrismulyadi@gmail.com', '083180946697', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Evaluasi dan Kajian Kemitraan Infrastruktur', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_205', 'asyi001', 'Asyifa Salsabilla', 'asyifa.salsabilla@brin.go.id', 'asyifasalsabillaas@gmail.com', '081274701555', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Evaluasi dan Kajian Kemitraan Infrastruktur', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_206', 'atta001', 'Attalia Meisya Maharani', 'attalia.meisya.maharani@brin.go.id', 'attaliameisya@gmail.com', '087758361277', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Komunikasi Publik DIRI', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_207', 'muha402', 'Muhammad Fathan Insanulkamil', 'muhammad.fathan.insanulkamil@brin.go.id', 'insanulkamilfathan@gmail.com', '081324832153', 'Laki-Laki', 'Sesdep DIRI', NULL, 'Asisten Komunikasi Publik DIRI', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_208', 'fati011', 'Fatika Nadiyah Aulia', 'fatika.nadiyah.aulia@brin.go.id', 'auliafatikanadiyah@gmail.com', '085864481695', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Penatausahaan BMN', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_209', 'bung011', 'Bunga Melfiana', 'bunga.melfiana@brin.go.id', 'bungamelfiana755@gmail.com', '082269331303', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Penatausahaan BMN', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_210', 'lisa007', 'Lisa Syafira', 'lisa.syafira@brin.go.id', 'lisasyafira80@gmail.com', '081278489704', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Penatausahaan BMN', 'LKSDM 7', 'Member', 'Password123!'),
  ('usr_211', 'adir003', 'Adira Fiona Prinangesti', 'adira.fiona.prinangesti@brin.go.id', 'adirafiona2001@gmail.com', '08999459173', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Penatausahaan BMN', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_212', 'sabr006', 'Sabrina Ernina Fajar', 'sabrina.ernina.fajar@brin.go.id', 'litdhalailatulsabrina@gmail.com', '088271592962', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Penatausahaan BMN', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_213', 'faja032', 'Fajar Maulana Choirullah', 'fajar.maulana.choirullah@brin.go.id', 'fajarmau6na@gmail.com', '081226119732', 'Laki-Laki', 'Sesdep DIRI', NULL, 'Asisten Pengembangan Program', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_214', 'ahma212', 'Ahmad Nail Bisyri', 'ahmad.nail.bisyri@brin.go.id', 'ahmadnailbisyri29@gmail.com', '082335518033', 'Laki-Laki', 'Sesdep DIRI', NULL, 'Asisten Pengembangan Program', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_215', 'acep006', 'Acep Rusmana', 'acep.rusmana@brin.go.id', 'rusmananamta123@gmail.com', '083808609063', 'Laki-Laki', 'Sesdep DIRI', NULL, 'Asisten Pengembangan Program', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_216', 'najw004', 'Najwa Safina Nurhaliza', 'najwa.safina.nurhaliza@brin.go.id', 'najwasafina315@gmail.com', '085159776480', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Pengembangan Program', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_217', 'muha403', 'Muhammad Abdurrozaq', 'muhammad.abdurrozaq@brin.go.id', 'muhammadabdurrozaq88@gmail.com', '089654834543', 'Laki-Laki', 'Sesdep DIRI', NULL, 'Asisten Pengembangan Program', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_218', 'amir019', 'Amira Nurus Salma', 'amira.nurus.salma@brin.go.id', 'amiransalma@gmail.com', '082133164400', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Pengembangan Program', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_219', 'dwik007', 'Dwiki Andreansyah Nugraha', 'dwiki.andreansyah.nugraha@brin.go.id', 'dwikiandreaa@gmail.com', '081324869658', 'Laki-Laki', 'Sesdep DIRI', NULL, 'Asisten Perencanaan Program dan Anggaran, serta Ketatausahaan dan Kearsipan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_220', 'muha404', 'Muhammad Nizar Azmi', 'muhammad.nizar.azmi@brin.go.id', 'lolfadil3@gmail.com', '081234090087', 'Laki-Laki', 'Sesdep DIRI', NULL, 'Asisten Perencanaan Program dan Anggaran, serta Ketatausahaan dan Kearsipan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_221', 'rein003', 'Reinhard Halomoan Lumbantobing', 'reinhard.halomoan.lumbantobing@brin.go.id', 'reihalomoan@gmail.com', '082281371055', 'Laki-Laki', 'Sesdep DIRI', NULL, 'Asisten Perencanaan Program dan Anggaran, serta Ketatausahaan dan Kearsipan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_222', 'maha014', 'Maharani Rahman', 'maharani.rahman@brin.go.id', 'maharanirahman2302@gmail.com', '083121892274', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Perencanaan Program dan Anggaran, serta Ketatausahaan dan Kearsipan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_223', 'daff002', 'Daffina Ghisca Hafidzah', 'daffina.ghisca.hafidzah@brin.go.id', 'hdaffinaghisca@gmail.com', '082370480729', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Perencanaan Program dan Anggaran, serta Ketatausahaan dan Kearsipan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_224', 'fati012', 'Fatimah Ainul Mardhiyah', 'fatimah.ainul.mardhiyah@brin.go.id', 'fatimahainulmardhiyah@gmail.com', '081223136997', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Persediaan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_225', 'adil002', 'Adila Marsada Roha Sinurat', 'adila.marsada.roha.sinurat@brin.go.id', 'adilamarsadarohasinurat@gmail.com', '082273923064', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Persediaan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_226', 'syif008', 'Syifa Nurul Syafitri', 'syifa.nurul.syafitri@brin.go.id', 'syafitrisyifa12@gmail.com', '08889402864', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Persediaan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_227', 'ikhd001', 'Ikhda Rofiqotul Khoiriyah', 'ikhda.rofiqotul.khoiriyah@brin.go.id', 'ikhdakhoiriyah235@gmail.com', '083861850481', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Persediaan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_228', 'hani027', 'Hani Rufaidah', 'hani.rufaidah@brin.go.id', 'hani2002.hr@gmail.com', '081945060289', 'Perempuan', 'Sesdep DIRI', NULL, 'Asisten Persediaan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_229', 'haid002', 'Haidar Ahmad', 'haidar.ahmad@brin.go.id', 'haidarboy26@gmail.com', '082258088428', 'Laki-Laki', 'Sesdep DKP', NULL, 'Asisten Komunikasi Publik DKP', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_230', 'agne005', 'Agnes Tesalonika Padang', 'agnes.tesalonika.padang@brin.go.id', 'agnespadang22@gmail.com', '082347161773', 'Perempuan', 'Sesdep DKP', NULL, 'Asisten Perencanaan Program & Keuangan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_231', 'evri001', 'Evrilya Kemaladewi', 'evrilya.kemaladewi@brin.go.id', 'evrilyakemala@gmail.com', '0895359853626', 'Perempuan', 'Sesdep DKRI', NULL, 'Asisten Komunikasi Publik DKRI', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_232', 'prim014', 'Primaresti Resandriya', 'primaresti.resandriya@brin.go.id', 'primrestiresandriya@gmail.com', '081298651323', 'Perempuan', 'Sesdep DKRI', NULL, 'Asisten Perencanaan Program & Keuangan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_233', 'amar008', 'Amardina Qoni’Atun Nisaa’', 'amardina.qoni’atun.nisaa’@brin.go.id', 'amardinanisaa@gmail.com', '082329323836', 'Perempuan', 'Sesdep DPRI', NULL, 'Asisten Komunikasi Publik DPRI', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_234', 'grac007', 'Grace Clara Gabriella', 'grace.clara.gabriella@brin.go.id', 'ggraceclargab@gmail.com', '082130506757', 'Perempuan', 'Sesdep DPRI', NULL, 'Asisten Perencanaan Program & Keuangan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_235', 'nabi012', 'Nabila Desinta Budiono', 'nabila.desinta.budiono@brin.go.id', 'nabjenabbb26@gmail.com', '081398358061', 'Perempuan', 'Sesdep DRID', NULL, 'Asisten Ketatausahaan & Kearsipan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_236', 'rade046', 'Raden Ajeng Ayu Tiara Girindraningrum', 'raden.ajeng.ayu.tiara.girindraningrum@brin.go.id', 'raayutiara@gmail.com', '082130707827', 'Perempuan', 'Sesdep DRID', NULL, 'Asisten Perencanaan Program & Keuangan', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_237', 'muha405', 'Muhammad Farhat Luthfi', 'muhammad.farhat.luthfi@brin.go.id', 'farhat2674@gmail.com', '085314728041', 'Laki-Laki', 'Sesdep DSDMI', NULL, 'Asisten Komunikasi Publik DSDMI', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_238', 'inda892', 'Indah Amelia', 'indah.amelia@brin.go.id', 'indahameliaa1703@gmail.com', '081317012270', 'Perempuan', 'Sesdep DSDMI', NULL, 'Asisten Komunikasi Publik DSDMI', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_239', 'azka002', 'Azka Alifia Dharmawan', 'azka.alifia.dharmawan@brin.go.id', 'azkaalifia26@gmail.com', '082146194341', 'Perempuan', 'Sesdep DSDMI', NULL, 'Asisten Perencanaan Program & Anggaran DSDMI', 'LKSDM 8', 'Member', 'Password123!'),
  ('usr_240', 'anni036', 'Annisah Tanziela Aziezir', 'annisah.tanziela.aziezir@brin.go.id', 'annisahtanzielaaziezir@gmail.com', '0895406719696', 'Perempuan', 'BOSDM', 'tim_019', 'Asisten Hubungan Antar Lembaga', 'LKSDM 1', 'Staff Admin', 'Password123!');

-- 8. SEED TIKET PENGUJIAN ALUR 3-PIHAK (PEGAWAI -> LKSDM -> PUSAT)
INSERT INTO public.questions (
  id, ticket_number, user_id, judul, isi, status, lksdm_kawasan, target_tim_pusat, id_tusi, tugas_fungsi_nama, admin_lksdm_id, admin_pusat_id, is_public, created_at
) VALUES (
  1, 'TKT-202610-0001', 'usr_007', 
  'Kendala Pengusulan SK Penyetaraan Ijazah S3 LN',
  'Ijazah doktoral saya telah disetarakan Kemendikbud, namun belum muncul pada profil SIMPEG kawasan Thamrin.',
  'dialihkan_ke_pusat',
  'LKSDM 1',
  'PKSPU',
  'ts_019',
  'Melaksanakan pengembangan karier (proyeksi mutasi, rotasi, promosi jabatan, konversi jabatan)',
  'usr_018',
  'usr_002',
  true,
  NOW() - INTERVAL '3 hours'
);

INSERT INTO public.answers (question_id, user_id, sender_name, sender_role, isi_pesan, created_at) VALUES
  (1, 'usr_007', 'Manda Talita Taruli Hasibuan', 'Member', 'Halo rekan admin kawasan, mohon dibantu verifikasi berkas penyetaraan ijazah S3 saya.', NOW() - INTERVAL '2 hours 50 mins'),
  (1, 'usr_018', 'Maria Fernanda De Vega', 'Staff Admin', 'Halo Mbak Manda, berkas kawasan sudah kami periksa. Namun validasi penyesuaian gelar pusat membutuhkan koordinasi dengan Tim Pusat (PKSPU). Tiket saya eskalasikan ke Pusat ya.', NOW() - INTERVAL '2 hours 30 mins'),
  (1, NULL, 'Sistem', 'System', 'Tiket telah dialihkan oleh Maria Fernanda De Vega (LKSDM) ke Tim Pusat (PKSPU).', NOW() - INTERVAL '2 hours 28 mins'),
  (1, 'usr_002', 'Syifaniar Ramadhanny', 'Staff Admin', 'Halo Mbak Manda dan Mbak Maria. Berkas penyesuaian gelar sudah kami validasi di basis data pusat dan akan sinkron ke profil dalam 1x24 jam.', NOW() - INTERVAL '1 hour');

-- 9. REALTIME REPLICATION
ALTER PUBLICATION supabase_realtime ADD TABLE public.teams;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tugas_fungsi;
ALTER PUBLICATION supabase_realtime ADD TABLE public.team_tusi;
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
ALTER PUBLICATION supabase_realtime ADD TABLE public.questions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.answers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
