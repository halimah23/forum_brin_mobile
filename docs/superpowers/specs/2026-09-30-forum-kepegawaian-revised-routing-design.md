# Spesifikasi Teknis: Forum Kepegawaian BOSDM Connect (Revisi Alur Routing & Bubble Chat)

**Tanggal:** 30 September 2026  
**Status:** Draf Tervalidasi  
**Sistem:** Forum Kepegawaian Mobile (`forum_brin_mobile`)

---

## 1. Latar Belakang & Tujuan

Berdasarkan dokumen konsep terbaru dari klien, forum layanan kepegawaian BOSDM Connect ditransformasikan dari bentuk forum tanya-jawab berbasis tiket kaku menjadi mekanisme **bubble chat langsung berjenjang** yang cerdas.

Tujuan utama revisi ini adalah:
1. **Routing Otomatis**: Pegawai tidak perlu bingung memilih tim atau kode tugas-fungsi tujuan. Pertanyaan otomatis dialirkan ke **Staf Admin LKSDM (Kawasan)** sesuai wilayah kerja pegawai.
2. **Penyelesaian Berjenjang**: Pertanyaan diselesaikan terlebih dahulu di tingkat LKSDM. Jika tuntas, percakapan ditutup.
3. **Eskalasi Pintar ke Tim Pusat (14 Tim)**: Jika belum tuntas (misal pegawai mengonfirmasi "Belum Terjawab"), sistem menganalisis konteks/kata kunci pertanyaan untuk merekomendasikan tim pusat yang tepat bagi Staf LKSDM.
4. **Ruang Chat Tripartit Berkembang**: Ruang obrolan berkembang menjadi `Pegawai + Staf LKSDM + Tim Pusat`, riwayat percakapan tetap utuh, dan Staf LKSDM tetap aktif sebagai fasilitator pendamping.
5. **Dukungan 5 Peran Lengkap**: Pegawai, Staf Admin (LKSDM & Pusat), Ketua Tim, Eksekutif (pemantauan read-only & tren isu), dan Super Admin (monitoring & FAQ).

---

## 2. Struktur Peran & Hak Akses (User Roles)

### 2.1 Daftar Peran
1. **Pegawai (`member`)**
   - Mengajukan pertanyaan tanpa memilih tim tujuan teknis.
   - Wilayah LKSDM terdeteksi otomatis dari profil/preferensi tersimpan.
   - Merespons konfirmasi kepuasan jawaban (*"Apakah pertanyaan sudah terjawab? [Ya]/[Tidak]"*).
2. **Staf Admin (`admin`)**
   - **Staf Admin LKSDM**: Menerima pertanyaan wilayahnya, memberikan jawaban langsung, mengonfirmasi eskalasi ke 1 dari 14 Tim Pusat jika belum selesai, mendampingi percakapan tripartit.
   - **Staf Admin Pusat**: Menerima eskalasi sesuai salah satu dari 14 Tim Pusat, memberikan tanggapan resmi, menyelesaikan pertanyaan.
3. **Ketua Tim (`ketuaTim`)**
   - Memantau pertanyaan dan kinerja staf admin di timnya.
   - Berhak membalas/menjawab pertanyaan publik maupun privat.
   - Memiliki akses ringkasan eksekutif terhadap isu-isu di timnya.
4. **Eksekutif (`eksekutif`) - *Baru***
   - Akses murni *read-only*.
   - Tidak memiliki tombol untuk menjawab atau mengeskalasi pertanyaan.
   - Memantau volume aktivitas dan dasbor analitik tren isu kepegawaian.
5. **Super Admin (`superAdmin`)**
   - Akses audit menyeluruh lintas tim dan lintas LKSDM.
   - Memantau isu-isu yang paling banyak dibahas dan mengangkat topik populer menjadi basis informasi / FAQ resmi.

---

## 3. Alur Kerja (Workflow) & Siklus Hidup Pertanyaan

