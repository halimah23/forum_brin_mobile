# Implementation Plan: Standardized FAQ System, Detail Screen, and Dashboard Cleanup

Fitur ini merealisasikan FAQ resmi BOSDM Connect yang bersumber langsung dari tiket pertanyaan yang telah di-up ke publik dan dibakukan bahasanya oleh Super Admin, dilengkapi satu respon solusi resmi hasil rangkuman (*summary*) penanganan dari Staf Admin LKSDM, Staf Admin Pusat, dan Ketua Tim, serta menghapus chart topik populer statis lama di seluruh 5 dashboard peran.

---

## User Review Required

> [!IMPORTANT]
> **Skema Database Supabase**:
> - Menambahkan kolom `summary_jawaban TEXT` pada tabel `public.questions` untuk menyimpan hasil rangkuman solusi resmi yang dibuat oleh Super Admin.
> - Membuat PostgreSQL View dinamis `public.view_faq_standardized` untuk kemudahan pemanggilan data FAQ yang cepat dan anti-desinkronisasi.
> - Telah disiapkan skrip migrasi SQL di `supabase/migrations/20261026_standardized_faq_view.sql` dan `lib/core/network/supabase_faq_view.sql`.
> - Jika dijalankan offline atau Supabase belum dimigrasi, aplikasi memiliki *multi-tier in-memory fallback* otomatis dari data tiket yang ada.

> [!NOTE]
> **Penggantian Komponen di Seluruh 5 Dashboard Peran**:
> - Komponen `TrendingChartWidget` lama dan judulnya ("Analisis Topik Populer FAQ" / "Tren Topik Layanan Kepegawaian" / "Topik Pertanyaan Populer Tim") akan dihapus dari seluruh 5 dashboard (`MemberDashboardScreen`, `AdminDashboardScreen`, `KetuaTimDashboardScreen`, `EksekutifDashboardScreen`, dan `SuperAdminDashboardScreen`).
> - Sebagai gantinya, di bagian bawah dashboard akan dipasang `DashboardFaqWidget`, yang menampilkan daftar kartu FAQ resmi yang bisa diklik langsung menuju `FaqDetailScreen`.

---

## Proposed Changes

```mermaid
graph TD
    subgraph Supabase Database
        Q["Tabel public.questions (+ summary_jawaban)"]
        A["Tabel public.answers"]
        V["PostgreSQL View: view_faq_standardized"]
        Q & A --> V
    end

    subgraph Service Layer
        QS["QuestionService"]
        PSD["PublishAndStandardizeDialog"]
    end

    subgraph Presentation Layer
        D1["MemberDashboardScreen"]
        D2["AdminDashboardScreen"]
        D3["KetuaTimDashboardScreen"]
        D4["EksekutifDashboardScreen"]
        D5["SuperAdminDashboardScreen"]

        DFW["DashboardFaqWidget"]
        FS["FaqScreen"]
        FDS["FaqDetailScreen"]
    end

    V --> QS
    QS --> DFW & FS & FDS
    D1 & D2 & D3 & D4 & D5 -->|Pasang di bawah| DFW
    DFW -->|Tap Kartu FAQ| FDS
    DFW -->|Tap 'Lihat Semua'| FS
    FS -->|Tap Kartu FAQ| FDS
    PSD -->|Simpan Baku & Summary| QS
    FDS -->|Edit (Super Admin)| PSD
```

---

### 1. Database & Migrasi Supabase

#### [NEW] `supabase/migrations/20261026_standardized_faq_view.sql` & `lib/core/network/supabase_faq_view.sql`
- Tambahkan kolom `summary_jawaban` pada tabel `public.questions`.
- Buat PostgreSQL View `public.view_faq_standardized` yang mengambil tiket dengan `is_public = TRUE` dan memiliki teks pertanyaan baku (`original_judul IS NOT NULL`) atau memiliki rangkuman solusi (`summary_jawaban IS NOT NULL`) atau disematkan (`is_pinned = TRUE`).
- Berikan hak akses `GRANT SELECT ON public.view_faq_standardized TO authenticated, anon;`.

---

### 2. Model & Serialization Layer

