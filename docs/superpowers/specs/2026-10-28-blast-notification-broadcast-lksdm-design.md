# Dokumen Desain & Perencanaan Fitur: Blast Notification & Broadcast LKSDM (BOSDM Connect)

**Tanggal:** 28 Oktober 2026  
**Status:** Draf Terfinalisasi Berdasarkan Diskusi Kebutuhan (Grill-Me & Brainstorming)  
**Target Modul:** `lib/features/broadcasts/` & integrasi ke `dashboard`, `notifications`, dan `auth`

---

## 1. Ringkasan Eksekutif & Latar Belakang

Fitur **Blast Notification / Broadcast LKSDM** bertujuan memberikan sarana komunikasi resmi satu arah (one-to-many atau targeted) yang cepat, akurat, dan terstruktur dari pengelola Layanan Kawasan SDM (LKSDM) kepada para pegawai di wilayah kerja masing-masing.

Sebelum fitur ini ada, pengumuman atau instruksi kepegawaian kawasan seringkali tercecer di grup percakapan informal atau tenggelam dalam riwayat tanya-jawab konsultasi tiket. Dengan modul ini:
- Pengelola LKSDM (Admin LKSDM & Ketua Tim LKSDM) serta Super Admin dapat membuat pengumuman resmi berkas lampiran (PDF/Word/Gambar).
- Pesan dapat disiarkan ke seluruh pegawai di LKSDM terkait, dikelompokkan berdasarkan Satuan Kerja/Kawasan, ataupun ditargetkan ke pegawai tertentu (multi-select).
- Pengumuman dengan prioritas **"Penting / Urgent"** akan langsung memicu dialog pop-up di layar beranda pegawai saat membuka aplikasi.
- Seluruh riwayat pengumuman tersimpan rapi dalam arsip **"Pengumuman LKSDM"** dan pengirim dapat memantau metrik keterbacaan (*Read Status*).

---

## 2. Hak Akses & Matriks Peran (Role-Based Access)

| Aktor / Peran | Cakupan Penyiaran (Broadcast Scope) | Hak Akses Fitur |
|---|---|---|
| **Admin LKSDM** | Hanya pegawai yang berada dalam naungan wilayah LKSDM-nya | Membuat siaran, melampirkan berkas, melihat riwayat siaran wilayahnya, melihat metrik keterbacaan pegawai |
| **Ketua Tim LKSDM** | Hanya pegawai yang berada dalam naungan wilayah LKSDM-nya | Membuat siaran, melampirkan berkas, melihat riwayat siaran wilayahnya, melihat metrik keterbacaan pegawai |
| **Super Admin** | Bebas memilih: LKSDM Tertentu atau Seluruh Pegawai BRIN | Membuat siaran ke seluruh lingkup, memantau seluruh broadcast nasional/kawasan |
| **Pegawai (Member)** | *Hanya Penerima* | Menerima push notification & lonceng, melihat pop-up dashboard (jika status urgent), membuka detail pesan, mengunduh lampiran, melihat arsip pengumuman |

---

## 3. Alur Pengalaman Pengguna (User Experience & Flow)

```
[Pengirim: Admin / Ketua Tim LKSDM]
  │
  ├── 1. Akses Menu: Quick Action Card / Tombol FAB di Dashboard LKSDM
  │
  ├── 2. Masuk Layar "Manajemen Broadcast LKSDM"
  │        ├── Tab 1: Riwayat Siaran (Status Dibaca: misal "Dibaca oleh 42/50")
  │        └── Tombol FAB: "Buat Siaran Baru"
  │
  ├── 3. Formulir Pembuatan Broadcast:
  │        ├── Judul Pengumuman
  │        ├── Isi Pesan Siaran (Markdown / Teks Panjang)
  │        ├── Tingkat Urgensi: [Informasi Biasa] vs [Penting / Urgent]
  │        ├── Mode Target Penerima:
  │        │     ├── (A) Semua Pegawai di LKSDM ini
  │        │     ├── (B) Filter Berdasarkan Unit / Kawasan Kerja
  │        │     └── (C) Pilih Pegawai Tertentu (Multi-select Checklist + Search)
  │        └── Lampirkan Berkas (PDF, DOC/DOCX, Gambar maks 10 MB)
  │
  └── 4. Pratinjau & Konfirmasi Kirim (Broadcast Dispatch)
           │
           ▼
[Sistem: Supabase & FCM Engine]
  ├── Simpan ke tabel `broadcasts`
  ├── Simpan daftar penerima ke `broadcast_recipients`
  ├── Buat entri notifikasi di tabel `notifications` (type: 'broadcast')
  └── Kirim FCM Push Notification ke perangkat penerima
           │
           ▼
[Penerima: Pegawai]
  ├── (A) Notifikasi Lonceng & Push Notification (realtime pop-up)
  ├── (B) Pop-up Alert di Dashboard (Khusus jika status "Penting / Urgent")
  └── (C) Membuka "Detail Siaran & Berkas":
            ├── Baca konten lengkap & data pengirim
            ├── Pratinjau dokumen / gambar
            ├── Tombol unduh lampiran ke perangkat
            └── Status otomatis tercatat "Dibaca" (Read)
```

