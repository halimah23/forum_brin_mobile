# Spesifikasi Desain: WhatsApp-Style Bubble Chat, Lampiran Balasan, Popup Profil Pegawai & Foto Profil Pengguna

**Tanggal**: 22 Oktober 2026  
**Status**: Menunggu Review & Persetujuan Pengguna  
**Kategori**: Arsitektural (*Architectural & UI/UX Enhancement*)  

---

## 1. Latar Belakang & Tujuan (*Intent and The Why*)

Sistem konsultasi kepegawaian BOSDM Connect sebelumnya menyajikan balasan pesan dalam format kartu statis bersusun yang kurang dinamis dan belum mencerminkan pengalaman percakapan modern layaknya aplikasi pesan instan (seperti WhatsApp). Selain itu, penempatan balasan pesan sebelumnya masih bersifat kaku (jawaban staf selalu di kiri, pertanyaan susulan selalu di kanan) tanpa memperhitungkan siapa pengguna yang sedang aktif/masuk (*logged-in user*).

Spesifikasi ini dirancang untuk:
1. Menghadirkan **WhatsApp-Style Bubble Chat** dengan penataan letak (*alignment*) dinamis: pesan yang dikirim oleh akun yang sedang aktif berada di **sisi kanan** (berwarna hijau muda khas WhatsApp `#DCF8C6`), sedangkan pesan dari lawan bicara (staf/admin/pusat/ketua tim atau member lain) berada di **sisi kiri** (berwarna putih bersih).
2. Menyajikan **pesan awal konsultasi pegawai** sebagai pesan pertama dalam riwayat gelembung percakapan (*chat bubble*), sembari mempertahankan kartu ringkasan tiket (nomor tiket, status badge, dan timeline tracker) secara rapi dan kompak di bagian atas.
3. Menampilkan **Popup Modal Profil Pegawai** di tengah layar saat nama atau foto pengirim pada chat diklik, menyajikan foto profil bulat, nama lengkap, peran, jabatan, email, dan LKSDM.
4. Mendukung **Lampiran Berkas & Gambar (Maksimal 10 MB)** pada setiap balasan pesan pegawai, admin, maupun ketua tim, lengkap dengan tombol klip kertas (*attachment*), chip pratinjau sebelum dikirim, dan kartu dokumen / gambar interaktif di dalam bubble chat.
5. Membersihkan tampilan **Formulir Pengajuan Tiket (`AskQuestionScreen`)** dengan menghapus kotak pemberitahuan lama (*intro card*) yang sudah redundan, karena wilayah penanganan LKSDM kini terdeteksi otomatis dari profil pengguna.
6. Menambahkan fitur **Foto Profil Pegawai** dengan bingkai lingkaran (*rounded circle*), dialog interaktif untuk mengatur posisi foto (*pan & zoom* menggunakan `InteractiveViewer`), fallback ikon pengguna default seperti WhatsApp, serta integrasi penyimpanan Supabase Storage dan `UserModel`.

---

## 2. Sasaran (*Goals, Non-Goals, & Anti-Goals*)

### 2.1 Goals (Sasaran Utama)
- **WhatsApp Experience**: Bubble chat rapi, dinamis, responsif pada berbagai ukuran layar ponsel dan tablet (lebar dinamis maksimal 78-85% layar).
- **Active-User Centric Alignment**: Pengguna aktif (siapapun rolenya: Pegawai, Admin LKSDM, Admin Pusat, Ketua Tim) selalu melihat pesannya sendiri di sebelah kanan dengan tanda centang (*double check*) dan stempel waktu, serta pesan orang lain di sebelah kiri.
- **Center System Events**: Status tiket, eskalasi, atau pengalihan sistem tetap berada di tengah layar berbentuk pill abu-abu lembut.
- **Profile Summary Popup**: Dialog modal yang elegan dan terpusat saat mengetuk nama atau avatar lawan bicara pada bubble chat.
- **10 MB File & Image Attachment**: Ikon klip kertas di bar input balasan tiket, validasi batas ukuran 10 MB, pengunggahan aman ke Supabase Storage (atau fallback lokal), serta rendering gambar thumbnail (bisa dizoom) dan file chip yang bisa dibuka/diunduh.
- **Profil Foto & Reposisi Interaktif**: Di halaman `ProfileScreen`, pengguna dapat mengetuk avatar untuk memilih foto baru, menggeser dan memperbesar posisi foto di dalam lingkaran pratinjau, lalu menyimpannya ke Supabase dan sesi lokal (`SessionManager`).
- **Formulir Ajukan Bersih**: Menghilangkan kartu intro *"Silakan pilih kawasan LKSDM..."* di `AskQuestionScreen`.

### 2.2 Non-Goals (Bukan Sasaran)
- Fitur panggilan suara/video atau rekaman pesan suara (*voice note*).
- Fitur status read/unread berbasis per-user websocket delivery acknowledgement (tetap menggunakan event realtime pesan baru Supabase).
- Fitur penghapusan atau penarikan pesan yang sudah terkirim (*delete for everyone*).

