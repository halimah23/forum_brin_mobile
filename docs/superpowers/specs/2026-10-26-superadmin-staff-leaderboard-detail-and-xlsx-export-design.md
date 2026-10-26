# Desain Arsitektur: Halaman Detail Leaderboard Kinerja Petugas & Ekspor XLSX (Khusus Super Admin)

## 1. Pendahuluan
Dokumen ini merinci desain arsitektur fitur **Leaderboard Kinerja Petugas & Staf Admin**, mencakup:
1. **PostgreSQL View di Supabase** (`view_staff_performance_leaderboard`) untuk kalkulasi analitik performa dinamis & realtime.
2. **Halaman Daftar Lengkap Leaderboard** (`StaffLeaderboardScreen`) dengan filter, pencarian, dan tombol ekspor Excel.
3. **Halaman Profil Kinerja Individu Petugas** (`StaffPerformanceDetailScreen`) dengan visualisasi KPI, distribusi rating, dan riwayat tiket yang ditangani.
4. **Fitur Ekspor Berkas Excel (.xlsx)** menggunakan package `excel` & `path_provider` + `open_filex` dengan notifikasi SnackBar tombol 'Buka'.
5. **Pembatasan Hak Akses Khusus Super Admin**.

---

## 2. Arsitektur Database Supabase

### 2.1 Skema View PostgreSQL: `view_staff_performance_leaderboard`
View ini melakukan join dan agregasi antara `public.answers`, `public.questions`, dan `public.profiles`:
```sql
CREATE OR REPLACE VIEW public.view_staff_performance_leaderboard AS
WITH official_answers AS (
  SELECT 
    a.question_id,
    a.user_id,
    COALESCE(p.name, a.sender_name, a.penjawab_nama) AS staff_name,
    COALESCE(p.role::text, a.sender_role, a.penjawab_role) AS role,
    COALESCE(p.tim, p.unit, 'Layanan SDM BRIN') AS team_or_lksdm,
    a.created_at AS answered_at,
    q.created_at AS question_created_at,
    q.rating,
    q.status,
    ROW_NUMBER() OVER (PARTITION BY a.question_id, COALESCE(a.user_id::text, a.penjawab_nama) ORDER BY a.created_at ASC) AS ans_seq
  FROM public.answers a
  JOIN public.questions q ON a.question_id = q.id
  LEFT JOIN public.profiles p ON a.user_id = p.id
  WHERE 
    (a.sender_role IN ('admin_lksdm', 'admin_pusat', 'ketua_tim', 'admin', 'super_admin')
     OR a.penjawab_role ILIKE '%admin%' 
     OR a.penjawab_role ILIKE '%staf%' 
     OR a.penjawab_role ILIKE '%ketua%')
    AND a.sender_name NOT ILIKE '%sistem%'
)
SELECT 
  user_id AS staff_id,
  staff_name,
  role,
  team_or_lksdm,
  COUNT(DISTINCT question_id) AS total_tickets_handled,
  COUNT(*) AS total_answers,
  COUNT(DISTINCT CASE WHEN status = 'selesai' OR status = 'CLOSED' THEN question_id END) AS total_closed_tickets,
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
```

---

## 3. Alur Pengguna (User Flow)

```mermaid
flowchart TD
    A[Super Admin Dashboard] -->|Klik 'Lihat Semua' pada Kartu Leaderboard| B[Halaman Daftar Lengkap Leaderboard]
    B -->|Pilih Filter Tim/Kawasan| B
    B -->|Cari Nama Petugas| B
    B -->|Klik 'Download Laporan (.xlsx)'| C[Generate & Simpan XLSX Rekapitulasi]
    C -->|Tampilkan SnackBar Sukses| D[Klik Tombol 'Buka' di SnackBar]
    D -->|Membuka file via OpenFilex| E[Aplikasi Spreadsheet Terpasang]
    B -->|Klik salah satu Petugas di Leaderboard| F[Halaman Profil Kinerja Individu Petugas]
    F -->|Lihat KPI, Rating CSAT, & Tag Ulasan| F
    F -->|Lihat Riwayat Tiket yang Ditangani| F
    F -->|Klik 'Download Riwayat Tiket (.xlsx)'| G[Generate & Simpan XLSX Tiket Petugas]
    G -->|Tampilkan SnackBar Sukses| H[Klik Tombol 'Buka' di SnackBar]
```

