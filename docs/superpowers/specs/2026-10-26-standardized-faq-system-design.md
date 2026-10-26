# Design Spec: Standardized FAQ System and Detail Screen

## 1. Overview & Context

Aplikasi Helpdesk Kepegawaian **BOSDM Connect** saat ini memiliki dua keterbatasan pada fitur FAQ:
1. Analisis tren topik populer lama (`TrendingChartWidget`) yang menampilkan data statis/mock di seluruh lima role dashboard (`Member`, `Admin LKSDM`, `Ketua Tim`, `Eksekutif`, dan `Super Admin`).
2. Layar `FaqScreen` masih menggunakan data simulasi mock (`TrendingIssuesData`), padahal Super Admin telah memiliki fitur membakukan pertanyaan pegawai dan mengunggahnya ke publik.

Tujuan dari desain ini adalah:
- Menghapus komponen analisis topik populer lama (`TrendingChartWidget`) dari seluruh lima dashboard peran.
- Menggantikannya dengan daftar interaktif FAQ resmi di bagian bawah dashboard semua peran.
- Mengintegrasikan FAQ langsung dengan tiket pertanyaan yang telah di-up ke publik dan dibakukan bahasanya oleh Super Admin.
- Menyediakan satu respon solusi resmi yang telah dirangkum (*summary*) oleh Super Admin dari berbagai masukan staf penanganan (Staf Admin LKSDM, Staf Admin Pusat, dan Ketua Tim).
- Membangun halaman detail FAQ (`FaqDetailScreen`) yang menampilkan pertanyaan baku, satu solusi hasil rangkuman Super Admin, dan transparansi jejak tanggapan penanganan resmi para staf.
- Membangun skema database PostgreSQL di Supabase (kolom `summary_jawaban` dan view dinamis `view_faq_standardized`).

---

## 2. Requirements & User Decisions

- **Penghapusan Chart Populer Lama**: Hapus `TrendingChartWidget` dari seluruh 5 dashboard peran:
  - `MemberDashboardScreen`
  - `AdminDashboardScreen`
  - `KetuaTimDashboardScreen`
  - `EksekutifDashboardScreen`
  - `SuperAdminDashboardScreen`
- **Dashboard FAQ Section**: Tempatkan widget FAQ di bagian bawah seluruh 5 dashboard tersebut. Kartu pertanyaan dapat di-tap langsung untuk menuju `FaqDetailScreen`, dan disediakan tombol "Lihat Semua FAQ" menuju `FaqScreen`.
- **Database Supabase**:
  - Kolom `summary_jawaban TEXT` pada tabel `public.questions`.
  - PostgreSQL View dinamis `view_faq_standardized` yang memfilter tiket dengan `is_public = TRUE` dan memiliki teks pertanyaan baku / rangkuman jawaban, terurut berdasarkan status `is_pinned` dan tanggal terbaru.
  - Multi-tier in-memory fallback di aplikasi Flutter untuk keandalan saat offline.
- **Kurasi Super Admin**:
  - Di `PublishAndStandardizeDialog`, sediakan input "Rangkuman Solusi / Summary Jawaban Resmi" dengan tombol prefill otomatis dari jawaban resmi staf yang sudah ada pada tiket.
- **Halaman Detail FAQ (`FaqDetailScreen`)**:
  - Pertanyaan yang telah dibakukan (dengan nama penanya disamarkan menjadi "Pegawai" demi privasi).
  - Satu respon penanganan utama hasil *summary* resmi dari Super Admin.
  - Kartu jejak/riwayat tanggapan resmi dari Staf Admin LKSDM, Staf Admin Pusat, dan arahan/validasi Ketua Tim secara kronologis transparan.
  - Tombol aksi Super Admin untuk menyunting kembali teks pembakuan dan ringkasan solusi langsung dari layar detail.

---