```mermaid
sequenceDiagram
    autonumber
    actor P as Pegawai
    actor L as Staf Admin LKSDM
    actor C as Staf Admin Pusat (14 Tim)
    actor E as Eksekutif / Super Admin

    P->>L: 1. Kirim Pertanyaan (Auto-route ke LKSDM Wilayah)
    Note over P,L: Ruang Chat: Pegawai + LKSDM
    L->>P: 2. Jawaban Solusi Awal
    Note over P: Muncul Kartu: "Apakah pertanyaan sudah terjawab?"
    alt Kasus A: Terjawab di LKSDM
        P->>L: Klik [Ya, Sudah Terjawab]
        Note over P,L: Tiket SELESAI & Ditutup
    else Kasus B: Butuh Arahan Pusat
        P->>L: Klik [Tidak / Butuh Pusat]
        Note over L: Sistem merekomendasikan Tim Pusat berdasarkan kata kunci
        L->>C: Konfirmasi Eskalasi ke Tim Pusat (1 dari 14 Tim)
        Note over P,L,C: Ruang Chat Berkembang: Tripartit (Pegawai + LKSDM + Tim Pusat)
        C->>P: 3. Jawaban Resmi & Arahan Kebijakan
        C->>P: Tiket SELESAI & Terdokumentasi
    end
    E-->>P: Monitoring Isu Populer & Analitik FAQ
```

### 3.1 Status Pertanyaan (*Status Lifecycle*)
- `menunggu_lksdm`: Pertanyaan baru dibuat oleh pegawai, menunggu tanggapan Staf Admin LKSDM.
- `ditangani_lksdm`: Staf Admin LKSDM telah mengirimkan respons dan kartu konfirmasi aktif.
- `eskalasi_pusat`: Pertanyaan dialihkan ke salah satu dari 14 Tim Pusat; ruang chat kini tripartit.
- `selesai`: Percakapan telah terselesaikan secara tuntas.

---

## 4. Desain Komponen & Antarmuka (UI/UX)

### 4.1 Halaman Buat Pertanyaan (`AskQuestionScreen`)
- **Penyederhanaan Form**:
  - Menghilangkan dropdown pemilihan 14 Tim dan pemilihan Tusi manual oleh pegawai.
  - Memeriksa preferensi wilayah LKSDM pegawai (disimpan di `SharedPreferences` via `SessionManager`). Jika belum ada, dialog cepat pemilihan wilayah LKSDM (LKSDM 1 s/d LKSDM 6) akan tersimpan permanen.
  - Form hanya berisi: Judul Pertanyaan, Rincian Kendala, dan Status Visibilitas (Publik / Privat).
  - Banner informatif: *"Pertanyaan akan otomatis ditangani oleh Staf Admin [LKSDM X]"*.

### 4.2 Halaman Ruang Chat Berjenjang (`QuestionDetailScreen`)
- **Bubble Chat Thread**:
  - Bubble Pengirim (Pegawai): Kanan, latar biru lembut (`#E3F2FD`).
  - Bubble Staf LKSDM: Kiri, border teal dengan lencana *"Staf LKSDM [Wilayah]"*.
  - Bubble Tim Pusat: Kiri, border biru tua/oranye dengan lencana *"Tim Pusat [Nama Tim]"*.
  - Bubble Ketua Tim: Kiri, border ungu dengan lencana *"Ketua Tim"*.
  - Bubble Acara Sistem (*System Event*): Tengah, kapsul abu-abu/kuning untuk notifikasi eskalasi.
- **Kartu Konfirmasi Kepuasan Interaktif**:
  - Muncul di dalam antrean chat setelah tanggapan LKSDM diberikan:
    - Tombol `[ Ya, Sudah Terjawab ]` -> Mengubah status menjadi `selesai`.
    - Tombol `[ Belum / Butuh Pusat ]` -> Menampilkan rekomendasi cerdas tim pusat tujuan dan memicu alur eskalasi.
- **Panel Input Pesan Dinamis**:
  - Kolom input pesan langsung aktif untuk peserta yang memiliki kewenangan membalas.
  - Menonaktifkan input jika tiket berstatus `selesai` atau pengguna adalah `eksekutif` (read-only banner).

