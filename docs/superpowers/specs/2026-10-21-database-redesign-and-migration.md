# Spesifikasi Desain: Redesain Skema Database & Migrasi Data Instansi BRIN

- **Tanggal**: 21 Oktober 2026
- **Status**: Menunggu Persetujuan (Pending Approval)
- **Topik**: Rekonstruksi Skema Tabel `users`, `teams`, `tugas_fungsi`, `team_tusi`, serta Integrasi Aplikasi Mobile Forum Kepegawaian BRIN

---

## 1. Latar Belakang & Tujuan
Tabel lama (`profiles`, `teams`, `tugas_fungsi`) memiliki struktur yang kurang terstandarisasi, memiliki redundansi data, dan belum merefleksikan hierarki kerja instansi BRIN (Pusat vs LKSDM Kawasan, relasi many-to-many antara Tim dan Tusi).

Tujuan migrasi ini adalah:
1. Merestrukturisasi tabel database Supabase agar sesuai Standar Operasional Prosedur (SOP) pangkalan data instansi pemerintah:
   - `teams`: Menyimpan data unit kerja / tim (Pusat dan LKSDM Kawasan) dengan cakupan wilayah (*coverage*) dan catatan operasional.
   - `tugas_fungsi`: Menyimpan katalog 91 butir tugas dan fungsi (Tusi).
   - `team_tusi`: Tabel relasi *many-to-many* antara Tim dan Tugas Fungsinya.
   - `users`: Menyimpan profil 240 pegawai BRIN dengan relasi langsung ke `teams(id_tim)`. Redundansi kolom tim/eskalasi dinormalisasi.
   - `questions` & `answers`: Menyesuaikan foreign key agar mengacu ke `users(id_user)` dan `tugas_fungsi(id_tusi)`.
2. Mengosongkan data lama di Supabase dan mengimpor 240 pengguna, 22 tim, 91 tusi, dan seluruh relasi tim-tusi yang valid.
3. Menyiapkan 1 tiket pertanyaan pengujian alur 3-pihak (Pegawai $\rightarrow$ LKSDM $\rightarrow$ Pusat) menggunakan akun data baru.
4. Memperbarui seluruh kode sumber Flutter (Models, Services, Cubits, Screens) dan menyematkan 7 preset akun pada fitur Akses Pengujian Cepat di halaman login.

---

## 2. Struktur Skema Database Baru (PostgreSQL / Supabase DDL)

### 2.1. Tabel `teams`
Menyimpan 22 tim kerja resmi (14 Tim Pusat BOSDM dan 8 Tim Layanan Kawasan SDM / LKSDM).
```sql
CREATE TABLE public.teams (
    id_tim VARCHAR(50) PRIMARY KEY, -- 'tim_001' s/d 'tim_022'
    tim VARCHAR(100) NOT NULL, -- Kode singkatan: ORTALA, LKSDM 1, dsb.
    detail_nama_tim TEXT NOT NULL,
    coverage TEXT,
    sebaran_hbp TEXT,
    catatan TEXT,
    eskalasi VARCHAR(50) NOT NULL -- 'PUSAT' atau 'LKSDM'
);
```

### 2.2. Tabel `tugas_fungsi`
Menyimpan 91 butir tugas dan fungsi resmi kepegawaian BRIN.
```sql
CREATE TABLE public.tugas_fungsi (
    id_tusi VARCHAR(50) PRIMARY KEY, -- 'ts_001' s/d 'ts_091'
    tugas_fungsi TEXT NOT NULL
);
```

### 2.3. Tabel Relasi `team_tusi`
Relasi *many-to-many* antara Tim dan Tugas Fungsi.
```sql
CREATE TABLE public.team_tusi (
    id_tim VARCHAR(50) NOT NULL REFERENCES public.teams(id_tim) ON DELETE CASCADE,
    id_tusi VARCHAR(50) NOT NULL REFERENCES public.tugas_fungsi(id_tusi) ON DELETE CASCADE,
    PRIMARY KEY (id_tim, id_tusi)
);
```