### 2.3 Anti-Goals (Hal yang Dihindari)
- Jangan merusak fungsionalitas alur bisnis eskalasi tiket, persetujuan ketua tim, penutupan tiket oleh pegawai, dan pengisian rating CSAT yang sudah berjalan.
- Jangan menyebabkan overflow UI atau terpotongnya teks pada layar kecil (mendukung pembungkusan teks rapi dengan `Flexible` / `ConstrainedBox`).

---

## 3. Batasan Teknis (*Constraints*)

- **Framework**: Flutter (Dart 3.x), Material 3.
- **Storage**: Supabase Storage bucket `attachments` (sub-folder `chat/` dan `profiles/`) dengan batas ukuran file maksimal 10 MB (10.485.760 bytes).
- **Database**: Supabase PostgreSQL. Kolom `photo_url` / `avatar_url` ditambahkan pada tabel `public.profiles` dan tabel `public.answers` sudah memiliki kolom `attachment_url`.
- **State Management**: BLoC / Cubit & `StatefulWidget` yang reaktif terhadap Supabase Realtime channel.

---

## 4. Rincian Keputusan Desain (*Detailed Design Decisions*)

### 4.1 Skema Data & Model

#### 4.1.1 Penambahan Kolom Database (`supabase/migrations/20261022_chat_and_profile_photo.sql`)
```sql
-- Tambah photo_url pada profiles jika belum ada
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- Pastikan tabel answers memiliki sender_id / user_id dan attachment_url
ALTER TABLE public.answers 
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS attachment_url TEXT,
  ADD COLUMN IF NOT EXISTS attachment_name TEXT;
```

#### 4.1.2 Pembaruan `UserModel` (`lib/features/auth/models/user_model.dart`)
- Tambahkan properti `final String? photoUrl;`
- Perbarui `fromJson`, `toJson`, dan `copyWith` untuk membaca/menulis `photo_url` atau `photoUrl`.

#### 4.1.3 Pembaruan `AnswerModel` (`lib/features/questions/models/answer_model.dart`)
- Lengkapi dengan `final String? attachmentName;` dan `final String? senderPhotoUrl;` (diisi dari join profil atau data sesi).

---

### 4.2 Tampilan Chat & Gelembung Percakapan (*WhatsApp-Style Bubble Chat*)

#### 4.2.1 Penentuan Posisi Kanan vs Kiri
- Evaluasi pengirim:
  ```dart
  final bool isMe = (ans.userId != null && widget.currentUser?.id != null && ans.userId == widget.currentUser?.id) ||
                    (ans.penjawabNama.trim().toLowerCase() == widget.currentUser?.name.trim().toLowerCase());
  ```
- **Jika `isMe == true` (Sisi Kanan)**:
  - Background: `Color(0xFFDCF8C6)` (WhatsApp light green).
  - Border: `Color(0xFFC5E1A5)` tipis (0.8px).
  - BorderRadius: `BorderRadius.only(topLeft: 14, topRight: 14, bottomLeft: 14, bottomRight: 2)`.
  - Margin: `const EdgeInsets.only(left: 48, right: 8, bottom: 8)`.
  - Footer: Jam pengiriman + ikon centang ganda (`Icons.done_all`, warna hijau zaitun).
- **Jika `isMe == false` (Sisi Kiri)**:
  - Background: `Colors.white`.
  - Border: `Color(0xFFE2E8F0)` tipis (1px) + bayangan lembut (*box shadow* `Color(0x0A000000)`).
  - BorderRadius: `BorderRadius.only(topLeft: 14, topRight: 14, bottomRight: 14, bottomLeft: 2)`.
  - Margin: `const EdgeInsets.only(left: 8, right: 48, bottom: 8)`.
  - Header: Nama pengirim berwarna (hijau untuk pegawai, teal untuk LKSDM, oranye/amber untuk pusat, ungu untuk ketua tim) yang **dapat diklik** untuk membuka popup profil, diikuti oleh badge peran mini.
  - Footer: Jam pengiriman.
- **Pesan Sistem (Tengah)**:
  - Background: `AppColors.slate100`, border `AppColors.slate300`.
  - Ikon informasi mini dan teks keterangan event sistem (misal: "Tiket dieskalasi ke Tim Pusat").

#### 4.2.2 Pesan Awal Pegawai (Pertanyaan Awal)
- Di bagian atas daftar chat, pesan awal pertanyaan tiket ditampilkan sebagai bubble pertama (dari sisi pegawai) dengan judul tebal dan isi pertanyaan awal.
- Kartu ringkasan tiket di atas chat dipertahankan secara rapi: menampilkan nomor tiket, status badge saat ini, tombol detail/timeline, dan durasi SLA.

---

### 4.3 Popup Modal Profil Pengirim (*Center Modal Popup*)

