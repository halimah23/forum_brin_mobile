# Implementation Plan: Isolasi Privasi Tiket, Layar Tiket Saya, dan Widget Topik Populer Forum

- **Tanggal**: 15 Oktober 2026
- **Spesifikasi**: [docs/superpowers/specs/2026-10-15-privacy-forum-tickets-design.md](file:///d:/forum_brin_mobile/docs/superpowers/specs/2026-10-15-privacy-forum-tickets-design.md)

---

## 1. Rincian Task & File yang Terdampak

### Task 1: Isolasi Privasi Tiket Baru & Query Member
- **File**: `lib/features/questions/screens/ask_question_screen.dart`
  - Ubah `isPublic: true` di baris 113 menjadi `isPublic: false`.
- **File**: `lib/features/questions/services/question_service.dart`
  - Perbaiki `getMyQuestions` agar menerima `userId` opsional dan mengambil fallback user ID dari `SessionManager.getUser()` jika Supabase Auth session belum sinkron.
  - Pastikan query pada saat `userIdFilter` diberikan memfilter tiket strictly milik user tersebut.

### Task 2: Pembuatan Halaman Terpadu "Tiket Saya" (`MemberTicketsScreen`)
- **File Baru**: `lib/features/questions/screens/member_tickets_screen.dart`
  - Halaman terpadu dengan 2 tab: **Tiket Aktif** & **Tiket Selesai**.
  - Parameter `initialTabIndex` (0: Tiket Aktif, 1: Tiket Selesai).
  - Mengambil data tiket milik member yang sedang login (`QuestionService.getMyQuestions`).
  - Dilengkapi `RefreshIndicator`, filter tab dinamis, empty state yang informatif, dan klik card menuju `QuestionDetailScreen`.

### Task 3: Hubungkan Kartu KPI Dashboard ke "Tiket Saya"
- **File**: `lib/features/dashboard/screens/member_dashboard_screen.dart`
  - Bungkus kartu KPI "Tiket Aktif" dan "Tiket Selesai" dengan `InkWell` / `GestureDetector`.
  - Berikan efek visual interaktif (ink splash / tap effect).
  - Mengetuk "Tiket Aktif" ➔ Navigasi ke `MemberTicketsScreen(user: widget.user, initialTabIndex: 0)`.
  - Mengetuk "Tiket Selesai" ➔ Navigasi ke `MemberTicketsScreen(user: widget.user, initialTabIndex: 1)`.
  - Setelah kembali dari `MemberTicketsScreen`, refresh data dashboard agar sinkron.

### Task 4: Widget Topik Populer di Menu Forum (`QuestionListScreen`)
- **File**: `lib/features/questions/screens/question_list_screen.dart`
  - Pastikan query forum untuk tab member strictly `isPublicOnly: true`.
  - Tambahkan komponen ringkas **Topik Populer** di bagian bawah daftar forum:
    - Menampilkan 3 topik konsultasi teratas (rank 01, 02, 03) dengan badge jumlah tiket.
    - Tombol "Lihat Semua Topik Populer" yang memunculkan BottomSheet modal berisi seluruh daftar topik populer dari `TrendingIssuesData`.
    - Tampilan responsif dan tetap muncul baik ketika ada pertanyaan forum maupun saat forum masih kosong (empty state).

### Task 5: Pengujian, Analisis Statis & Verifikasi
- Jalankan `flutter analyze` untuk memastikan tidak ada error sintaks atau regresi.
- Jalankan `flutter test` untuk memverifikasi fungsionalitas unit dan widget test.