### 2.4. Tabel `users`
Menyimpan 240 akun pengguna resmi instansi BRIN.
```sql
CREATE TABLE public.users (
    id_user VARCHAR(50) PRIMARY KEY, -- 'usr_001' s/d 'usr_240'
    username VARCHAR(100) UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    external_email VARCHAR(255),
    phone VARCHAR(50),
    sex VARCHAR(20), -- 'Laki-Laki' atau 'Perempuan'
    satuan_kerja VARCHAR(100), -- 'BOSDM', 'BHKS', dsb.
    id_tim VARCHAR(50) REFERENCES public.teams(id_tim) ON DELETE SET NULL,
    jabatan TEXT,
    kawasan VARCHAR(100), -- Kawasan LKSDM penugasan/lokasi
    role VARCHAR(50) NOT NULL, -- 'Ketua Tim', 'Staff Admin', 'Member', 'Executive', 'Super Admin'
    password VARCHAR(255) DEFAULT 'Password123!' -- Default kredensial
);
```

### 2.5. Tabel `questions` (Tiket)
Tabel tiket pertanyaan disesuaikan foreign key dan mempertahankan atribut fitur UI:
```sql
CREATE TABLE public.questions (
    id BIGSERIAL PRIMARY KEY,
    ticket_number TEXT UNIQUE,
    user_id VARCHAR(50) NOT NULL REFERENCES public.users(id_user) ON DELETE CASCADE,
    judul TEXT NOT NULL,
    isi TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'menunggu_lksdm',
    lksdm_kawasan TEXT,
    target_tim_pusat TEXT,
    id_tusi VARCHAR(50) REFERENCES public.tugas_fungsi(id_tusi) ON DELETE SET NULL,
    tugas_fungsi_nama TEXT,
    admin_lksdm_id VARCHAR(50) REFERENCES public.users(id_user) ON DELETE SET NULL,
    admin_pusat_id VARCHAR(50) REFERENCES public.users(id_user) ON DELETE SET NULL,
    is_public BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    attachment_url TEXT,
    attachment_name TEXT,
    rating INT,
    rating_feedback TEXT,
    rating_submitted_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.6. Tabel `answers` (Percakapan Thread)
```sql
CREATE TABLE public.answers (
    id BIGSERIAL PRIMARY KEY,
    question_id BIGINT NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    user_id VARCHAR(50) REFERENCES public.users(id_user) ON DELETE SET NULL,
    sender_name TEXT NOT NULL,
    sender_role TEXT NOT NULL,
    isi_pesan TEXT NOT NULL,
    attachment_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.7. Tabel `notifications` (Notifikasi Pengguna)
```sql
CREATE TABLE public.notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL REFERENCES public.users(id_user) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    question_id BIGINT REFERENCES public.questions(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.8. Kebijakan Row Level Security (RLS)
Karena `id_user` menggunakan format string instansi (`usr_001`), otentikasi dan query via PostgREST menggunakan key publik/anon Supabase dengan kebijakan RLS yang mengizinkan akses operasional aplikasi:
```sql
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tugas_fungsi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_tusi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read teams" ON public.teams FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read tugas_fungsi" ON public.tugas_fungsi FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read team_tusi" ON public.team_tusi FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all users" ON public.users FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all questions" ON public.questions FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all answers" ON public.answers FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all notifications" ON public.notifications FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
```

---

## 3. Aturan Bisnis & Logika Peran (Role Mapping)

Aplikasi mobile memetakan data dari tabel `users` dan `teams` ke enum `UserRole` di Flutter:
1. `role == 'Super Admin'` $\rightarrow$ `UserRole.superAdmin`
2. `role == 'Executive'` $\rightarrow$ `UserRole.eksekutif`
3. `role == 'Member'` $\rightarrow$ `UserRole.member`
4. `role == 'Ketua Tim'` $\rightarrow$ `UserRole.ketuaTim` (mengenali cakupan `teams.eskalasi` Pusat vs LKSDM)
5. `role == 'Staff Admin'`:
   - Jika `teams.eskalasi == 'LKSDM'` $\rightarrow$ `UserRole.adminLksdm`
   - Jika `teams.eskalasi == 'PUSAT'` $\rightarrow$ `UserRole.adminPusat`
   - Default: `UserRole.admin`

---

## 4. Mekanisme Otentikasi & Preset Akses Cepat

### 4.1. Login Identifiers
Pengguna dapat memasukkan **Email BRIN** (misal: `fathurrahman.adam.rahadian@brin.go.id`) ATAU **Username** (misal: `fath014`).
Kata sandi standar untuk seluruh 240 akun pengujian disetel ke `Password123!`.

### 4.2. Preset Akses Pengujian Cepat (7 Akun)
1. **Super Admin**: Aisyah Febrianti Kusmiandini (`aisyah.febrianti.kusmiandini@brin.go.id` / `aisy004`)
2. **Eksekutif**: Siti Halimah (`siti.halimah@brin.go.id` / `siti127`)
3. **Ketua Tim (Pusat)**: Fathurrahman Adam Rahadian (`fathurrahman.adam.rahadian@brin.go.id` / `fath014`, Tim PKSPU)
4. **Ketua Tim (LKSDM)**: Lutvia Restu Putriana (`lutvia.restu.putriana@brin.go.id` / `lutv003`, Tim LKSDM 1)
5. **Staff Admin (Pusat)**: Syifaniar Ramadhanny (`syifaniar.ramadhanny@brin.go.id` / `syif007`, Tim PKSPU)
6. **Staff Admin (LKSDM)**: Maria Fernanda De Vega (`maria.fernanda.de.vega@brin.go.id` / `mari063`, Tim LKSDM 6)
7. **Member / Pegawai**: Manda Talita Taruli Hasibuan (`manda.talita.taruli.hasibuan.@brin.go.id` / `mand001`, BHKS)

---

## 5. Rencana Eksekusi Kode & Migrasi
1. **Pembersihan Database & Eksekusi DDL**:
   - Menghapus tabel lama (`profiles`, `teams`, `tugas_fungsi`, `question_tugas_fungsi`, `questions`, `answers`).
   - Membuat tabel baru `teams`, `tugas_fungsi`, `team_tusi`, `users`, `questions`, `answers` dengan RLS yang sesuai.
   - Meng-insert 22 records ke `teams`, 91 records ke `tugas_fungsi`, relasi ke `team_tusi`, 240 records ke `users`, serta 1 tiket thread pengujian.
2. **Refactor Kode Mobile**:
   - `lib/features/auth/models/user_model.dart`: Mendukung kolom `id_user`, `username`, `first_name`, `id_tim`, `satuan_kerja`, `phone`, `sex`, dsb.
   - `lib/features/auth/services/auth_service.dart`: Mengarahkan query login ke tabel `users` (mendukung email & username), join ke `teams`.
   - `lib/features/auth/services/user_service.dart`: Menyesuaikan CRUD dengan tabel `users` dan `teams`.
   - `lib/features/questions/services/question_service.dart`: Menyesuaikan query join `users` (sebelumnya `profiles`) dan `tugas_fungsi` / `team_tusi`.
   - `lib/features/auth/screens/login_screen.dart`: Memperbarui 7 tombol akses cepat.
   - `lib/features/auth/widgets/user_form_dialog.dart` & `user_account_card.dart`: Menyesuaikan fields baru.
3. **Verifikasi**:
   - Menjalankan `flutter analyze` hingga 0 issue.
   - Menjalankan seluruh rangkaian `flutter test` untuk memastikan semua fitur berjalan optimal.
