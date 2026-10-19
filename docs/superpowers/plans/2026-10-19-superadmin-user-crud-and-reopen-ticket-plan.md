# Rencana Implementasi: Manajemen Pengguna (CRUD User) & Pembukaan Kembali Tiket (Superadmin)

**Tanggal:** 2026-10-19  
**Dokumen Desain Referensi:** `docs/superpowers/specs/2026-10-19-superadmin-user-crud-and-reopen-ticket-design.md`  
**Target:** Repositori Forum Kepegawaian BRIN (`forum_brin_mobile`)

---

## Ringkasan Rencana Kerja
Rencana kerja ini mengimplementasikan dua fitur utama pada role Superadmin:
1. **Fitur CRUD Akun Pengguna** untuk seluruh role (`pegawai`, `admin_lksdm`, `admin_pusat`, `ketua_tim`, `eksekutif`, `super_admin`) yang terhubung langsung ke tabel `public.profiles` di Supabase.
2. **Fitur Pembukaan Kembali (Reopen) Tiket Selesai** dengan dialog alasan audit, pilihan target disposisi (LKSDM / Pusat), pencatatan pesan sistem di riwayat chat, dan pengiriman notifikasi ke Pegawai.

---

## Pembagian Fase & Tugas

### Fase 1: Lapisan Data & Layanan Backend (Service Layer)

#### Tugas 1.1: Pembuatan `UserService` (`lib/features/auth/services/user_service.dart`)
- **Tujuan**: Mengelola operasi data akun pengguna langsung ke Supabase `public.profiles`.
- **Fungsi yang Diimplementasikan**:
  - `getAllUsers({String? query, UserRole? roleFilter})`: Query data dari tabel `public.profiles` dengan dukungan pencarian string (nama, email, unit) dan filter peran.
  - `createUser(...)`: Menambahkan akun baru ke `public.profiles` (serta akun Supabase Auth menggunakan password awal default `BRINpop2026!`).
  - `updateUser(...)`: Memperbarui data nama, role, unit kerja, tim/LKSDM, dan jabatan.
  - `deleteUser(...)`: Menghapus baris profil dari `public.profiles` dengan validasi proteksi keamanan (mencegah Superadmin menghapus dirinya sendiri).
- **Fallback**: Memastikan ketahanan (*resilience*) dengan fallback ke list demo pengguna jika koneksi jaringan offline.

#### Tugas 1.2: Penambahan Metode `reopenTicket` pada `QuestionService`
- **File**: `lib/features/questions/services/question_service.dart`
- **Tujuan**: Mengubah status tiket selesai menjadi aktif kembali.
- **Operasi**:
  1. Insert bubble chat *system event* ke tabel `public.answers` berisi catatan alasan pembukaan kembali dari Superadmin.
  2. Update baris tiket pada `public.questions`: `status = targetStatus`, `closed_at = null`, `updated_at = NOW()`.
  3. Mengirimkan notifikasi in-app kepada pemilik tiket via `NotificationService.sendNotification`.

---

### Fase 2: Antarmuka CRUD Pengguna (User Management UI)

#### Tugas 2.1: Pembuatan Komponen `UserFormDialog`
- **File**: `lib/features/auth/widgets/user_form_dialog.dart`
- **Tujuan**: Formulir modal interaktif untuk menambah atau mengedit pengguna.
- **Komponen**:
  - Validasi teks nama dan email BRIN.
  - Pilihan Role dengan dropdown terstandarisasi.
  - Dropdown dinamis Unit Kerja dan Tim/LKSDM (menampilkan 7 LKSDM jika role Staf LKSDM; menampilkan 14 Tim Layanan jika role Pusat/Ketua Tim).
  - Field Password awal saat membuat akun baru (default: `BRINpop2026!`) dengan opsi intip/sembunyikan password.
  - Tombol simpan dan indikator loading.

#### Tugas 2.2: Pembuatan Komponen Kartu Akun `UserAccountCard`
- **File**: `lib/features/auth/widgets/user_account_card.dart`
- **Tujuan**: Menampilkan data profil pengguna secara rapi dan modular.
- **Komponen**:
  - Avatar inisial dengan warna peran yang khas.
  - Nama, email, badge peran, unit kerja, dan tim.
  - Tombol aksi cepat: Edit (Ikon Pensil) dan Hapus (Ikon Tempat Sampah).
  - Dialog konfirmasi hapus akun permanen dengan penegasan nama pengguna dan proteksi self-delete.

