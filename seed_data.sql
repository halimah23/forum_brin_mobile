-- ==============================================================
-- DATA SEEDER LENGKAP PLATFORM BOSDM CONNECT (BRIN)
-- Memuat: Auth Users, Profiles Role, Master Tusi (106 Items / 15 Tim), Tiket & Jawaban
-- ==============================================================

-- 1. SEEDER AUTH USERS (Memastikan ID User Ada di Schema auth.users)
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  role,
  aud
) VALUES 
  ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000', 'superadmin@brin.go.id', crypt('Password123!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Super Admin BOSDM","role":"super_admin"}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000', 'ketua.ortala@brin.go.id', crypt('Password123!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Dr. Hendra (Ketua Tim Ortala)","role":"ketua_tim"}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000000', 'ketua.jf1@brin.go.id', crypt('Password123!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Rina Wati, S.T. (Ketua Tim Mutasi JF 1)","role":"ketua_tim"}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('44444444-4444-4444-4444-444444444444', '00000000-0000-0000-0000-000000000000', 'analis.jf1@brin.go.id', crypt('Password123!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Analis JF Peneliti","role":"admin"}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', '00000000-0000-0000-0000-000000000000', 'admin.lksdm.bandung@brin.go.id', crypt('Password123!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Staf LKSDM Kawasan Bandung","role":"admin"}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('66666666-6666-6666-6666-666666666666', '00000000-0000-0000-0000-000000000000', 'direktur.bosdm@brin.go.id', crypt('Password123!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Dr. Ir. Bambang (Direktur BOSDM)","role":"eksekutif"}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('77777777-7777-7777-7777-777777777777', '00000000-0000-0000-0000-000000000000', 'budi.pegawai@brin.go.id', crypt('Password123!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Budi Santoso (Pegawai Periset)","role":"member"}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('88888888-8888-8888-8888-888888888888', '00000000-0000-0000-0000-000000000000', 'siti.periset@brin.go.id', crypt('Password123!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Siti Rahma (Pegawai Administrasi)","role":"member"}', NOW(), NOW(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- 2. SEEDER PROFILES (BERBAGAI ROLE & TIM/LKSDM)
INSERT INTO public.profiles (id, name, email, role, unit, tim, jabatan) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Super Admin BOSDM', 'superadmin@brin.go.id', 'super_admin', 'BOSDM Pusat', 'Tim Pengelolaan Data dan Informasi SDM', 'Administrator Utama'),
  ('22222222-2222-2222-2222-222222222222', 'Dr. Hendra (Ketua Tim Ortala)', 'ketua.ortala@brin.go.id', 'ketua_tim', 'BOSDM Pusat', 'Tim Ortala', 'Ketua Tim Organisasi & Tata Laksana'),
  ('33333333-3333-3333-3333-333333333333', 'Rina Wati, S.T. (Ketua Tim Mutasi JF 1)', 'ketua.jf1@brin.go.id', 'ketua_tim', 'BOSDM Pusat', 'Tim Mutasi dan Pengelolaan JF 1', 'Ketua Tim Mutasi JF 1'),
  ('44444444-4444-4444-4444-444444444444', 'Analis JF Peneliti', 'analis.jf1@brin.go.id', 'admin', 'BOSDM Pusat', 'Tim Mutasi dan Pengelolaan JF 1', 'Analis SDM Layanan JF'),
  ('55555555-5555-5555-5555-555555555555', 'Staf LKSDM Kawasan Bandung', 'admin.lksdm.bandung@brin.go.id', 'admin', 'LKSDM Bandung', 'Tim LKSDM', 'Staf Layanan Kawasan Bandung'),
  ('66666666-6666-6666-6666-666666666666', 'Dr. Ir. Bambang (Direktur BOSDM)', 'direktur.bosdm@brin.go.id', 'eksekutif', 'BOSDM Pusat', 'Pimpinan', 'Direktur BOSDM BRIN'),
  ('77777777-7777-7777-7777-777777777777', 'Budi Santoso (Pegawai Periset)', 'budi.pegawai@brin.go.id', 'pegawai', 'PR Fisika', 'Kelompok Riset Optik', 'Periset Ahli Muda'),
  ('88888888-8888-8888-8888-888888888888', 'Siti Rahma (Pegawai Administrasi)', 'siti.periset@brin.go.id', 'pegawai', 'PR Bioteknologi', 'Tata Usaha', 'Pranata Humas')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name, email = EXCLUDED.email, role = EXCLUDED.role, unit = EXCLUDED.unit, tim = EXCLUDED.tim, jabatan = EXCLUDED.jabatan;

-- 3. SEEDER KATALOG MASTER TUGAS FUNGSI (106 TUSI - 15 TIM)
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

-- 4. SEEDER TIKET PERTANYAAN (MEMUAT VARIASI STATUS TICKETING & ROUTING TIM)
INSERT INTO public.questions (id, user_id, ticket_number, judul, isi, status, target_tim, assigned_to, tugas_fungsi_nama, is_public, created_at) VALUES
  (101, '77777777-7777-7777-7777-777777777777', 'TKT-202609-001', 'Persyaratan Usulan Hasil Kerja Maksimal (HKM) Peneliti Utama', 'Mohon informasi kelengkapan dokumen pendukung usulan HKM Peneliti jenjang Utama tahun 2026.', 'dijawab', 'Tim Mutasi dan Pengelolaan JF 1', 'Analis JF Peneliti', 'BRIN-04.03.06.02.01.01 - Penilaian Usulan HKM', true, NOW() - INTERVAL '2 days'),
  
  (102, '88888888-8888-8888-8888-888888888888', 'TKT-202609-002', 'Prosedur Penyusunan Evaluasi Jabatan Fungsional', 'Bagaimana tahapan pengajuan review Evaluasi Jabatan untuk unit riset baru?', 'sedang_diproses', 'Tim Ortala', 'Dr. Hendra', 'BRIN-04.03.01.04 - Penyusunan Evaluasi Jabatan', true, NOW() - INTERVAL '1 day'),
  
  (103, '77777777-7777-7777-7777-777777777777', 'TKT-202609-003', 'Pengajuan Cuti di Luar Tanggungan Negara (CLTN)', 'Apakah pengajuan CLTN untuk keperluan studi mandiri memerlukan rekomendasi dari kepala pusat?', 'menunggu_disposisi', 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', NULL, 'BRIN-04.03.08.01 - CLTN (Cuti di Luar Tanggungan Negara)', false, NOW() - INTERVAL '5 hours'),

  (104, '88888888-8888-8888-8888-888888888888', 'TKT-202609-004', 'Pencetakan Ulang ID Card Pegawai Hilang', 'ID card saya hilang saat penugasan lapangan. Apa saja berkas yang harus dilampirkan?', 'selesai', 'Tim Pengelolaan Data dan Informasi SDM', 'Super Admin BOSDM', 'BRIN-04.03.09.04 - Pencetakan Ulang ID Card Baru/Karena Hilang/Rusak', true, NOW() - INTERVAL '4 days')
ON CONFLICT (id) DO UPDATE SET
  ticket_number = EXCLUDED.ticket_number, judul = EXCLUDED.judul, isi = EXCLUDED.isi, status = EXCLUDED.status, target_tim = EXCLUDED.target_tim, assigned_to = EXCLUDED.assigned_to, tugas_fungsi_nama = EXCLUDED.tugas_fungsi_nama;

-- 5. SEEDER RELASI PERTANYAAN & TUSI
INSERT INTO public.question_tugas_fungsi (question_id, tugas_fungsi_id) VALUES
  (101, 44),
  (102, 4),
  (103, 68),
  (104, 81)
ON CONFLICT DO NOTHING;

-- 6. SEEDER JAWABAN RESMI TIM & AUTO-RESPONDER
INSERT INTO public.answers (id, question_id, penjawab_nama, penjawab_role, isi_jawaban, created_at) VALUES
  (1001, 101, 'Tim Mutasi dan Pengelolaan JF 1', 'Tim Layanan SDM BRIN', 'Halo Budi! Berkas pendukung usulan HKM Peneliti Utama mencakup: 1. Naskah Karya Tulis Ilmiah terpublikasi, 2. Surat Pernyataan Keabsahan Karya, 3. Rekomendasi Majelis Penilai. Berkas diunggah via portal SIMARIN.', NOW() - INTERVAL '1 day'),
  (1002, 104, 'Tim Pengelolaan Data dan Informasi SDM', 'Staf Layanan Data SDM', 'Permohonan ID Card baru telah disetujui. Surat Keterangan Hilang dari Kepolisian dan Form Penggantian ID Card sudah terverifikasi. ID Card fisik dapat diambil di sekretariat BOSDM.', NOW() - INTERVAL '3 days')
ON CONFLICT (id) DO UPDATE SET
  penjawab_nama = EXCLUDED.penjawab_nama, penjawab_role = EXCLUDED.penjawab_role, isi_jawaban = EXCLUDED.isi_jawaban;

-- 7. SINKRONISASI SEQUENCE DI POSGRESQL (MEMASTIKAN TIKET BARU PEGAWAI BISA MASUK KE DATABASE)
SELECT setval('public.questions_id_seq', GREATEST(COALESCE((SELECT MAX(id) FROM public.questions), 1), 105));
SELECT setval('public.answers_id_seq', GREATEST(COALESCE((SELECT MAX(id) FROM public.answers), 1), 1005));
SELECT setval('public.tugas_fungsi_id_seq', GREATEST(COALESCE((SELECT MAX(id) FROM public.tugas_fungsi), 1), 110));