### 4.3 Dasbor Pengguna Sesuai Peran
1. **`MemberDashboardScreen`**: Panel pegawai yang fokus pada tombol buat pertanyaan cepat dan pemantauan daftar pertanyaan saya.
2. **`AdminDashboardScreen`**:
   - Jika pengguna adalah Admin LKSDM: Menampilkan antrean masuk LKSDM dan tombol kelola eskalasi.
   - Jika pengguna adalah Admin Pusat: Menampilkan tiket hasil eskalasi sesuai timnya.
3. **`EksekutifDashboardScreen`**:
   - Kartu statistik pemantauan (Total Tiket, Selesai di Wilayah, Dieskalasi ke Pusat).
   - Widget **Tren Isu Kepegawaian** (kategori/kata kunci yang paling sering muncul).
   - Akses daftar seluruh forum publik tanpa tombol aksi penulisan.
4. **`SuperAdminDashboardScreen`**:
   - Pemantauan komprehensif seluruh tiket.
   - Modul **Bank Isu Populer & FAQ**, memungkinkan Super Admin melihat pertanyaan berulang dan menjadikannya materi informasi resmi.

---

## 5. Rincian Perubahan Berkas Kode

| Berkas | Aksi | Deskripsi Perubahan |
| :--- | :--- | :--- |
| `lib/features/auth/models/user_role.dart` | Modifikasi | Tambah enum `eksekutif`, sesuaikan `fromString()`, `displayName`, dan `key`. |
| `lib/features/auth/models/user_model.dart` | Modifikasi | Tambah getter `isAdminLksdm`, `isAdminPusat`, `isEksekutif`, dan atribut wilayah LKSDM. |
| `lib/features/questions/models/question_model.dart` | Modifikasi | Dukungan field `lksdmWilayah`, `escalatedToTeam`, dan status baru (`menunggu_lksdm`, `eskalasi_pusat`). |
| `lib/features/questions/models/answer_model.dart` | Modifikasi | Dukungan tipe pengirim: `senderRoleType` untuk membedakan bubble LKSDM, Tim Pusat, dan Pegawai. |
| `lib/features/questions/data/trending_issues_data.dart` | Baru | Data mock / engine analitik topik populer dan FAQ kepegawaian. |
| `lib/features/questions/services/question_service.dart` | Modifikasi | Tambah metode `escalateQuestion()`, `confirmAnswerResolution()`, dan `getTrendingIssues()`. |
| `lib/features/questions/screens/ask_question_screen.dart` | Modifikasi | Alur pengajuan otomatis ke LKSDM tanpa form manual 14 tim. |
| `lib/features/questions/screens/question_detail_screen.dart` | Modifikasi | Rombak menjadi bubble chat berjenjang, kartu konfirmasi interaktif, dan penanganan tripartit. |
| `lib/features/dashboard/screens/eksekutif_dashboard_screen.dart` | Baru | Dashboard monitoring read-only dan tren isu kepegawaian. |
| `lib/features/dashboard/screens/role_router_screen.dart` | Modifikasi | Arahkan `UserRole.eksekutif` ke `EksekutifDashboardScreen`. |
| `lib/features/dashboard/screens/super_admin_dashboard_screen.dart` | Modifikasi | Tambahkan tab/kartu Tren Isu dan Bank FAQ. |
| `lib/features/dashboard/screens/admin_dashboard_screen.dart` | Modifikasi | Dukungan tampilan antrean LKSDM vs antrean Tim Pusat. |

---

## 6. Rencana Pengujian & Verifikasi

1. **Static Analysis**: Jalankan `flutter analyze` untuk memastikan tidak ada kesalahan tipe data atau linting error.
2. **Widget & Unit Testing**:
   - Pengujian parsing `UserRole` termasuk `eksekutif`.
   - Pengujian alur pengajuan pertanyaan dengan auto-routing LKSDM.
   - Pengujian rendering bubble chat dan kartu konfirmasi Ya/Tidak.
   - Menjalankan `flutter test` pada rangkaian test suite yang ada.
