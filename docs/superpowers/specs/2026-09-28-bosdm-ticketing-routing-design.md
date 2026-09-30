# Spesifikasi Desain: Sistem Ticketing & Routing Tusi BOSDM BRIN

**Tanggal**: 28 September 2026  
**Status**: Disetujui (Approved)  
**Tujuan**: Implementasi sistem ticketing berbasis antrean dan routing pertanyaan otomatis ke 15 Tim Layanan BOSDM BRIN berdasarkan klasifikasi Tugas & Fungsi (Tusi), terintegrasi dengan database Supabase dan dukungan offline/fallback.

---

## 1. Latar Belakang & Kebutuhan

Pegawai (Member) di lingkungan BRIN membutuhkan kanal pengajuan pertanyaan dan konsultasi layanan kepegawaian BOSDM yang terarah. Setiap pertanyaan harus secara otomatis teridentifikasi dan disalurkan (*routed*) ke Tim terkait sesuai jenis pertanyaan dan kode Tusi (misal: kenaikan jenjang jabatan ke Tim Mutasi & Pengelolaan JF atau Tim Penilaian & Pengembangan Kompetensi).

Ketua Tim yang bersangkutan akan menerima tiket pada antrean timnya untuk kemudian:
1. **Mendisposisikan** tiket ke anggota tim teknis terkait, atau
2. **Menjawab langsung** pertanyaan tersebut secara resmi.

---

## 2. Struktur Master Data Tim & Tugas Fungsi (Tusi) BOSDM

Sistem mencakup 15 Tim Layanan BOSDM dengan rincian kode klasifikasi Tusi:

### Daftar Tim & Kode Tusi:
1. **Tim Ortala**
   - `BRIN-04.03.01.01` - Evaluasi Organisasi
   - `BRIN-04.03.01.02` - Penataan Organisasi
   - `BRIN-04.03.01.03` - Penyusunan Analisis Jabatan
   - `BRIN-04.03.01.04` - Penyusunan Evaluasi Jabatan
   - `BRIN-04.03.01.05` - Penyusunan Peta Jabatan
   - `BRIN-04.03.01.06` - Sistem Kerja
   - `BRIN-04.03.02.01` - Pemetaan Proses Bisnis
   - `BRIN-04.03.02.01.04` - Penyusunan SOP
   - `BRIN-04.03.02.01.05` - Evaluasi SOP
   - `BRIN-04.03.02.02` - Pengelolaan Layanan SDM Kawasan
2. **Tim Sekretariat RB**
   - `BRIN-04.03.03` - Pelaksanaan Reformasi Birokrasi
   - `BRIN-04.03.03.01` - Pelaksanaan Reformasi Birokrasi
   - `BRIN-04.03.03.02` - Zona Integritas
3. **Tim Perencanaan dan Pengembangan Karier**
   - `BRIN-04.03.04` - Perencanaan dan Pengembangan Karier SDM
   - `BRIN-04.03.04.01` - Penyusunan Analisis Beban Kerja
   - `BRIN-04.03.04.02` - Perencanaan ASN
   - `BRIN-04.03.04.03` - Pengadaan SDM
   - `BRIN-04.03.04.04` - Penempatan CASN
   - `BRIN-04.03.04.05` - Penataan SDM
   - `BRIN-04.03.04.06` - Pengembangan Karier
   - `BRIN-04.03.04.07` - Pelaksanaan Sidang Tim Penilai Kinerja Pegawai (Baperjakat)
   - `BRIN-04.03.04.08` - Lokasi Kerja Eksternal Periset BRIN
4. **Tim Penilaian Kompetensi**
   - `BRIN-04.03.05` - Penilaian dan Pengembangan SDM
   - `BRIN-04.03.05.01` - Standarisasi Jabatan
   - `BRIN-04.03.05.02` - Penilaian Kompetensi
   - `BRIN-04.03.05.06` - Manajemen Talenta ASN BRIN
