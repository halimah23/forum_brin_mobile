# Implementation Plan: 6 Fitur Esensial Helpdesk BOSDM Connect

- **Tanggal**: 15 Oktober 2026
- **Spesifikasi**: [docs/superpowers/specs/2026-10-15-essential-helpdesk-features-design.md](file:///d:/forum_brin_mobile/docs/superpowers/specs/2026-10-15-essential-helpdesk-features-design.md)

---

## 1. Rincian Task & File yang Terdampak

### Task 1: Migrasi Skema Supabase & Pembaruan Model
- **File**: `supabase/migrations/20261015_essential_features.sql`
  - Buat script SQL: alter table `questions` (attachment, rating, feedback, resolved_at) & create table `notifications`.
- **File**: `lib/features/questions/models/question_model.dart`
  - Tambah field: `attachmentUrl`, `attachmentName`, `rating`, `ratingFeedback`, `ratingSubmittedAt`, `resolvedAt`.
  - Update method `fromJson`, `toJson`, dan `copyWith`.
- **File Baru**: `lib/features/notifications/models/notification_model.dart`
  - Buat model `NotificationModel` (`id`, `userId`, `questionId`, `title`, `message`, `type`, `isRead`, `createdAt`).

### Task 2: Service Layer (Pembaruan & Penambahan Layanan)
- **File**: `lib/features/questions/services/question_service.dart`
  - Tambah dukungan `attachmentUrl` dan `attachmentName` pada `createQuestion`.
  - Tambah method `submitRating({required int questionId, required int rating, String? feedback})`.
  - Trigger notifikasi saat status tiket berubah (disposisi / jawaban baru).
- **File Baru**: `lib/features/notifications/services/notification_service.dart`
  - Method: `getNotifications(userId)`, `getUnreadCount(userId)`, `markAsRead(id)`, `markAllAsRead(userId)`, `createNotification(...)`.
- **File Baru**: `lib/features/reports/services/report_export_service.dart`
  - Method: `generateTicketsCsv(List<QuestionModel> tickets)` menghasilkan string CSV dengan format baku (RFC 4180).

### Task 3: Pencarian & Filter Cepat (Search & Filter Bar)
- **File Baru**: `lib/core/widgets/search_filter_bar.dart`
  - Komponen search field dengan icon kaca pembesar, tombol hapus, dan debouncing 300ms.
- **File**: `lib/features/questions/screens/member_tickets_screen.dart`
  - Pasang `SearchFilterBar` di atas daftar tiket untuk menyaring tiket aktif dan tiket selesai secara instan.
- **File**: `lib/features/questions/screens/question_list_screen.dart`
  - Pasang `SearchFilterBar` untuk mencari pertanyaan forum atau antrean admin/ketua tim.

### Task 4: SLA Visual Timeline Tracker & SLA Badge
- **File Baru**: `lib/features/questions/widgets/ticket_timeline_tracker.dart`
  - Stepper visual 4 fase perjalanan tiket: *Diajukan* ➔ *Verifikasi Kawasan* ➔ *Penanganan Pusat* ➔ *Selesai*.
  - Menampilkan badge SLA 48 jam dengan warna:
    - Hijau (Tepat waktu / aman)
    - Kuning (Mendekati batas < 12 jam)
    - Merah (Terlambat / melebihi batas)
- **File**: `lib/features/questions/screens/question_detail_screen.dart`
  - Pasang `TicketTimelineTracker` di bagian atas detail pertanyaan.

### Task 5: Survei Kepuasan Layanan (CSAT / Rating)
- **File Baru**: `lib/features/questions/widgets/csat_rating_card.dart`
  - Komponen rating bintang 1–5 interaktif + ulasan feedback jika tiket berstatus `selesai`.
  - Tampilan rating terkunci jika pegawai sudah memberikan penilaian.
- **File**: `lib/features/questions/screens/question_detail_screen.dart`
  - Integrasikan `CsatRatingCard` saat tiket berstatus selesai.

### Task 6: Lampiran Berkas (Attachments Input & Viewer)
- **File Baru**: `lib/features/questions/widgets/attachment_picker_widget.dart`
  - Form lampiran berkas (nama berkas, status lampiran, tombol upload/pilih berkas atau URL bukti berkas).
- **File**: `lib/features/questions/screens/ask_question_screen.dart`
  - Integrasikan lampiran berkas pada formulir pengajuan pertanyaan.
- **File**: `lib/features/questions/screens/question_detail_screen.dart`
  - Tampilkan kartu lampiran berkas jika tiket memiliki `attachmentUrl`.

### Task 7: In-App Notification Center
- **File Baru**: `lib/features/notifications/widgets/notification_bell_widget.dart`
  - Ikon lonceng AppBar dengan badge merah jumlah notifikasi yang belum dibaca.
- **File Baru**: `lib/features/notifications/screens/notification_center_screen.dart`
  - Layar pusat notifikasi dengan daftar notifikasi, penanda belum dibaca, tombol tandai semua dibaca, dan navigasi langsung ke detail tiket.
- **File**: `lib/features/dashboard/screens/member_dashboard_screen.dart` & AppBar antrean
  - Pasang `NotificationBellWidget` di AppBar.

### Task 8: Ekspor Rekap Laporan untuk Admin & Ketua Tim
- **File**: `lib/features/questions/screens/question_list_screen.dart`
  - Tambahkan tombol aksi "Ekspor Rekap Laporan" (khusus peran non-member / Admin / Ketua Tim).
  - Tampilkan modal ringkasan ekspor dan unduh / share berkas CSV.

### Task 9: Verifikasi, Linting & Pengujian
- Jalankan `flutter analyze` dan pastikan 0 error/warning.
- Jalankan `flutter test` untuk memverifikasi keutuhan aplikasi.

---

## 2. Rencana Eksekusi Bertahap

- **Fase 1**: Fondasi Data (Skema SQL, QuestionModel, NotificationModel, Service Layer).
- **Fase 2**: Fitur Interaktif Tiket (SearchFilterBar, SLA & Timeline Tracker, CSAT Rating Card).
- **Fase 3**: Lampiran Berkas & Pusat Notifikasi (Attachment Picker & Viewer, NotificationBell & NotificationCenterScreen).
- **Fase 4**: Ekspor Rekap Laporan CSV & Integrasi Aksi Admin.
- **Fase 5**: Pengujian Menyeluruh (`flutter analyze` & `flutter test`).
