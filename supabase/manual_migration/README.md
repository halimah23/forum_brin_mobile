# Panduan Migrasi Database Mandiri (Manual SQL) ke Supabase Baru
**Aplikasi: BOSDM Connect (Forum & Layanan Terpadu Pegawai BRIN)**

Dokumen ini berisi panduan langkah demi langkah untuk melakukan inisialisasi basis data pada proyek Supabase baru yang masih kosong (**fresh/empty database**) menggunakan kumpulan berkas query SQL yang telah dirancang rapi dan modular.

---

## 📂 Struktur Berkas SQL

Seluruh berkas query migrasi tersimpan di folder `supabase/manual_migration/`:

| No | Berkas SQL | Deskripsi & Tujuan | Status Data |
|---|---|---|---|
| **00** | `00_complete_migration_all_in_one.sql` | **Semua skrip digabung menjadi satu** untuk eksekusi sekali jalan (one-click run). | Lengkap (Struktur + Seed Master) |
| **01** | `01_schema_master.sql` | Membuat tabel master instansi: `teams`, `tugas_fungsi`, `team_tusi`, dan `users` (beserta indexes & RLS). | Skema Saja |
| **02** | `02_schema_ticketing_and_chat.sql` | Membuat tabel transaksi layanan: `questions` (tiket), `answers` (chat thread 3-pihak), dan `notifications`. | **Kosongan (Bersih)** |
| **03** | `03_schema_broadcasts_and_storage.sql` | Membuat tabel `broadcasts` (blast notif LKSDM), `broadcast_recipients`, dan bucket storage `attachments`. | **Kosongan (Bersih)** |
| **04** | `04_views_and_realtime.sql` | Membuat View agregasi `view_faq_standardized`, `view_staff_performance_leaderboard`, dan konfigurasi Supabase Realtime. | Database Views & Realtime |
| **05** | `05_seed_teams_and_tusi.sql` | Mengisi data master resmi: **22 Tim BRIN**, **91 Tugas dan Fungsi**, dan relasi pemetaan `team_tusi`. | **Data Awal Wajib Terisi** |
| **06** | `06_seed_users_240.sql` | Mengisi data **240 Pegawai Resmi BRIN** dengan peran, jabatan, kawasan LKSDM, dan password default. | **Data Awal Wajib Terisi** |
| **08** | `08_update_role_member_to_sivitas.sql` | Query untuk memperbarui database Supabase yang sedang berjalan: mengubah seluruh role `'Member'` / `'Pegawai'` menjadi `'Sivitas'`. | Skrip Pembaruan (Hot-fix) |
| **09** | `09_auto_transition_off_hours_queue.sql` | Query fungsi transisi otomatis status tiket 'antrean_luar_jam_kerja' ke antrean terbuka saat jam operasional tiba. | Skrip Pembaruan & Trigger |

---

## 🚀 Cara Menjalankan di Supabase Dashboard

### Opsi A: Eksekusi Sekaligus (Direkomendasikan)
1. Buka dashboard proyek Supabase baru Anda.
2. Masuk ke menu **SQL Editor** di bilah navigasi kiri.
3. Klik tombol **New Query**.
4. Buka berkas `00_complete_migration_all_in_one.sql`, salin seluruh isinya, lalu tempel (*paste*) ke dalam SQL Editor.
5. Klik tombol **Run** (atau tekan `Ctrl + Enter`).
6. Pastikan muncul pesan sukses: `Success. No rows returned`.

---

### Opsi B: Eksekusi Bertahap (Modular per Berkas)
Jika Anda ingin memeriksa eksekusi langkah per langkah secara terpisah, jalankan query sesuai urutan nomor berikut:

1. **Jalankan `01_schema_master.sql`**: Mempersiapkan tabel master struktur organisasi dan kepegawaian.
2. **Jalankan `02_schema_ticketing_and_chat.sql`**: Menyiapkan tabel tiket pertanyaan dan obrolan (keadaan kosong tanpa tiket lama).
3. **Jalankan `03_schema_broadcasts_and_storage.sql`**: Menyiapkan tabel blast notification dan bucket penyimpanan lampiran berkas.
4. **Jalankan `04_views_and_realtime.sql`**: Memasang View FAQ, Leaderboard staf, dan mengaktifkan Webhook / Realtime listener.
5. **Jalankan `05_seed_teams_and_tusi.sql`**: Menginjeksi 22 Tim BRIN (14 Pusat + 8 LKSDM), 91 Tugas dan Fungsi, serta relasinya.
6. **Jalankan `06_seed_users_240.sql`**: Menginjeksi 240 Pegawai resmi BRIN ke tabel `users`.

---

## 🔑 Menghubungkan Aplikasi Flutter ke Supabase Baru

Setelah database selesai dimigrasikan, perbarui konfigurasi kredensial pada berkas `.env` di direktori utama aplikasi Flutter:

```env
SUPABASE_URL=https://<PROJECT-ID-ANDA>.supabase.co
SUPABASE_ANON_KEY=<ANON-PUBLIC-KEY-ANDA>
```

> **Catatan**: Kredensial di atas dapat Anda temukan di dashboard Supabase:
> **Project Settings** -> **API** -> **Project URL** dan **Project API Keys (anon public)**.

---

## 👥 Akun Login Uji Coba Sesuai Peran (Role)

Seluruh akun pegawai telah memiliki password standar: `BRINpop2026!`

| Peran (Role) | Username | Email | Kawasan / Tim |
|---|---|---|---|
| **Sivitas (Pegawai LKSDM 1)** | `mand001` | `manda.talita.taruli.hasibuan.@brin.go.id` | LKSDM 1 (Kawasan Thamrin) |
| **Sivitas (Pegawai LKSDM 6)** | `hafi013` | `hafiz.rifki@brin.go.id` | LKSDM 6 (Kawasan Cibinong) |
| **Staff Admin (LKSDM 1)** | `syif007` | `syifaniar.ramadhanny@brin.go.id` | LKSDM 1 (PKSPU) |
| **Staff Admin (LKSDM 6)** | `zabr001` | `zabrina.ramadhani.aristawati@brin.go.id` | LKSDM 1 / LKSDM 6 |
| **Staff Admin (Tim Pusat)** | `mari063` | `maria.fernanda.de.vega@brin.go.id` | Tim Pusat (Cibinong) |
| **Ketua Tim (Pusat / LKSDM)** | `fath014` | `fathurrahman.adam.rahadian@brin.go.id` | Tim Pusat PKSPU |
| **Eksekutif** | `siti127` | `siti.halimah@brin.go.id` | Eksekutif BRIN |
| **Super Admin** | `aisy004` | `aisyah.febrianti.kusmiandini@brin.go.id` | Super Admin BOSDM |

---

## ✅ Verifikasi Pasca Migrasi
Setelah menjalankan query, Anda dapat memverifikasi isi tabel melalui **Table Editor** di Supabase:
- Tabel `teams`: berisi **22 baris**.
- Tabel `tugas_fungsi`: berisi **91 baris**.
- Tabel `team_tusi`: berisi relasi tusi masing-masing tim.
- Tabel `users`: berisi **240 pegawai**.
- Tabel `questions`: **0 baris** (kosongan).
- Tabel `answers`: **0 baris** (kosongan).
- Tabel `notifications`: **0 baris** (kosongan).
- Tabel `broadcasts`: **0 baris** (kosongan).
- Tabel `broadcast_recipients`: **0 baris** (kosongan).
- Storage Bucket: terdapat bucket `attachments` dengan status **Public**.