5. **Tim Perencanaan dan Pengembangan Kompetensi**
   - `BRIN-04.03.05.03` - Penyusunan Rencana Kebutuhan & Pengembangan Kompetensi
   - `BRIN-04.03.05.04` - Pelaksanaan Pengembangan Kompetensi
   - `BRIN-04.03.05.05` - Evaluasi Pengembangan Kompetensi
   - `BRIN-04.03.05.08` - Ujian Penyesuaian Kenaikan Pangkat (UPKP)
   - `BRIN-04.03.05.09` - Pencantuman Gelar Akademik
6. **Tim Mutasi Umum dan Kesejahteraan**
   - `BRIN-04.03.06` - Pengelolaan Mutasi SDM
   - `BRIN-04.03.06.01.01` - Pengaktifan Kembali
   - `BRIN-04.03.06.01.02` - Penerbitan SK PNS
   - `BRIN-04.03.06.01.03` - Pelantikan & Sumpah Jabatan
   - `BRIN-04.03.06.01.04` - Mutasi Pegawai
   - `BRIN-04.03.06.01.05` - Pemberhentian SDM
   - `BRIN-04.03.06.01.06` - Kenaikan Pangkat
   - `BRIN-04.03.06.01.07` - Peninjauan Masa Kerja
   - `BRIN-04.03.06.01.08` - Penugasan ke Instansi Luar
   - `BRIN-04.03.06.01.09` - Penetapan Tewas
   - `BRIN-04.03.06.01.10` - Jamkestama/Jamkesmen
   - `BRIN-04.03.06.01.11` - Penetapan Kecelakaan Kerja & Penyakit Akibat Kerja
7. **Tim Mutasi dan Pengelolaan JF 1**
   - `BRIN-04.03.06.02.01.01` - Penilaian Usulan HKM
   - `BRIN-04.03.06.02.01.02` - Fasilitasi Uji Kompetensi (Kenaikan Jenjang Jabatan)
   - `BRIN-04.03.06.02.01.03` - Fasilitasi Uji Kompetensi (Perpindahan Jabatan)
   - `BRIN-04.03.06.02.01.04` - Pemberhentian JF Peneliti
   - `BRIN-04.03.06.02.01.05` - Pengangkatan Kembali
8. **Tim Mutasi dan Pengelolaan JF 2**
   - `BRIN-04.03.06.02.02.02.01` - Penyusunan PAK
   - `BRIN-04.03.06.02.02.02.02` - Uji Kompetensi
   - `BRIN-04.03.06.02.02.02.03` - Pemberhentian JF
   - `BRIN-04.03.06.02.02.02.04` - Pengangkatan Kembali JF
   - `BRIN-04.03.06.02.02.02.05` - Kenaikan Pangkat karena Peningkatan Pendidikan
9. **Tim Mutasi dan Pengelolaan JF 3**
   - `BRIN-04.03.06.02.03.01` - Penyusunan PAK
   - `BRIN-04.03.06.02.03.02` - Uji Kompetensi
   - `BRIN-04.03.06.02.02.02.03` - Pemberhentian JF
   - `BRIN-04.03.06.02.02.03.04` - Pengangkatan Kembali JF
   - `BRIN-04.03.06.02.02.03.05` - Kenaikan Pangkat karena Peningkatan Pendidikan
10. **Tim Sekretariat Majelis Profesor Riset**
    - `BRIN-04.03.06.03` - Penilaian Naskah Orasi Profesor Riset
11. **Tim Manajemen Kinerja**
    - `BRIN-04.03.07.01` - Perencanaan Kinerja
    - `BRIN-04.03.07.02` - Pemantauan Kinerja
    - `BRIN-04.03.07.03` - Penilaian dan Evaluasi Kinerja
    - `BRIN-04.03.07.04` - Tindak Lanjut
    - `BRIN-04.03.07.05` - Penghargaan
    - `BRIN-04.03.07.06` - Manajemen Resiko
    - `BRIN-04.03.07.07` - Evaluasi Periodik
    - `BRIN-04.03.07.08` - Pendokumentasian Hasil Kerja pada SIMARIN