#### [MODIFY] `lib/features/questions/models/question_model.dart`
- Tambahkan property:
  ```dart
  final String? summaryJawaban;
  ```
- Tambahkan getter:
  ```dart
  bool get hasSummary => summaryJawaban != null && summaryJawaban!.trim().isNotEmpty;
  
  /// Mengambil solusi resmi: jika summaryJawaban diisi gunakan itu, jika belum gunakan sintesis dari jawaban staf resmi
  String get effectiveOfficialSummary {
    if (hasSummary) return summaryJawaban!;
    final officialAnswers = answers?.where((a) => a.isOfficial && !a.isSystemEvent).toList() ?? [];
    if (officialAnswers.isNotEmpty) {
      return officialAnswers.map((a) => '[${a.penjawabRole}] ${a.isiJawaban}').join('\n\n');
    }
    return 'Belum ada rangkuman solusi resmi yang dicantumkan.';
  }
  ```
- Perbarui `fromJson`, `toJson`, dan `copyWith` untuk mendukung `summary_jawaban`.

---

### 3. Service Layer

#### [MODIFY] `lib/features/questions/services/question_service.dart`
- Perbarui `publishAndStandardizeQuestion`:
  - Tambahkan parameter `String? summaryJawaban`.
  - Simpan `'summary_jawaban': summaryJawaban` ke Supabase tabel `questions`.
- Tambahkan fungsi baru `getFaqQuestions({String? teamFilter, String? search})`:
  - Melakukan query ke `_client.from('view_faq_standardized').select(...)` beserta `answers`.
  - Jika Supabase offline atau error, fallback in-memory ke pertanyaan yang ada di lokal dengan kondisi `isPublic && isStandardized`.

---

### 4. Kurasi Super Admin: Dialog Pembakuan & Summary

#### [MODIFY] `lib/features/questions/widgets/publish_and_standardize_dialog.dart`
- Tambahkan `TextEditingController _summaryController`.
- Tambahkan fungsi helper otomatis: **"Hasilkan Draf dari Jawaban Staf"**:
  - Mengambil jawaban resmi yang ada dari Staf Admin LKSDM, Staf Admin Pusat, dan Ketua Tim pada tiket.
  - Memasukkan draf terstruktur ke dalam `_summaryController`.
- Tambahkan input `TextFormField` multiline untuk *Rangkuman Solusi / Summary Jawaban Resmi*.
- Simpan `summaryJawaban` melalui `QuestionService.publishAndStandardizeQuestion`.

---

### 5. UI Widgets: Dashboard FAQ Section

#### [NEW] `lib/features/dashboard/widgets/dashboard_faq_widget.dart`
- Widget baru yang dipasang di bagian bawah setiap dashboard:
  - Header: Icon buku bantuan, Judul "Pertanyaan Populer & FAQ Resmi", Subtitle "Solusi terverifikasi yang telah dibakukan oleh Tim BOSDM", dan tombol "Lihat Semua >".
  - Body: Menampilkan hingga 3 kartu FAQ terbaru.
  - Kartu menampilkan badge kategori tim/tusi, judul pertanyaan baku, cuplikan solusi ringkas 2 baris, dan icon chevron right.
  - Tap kartu langsung membuka `FaqDetailScreen(question: q, currentUser: currentUser)`.
  - Tombol "Lihat Semua >" membuka `FaqScreen(currentUser: currentUser)`.

---

### 6. Layar FAQ & Layar Detail FAQ

