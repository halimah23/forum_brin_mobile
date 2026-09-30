-- ==============================================================
-- SQL SEEDER LENGKAP: TUGAS FUNGSI, CONTOH TIKET & JAWABAN TIM
-- Berdasarkan Model QuestionModel, QuestionService, & TusiCatalogData
-- ==============================================================

-- 1. SEEDER KATALOG MASTER TUGAS FUNGSI (106 TUSI - 15 TIM)
INSERT INTO public.tugas_fungsi (id, kode, nama, team_name) VALUES
  -- 1. Tim Ortala
  (1, 'BRIN-04.03.01.01', 'BRIN-04.03.01.01 - Evaluasi Organisasi', 'Tim Ortala'),
  (2, 'BRIN-04.03.01.02', 'BRIN-04.03.01.02 - Penataan Organisasi', 'Tim Ortala'),
  (3, 'BRIN-04.03.01.03', 'BRIN-04.03.01.03 - Penyusunan Analisis Jabatan', 'Tim Ortala'),
  (4, 'BRIN-04.03.01.04', 'BRIN-04.03.01.04 - Penyusunan Evaluasi Jabatan', 'Tim Ortala'),
  (5, 'BRIN-04.03.01.05', 'BRIN-04.03.01.05 - Penyusunan Peta Jabatan', 'Tim Ortala'),
  (6, 'BRIN-04.03.01.06', 'BRIN-04.03.01.06 - Sistem Kerja', 'Tim Ortala'),
  (7, 'BRIN-04.03.02.01', 'BRIN-04.03.02.01 - Pemetaan Proses Bisnis', 'Tim Ortala'),
  (8, 'BRIN-04.03.02.01.04', 'BRIN-04.03.02.01.04 - Penyusunan SOP', 'Tim Ortala'),
  (9, 'BRIN-04.03.02.01.05', 'BRIN-04.03.02.01.05 - Evaluasi SOP', 'Tim Ortala'),
  (10, 'BRIN-04.03.02.02', 'BRIN-04.03.02.02 - Pengelolaan Layanan SDM Kawasan', 'Tim Ortala'),

  -- 2. Tim Sekretariat RB
  (11, 'BRIN-04.03.03', 'BRIN-04.03.03 - Pelaksanaan Reformasi Birokrasi', 'Tim Sekretariat RB'),
  (12, 'BRIN-04.03.03.01', 'BRIN-04.03.03.01 - Pelaksanaan Reformasi Birokrasi Sub-Unit', 'Tim Sekretariat RB'),
  (13, 'BRIN-04.03.03.02', 'BRIN-04.03.03.02 - Zona Integritas', 'Tim Sekretariat RB'),

  -- 3. Tim Perencanaan dan Pengembangan Karier
  (14, 'BRIN-04.03.04', 'BRIN-04.03.04 - Perencanaan dan Pengembangan Karier SDM', 'Tim Perencanaan dan Pengembangan Karier'),
  (15, 'BRIN-04.03.04.01', 'BRIN-04.03.04.01 - Penyusunan Analisis Beban Kerja', 'Tim Perencanaan dan Pengembangan Karier'),
  (16, 'BRIN-04.03.04.02', 'BRIN-04.03.04.02 - Perencanaan ASN', 'Tim Perencanaan dan Pengembangan Karier'),
  (17, 'BRIN-04.03.04.03', 'BRIN-04.03.04.03 - Pengadaan SDM', 'Tim Perencanaan dan Pengembangan Karier'),
  (18, 'BRIN-04.03.04.04', 'BRIN-04.03.04.04 - Penempatan CASN', 'Tim Perencanaan dan Pengembangan Karier'),
  (19, 'BRIN-04.03.04.05', 'BRIN-04.03.04.05 - Penataan SDM', 'Tim Perencanaan dan Pengembangan Karier'),
  (20, 'BRIN-04.03.04.06', 'BRIN-04.03.04.06 - Pengembangan Karier', 'Tim Perencanaan dan Pengembangan Karier'),
  (21, 'BRIN-04.03.04.07', 'BRIN-04.03.04.07 - Pelaksanaan Sidang Tim Penilai Kinerja Pegawai (Baperjakat)', 'Tim Perencanaan dan Pengembangan Karier'),
  (22, 'BRIN-04.03.04.08', 'BRIN-04.03.04.08 - Lokasi Kerja Eksternal Periset BRIN', 'Tim Perencanaan dan Pengembangan Karier'),

  -- 4. Tim Penilaian Kompetensi
  (23, 'BRIN-04.03.05', 'BRIN-04.03.05 - Penilaian dan Pengembangan SDM', 'Tim Penilaian Kompetensi'),
  (24, 'BRIN-04.03.05.01', 'BRIN-04.03.05.01 - Standarisasi Jabatan', 'Tim Penilaian Kompetensi'),
  (25, 'BRIN-04.03.05.02', 'BRIN-04.03.05.02 - Penilaian Kompetensi', 'Tim Penilaian Kompetensi'),
  (26, 'BRIN-04.03.05.06', 'BRIN-04.03.05.06 - Manajemen Talenta ASN BRIN', 'Tim Penilaian Kompetensi'),

  -- 5. Tim Perencanaan dan Pengembangan Kompetensi
  (27, 'BRIN-04.03.05.03', 'BRIN-04.03.05.03 - Penyusunan Rencana Kebutuhan & Pengembangan Kompetensi', 'Tim Perencanaan dan Pengembangan Kompetensi'),
  (28, 'BRIN-04.03.05.04', 'BRIN-04.03.05.04 - Pelaksanaan Pengembangan Kompetensi', 'Tim Perencanaan dan Pengembangan Kompetensi'),
  (29, 'BRIN-04.03.05.05', 'BRIN-04.03.05.05 - Evaluasi Pengembangan Kompetensi', 'Tim Perencanaan dan Pengembangan Kompetensi'),
  (30, 'BRIN-04.03.05.08', 'BRIN-04.03.05.08 - Ujian Penyesuaian Kenaikan Pangkat (UPKP)', 'Tim Perencanaan dan Pengembangan Kompetensi'),
  (31, 'BRIN-04.03.05.09', 'BRIN-04.03.05.09 - Pencantuman Gelar Akademik', 'Tim Perencanaan dan Pengembangan Kompetensi'),

  -- 6. Tim Mutasi Umum dan Kesejahteraan
  (32, 'BRIN-04.03.06', 'BRIN-04.03.06 - Pengelolaan Mutasi SDM', 'Tim Mutasi Umum dan Kesejahteraan'),
  (33, 'BRIN-04.03.06.01.01', 'BRIN-04.03.06.01.01 - Pengaktifan Kembali', 'Tim Mutasi Umum dan Kesejahteraan'),
  (34, 'BRIN-04.03.06.01.02', 'BRIN-04.03.06.01.02 - Penerbitan SK PNS', 'Tim Mutasi Umum dan Kesejahteraan'),
  (35, 'BRIN-04.03.06.01.03', 'BRIN-04.03.06.01.03 - Pelantikan & Sumpah Jabatan', 'Tim Mutasi Umum dan Kesejahteraan'),
  (36, 'BRIN-04.03.06.01.04', 'BRIN-04.03.06.01.04 - Mutasi Pegawai', 'Tim Mutasi Umum dan Kesejahteraan'),
  (37, 'BRIN-04.03.06.01.05', 'BRIN-04.03.06.01.05 - Pemberhentian SDM', 'Tim Mutasi Umum dan Kesejahteraan'),
  (38, 'BRIN-04.03.06.01.06', 'BRIN-04.03.06.01.06 - Kenaikan Pangkat', 'Tim Mutasi Umum dan Kesejahteraan'),
  (39, 'BRIN-04.03.06.01.07', 'BRIN-04.03.06.01.07 - Peninjauan Masa Kerja', 'Tim Mutasi Umum dan Kesejahteraan'),
  (40, 'BRIN-04.03.06.01.08', 'BRIN-04.03.06.01.08 - Penugasan ke Instansi Luar', 'Tim Mutasi Umum dan Kesejahteraan'),
  (41, 'BRIN-04.03.06.01.09', 'BRIN-04.03.06.01.09 - Penetapan Tewas', 'Tim Mutasi Umum dan Kesejahteraan'),
  (42, 'BRIN-04.03.06.01.10', 'BRIN-04.03.06.01.10 - Jamkestama/Jamkesmen', 'Tim Mutasi Umum dan Kesejahteraan'),
  (43, 'BRIN-04.03.06.01.11', 'BRIN-04.03.06.01.11 - Penetapan Kecelakaan Kerja & Penyakit Akibat Kerja', 'Tim Mutasi Umum dan Kesejahteraan'),

  -- 7. Tim Mutasi dan Pengelolaan JF 1
  (44, 'BRIN-04.03.06.02.01.01', 'BRIN-04.03.06.02.01.01 - Penilaian Usulan HKM', 'Tim Mutasi dan Pengelolaan JF 1'),
  (45, 'BRIN-04.03.06.02.01.02', 'BRIN-04.03.06.02.01.02 - Fasilitasi Uji Kompetensi (Kenaikan Jenjang Jabatan)', 'Tim Mutasi dan Pengelolaan JF 1'),
  (46, 'BRIN-04.03.06.02.01.03', 'BRIN-04.03.06.02.01.03 - Fasilitasi Uji Kompetensi (Perpindahan Jabatan)', 'Tim Mutasi dan Pengelolaan JF 1'),
  (47, 'BRIN-04.03.06.02.01.04', 'BRIN-04.03.06.02.01.04 - Pemberhentian JF Peneliti', 'Tim Mutasi dan Pengelolaan JF 1'),
  (48, 'BRIN-04.03.06.02.01.05', 'BRIN-04.03.06.02.01.05 - Pengangkatan Kembali', 'Tim Mutasi dan Pengelolaan JF 1'),

  -- 8. Tim Mutasi dan Pengelolaan JF 2
  (49, 'BRIN-04.03.06.02.02.02.01', 'BRIN-04.03.06.02.02.02.01 - Penyusunan PAK', 'Tim Mutasi dan Pengelolaan JF 2'),
  (50, 'BRIN-04.03.06.02.02.02.02', 'BRIN-04.03.06.02.02.02.02 - Uji Kompetensi', 'Tim Mutasi dan Pengelolaan JF 2'),
  (51, 'BRIN-04.03.06.02.02.02.03', 'BRIN-04.03.06.02.02.02.03 - Pemberhentian JF', 'Tim Mutasi dan Pengelolaan JF 2'),
  (52, 'BRIN-04.03.06.02.02.02.04', 'BRIN-04.03.06.02.02.02.04 - Pengangkatan Kembali JF', 'Tim Mutasi dan Pengelolaan JF 2'),
  (53, 'BRIN-04.03.06.02.02.02.05', 'BRIN-04.03.06.02.02.02.05 - Kenaikan Pangkat karena Peningkatan Pendidikan', 'Tim Mutasi dan Pengelolaan JF 2'),

  -- 9. Tim Mutasi dan Pengelolaan JF 3
  (54, 'BRIN-04.03.06.02.03.01', 'BRIN-04.03.06.02.03.01 - Penyusunan PAK', 'Tim Mutasi dan Pengelolaan JF 3'),
  (55, 'BRIN-04.03.06.02.03.02', 'BRIN-04.03.06.02.03.02 - Uji Kompetensi', 'Tim Mutasi dan Pengelolaan JF 3'),
  (56, 'BRIN-04.03.06.02.03.03', 'BRIN-04.03.06.02.03.03 - Pemberhentian JF', 'Tim Mutasi dan Pengelolaan JF 3'),
  (57, 'BRIN-04.03.06.02.03.04', 'BRIN-04.03.06.02.03.04 - Pengangkatan Kembali JF', 'Tim Mutasi dan Pengelolaan JF 3'),
  (58, 'BRIN-04.03.06.02.03.05', 'BRIN-04.03.06.02.03.05 - Kenaikan Pangkat karena Peningkatan Pendidikan', 'Tim Mutasi dan Pengelolaan JF 3'),

  -- 10. Tim Sekretariat Majelis Profesor Riset
  (59, 'BRIN-04.03.06.03', 'BRIN-04.03.06.03 - Penilaian Naskah Orasi Profesor Riset', 'Tim Sekretariat Majelis Profesor Riset'),

  -- 11. Tim Manajemen Kinerja
  (60, 'BRIN-04.03.07.01', 'BRIN-04.03.07.01 - Perencanaan Kinerja', 'Tim Manajemen Kinerja'),
  (61, 'BRIN-04.03.07.02', 'BRIN-04.03.07.02 - Pemantauan Kinerja', 'Tim Manajemen Kinerja'),
  (62, 'BRIN-04.03.07.03', 'BRIN-04.03.07.03 - Penilaian dan Evaluasi Kinerja', 'Tim Manajemen Kinerja'),
  (63, 'BRIN-04.03.07.04', 'BRIN-04.03.07.04 - Tindak Lanjut Kinerja', 'Tim Manajemen Kinerja'),
  (64, 'BRIN-04.03.07.05', 'BRIN-04.03.07.05 - Penghargaan', 'Tim Manajemen Kinerja'),
  (65, 'BRIN-04.03.07.06', 'BRIN-04.03.07.06 - Manajemen Resiko', 'Tim Manajemen Kinerja'),
  (66, 'BRIN-04.03.07.07', 'BRIN-04.03.07.07 - Evaluasi Periodik', 'Tim Manajemen Kinerja'),
  (67, 'BRIN-04.03.07.08', 'BRIN-04.03.07.08 - Pendokumentasian Hasil Kerja pada SIMARIN', 'Tim Manajemen Kinerja'),

  -- 12. Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN
  (68, 'BRIN-04.03.08.01', 'BRIN-04.03.08.01 - CLTN (Cuti di Luar Tanggungan Negara)', 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN'),
  (69, 'BRIN-04.03.08.02', 'BRIN-04.03.08.02 - Pembinaan Disiplin', 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN'),
  (70, 'BRIN-04.03.08.03', 'BRIN-04.03.08.03 - Perceraian', 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN'),
  (71, 'BRIN-04.03.08.04', 'BRIN-04.03.08.04 - Monitoring dan Evaluasi Pemberian Cuti ASN', 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN'),
  (72, 'BRIN-04.03.08.05', 'BRIN-04.03.08.05 - Pemberhentian Sementara PNS (Tersangka Dugaan Pidana)', 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN'),
  (73, 'BRIN-04.03.08.06', 'BRIN-04.03.08.06 - Permohonan PNS Pria Beristri Lebih dari Satu', 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN'),
  (74, 'BRIN-04.03.08.07', 'BRIN-04.03.08.07 - Aktif Kembali setelah Menjalani Hukuman Pidana', 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN'),
  (75, 'BRIN-04.03.08.08', 'BRIN-04.03.08.08 - Pemberhentian PNS Lain-Lain', 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN'),
  (76, 'BRIN-04.03.08.09', 'BRIN-04.03.08.09 - Pemberhentian karena Terbukti Menggunakan Ijazah Palsu', 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN'),
  (77, 'BRIN-04.03.08.14', 'BRIN-04.03.08.14 - Penanganan Aduan/Laporan Dugaan Pelanggaran Disiplin & Kode Etik', 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN'),

  -- 13. Tim Pengelolaan Data dan Informasi SDM
  (78, 'BRIN-04.03.09.01', 'BRIN-04.03.09.01 - Pemutakhiran Dokumen', 'Tim Pengelolaan Data dan Informasi SDM'),
  (79, 'BRIN-04.03.09.02', 'BRIN-04.03.09.02 - Permintaan Data dan Informasi SDM', 'Tim Pengelolaan Data dan Informasi SDM'),
  (80, 'BRIN-04.03.09.03', 'BRIN-04.03.09.03 - Penerbitan Karis/Karsu Virtual', 'Tim Pengelolaan Data dan Informasi SDM'),
  (81, 'BRIN-04.03.09.04', 'BRIN-04.03.09.04 - Pencetakan Ulang ID Card Baru/Karena Hilang/Rusak', 'Tim Pengelolaan Data dan Informasi SDM'),
  (82, 'BRIN-04.03.09.05', 'BRIN-04.03.09.05 - Perbaikan Identitas (Nama, Tanggal Lahir) PNS', 'Tim Pengelolaan Data dan Informasi SDM'),
  (83, 'BRIN-04.03.09.06', 'BRIN-04.03.09.06 - Pelaksanaan Updating Data Pegawai', 'Tim Pengelolaan Data dan Informasi SDM'),
  (84, 'BRIN-04.03.09.07', 'BRIN-04.03.09.07 - Pemberian Role Akses Pegawai', 'Tim Pengelolaan Data dan Informasi SDM'),
  (85, 'BRIN-04.03.09.08', 'BRIN-04.03.09.08 - Pemutakhiran Status Pekerjaan pada Tapera', 'Tim Pengelolaan Data dan Informasi SDM'),
  (86, 'BRIN-04.03.09.09', 'BRIN-04.03.09.09 - Penyampaian Output Layanan melalui Perubahan Faktor Gaji SIMPEG', 'Tim Pengelolaan Data dan Informasi SDM'),
  (87, 'BRIN-04.03.09.10', 'BRIN-04.03.09.10 - Pengelolaan Cuti ASN', 'Tim Pengelolaan Data dan Informasi SDM'),
  (88, 'BRIN-04.03.09.11', 'BRIN-04.03.09.11 - Permohonan Pemberhentian Role Akses', 'Tim Pengelolaan Data dan Informasi SDM'),

  -- 14. Tim Program Pembinaan dan Penugasan Ulang
  (89, 'BRIN-04.03.11', 'BRIN-04.03.11 - Program Pembinaan dan Penugasan Ulang Pegawai', 'Tim Program Pembinaan dan Penugasan Ulang'),

  -- 15. Tim LKSDM
  (90, 'BRIN-04.03.10.01', 'BRIN-04.03.10.01 - Layanan Selesai di Kawasan', 'Tim LKSDM'),
  (91, 'BRIN-04.03.10.01.01', 'BRIN-04.03.10.01.01 - Layanan Otomatis Selesai di Kawasan', 'Tim LKSDM'),
  (92, 'BRIN-04.03.10.01.01.01', 'BRIN-04.03.10.01.01.01 - Hukuman Disiplin Pegawai Ringan', 'Tim LKSDM'),
  (93, 'BRIN-04.03.10.01.01.02', 'BRIN-04.03.10.01.01.02 - Fasilitasi Kenaikan Gaji Berkala (KGB)', 'Tim LKSDM'),
  (94, 'BRIN-04.03.10.01.01.03', 'BRIN-04.03.10.01.01.03 - Monitoring Pegawai Tubel', 'Tim LKSDM'),
  (95, 'BRIN-04.03.10.01.01.04', 'BRIN-04.03.10.01.01.04 - Monitoring Kehadiran Pegawai', 'Tim LKSDM'),
  (96, 'BRIN-04.03.10.01.02.01', 'BRIN-04.03.10.01.02.01 - Laporan Kelahiran Anak/ Perkawinan/ Perceraian', 'Tim LKSDM'),
  (97, 'BRIN-04.03.10.01.02.02', 'BRIN-04.03.10.01.02.02 - Laporan Pembayaran Gaji/Uang Makan Tidak Sesuai', 'Tim LKSDM'),
  (98, 'BRIN-04.03.10.01.02.03', 'BRIN-04.03.10.01.02.03 - Penerbitan Surat Izin Cerai/Keterangan Perceraian', 'Tim LKSDM'),
  (99, 'BRIN-04.03.10.01.02.04', 'BRIN-04.03.10.01.02.04 - Pelaporan Perpanjangan Tunjangan/Hak PNS', 'Tim LKSDM'),
  (100, 'BRIN-04.03.10.01.02.05', 'BRIN-04.03.10.01.02.05 - Tugas Belajar', 'Tim LKSDM'),
  (101, 'BRIN-04.03.10.01.02.06', 'BRIN-04.03.10.01.02.06 - Penerbitan Surat Pengantar SP Setneg Tugas Belajar', 'Tim LKSDM'),
  (102, 'BRIN-04.03.10.01.02.07', 'BRIN-04.03.10.01.02.07 - Laporan Perceraian/Meninggalnya Suami/Istri/Anak PNS', 'Tim LKSDM'),
  (103, 'BRIN-04.03.10.01.02.08', 'BRIN-04.03.10.01.02.08 - Laporan Penghentian Tunjangan Anak PNS', 'Tim LKSDM'),
  (104, 'BRIN-04.03.10.01.02.09', 'BRIN-04.03.10.01.02.09 - Pendaftaran BPJS untuk Anggota Keluarga Lainnya', 'Tim LKSDM'),
  (105, 'BRIN-04.03.10.01.02.10', 'BRIN-04.03.10.01.02.10 - Pendaftaran BPJS untuk PNS Baru / Anak 1-3 / Perpanjangan BPJS', 'Tim LKSDM'),
  (106, 'BRIN-04.03.10.01.02.11', 'BRIN-04.03.10.01.02.11 - Pengajuan Cuti Besar', 'Tim LKSDM')
ON CONFLICT (id) DO UPDATE 
SET kode = EXCLUDED.kode, nama = EXCLUDED.nama, team_name = EXCLUDED.team_name;
