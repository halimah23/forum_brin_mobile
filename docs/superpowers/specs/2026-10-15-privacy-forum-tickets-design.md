# Desain Spesifikasi: Isolasi Privasi Tiket, Pemisahan Forum Publik, Navigasi Tiket Saya & Analisis Kebutuhan Sistem

**Tanggal**: 15 Oktober 2026  
**Status**: Usulan Desain (Menunggu Persetujuan Pengguna)  
**Tujuan**:
1. Menjamin privasi tiket pertanyaan pegawai (100% privat, hanya tampil di akun pembuat dan tim penangan).
2. Memposisikan Menu Forum sebagai Pusat Edukasi/FAQ Publik dengan kartu ringkas *Topik Populer* di bagian bawah list.
3. Menyediakan halaman terpadu "Tiket Saya" dengan tab interaktif (Tiket Aktif vs Tiket Selesai) yang dapat diakses langsung dari kartu KPI Dashboard.
4. Mendokumentasikan identifikasi kekurangan sistem saat ini dan roadmap fitur yang esensial untuk platform Helpdesk BOSDM BRIN.

---

## 1. Identifikasi Kekurangan Sistem Saat Ini & Rekomendasi Fitur Esensial

Berdasarkan audit menyeluruh terhadap arsitektur, basis data, dan antarmuka pengguna BOSDM Connect, berikut adalah gap/kekurangan sistem beserta rekomendasi fiturnya:

| No | Kategori | Kondisi Saat Ini (Kekurangan) | Rekomendasi Fitur yang Seharusnya Ada | Prioritas |
|---|---|---|---|---|
| 1 | **Privasi & Keamanan Data** | Nilai `isPublic: true` ter-hardcode saat submit tiket, menyebabkan pertanyaan kepegawaian pribadi pegawai bocor ke Tab Forum publik seluruh pengguna. | • Default `is_public: false` untuk seluruh tiket konsultasi pegawai.<br>• Implementasi Row Level Security (RLS) di Supabase agar query direct API tidak dapat diintip pegawai lain. | **P0 (Kritis - Masuk Sesi Ini)** |
| 2 | **Navigasi Arsip Tiket** | Kartu KPI "Tiket Aktif" dan "Tiket Selesai" di Dashboard bersifat statis (tidak bisa diklik). Tidak ada halaman untuk melihat riwayat tiket yang sudah selesai. | • Halaman "Tiket Saya" dengan Tab **Tiket Aktif** dan **Tiket Selesai**.<br>• Filter status dan riwayat konsultasi lengkap. | **P0 (Kritis - Masuk Sesi Ini)** |
| 3 | **Pemisahan Helpdesk vs Forum** | Tab Forum tercampur aduk antara tiket aduan pribadi pegawai dan materi umum. | • Forum khusus untuk FAQ publik, regulasi kepegawaian, dan pengumuman BOSDM.<br>• Widget Topik Populer (preview 3 teratas + Lihat Selengkapnya). | **P0 (Kritis - Masuk Sesi Ini)** |
| 4 | **Lampiran Berkas (Attachments)** | Form pengajuan pertanyaan hanya berupa teks singkat (`judul` & `isi`). Pegawai tidak bisa melampirkan bukti berkas. | • Fitur Upload Dokumen/Gambar (PDF, JPG, PNG) ke Supabase Storage (misal: Bukti SK, Nota Dinas, Transkrip/Ijazah). | P1 (Sangat Penting) |
| 5 | **Pencarian & Filter Cepat (Search & Filter)** | Tidak ada kolom pencarian di daftar tiket maupun forum. Pegawai harus men-scroll manual jika tiket sudah banyak. | • Search bar instan berdasarkan No Tiket (`#TKT-...`) atau kata kunci judul/isi.<br>• Filter berdasarkan tanggal dan kategori Tim. | P1 (Sangat Penting) |
| 6 | **SLA & Visual Tracker (Timeline)** | Pegawai tidak tahu berapa lama waktu pengerjaan (SLA) dan posisi tiket saat ini di birokrasi. | • Indikator SLA (contoh: "Target respon: 2x24 jam").<br>• Visual Progress Stepper: *Terkirim* ➔ *Verifikasi Kawasan/LKSDM* ➔ *Eskalasi Pusat* ➔ *Selesai*. | P1 (Sangat Penting) |
| 7 | **Survei Kepuasan (CSAT / Rating)** | Ketika tiket diselesaikan, tidak ada feedback loop untuk menilai mutu pelayanan tim. | • Rating bintang 1-5 + ulasan kepuasan saat tiket ditutup untuk mengukur Indeks Kepuasan Layanan (IKL) BOSDM. | P2 (Penting) |
| 8 | **Notifikasi Real-time (In-App / Push)** | Pegawai tidak tahu tiketnya sudah dijawab kecuali membuka aplikasi berulang kali. | • Badge notifikasi dan push notification saat tiket didisposisikan atau dijawab oleh Ketua Tim. | P2 (Penting) |
| 9 | **Ekspor Rekap Laporan (Admin/Ketua Tim)** | Admin dan Pimpinan belum memiliki ringkasan rekapitulasi data untuk laporan berkala. | • Fitur export laporan rekap tiket (PDF / Excel / CSV) per periode atau per tim. | P3 (Penyempurnaan) |