---

## 4. Arsitektur Data (Database & Storage Schema)

### A. Tabel `public.broadcasts` (Master Siaran)
```sql
CREATE TABLE IF NOT EXISTS public.broadcasts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES public.users(id_user) ON DELETE CASCADE,
    sender_name TEXT NOT NULL,
    sender_role TEXT NOT NULL,
    lksdm_scope TEXT NOT NULL, -- contoh: 'LKSDM 1', 'LKSDM 2', atau 'ALL'
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'normal', -- 'normal' atau 'urgent'
    target_type TEXT NOT NULL DEFAULT 'all_lksdm', -- 'all_lksdm', 'unit_filter', 'custom_users'
    target_filter_value TEXT, -- nama unit/kawasan jika target_type = 'unit_filter'
    attachment_url TEXT,
    attachment_name TEXT,
    attachment_size TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### B. Tabel `public.broadcast_recipients` (Pelacakan Keterbacaan Penerima)
```sql
CREATE TABLE IF NOT EXISTS public.broadcast_recipients (
    id BIGSERIAL PRIMARY KEY,
    broadcast_id UUID NOT NULL REFERENCES public.broadcasts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id_user) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(broadcast_id, user_id)
);

CREATE INDEX idx_broadcast_recipients_user ON public.broadcast_recipients(user_id, is_read);
CREATE INDEX idx_broadcast_recipients_broadcast ON public.broadcast_recipients(broadcast_id);
```

### C. Integrasi dengan Tabel `public.notifications`
Ketika broadcast dibuat, sistem menyisipkan baris notifikasi ke tabel `notifications` yang sudah ada:
- `user_id`: Target penerima
- `title`: Judul broadcast (misal: `"[LKSDM 1] Pengumuman Hari Libur Nasional"`)
- `message`: Cuplikan isi pesan
- `type`: `'broadcast'`
- `question_id`: `null`
- `created_at`: `NOW()`
- `payload`: Menampung `broadcast_id` untuk navigasi langsung ke halaman Detail Broadcast.

### D. Supabase Storage Bucket
- Menggunakan bucket `attachments` (atau folder `broadcasts/` di Supabase Storage) dengan batas ukuran maksimum 10 MB per berkas.

---

## 5. Rincian Desain Antarmuka Pengguna (UI/UX)

### 1. Dashboard LKSDM (Admin LKSDM & Ketua Tim LKSDM)
- **Komponen Aksi Cepat (Quick Action Card):** Kartu "Broadcast Notifikasi" dengan ikon megapon bergradasi modern dan indikator ringkasan siaran aktif.
- **Floating Action Button (FAB):** Tombol aksi cepat dengan label *"Buat Siaran"* yang selalu mudah dijangkau.

### 2. Layar Manajemen Broadcast (`BroadcastManagementScreen`)
- **Tab 1: Riwayat Broadcast:**
  - Kartu daftar pengumuman yang pernah dibuat pengirim.
  - Menampilkan badge prioritas ("Urgent" merah atau "Biasa" biru).
  - Indikator keterbacaan: *"Dibaca 45 / 50 Pegawai (90%)"*.
  - Aksi hapus/batalkan siaran bila diperlukan.
- **Tab 2: Statistik & Analisis:**
  - Grafik persentase respons keterbacaan di wilayah LKSDM terkait.

### 3. Layar Pembuatan Broadcast (`CreateBroadcastScreen`)
- **Header:** Informasi LKSDM pengirim (misal: *"Pengirim: LKSDM 2 - Serpong"*).
- **Formulir Input:**
  - Input teks Judul Pengumuman dengan counter karakter.
  - Input area Teks Pesan Pengumuman.
  - Switch/Toggle: *"Tandai sebagai Siaran Penting / Urgent"* (dengan penjelasan: akan memunculkan dialog pop-up pada layar beranda pegawai penerima).
- **Selector Target Penerima:**
  - Tab pilihan:
    1. *Semua Pegawai LKSDM*: Otomatis menghitung total pegawai terdaftar (misal: *"58 Pegawai"*).
    2. *Pilih Satuan Kerja / Kawasan*: Dropdown pilihan unit kerja di bawah LKSDM tersebut.
    3. *Pilih Pegawai Tertentu*: Daftar checklist pegawai dilengkapi bilah pencarian instan (nama/NIP/unit).
- **Komponen Lampiran Berkas:**
  - Mengintegrasikan fungsi file picker (PDF, Word, Gambar) dengan preview nama, ukuran berkas, dan tombol hapus/ganti berkas.
- **Tombol Aksi:**
  - Tombol *"Pratinjau Siaran"* (menampilkan modal tampilan sebagaimana yang akan dilihat pegawai).
  - Tombol *"Kirim Siaran Sekarang"* dengan dialog konfirmasi akhir.

### 4. Tampilan Sisi Pegawai (Penerima)
- **Dashboard Urgent Alert Dialog:**
  - Begitu pegawai membuka aplikasi, sistem memeriksa apakah ada broadcast berlabel "Urgent" yang belum dibaca dalam 7 hari terakhir.
  - Jika ada, muncul modal dialog elegan yang menampilkan judul penting, ringkasan, dan tombol *"Lihat Pengumuman Selengkapnya"*.
- **Layar Arsip Pengumuman LKSDM (`BroadcastFeedScreen`):**
  - Dapat diakses melalui ikon di appbar atau menu informasi.
  - Menampilkan daftar kronologis seluruh pengumuman dari LKSDM tempat pegawai bernaung.
  - Filter pengumuman: *Semua*, *Belum Dibaca*, *Penting*.
- **Layar Detail Broadcast (`BroadcastDetailScreen`):**
  - Tampilan teks lengkap isi pengumuman.
  - Header profil pengirim resmi LKSDM dan cap waktu (timestamp).
  - Kartu Lampiran Berkas interaktif:
    - Jika Gambar: Tampilan pratinjau langsung + tombol perbesar layar penuh.
    - Jika PDF/Dokumen: Kartu dokumen lengkap dengan tombol *"Buka / Pratinjau"* dan *"Unduh Berkas"*.

---

## 6. Rencana Implementasi Bertahap (Implementation Roadmap)

```
[Tahap 1: Fondasi Data & Service]
  ├── Eksekusi skrip DDL Supabase (tabel `broadcasts` & `broadcast_recipients`)
  ├── Model data: `BroadcastModel` & `BroadcastRecipientModel`
  ├── Service backend: `BroadcastService` (create, fetch, markAsRead, getRecipientStats)
  └── Integrasi query user target berdasarkan cakupan wilayah LKSDM

[Tahap 2: UI Pengirim (Admin & Ketua Tim LKSDM)]
  ├── Layar `CreateBroadcastScreen` (Form, Recipient Selector, Attachment Picker)
  ├── Dialog pratinjau sebelum kirim
  ├── Layar `BroadcastManagementScreen` (Riwayat pengiriman & indikator read status)
  └── Integrasi Quick Action Card & FAB di `AdminDashboardScreen` & `KetuaTimDashboardScreen`

[Tahap 3: UI & Notifikasi Penerima (Pegawai)]
  ├── Modifikasi penanganan klik notifikasi lonceng untuk route ke `BroadcastDetailScreen`
  ├── Komponen Pop-up Urgent Alert di `DashboardScreen` / `MemberDashboardScreen`
  ├── Layar `BroadcastDetailScreen` lengkap dengan preview & download attachment
  └── Layar Arsip `BroadcastFeedScreen` (daftar pengumuman LKSDM)

[Tahap 4: Pengujian & Pemolesan]
  ├── Static analysis & linting (`flutter analyze`)
  ├── Verifikasi pengiriman realtime Supabase & pembaruan status read
  └── Dokumentasi panduan penggunaan fitur
```