#### Tugas 2.3: Pembuatan Halaman `UserManagementScreen`
- **File**: `lib/features/auth/screens/user_management_screen.dart`
- **Tujuan**: Halaman utama manajemen akun untuk Superadmin.
- **Komponen**:
  - Search bar responsif dengan debounce.
  - Filter *chips* per role (*Semua, Pegawai, Staf LKSDM, Staf Pusat, Ketua Tim, Eksekutif, Super Admin*).
  - Floating Action Button (FAB) `+ Tambah Akun Baru`.
  - RefreshIndicator untuk sinkronisasi ulang data dari Supabase.
  - Penanganan state kosong (*empty state*) dan indikator pemuatan data.

#### Tugas 2.4: Integrasi Menu ke Dashboard Superadmin
- **File**: `lib/features/dashboard/screens/super_admin_dashboard_screen.dart`
- **Tujuan**: Menyediakan akses cepat ke halaman manajemen pengguna.
- **Perubahan**:
  - Memperbarui kartu pada grup *Superadmin Control* menjadi tombol **"Manajemen Akun & Hak Akses"** (*subtitle: Tambah, edit & hapus akun semua role*).
  - Menghubungkan klik kartu ke `UserManagementScreen`.

---

### Fase 3: Antarmuka Pembukaan Kembali Tiket (Reopen Ticket UI)

#### Tugas 3.1: Pembuatan Komponen `ReopenTicketDialog`
- **File**: `lib/features/questions/widgets/reopen_ticket_dialog.dart`
- **Tujuan**: Dialog konfirmasi aktivasi kembali tiket selesai.
- **Komponen**:
  - Ringkasan nomor tiket & judul pertanyaan.
  - Pilihan radio button target disposisi:
    - *Staf LKSDM Kawasan* (`ditangani_lksdm`)
    - *Staf Tim Pusat BOSDM* (`dialihkan_ke_pusat`)
  - Input catatan alasan pembukaan kembali (wajib diisi).
  - Tombol konfirmasi eksekusi dengan feedback visual.

#### Tugas 3.2: Penambahan Aksi Reopen pada `QuestionDetailScreen`
- **File**: `lib/features/questions/screens/question_detail_screen.dart`
- **Tujuan**: Memungkinkan Superadmin mengaktifkan kembali tiket saat meninjau detail percakapan.
- **Perubahan**:
  - Pada banner bawah tiket selesai (`question.isClosed == true`), tambahkan tombol **"Buka Kembali Tiket"** khusus untuk Superadmin.
  - Tambahkan tombol aksi Reopen di AppBar.
  - Setelah aktivasi berhasil, perbarui state lokal tiket menjadi aktif dan buka kembali kolom input chat balasan.

#### Tugas 3.3: Penambahan Aksi Reopen Cepat pada `AuditQuestionCard` & `SuperAdminAuditScreen`
- **Files**:
  - `lib/features/dashboard/widgets/audit_question_card.dart`
  - `lib/features/dashboard/screens/super_admin_audit_screen.dart`
- **Tujuan**: Memberikan jalan pintas bagi Superadmin untuk mengaktifkan kembali tiket langsung dari daftar tab audit tiket berstatus "Selesai".

---

### Fase 4: Pengujian, Validasi Statis & Uji Regresi

#### Tugas 4.1: Analisis Statis Kode
- Menjalankan `flutter analyze` untuk memastikan tidak ada lint error, type mismatch, maupun unused elements baru.

#### Tugas 4.2: Eksekusi Uji Widget
- Menjalankan `flutter test test/widget_test.dart` untuk memastikan seluruh komponen aplikasi tetap berjalan normal tanpa regresi.

---

## Urutan Eksekusi
1. Jalankan Fase 1 (Tugas 1.1 & Tugas 1.2)
2. Jalankan Fase 2 (Tugas 2.1, 2.2, 2.3, & 2.4)
3. Jalankan Fase 3 (Tugas 3.1, 3.2, & 3.3)
4. Jalankan Fase 4 (Tugas 4.1 & Tugas 4.2)