---

## 4. Desain Komponen UI & Layanan

### 4.1 Dependency Tambahan (`pubspec.yaml`)
- `excel: ^4.0.6` — library murni Dart untuk membaca & menulis berkas `.xlsx`.
- `path_provider: ^2.1.5` — untuk mengakses direktori lokal perangkat (`getTemporaryDirectory` / `getApplicationDocumentsDirectory` / `getDownloadsDirectory`).
- `open_filex: ^4.7.0` — untuk membuka berkas `.xlsx` langsung dengan aplikasi default perangkat dari tombol SnackBar.

### 4.2 Layanan Ekspor Excel (`ExcelExportService`)
- Berlokasi di: `lib/core/services/export/excel_export_service.dart`
- Fungsi 1: `exportStaffLeaderboardToExcel(List<StaffPerformanceStat> staffList)`
  - Menghasilkan file Excel berformat rapi dengan kolom: Rank, Nama Petugas, Role, Tim/Kawasan, Total Tiket Ditangani, Tiket Selesai, CSAT Rata-rata, CSAT Total Ulasan, Respon Cepat (Gercep), Persentase Gercep, Total Jawaban.
- Fungsi 2: `exportStaffTicketHistoryToExcel(StaffPerformanceStat staff, List<QuestionModel> tickets)`
  - Menghasilkan file Excel untuk riwayat tiket petugas: No. Tiket, Judul Pertanyaan, Kategori Tusi, Tanggal Masuk, Tanggal Respons, Status, Rating Bintang, Ulasan Pegawai.

### 4.3 Layanan Database (`LeaderboardService` & integrasi `PerformanceAnalyticsService`)
- Mengambil data dari view `view_staff_performance_leaderboard` di Supabase.
- Memiliki fallback multi-tier ke kalkulasi analitik in-memory Dart (`PerformanceAnalyticsService.getStaffPerformanceLeaderboard`) jika Supabase offline.

### 4.4 Halaman Baru
1. `lib/features/dashboard/screens/staff_leaderboard_screen.dart` (Level 1)
   - AppBar: "Leaderboard Kinerja Petugas"
   - Filter Chips: Tim / Kawasan (Semua Tim, LKSDM 1-8, Tim Pusat 1-14)
   - Search Field: Pencarian cepat nama petugas atau role
   - Summary Banner: Total Petugas Aktif, Rata-rata CSAT Global, Total Tiket Ditangani
   - Action Button: "Download XLSX"
   - Ranking List: List kartu petugas dengan medali (Emas #1, Perak #2, Perunggu #3), skor KPI, dan tap gesture ke halaman detail individu.
2. `lib/features/dashboard/screens/staff_performance_detail_screen.dart` (Level 2)
   - Profile Header: Nama lengkap petugas, Role Badge, Asal Tim/LKSDM
   - KPI Stat Cards: 4 kartu metrik (Tiket Ditangani, Rating CSAT, Gercep Rate, Total Jawaban)
   - CSAT & Tag Breakdown: Ulasan positif pegawai (Ramah & Solutif, Respon Cepat, dsb)
   - Ticket History List: Daftar tiket yang ditangani dengan status badge dan rating
   - Floating / Top Action Button: "Download Riwayat Tiket (.xlsx)"

### 4.5 Modifikasi Komponen Eksisting
- `lib/features/dashboard/widgets/performance_analytics_widgets.dart`:
  - `StaffLeaderboardCardWidget`: Menambahkan tombol "Lihat Semua" yang aktif dan navigasi saat kartu staff diklik.
- `lib/features/dashboard/screens/super_admin_dashboard_screen.dart`:
  - Mengirimkan callback `onViewAll` menuju `StaffLeaderboardScreen`.