## 3. Architecture & Data Flow

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
        QNS["QuestionNormalizerService"]
    end

    subgraph Presentation Layer
        D1["MemberDashboardScreen"]
        D2["AdminDashboardScreen"]
        D3["KetuaTimDashboardScreen"]
        D4["EksekutifDashboardScreen"]
        D5["SuperAdminDashboardScreen"]
        
        DFW["DashboardFaqWidget (Bagian Bawah Dashboard)"]
        FS["FaqScreen (Daftar Seluruh FAQ & Pencarian)"]
        FDS["FaqDetailScreen (Detail Pertanyaan Baku & Rangkuman Solusi)"]
        PSD["PublishAndStandardizeDialog (Super Admin)"]
    end

    V --> QS
    QS --> DFW & FS & FDS
    D1 & D2 & D3 & D4 & D5 -->|Render di bawah| DFW
    DFW -->|Klik kartu FAQ| FDS
    DFW -->|Tombol 'Lihat Semua'| FS
    FS -->|Klik item FAQ| FDS
    FDS -->|Edit (Super Admin)| PSD
    PSD -->|Simpan Baku & Summary| QS
```

---

## 4. Detailed Component Design

### 4.1. Database Migration (Supabase SQL)
- File: `supabase/migrations/20261026_standardized_faq_view.sql` & `lib/core/network/supabase_faq_view.sql`
- Script SQL:
  ```sql
  -- 1. Tambah kolom summary_jawaban jika belum ada
  ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS summary_jawaban TEXT;

  -- 2. View FAQ Terstandarisasi
  CREATE OR REPLACE VIEW public.view_faq_standardized AS
  SELECT 
      q.id,
      q.ticket_number,
      q.judul,
      q.isi,
      q.original_judul,
      q.original_isi,
      q.summary_jawaban,
      q.status,
      q.target_tim,
      q.target_tim_pusat,
      q.lksdm_kawasan,
      q.tugas_fungsi_nama,
      q.is_public,
      q.is_pinned,
      q.created_at,
      q.updated_at,
      p.id AS author_id,
      p.name AS author_name,
      p.role AS author_role,
      p.unit AS author_unit
  FROM public.questions q
  LEFT JOIN public.profiles p ON q.user_id = p.id
  WHERE q.is_public = TRUE
    AND (
      q.original_judul IS NOT NULL 
      OR q.summary_jawaban IS NOT NULL 
      OR q.is_pinned = TRUE
    )
  ORDER BY q.is_pinned DESC, q.created_at DESC;

  -- 3. Hak akses publik untuk membaca view FAQ
  GRANT SELECT ON public.view_faq_standardized TO authenticated, anon;
  ```

### 4.2. Data Model & Serialization
- `QuestionModel` (`lib/features/questions/models/question_model.dart`):
  - Field: `final String? summaryJawaban;`
  - Getter: `bool get hasSummary => summaryJawaban != null && summaryJawaban!.trim().isNotEmpty;`
  - Helper getter `effectiveOfficialSummary`: Jika `summaryJawaban` tersedia, gunakan itu. Jika tidak, sintetiskan dari jawaban staf LKSDM/Pusat/Ketua Tim yang ada di `answers`.
  - Serializer: `fromJson` membaca `'summary_jawaban'` atau `'official_summary'`, `toJson` dan `copyWith` diperbarui.

### 4.3. Service Layer
- `QuestionService` (`lib/features/questions/services/question_service.dart`):
  - `publishAndStandardizeQuestion`: Ditambahkan parameter opsional `String? summaryJawaban`. Menyimpan kolom `summary_jawaban` ke tabel `questions`.
  - `getFaqQuestions({String? teamFilter, String? search})`: Mengambil data dari view `view_faq_standardized` (beserta jawaban terkait dari `answers`), dengan fallback otomatis in-memory ke pertanyaan lokal berstatus `is_public` dan `isStandardized`.

### 4.4. Dialog Pembakuan Super Admin (`PublishAndStandardizeDialog`)
- Ditambahkan input teks multi-baris (TextField) untuk **Rangkuman Solusi / Summary Jawaban Resmi**.
- Tombol aksi cerdas: **"Hasilkan Draf dari Jawaban Staf"** yang mengumpulkan poin-poin utama dari jawaban Staf Admin LKSDM, Staf Pusat, dan Ketua Tim pada tiket tersebut ke dalam kotak teks.
- Super Admin dapat membaca, merevisi kalimat draf, atau mengetikkan ringkasan solusi final sesuai SOP kepegawaian BRIN.

### 4.5. Dashboard FAQ Section Widget (`DashboardFaqWidget`)
- Widget baru di `lib/features/dashboard/widgets/dashboard_faq_widget.dart`:
  - Menggantikan posisi `TrendingChartWidget` di bagian bawah seluruh lima layar dashboard.
  - Header: Icon buku bantuan / bintang, Judul "Pertanyaan Populer & FAQ Resmi BOSDM", dan tombol teks "Lihat Semua >".
  - Body: Menampilkan hingga 3-5 kartu FAQ terbaru / tersemat:
    - Tag Kategori Tim / Tusi kepegawaian.
    - Judul pertanyaan yang telah dibakukan.
    - Cuplikan 2 baris dari rangkuman solusi resmi.
    - Indikator panah navigasi.
  - Menangani state kosong (jika belum ada FAQ yang dibakukan, menampilkan kartu informasi ramah).
  - On tap: Membuka `FaqDetailScreen`.

### 4.6. Halaman FAQ Lengkap (`FaqScreen`)
- `lib/features/questions/screens/faq_screen.dart`:
  - Diperbarui dari penggunaan data mock statis menjadi data dinamis dari `QuestionService.getFaqQuestions()`.
  - Search bar interaktif (judul dan isi solusi).
  - Filter chip kategori Tim BOSDM / Layanan Kawasan.
  - Kartu FAQ interaktif yang ketika di-tap langsung mengarahkan ke `FaqDetailScreen`.

### 4.7. Halaman Detail FAQ (`FaqDetailScreen`)
- Widget baru di `lib/features/questions/screens/faq_detail_screen.dart`:
  - **AppBar**: Judul "Detail FAQ Resmi", tombol share/bookmark.
  - **Badge Validasi**: "Telah Ditelaah & Dibakukan Resmi oleh Super Admin BOSDM".
  - **Section Pertanyaan Baku**:
    - Judul pertanyaan baku resmi.
    - Kategori Tim / Tusi dan tanggal publikasi.
    - Uraian pertanyaan lengkap (nama penanya disamarkan menjadi "Pegawai").
    - Opsi ekspansi transparan: "Lihat Pertanyaan Asli Sebelum Dibakukan".
  - **Section Rangkuman Solusi Resmi (Hero Card)**:
    - Desain visual kontras berlatar lembut (emerald/sky) dengan badge "Solusi Resmi BOSDM".
    - Teks rangkuman solusi tuntas hasil rumusan Super Admin.
  - **Section Jejak Penanganan Resmi**:
    - Riwayat tanggapan kronologis dari Staf LKSDM, Staf Pusat, dan Ketua Tim dengan kartu visual berlabel peran resmi masing-masing.
  - **Hak Akses Super Admin**:
    - Floating Action Button atau tombol AppBar "Edit Pembakuan & Solusi" untuk membuka `PublishAndStandardizeDialog` jika Super Admin ingin memutakhirkan jawaban atau judul sewaktu-waktu.

### 4.8. Pembersihan di Seluruh Dashboard
- Menghapus referensi `TrendingChartWidget` dan teks judulnya dari:
  - `lib/features/dashboard/screens/member_dashboard_screen.dart`
  - `lib/features/dashboard/screens/admin_dashboard_screen.dart`
  - `lib/features/dashboard/screens/ketua_tim_dashboard_screen.dart`
  - `lib/features/dashboard/screens/eksekutif_dashboard_screen.dart`
  - `lib/features/dashboard/screens/super_admin_dashboard_screen.dart`
- Menggantikannya dengan `DashboardFaqWidget(currentUser: widget.user)`.

---

## 5. Testing & Verification

1. **Static Analysis**: `flutter analyze` harus menghasilkan 0 error dan 0 warning.
2. **Widget Tests**: `flutter test test/widget_test.dart` harus lulus 100%.
3. **Manual Verification**:
   - Buka tiap dashboard role (Member, Admin LKSDM, Ketua Tim, Eksekutif, Super Admin); pastikan chart lama hilang dan widget FAQ baru tampil dengan rapi di bagian bawah.
   - Klik kartu FAQ di dashboard; pastikan membuka `FaqDetailScreen` dengan pertanyaan baku dan rangkuman solusi.
   - Klik tombol "Lihat Semua" di widget FAQ; pastikan membuka `FaqScreen`.
   - Lakukan tes pembakuan tiket baru sebagai Super Admin dengan menyertakan rangkuman solusi; pastikan tersimpan ke Supabase dan langsung muncul di FAQ.