---

## 2. Arsitektur Solusi & Perubahan Komponen

### A. Isolasi Privasi Tiket Pegawai
```
[Pegawai Buat Pertanyaan (AskQuestionScreen)]
           │
           ▼
[is_public = false (Privat)] ──> [Supabase `questions` Table]
                                            │
               ┌────────────────────────────┴────────────────────────────┐
               ▼                                                         ▼
    [Akun Pegawai Pembuat]                                     [Akun Tim Penangan]
• Tampil di Dashboard Tiket Aktif                        • Tampil di Antrean LKSDM / Pusat
• Tampil di Halaman "Tiket Saya"                         • Disposisi & Dijawab oleh Tim
• TIDAK TAMPIL di Tab Forum                              • TIDAK TAMPIL di Pegawai Lain!
```

1. **`lib/features/questions/screens/ask_question_screen.dart`**:
   - Ubah pemanggilan `AskQuestionCubit.submitQuestion`:
     - Ganti nilai hardcoded `isPublic: true` menjadi `isPublic: false` (tiket konsultasi pegawai secara baku bersifat privat).
2. **`lib/features/questions/services/question_service.dart`**:
   - Pastikan pemanggilan daftar tiket untuk Tab Forum memfilter strictly `isPublicOnly: true`.
   - Pastikan pemanggilan tiket milik member menggunakan `userIdFilter: currentUser.id`.

---

### B. Halaman Terpadu "Tiket Saya" (`MemberTicketsScreen`)

1. **Akses dari Dashboard**:
   - Kartu KPI "Tiket Aktif" dan "Tiket Selesai" di `MemberDashboardScreen` dibungkus dengan `InkWell` / `GestureDetector`.
   - Mengetuk "Tiket Aktif" akan membuka `MemberTicketsScreen(initialTabIndex: 0)`.
   - Mengetuk "Tiket Selesai" akan membuka `MemberTicketsScreen(initialTabIndex: 1)`.
2. **Struktur Halaman `MemberTicketsScreen`**:
   - `AppBar` berwarna `AppColors.primaryRed` dengan judul "Tiket Saya".
   - `TabBar` dengan 2 tab:
     - **Tab 1: Tiket Aktif** (menampilkan tiket milik user dengan status `menunggu_lksdm`, `ditangani_lksdm`, `dialihkan_ke_pusat`).
     - **Tab 2: Tiket Selesai** (menampilkan tiket milik user dengan status `selesai`).
   - Setiap kartu tiket dapat diklik untuk membuka `QuestionDetailScreen` (melihat riwayat tanya jawab, status perjalanan disposisi, dan jawaban ketua tim).
   - Dilengkapi `RefreshIndicator` untuk swipe-to-refresh.

---

### C. Menu Forum Publik dengan Widget Topik Populer

1. **Tab Forum (`QuestionListScreen`)**:
   - Menampilkan daftar pertanyaan/artikel edukasi yang bersifat publik (`isPublicOnly: true`).
   - Jika belum ada posting publik, menampilkan pesan edukatif panduan layanan BOSDM.
2. **Widget Topik Populer**:
   - Ditempatkan di bagian bawah list pertanyaan Forum.
   - Menggunakan komponen `TrendingChartWidget` yang disesuaikan menjadi format **Compact Preview**:
     - Menampilkan **3 topik teratas**.
     - Tombol **"Lihat Semua Topik Populer"** yang saat ditekan akan memunculkan BottomSheet atau Dialog interaktif berisi seluruh ranking isu/topik kepegawaian.

---

## 3. Rencana Pengujian & Verifikasi

1. **Verifikasi Isolasi Privasi**:
   - Login sebagai Pegawai A, ajukan tiket baru.
   - Login sebagai Pegawai B, pastikan tiket Pegawai A **TIDAK MUNCUL** di dashboard Pegawai B dan **TIDAK MUNCUL** di Tab Forum.
   - Pastikan tiket Pegawai A hanya muncul di akun Pegawai A dan akun Tim/Admin terkait.
2. **Verifikasi Navigasi KPI Dashboard**:
   - Dari dashboard Pegawai, ketuk kartu "Tiket Aktif" ➔ memastikan membuka Tab Tiket Aktif di `MemberTicketsScreen`.
   - Ketuk kartu "Tiket Selesai" ➔ memastikan membuka Tab Tiket Selesai di `MemberTicketsScreen`.
3. **Verifikasi Topik Populer di Forum**:
   - Buka tab Forum ➔ gulir ke bawah ➔ pastikan kartu ringkas 3 Topik Populer tampil.
   - Ketuk "Lihat Semua Topik Populer" ➔ pastikan modal menampilkan seluruh daftar isu populer dengan benar.
4. **Analisis Statis & Linting**:
   - Menjalankan `flutter analyze` untuk memastikan tidak ada error sintaks atau regresi.
