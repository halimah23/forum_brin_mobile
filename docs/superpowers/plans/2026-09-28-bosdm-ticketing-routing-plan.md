# Rencana Implementasi: Sistem Ticketing & Routing Tusi BOSDM BRIN

**Dokumen Terkait**: [`docs/superpowers/specs/2026-09-28-bosdm-ticketing-routing-design.md`](file:///d:/forum_brin_mobile/docs/superpowers/specs/2026-09-28-bosdm-ticketing-routing-design.md)  
**Status**: Ready for Execution  

---

## Ringkasan Tugas
Mengimplementasikan sistem ticketing menyeluruh pada aplikasi BOSDM Connect yang mengarahkan pertanyaan anggota (member) ke salah satu dari 15 Tim BOSDM BRIN berdasarkan klasifikasi kode Tugas & Fungsi (Tusi), mengelola alur approval/disposisi oleh Ketua Tim, serta menyediakan skrip database Supabase dan katalog offline di Flutter.

---

## Rincian Langkah Implementasi

### Langkah 1: Skrip Database & Seeding Supabase
- **File**: `supabase/migrations/20260928_bosdm_ticketing_schema.sql`
- **Aksi**:
  - Buat tabel `teams`, `tugas_fungsi`, `questions` (dengan kolom `ticket_number`, `target_tim`, `assigned_to`, `status`), dan `answers`.
  - Masukkan (*seed*) seluruh 15 Tim BOSDM dan puluhan kode Tusi (dari `BRIN-04.03.01.01` hingga `BRIN-04.03.10.01.02.11`).
  - Tambahkan fungsi helper/trigger untuk auto-generate nomor tiket (contoh: `TKT-202609-001`).

### Langkah 2: Master Data Catalog & Model Tusi di Flutter
- **File**:
  - `lib/features/questions/data/tusi_catalog_data.dart` (Katalog data lokal 15 Tim dan seluruh kode Tusi)
  - `lib/features/questions/models/category_model.dart`
  - `lib/features/questions/models/question_model.dart`
- **Aksi**:
  - Definisikan list lengkap 15 Tim dan kode Tusi di `TusiCatalogData`.
  - Update `CategoryModel` untuk menampung `kode`, `nama`, dan `teamName`.
  - Update `QuestionModel` untuk menampung `ticketNumber`, `targetTim`, `assignedTo`, dan fleksibilitas parsing Supabase.

### Langkah 3: Update Widget Status Badge & Constants
- **File**: `lib/core/widgets/status_badge.dart`
- **Aksi**:
  - Tambahkan pemetaan status ticketing baru:
    - `menunggu_disposisi`: Kuning / Orange ("Menunggu Disposisi Ketua Tim")
    - `sedang_diproses`: Biru ("Sedang Diproses Tim")
    - `selesai`: Hijau ("Selesai Dijawab")

### Langkah 4: Layanan Question & Ticketing (Supabase + Offline Fallback)
- **File**: `lib/features/questions/services/question_service.dart`
- **Aksi**:
  - `getTeams()`: Mengambil daftar 15 Tim.
  - `getTugasFungsiByTeam(teamName)`: Mengambil kode Tusi berdasarkan Tim.
  - `createTicket(...)`: Menyimpan tiket ke Supabase dengan status `menunggu_disposisi`, auto-generate nomor tiket, dan fallback lokal.
  - `disposisiTicket(...)`: Aksi Ketua Tim untuk mendisposisikan ke staf/anggota tim (mengubah status ke `sedang_diproses`).
  - `answerAndResolveTicket(...)`: Aksi menjawab tiket dan mengubah status menjadi `selesai`.
  - `getTicketsForKetuaTim(teamName)`: Filter antrean khusus untuk tim yang dipimpin.

### Langkah 5: Formulir Pengajuan Tiket Bertingkat (Cascading UI)
- **File**: `lib/features/questions/screens/ask_question_screen.dart`
- **Aksi**:
  - Tingkat 1: Dropdown pilihan 15 Tim Layanan BOSDM.
  - Tingkat 2: Dropdown / Searchable Selector untuk Kode & Nama Tusi spesifik sesuai Tim yang dipilih.
  - Card Info Realtime: Menampilkan identitas Tim yang akan menerima tiket dan Ketua Tim penanggung jawab.

### Langkah 6: Dashboard Ketua Tim & Modal Aksi
- **File**:
  - `lib/features/dashboard/screens/ketua_tim_dashboard_screen.dart`
  - `lib/features/dashboard/screens/member_dashboard_screen.dart`
  - `lib/features/questions/screens/question_list_screen.dart`
- **Aksi**:
  - Di `KetuaTimDashboardScreen`: Metrik antrean tim (Menunggu Disposisi, Sedang Diproses, Selesai) dengan filter otomatis berdasarkan `user.tim`.
  - Tab navigasi untuk memilah tiket tim vs semua tiket.

### Langkah 7: Detail Tiket & Respon Tim (Disposisi / Jawab)
- **File**: `lib/features/questions/screens/question_detail_screen.dart`
- **Aksi**:
  - Tampilkan Nomor Tiket, Timeline Status, dan Tim Penanggung Jawab.
  - Jika pengguna adalah Ketua Tim / Anggota Tim terkait: Tampilkan tombol "Disposisikan ke Staf" dan "Beri Jawaban Resmi".
  - Tampilkan riwayat jawaban resmi dari tim.

### Langkah 8: Pengujian & Validasi
- Jalankan `flutter analyze` untuk memastikan tidak ada lint error atau tipe yang tidak kompatibel.
- Jalankan `flutter test` untuk memverifikasi fungsionalitas.

---

Mari kita mulai eksekusinya secara bertahap!
