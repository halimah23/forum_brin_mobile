-- ============================================================================
-- 05_SEED_TEAMS_AND_TUSI.SQL
-- BOSDM CONNECT - SISTEM FORUM & LAYANAN TERPADU INSTANSI BRIN
-- Modul: Inisialisasi Data Master (22 Tim BRIN, 91 Tugas Fungsi, dan Relasi)
-- Target: Supabase PostgreSQL (Fresh / Empty Database)
-- Urutan Eksekusi: #5 (Kelima)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. SEED DATA: 22 TIM RESMI BRIN (14 Tim Pusat + 8 LKSDM Wilayah Kawasan)
-- ----------------------------------------------------------------------------
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
2) Pengelolaan SDM Settama di OR mengikuti pembagian pengelolaan OR;', 'LKSDM')
ON CONFLICT (id_tim) DO UPDATE
SET tim = EXCLUDED.tim,
    detail_nama_tim = EXCLUDED.detail_nama_tim,
    coverage = EXCLUDED.coverage,
    sebaran_hbp = EXCLUDED.sebaran_hbp,
    catatan = EXCLUDED.catatan,
    eskalasi = EXCLUDED.eskalasi;

-- ----------------------------------------------------------------------------
-- 2. SEED DATA: 91 TUGAS DAN FUNGSI RESMI SESUAI SOP INSTANSI
-- ----------------------------------------------------------------------------
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
  ('ts_091', 'Melaksanakan verifikasi layanan kepegawaian yang selesai di pusat')
ON CONFLICT (id_tusi) DO UPDATE
SET tugas_fungsi = EXCLUDED.tugas_fungsi;

-- ----------------------------------------------------------------------------
-- 3. SEED DATA: PEMETAAN RELASI TEAM_TUSI (MANY-TO-MANY)
-- ----------------------------------------------------------------------------
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
  ('tim_022', 'ts_091')
ON CONFLICT (id_tim, id_tusi) DO NOTHING;