12. **Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN**
    - `BRIN-04.03.08.01` - CLTN
    - `BRIN-04.03.08.02` - Pembinaan Disiplin
    - `BRIN-04.03.08.03` - Perceraian
    - `BRIN-04.03.08.04` - Monitoring dan Evaluasi Pemberian Cuti ASN
    - `BRIN-04.03.08.05` - Pemberhentian Sementara PNS (Tersangka Pidana)
    - `BRIN-04.03.08.06` - Permohonan PNS Pria Beristri Lebih dari Satu
    - `BRIN-04.03.08.07` - Aktif Kembali setelah Hukuman Pidana
    - `BRIN-04.03.08.08` - Pemberhentian PNS Lain-Lain
    - `BRIN-04.03.08.09` - Pemberhentian karena Ijazah Palsu
    - `BRIN-04.03.08.14` - Penanganan Aduan / Laporan Pelanggaran Disiplin & Kode Etik
13. **Tim Pengelolaan Data dan Informasi SDM**
    - `BRIN-04.03.09.01` - Pemutakhiran Dokumen
    - `BRIN-04.03.09.02` - Permintaan Data dan Informasi SDM
    - `BRIN-04.03.09.03` - Penerbitan Karis/Karsu Virtual
    - `BRIN-04.03.09.04` - Pencetakan Ulang ID Card
    - `BRIN-04.03.09.05` - Perbaikan Identitas (Nama/Tanggal Lahir)
    - `BRIN-04.03.09.06` - Pelaksanaan Updating Data Pegawai
    - `BRIN-04.03.09.07` - Pemberian Role Akses Pegawai
    - `BRIN-04.03.09.08` - Pemutakhiran Status Pekerjaan pada Tapera
    - `BRIN-04.03.09.09` - Perubahan Faktor Gaji pada SIMPEG
    - `BRIN-04.03.09.10` - Pengelolaan Cuti ASN
    - `BRIN-04.03.09.11` - Permohonan Pemberhentian Role Akses
14. **Tim Program Pembinaan dan Penugasan Ulang**
    - `BRIN-04.03.11` - Program Pembinaan dan Penugasan Ulang Pegawai
15. **Tim LKSDM (Layanan Kepegawaian Selesai di Kawasan)**
    - `BRIN-04.03.10.01` - Layanan Selesai di Kawasan
    - `BRIN-04.03.10.01.01.01` - Hukuman Disiplin Pegawai Ringan
    - `BRIN-04.03.10.01.01.02` - Fasilitasi Kenaikan Gaji Berkala (KGB)
    - `BRIN-04.03.10.01.01.03` - Monitoring Pegawai Tubel
    - `BRIN-04.03.10.01.01.04` - Monitoring Kehadiran Pegawai
    - `BRIN-04.03.10.01.02.01` - Laporan Kelahiran Anak/ Perkawinan/ Perceraian
    - `BRIN-04.03.10.01.02.02` - Laporan Pembayaran Gaji/Uang Makan Tidak Sesuai
    - `BRIN-04.03.10.01.02.03` - Penerbitan Surat Izin Cerai/Keterangan Perceraian
    - `BRIN-04.03.10.01.02.04` - Pelaporan Perpanjangan Tunjangan/Hak PNS
    - `BRIN-04.03.10.01.02.05` - Tugas Belajar
    - `BRIN-04.03.10.01.02.06` - Penerbitan Surat Pengantar SP Setneg Tugas Belajar
    - `BRIN-04.03.10.01.02.07` - Laporan Perceraian/Meninggalnya Anggota Keluarga
    - `BRIN-04.03.10.01.02.08` - Laporan Penghentian Tunjangan Anak
    - `BRIN-04.03.10.01.02.09` - Pendaftaran BPJS Keluarga Lainnya
    - `BRIN-04.03.10.01.02.10` - Pendaftaran BPJS PNS Baru / Anak 1-3
    - `BRIN-04.03.10.01.02.11` - Pengajuan Cuti Besar

