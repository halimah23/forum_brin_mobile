# Spesifikasi Desain: Manajemen Pengguna (CRUD User) & Pembukaan Kembali Tiket (Superadmin)

**Tanggal:** 2026-10-19  
**Status:** Draf Terverifikasi  
**Target Rilis:** Modul Superadmin BOSDM Connect BRIN  

---

## 1. Ringkasan Eksekutif
Fitur ini melengkapi hak akses utama **Superadmin** dalam administrasi sistem dan tata kelola layanan bantuan kepegawaian BRIN melalui dua pilar utama:
1. **Manajemen Akun & Hak Akses Pengguna (CRUD User)**: Fasilitas komprehensif untuk menambah akun baru, melihat & memfilter akun berdasarkan peran (*Role*), mengubah metadata akun (*Edit*), serta menghapus akun (*Delete*) dengan integrasi langsung ke tabel `public.profiles` di Supabase.
2. **Aktivasi Kembali Tiket yang Telah Selesai (Reopen Ticket)**: Kemampuan kurasi darurat bagi Superadmin untuk mengaktifkan kembali tiket yang telah dinyatakan `selesai` (Closed), disertai pencatatan alasan audit (*audit trail log*) dan pengalihan disposisi yang terarah ke LKSDM Kawasan atau Tim Pusat.

---

## 2. Kebutuhan Pengguna & Batasan (Requirements & Constraints)

### 2.1 Manajemen Pengguna (CRUD User)
- **Role yang Didukung**:
  1. `pegawai` (Peneliti, Perekayasa, Pelaksana / Member)
  2. `admin_lksdm` (Staf Layanan Kawasan SDM Wilayah 1 s.d. 7)
  3. `admin_pusat` (Staf Layanan SDM 14 Tim Pusat BOSDM)
  4. `ketua_tim` (Ketua Tim Kerja Layanan SDM)
  5. `eksekutif` (Pimpinan / Kepala Biro / Direktur)
  6. `super_admin` (Administrator Sistem)
- **Penambahan Akun Baru**:
  - Kolom input: Nama Lengkap, Alamat Email BRIN, Password (dengan nilai *default* `BRINpop2026!`), Pilihan Role, Unit Kerja, Tim Layanan/Kawasan LKSDM (otomatis menyesuaikan pilihan katalog resmi), dan Jabatan.
  - Akun terdaftar langsung di `public.profiles` (dan akun autentikasi Supabase Auth) sehingga pengguna baru dapat langsung masuk (*login*).
- **Pencarian & Filter**:
  - Pencarian *live* berdasarkan nama, email, unit kerja, atau jabatan.
  - Filter *chips* per role (*Semua, Pegawai, Staf LKSDM, Staf Tim Pusat, Ketua Tim, Eksekutif, Super Admin*).
- **Pengeditan Akun**:
  - Superadmin dapat memperbarui nama, role, unit kerja, tim, dan jabatan pengguna secara langsung.
- **Penghapusan Akun**:
  - Penghapusan permanen dari `public.profiles` di Supabase.
  - **Proteksi Keamanan (Safety Guard)**: Superadmin dilarang keras menghapus akunnya sendiri yang sedang aktif digunakan (*Self-delete protection*).
  - Dialog konfirmasi eksplisit dengan pengetikan atau penegasan nama pengguna sebelum aksi hapus dieksekusi.

### 2.2 Pembukaan Kembali Tiket Selesai (Reopen Ticket)
- **Target Tiket**: Hanya berlaku untuk tiket berstatus `selesai` (Closed).
- **Alur & Dialog Interaktif**:
  - Superadmin memilih status aktivasi kembali:
    - `ditangani_lksdm` (Dikembalikan ke antrean/penanganan Staf LKSDM Kawasan).
    - `dialihkan_ke_pusat` (Eskalasi langsung ke antrean/penanganan Staf Tim Pusat).
  - Wajib menyertakan **Alasan Pembukaan Kembali** (misal: *Temuan bukti dukung baru, revisi SK, atau kendala belum tuntas sepenuhnya*).