Saat nama pengirim atau avatar pada bubble chat diklik:
- Panggil `showDialog` menampilkan kartu modal di tengah layar dengan spesifikasi:
  - Lebar: maksimal 340px, rounded corner 16px.
  - Header: Foto profil lingkaran besar (radius 42px). Jika ada `photoUrl`, muat gambar via `Image.network` (dengan fallback error). Jika tidak ada, tampilkan ikon default WA (`Icons.person` dengan latar belakang abu-abu/warna peran).
  - Nama Lengkap (font tebal 16px).
  - Badge Peran (Pegawai / Staf Admin LKSDM / Staf Admin Pusat / Ketua Tim / Super Admin).
  - Detail Baris:
    - Jabatan / Tusi.
    - Satuan Kerja / Unit BRIN.
    - Wilayah Kawasan LKSDM.
    - Email BRIN resmi.
  - Tombol aksi: "Tutup" yang bersih.

---

### 4.4 Pengiriman Balasan dengan Lampiran (*Attachments up to 10 MB*)

#### 4.4.1 Bilah Input Percakapan (*Bottom Reply Bar*)
- Tata letak:
  1. Tombol klip kertas (`Icons.attach_file_rounded`) di sisi kiri kolom teks.
  2. Kolom input teks (`TextField`) yang dinamis (multiline, maksimal 4 baris).
  3. Tombol Kirim (`IconButton`) bulat dengan warna primer merah BRIN (`AppColors.primaryRed`).
- Jika berkas dipilih:
  - Tampilkan bilah/chip pratinjau lampiran di atas kolom teks dengan ikon berkas, nama file yang dipotong rapi, ukuran berkas (misal: "2.4 MB"), dan tombol 'x' untuk membatalkan sebelum dikirim.
  - Validasi: Batas maksimal 10 MB. Jika file > 10 MB, tampilkan `SnackBar` peringatan.
- Pengunggahan: Mengunggah berkas ke Supabase Storage bucket `attachments/chat/` sebelum memanggil `QuestionService.sendFollowUpQuestion` atau `QuestionService.submitAnswer`.

#### 4.4.2 Tampilan Lampiran di dalam Bubble Chat
- **Gambar (`.jpg`, `.jpeg`, `.png`)**:
  - Tampilkan pratinjau gambar berukuran proporsional (tinggi maksimal 200px, border radius 8px).
  - Saat gambar diklik, buka dialog pratinjau layar penuh (*Full Screen Image Viewer*) dengan kemampuan zoom.
- **Dokumen (`.pdf`, `.doc`, `.docx`)**:
  - Tampilkan kartu mini bergaya dokumen WhatsApp: ikon dokumen, nama file, dan tombol/indikator buka dokumen menggunakan `launchUrl` atau dialog info.

---

### 4.5 Pembersihan `AskQuestionScreen`

- Hapus widget Intro Card (kontainer baris 237-267 yang berisi teks *"Silakan pilih kawasan LKSDM dan sampaikan konsultasi kepegawaian Anda di bawah ini"*).
- Pertahankan kartu deteksi kawasan otomatis *"1. Wilayah Penanganan Kawasan SDM"* yang sudah terintegrasi langsung dengan profil pegawai.

---

### 4.6 Fitur Foto Profil & Reposisi Interaktif (*Profile Photo Upload & Pan-Zoom*)

#### 4.6.1 Tampilan Profil (`ProfileScreen`)
- Avatar berbentuk lingkaran (*CircleAvatar*) dengan tombol kamera mengambang di pojok kanan bawah avatar.
- Mengetuk avatar membuka picker galeri gambar (`FilePicker` atau `ImagePicker`).
- Default jika belum memiliki foto: Ikon user WhatsApp lingkaran dengan latar belakang lembut atau inisial nama.

#### 4.6.2 Dialog Pengaturan Posisi Foto (*Interactive Pan & Zoom Repositioning*)
- Setelah foto dipilih dari perangkat, muncul dialog interaktif:
  - Judul: "Atur Posisi Foto Profil"
  - Area kerja dengan latar belakang gelap/transparan dan masker lingkaran (*Circular Cutout Overlay*).
  - Widget `InteractiveViewer` yang memungkinkan pengguna mencubit (*pinch to zoom* min 1.0x hingga max 3.5x) dan menggeser (*drag/pan*) foto agar pas di dalam lingkaran.
  - Tombol "Batal" dan "Gunakan Foto Ini".
- Setelah dikonfirmasi:
  - Berkas foto diunggah ke Supabase Storage (bucket `attachments` sub-path `profiles/{user_id}_{timestamp}.jpg`).
  - Simpan URL foto publik ke tabel `public.profiles (photo_url)` dan sesi lokal pengguna via `SessionManager.saveUser`.
  - Tampilan avatar pada AppBar dan Profile langsung terbarui.

---

## 5. Yang Diserahkan kepada Pelaksana (*Left to the Builder*)

- Penyesuaian mikro untuk warna bayangan (*box-shadow*) dan padding pada gelembung chat agar proporsional di resolusi layar mobile (< 400px) maupun tablet.
- Penanganan caching gambar jaringan menggunakan `Image.network` dengan `loadingBuilder` dan `errorBuilder` yang anggun.
- Struktur helper upload yang modular agar dapat dipakai bersama antara chat balasan tiket dan foto profil pengguna.