#### [NEW] `lib/features/questions/screens/faq_detail_screen.dart`
- Halaman Detail FAQ resmi:
  - **AppBar**: "Detail FAQ Resmi", tombol bagikan/kembali.
  - **Badge Status**: "Telah Ditelaah & Dibakukan oleh Super Admin BOSDM".
  - **Kartu Pertanyaan Baku**:
    - Judul pertanyaan baku resmi.
    - Tag Kategori Tusi / Tim dan tanggal rilis.
    - Uraian pertanyaan lengkap (penanya disamarkan menjadi "Pegawai" demi privasi).
    - Tombol ekspansi opsional: *"Lihat Pertanyaan Asli Sebelum Dibakukan"*.
  - **Kartu Solusi Utama (Hero Card Rangkuman)**:
    - Desain visual menonjol berlatar kontras lembut (hijau/biru toska).
    - Menampilkan teks satu respon solusi resmi hasil rangkuman Super Admin.
    - Keterangan: *"Solusi Resmi Terpadu BOSDM BRIN"*.
  - **Kartu Riwayat / Jejak Penanganan Resmi**:
    - Menampilkan catatan/tanggapan dari Staf LKSDM, Staf Pusat, dan Ketua Tim secara kronologis transparan untuk referensi penelusuran SOP.
  - **Khusus Super Admin**:
    - Tombol cepat *"Edit Pembakuan & Solusi"* untuk membuka `PublishAndStandardizeDialog` jika Super Admin ingin memutakhirkan teks FAQ kapan saja.

#### [MODIFY] `lib/features/questions/screens/faq_screen.dart`
- Migrasi dari data statis `TrendingIssuesData` ke pemanggilan dinamis `QuestionService.getFaqQuestions()`.
- Filter chip kategori Tim BOSDM / LKSDM Kawasan.
- Search bar interaktif pencarian instan judul dan isi jawaban.
- Menampilkan daftar kartu FAQ dinamis yang ketika di-tap membuka `FaqDetailScreen`.

---

### 7. Pembersihan di Seluruh Dashboard Peran

Menghapus referensi `TrendingChartWidget` dan teks judul lamanya ("Analisis Topik Populer FAQ" / "Topik Konsultasi Terpopuler" / "Tren Topik Layanan Kepegawaian") dan menggantikannya dengan `DashboardFaqWidget`:
- [MODIFY] `lib/features/dashboard/screens/member_dashboard_screen.dart`
- [MODIFY] `lib/features/dashboard/screens/admin_dashboard_screen.dart`
- [MODIFY] `lib/features/dashboard/screens/ketua_tim_dashboard_screen.dart`
- [MODIFY] `lib/features/dashboard/screens/eksekutif_dashboard_screen.dart`
- [MODIFY] `lib/features/dashboard/screens/super_admin_dashboard_screen.dart`

---

## Verification Plan

### Automated Tests
1. **Analisis Statis & Linting**:
   ```sh
   flutter analyze
   ```
   *Target: 0 error, 0 warning.*
2. **Widget Tests**:
   ```sh
   flutter test test/widget_test.dart
   ```
   *Target: Lulus 100%.*

### Manual Verification Flow
1. **Verifikasi Dashboard Seluruh Role**:
   - Buka aplikasi dan periksa dashboard masing-masing peran (Member, Admin LKSDM, Ketua Tim, Eksekutif, Super Admin).
   - Pastikan chart topik lama tidak lagi tampil.
   - Pastikan widget `DashboardFaqWidget` tampil rapi di bagian bawah.
2. **Verifikasi Detail FAQ (`FaqDetailScreen`)**:
   - Klik salah satu pertanyaan pada widget FAQ di dashboard.
   - Pastikan terbuka `FaqDetailScreen` dengan pertanyaan baku (identitas "Pegawai"), kartu solusi resmi hasil rangkuman Super Admin, dan jejak respon penanganan dari Staf LKSDM, Staf Pusat, dan Ketua Tim.
3. **Verifikasi Halaman Lengkap FAQ (`FaqScreen`)**:
   - Klik tombol "Lihat Semua FAQ".
   - Coba fitur filter kategori tim dan bar pencarian.
   - Klik kartu FAQ untuk memastikan navigasi ke `FaqDetailScreen` berjalan mulus.
4. **Verifikasi Kurasi & Rangkuman Super Admin**:
   - Login sebagai Super Admin, buka tiket pertanyaan yang selesai atau berjalan.
   - Buka dialog "Up ke Publik & Bakukan".
   - Klik tombol "Hasilkan Draf dari Jawaban Staf" untuk mengisi rangkuman solusi.
   - Simpan dan pastikan tiket tersebut langsung muncul di daftar FAQ dengan judul baku dan rangkuman jawaban yang tepat.