- **Dampak Sistem**:
  - Status tiket pada `public.questions` diperbarui menjadi status aktif yang dipilih.
  - Kolom `closed_at` direset menjadi `null`.
  - Pesan log sistem (*System Event*) otomatis disisipkan ke percakapan `public.answers` berbunyi: `"[TIKET DIAKTIFKAN KEMBALI] oleh Superadmin. Catatan: <alasan>"`.
  - Pengiriman notifikasi *in-app* otomatis ke pemilik tiket (Pegawai) via `public.notifications`.
  - Input bar percakapan di [`QuestionDetailScreen`](file:///d:/forum_brin_mobile/lib/features/questions/screens/question_detail_screen.dart) aktif kembali bagi semua pihak terkait.

---

## 3. Arsitektur Data & Desain Layanan (Backend & Data Layer)

### 3.1 Skema Data Supabase

```
+--------------------------------------------------------------------------+
|                            public.profiles                               |
+--------------------------------------------------------------------------+
| id          : UUID PRIMARY KEY (REFERENCES auth.users(id) ON DELETE CASCADE)
| name        : TEXT NOT NULL                                              |
| email       : TEXT UNIQUE NOT NULL                                       |
| role        : public.user_role_type NOT NULL DEFAULT 'pegawai'           |
| unit        : TEXT NOT NULL DEFAULT 'BRIN'                               |
| tim         : TEXT NOT NULL DEFAULT 'Umum'                               |
| jabatan     : TEXT NOT NULL DEFAULT 'Pegawai'                            |
| created_at  : TIMESTAMPTZ DEFAULT NOW()                                  |
+--------------------------------------------------------------------------+
```

### 3.2 Service Baru: `UserService` (`lib/features/auth/services/user_service.dart`)
Metode utama:
1. `Future<List<UserModel>> getAllUsers({String? query, UserRole? roleFilter})`: Mengambil seluruh profil pengguna dari `public.profiles` dengan pengurutan `created_at DESC` atau alfabetis.
2. `Future<UserModel> createUser({required String name, required String email, required String password, required UserRole role, required String unit, required String tim, required String jabatan})`:
   - Melakukan provisi akun autentikasi via Supabase Auth client dengan email & password awal (`BRINpop2026!`).
   - Melakukan *upsert/insert* ke tabel `public.profiles`.
3. `Future<bool> updateUser({required String id, required String name, required UserRole role, required String unit, required String tim, required String jabatan})`:
   - Melakukan *update* data profil di `public.profiles`.
4. `Future<bool> deleteUser({required String id, required String currentAdminId})`:
   - Validasi `id != currentAdminId` (proteksi diri).
   - Menghapus record dari `public.profiles` (dan auth jika didukung token admin).

### 3.3 Penambahan pada `QuestionService` (`lib/features/questions/services/question_service.dart`)
Metode baru:
```dart
static Future<bool> reopenTicket({
  required int questionId,
  required String targetStatus, // 'ditangani_lksdm' atau 'dialihkan_ke_pusat'
  required String reason,
  required String superAdminName,
  required String? authorUserId,
  required String ticketNumber,
});
```
Operasi:
1. Insert pesan audit ke `public.answers` dengan role `'system'`.
2. Update tabel `public.questions`: `status = targetStatus`, `closed_at = null`, `updated_at = NOW()`.
3. Mengirim notifikasi melalui `NotificationService.sendNotification`:
   - `title`: `Tiket $ticketNumber Diaktifkan Kembali`
   - `message`: `Tiket Anda telah dibuka kembali oleh Superadmin: "$reason"`
   - `type`: `'status_update'`

---

## 4. Rincian Antarmuka Pengguna (UI / UX)

### 4.1 Dashboard Superadmin ([`super_admin_dashboard_screen.dart`](file:///d:/forum_brin_mobile/lib/features/dashboard/screens/super_admin_dashboard_screen.dart))
- Memperbarui kartu aksi pada seksi **Administrasi & Monitoring**:
  - Mengubah kartu `Master Data & Akses` menjadi kartu interaktif **"Kelola Akun & Hak Akses"** (*subtitle: Tambah, edit & hapus user sistem*).
  - Navigasi langsung menuju [`UserManagementScreen`](file:///d:/forum_brin_mobile/lib/features/auth/screens/user_management_screen.dart).

### 4.2 Halaman Manajemen Pengguna ([`UserManagementScreen`](file:///d:/forum_brin_mobile/lib/features/auth/screens/user_management_screen.dart))
- **AppBar**: Judul "Manajemen Pengguna BRIN", jumlah total akun aktif, dan tombol `Refresh`.
- **Search & Filter Bar**:
  - Kolom pencarian teks (*Search field*) responsif.
  - Deretan `ChoiceChip` horizontal untuk kategori role (`Semua`, `Pegawai`, `Staf LKSDM`, `Staf Pusat`, `Ketua Tim`, `Eksekutif`, `Super Admin`).
- **Floating Action Button (FAB)**: Tombol melayang merah `+ Tambah Akun Baru`.
- **Daftar Kartu Pengguna (`UserAccountCard`)**:
  - Avatar inisial dengan warna aksen sesuai role.
  - Nama lengkap, email, badge status role, unit kerja, tim kerja, serta tombol aksi cepat: *Edit* (pensil) dan *Hapus* (tempat sampah).
- **State Handling**: Shimmer loading / progress indicator, tampilan kosong (*empty state* ilustratif), dan error fallback.

### 4.3 Dialog Form Tambah / Edit Pengguna ([`UserFormDialog`](file:///d:/forum_brin_mobile/lib/features/auth/widgets/user_form_dialog.dart))
- Mode Ganda: *Tambah Akun Baru* atau *Edit Data Akun*.
- Form Fields:
  1. **Nama Lengkap** (wajib)
  2. **Email BRIN** (wajib, format `@brin.go.id` divalidasi)
  3. **Password Awal** (hanya muncul saat tambah akun, default prefilled: `BRINpop2026!`, dengan tombol intip/hide password)
  4. **Peran / Role** (Dropdown: Pegawai, Staf LKSDM, Staf Tim Pusat, Ketua Tim, Eksekutif, Super Admin)
  5. **Unit Kerja** (Dropdown / Autocomplete dari katalog unit BRIN)
  6. **Tim Kerja / Kawasan LKSDM** (Dropdown dinamis: jika role LKSDM -> pilihan 7 LKSDM; jika role Pusat/Ketua Tim -> pilihan 14 Tim Layanan BOSDM)
  7. **Jabatan** (misal: *Pranata Komputer Ahli Muda, Analis SDM, dll.*)
- Tombol Aksi: `Batal` dan `Simpan Data Akun`.

### 4.4 Dialog Pembukaan Kembali Tiket ([`ReopenTicketDialog`](file:///d:/forum_brin_mobile/lib/features/questions/widgets/reopen_ticket_dialog.dart))
- Judul: "Buka Kembali Tiket Selesai"
- Komponen:
  1. Ringkasan tiket (Nomor tiket & Judul).
  2. Pilihan Target Penanganan (Radio tile: `Ditangani LKSDM Kawasan` atau `Dialihkan ke Staf Pusat`).
  3. Input Area: Catatan / Alasan Pembukaan Kembali (wajib diisi).
  4. Tombol: `Batal` dan `Aktifkan Kembali Tiket`.

### 4.5 Titik Akses Reopen Tiket
1. **Detail Pertanyaan ([`QuestionDetailScreen`](file:///d:/forum_brin_mobile/lib/features/questions/screens/question_detail_screen.dart))**:
   - Jika `question.isClosed == true` dan `currentUser.isSuperAdmin == true`:
     - Banner abu-abu di bagian bawah dilengkapi tombol mencolok berlabel **"Buka Kembali Tiket"** dengan ikon `Icons.replay_rounded`.
     - Tombol aksi cepat tambahan di AppBar (`Icons.restore_page_rounded`).
2. **Audit Tiket Superadmin ([`AuditQuestionCard`](file:///d:/forum_brin_mobile/lib/features/dashboard/widgets/audit_question_card.dart))**:
   - Pada kartu tiket yang berstatus `Selesai` / `Closed`, ditambahkan tombol aksi cepat `Buka Tiket` yang langsung memunculkan `ReopenTicketDialog`.

---

## 5. Rencana Pengujian & Validasi

1. **Pengujian Fungsionalitas CRUD User**:
   - Menambah akun dengan role `admin_lksdm` dan memverifikasi data tersimpan di Supabase `public.profiles`.
   - Mengubah data akun dan memverifikasi perubahan langsung ter-refresh di layar.
   - Menghapus akun pengujian dan memastikan data terhapus.
   - Menguji proteksi: Mencoba menghapus akun Superadmin sendiri dan memastikan dicegah dengan pesan peringatan yang tepat.
2. **Pengujian Reopen Tiket**:
   - Mengaktifkan kembali tiket selesai dan memeriksa status berpindah ke `ditangani_lksdm` / `dialihkan_ke_pusat`.
   - Memastikan pesan alasan tercatat di bubble chat.
   - Memastikan bar pesan terbuka kembali untuk pengetikan lanjutan.
3. **Analisis Statis & Widget Test**:
   - Menjalankan `flutter analyze` hingga menghasilkan 0 issue.
   - Menjalankan `flutter test test/widget_test.dart` hingga lolos 100%.