---

## 3. Siklus Hidup & Status Tiket (Lifecycle)

| Status | Label UI | Deskripsi |
|---|---|---|
| `menunggu_disposisi` | 🟡 Menunggu Disposisi | Tiket baru diajukan oleh Member dan masuk ke antrean Ketua Tim tujuan. |
| `sedang_diproses` | 🔵 Sedang Diproses | Tiket telah didisposisikan oleh Ketua Tim ke anggota staf tim teknis. |
| `selesai` | 🟢 Selesai / Terjawab | Jawaban resmi telah diberikan oleh Ketua Tim / Anggota Tim. |

---

## 4. Desain Database Supabase

### Tabel `teams`
- `id` (serial / text primary key)
- `nama` (varchar)
- `deskripsi` (text, nullable)

### Tabel `tugas_fungsi`
- `id` (serial primary key)
- `kode` (varchar, misal: `BRIN-04.03.01.01`)
- `nama` (varchar)
- `team_id` (foreign key ke `teams.id` / `teams.nama`)

### Tabel `questions` (Tiket)
- `id` (serial / uuid primary key)
- `ticket_number` (varchar, generated e.g. `TKT-2026-0001`)
- `user_id` (uuid foreign key ke `auth.users` / `profiles.id`)
- `judul` (text)
- `isi` (text)
- `target_tim` (text, nama tim BOSDM yang dituju)
- `tugas_fungsi_id` (int, foreign key ke `tugas_fungsi.id`)
- `status` (varchar: `menunggu_disposisi`, `sedang_diproses`, `selesai`)
- `assigned_to` (uuid / text, nama staf yang ditugaskan)
- `is_public` (boolean, default true)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)

### Tabel `answers` (Respon Tiket)
- `id` (serial primary key)
- `question_id` (foreign key ke `questions.id`)
- `user_id` (uuid, penjawab)
- `penjawab_nama` (varchar)
- `penjawab_role` (varchar)
- `isi_jawaban` (text)
- `created_at` (timestamptz)

---

## 5. Arsitektur Komponen Flutter

1. **`TusiCatalog` (Local Master Data Repository)**:
   - Menyediakan data statis 15 Tim & seluruh kode Tusi untuk cascading selector instan tanpa jeda loading.
   - Sinkronisasi dengan Supabase `tugas_fungsi` saat online.
2. **`AskQuestionScreen` (Cascading UI)**:
   - Dropdown 1: Pilih Tim BOSDM tujuan (15 Tim).
   - Dropdown 2 / BottomSheet: Pilih Kode & Nama Tusi dengan fitur *Search Filter*.
   - Live banner: Indikator routing *"Pertanyaan ini akan disalurkan ke [Nama Tim] dan diverifikasi oleh Ketua Tim"*.
3. **`KetuaTimDashboardScreen` & `QuestionListScreen`**:
   - Filter tab: "Semua", "Antrean Tim Saya (Menunggu Disposisi)", "Sedang Diproses", "Selesai".
   - Aksi Ketua Tim: Tombol "Disposisikan ke Staf" & "Jawab Langsung".
4. **`QuestionDetailScreen`**:
   - Menampilkan timeline status tiket (Disposisi $\rightarrow$ Proses $\rightarrow$ Selesai).
   - Menampilkan tanggapan resmi dari Tim teknis BOSDM.
5. **`QuestionService`**:
   - Mengelola query Supabase, fallback data offline, pembuatan tiket baru, disposisi tiket, dan submit jawaban resmi.

---

## 6. Rencana Pengujian
- Unit test untuk resolver klasifikasi Tim dan format tiket.
- Widget test untuk alur formulir bertingkat (Cascading Tim $\rightarrow$ Tusi).
- Integrasi query Supabase & state management `flutter_bloc`.
