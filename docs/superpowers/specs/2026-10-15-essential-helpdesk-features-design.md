# Spesifikasi Desain: 6 Fitur Esensial Helpdesk BOSDM Connect

**Tanggal**: 15 Oktober 2026  
**Status**: Menunggu Review & Persetujuan Pengguna  
**Kategori**: Arsitektural (*Architectural Path*)  

---

## 1. Ringkasan Eksekutif & Tujuan

Spesifikasi ini merancang implementasi 6 pilar fitur esensial sistem tiket kepegawaian BOSDM Connect:
1. **Lampiran Berkas (Attachments)**: Pegawai dapat melampirkan berkas (gambar/PDF bukti SK, nota dinas, ijazah) saat mengajukan atau menanggapi tiket, terhubung dengan Supabase Storage.
2. **Pencarian & Filter Cepat (Search & Filter)**: Kolom pencarian instan (search bar) dengan *debounce* untuk mencari nomor tiket, kata kunci judul, serta penyaringan berdasarkan tim dan status.
3. **SLA & Visual Tracker (Timeline)**: Indikator SLA 48 Jam (2 Hari Kerja) dengan kode warna (Hijau, Kuning, Merah) serta visual step tracker perjalanan tiket (*Terkirim* ➔ *Verifikasi Kawasan/LKSDM* ➔ *Eskalasi Pusat* ➔ *Selesai*).
4. **Survei Kepuasan (CSAT / Rating)**: Widget penilaian bintang 1–5 dan ulasan feedback saat tiket berstatus `selesai` untuk mengukur mutu pelayanan birokrasi kepegawaian.
5. **Notifikasi Real-Time (In-App Notification Center)**: Ikon lonceng notifikasi pada AppBar dengan badge *unread*, daftar pemberitahuan interaktif, dan notifikasi otomatis saat tiket didisposisi atau dijawab oleh tim.
6. **Ekspor Rekap Laporan (Admin & Ketua Tim)**: Fitur ekspor data rekapitulasi tiket ke format CSV / Spreadsheet yang siap dianalisis di Microsoft Excel atau Google Sheets.

---

## 2. Perubahan Skema Basis Data (Supabase Migration)

Migration SQL akan ditambahkan pada `supabase/migrations/20261015_essential_features.sql`:

```sql
-- 1. Penambahan Kolom pada Tabel questions
ALTER TABLE public.questions
  ADD COLUMN IF NOT EXISTS attachment_url TEXT,
  ADD COLUMN IF NOT EXISTS attachment_name TEXT,
  ADD COLUMN IF NOT EXISTS rating INT CHECK (rating >= 1 AND rating <= 5),
  ADD COLUMN IF NOT EXISTS rating_feedback TEXT,
  ADD COLUMN IF NOT EXISTS rating_submitted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;

-- 2. Pembuatan Tabel notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  question_id BIGINT REFERENCES public.questions(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'status_update', -- 'disposisi', 'jawaban_baru', 'tiket_selesai'
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS untuk notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notification read status"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "System and staff can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (true);
```

---

## 3. Rincian Desain Komponen per Fitur

### A. Lampiran Berkas (Attachments)
- **Komponen Input**: `lib/features/questions/widgets/attachment_picker_widget.dart`
  - Memilih berkas dari perangkat (Image Picker / File Picker).
  - Menampilkan thumbnail preview nama file, ukuran file, dan tombol hapus sebelum submit.
  - Mengunggah file ke Supabase Storage bucket `ticket-attachments` dan menyimpan URL publiknya ke kolom `attachment_url` & `attachment_name`.
- **Komponen Tampilan**: Pada `QuestionDetailScreen`, jika `question.attachmentUrl != null`, tampil kartu berkas lampiran dengan ikon jenis berkas dan tombol "Buka / Unduh Berkas".

### B. Pencarian & Filter Cepat (Search & Filter)
- **Komponen**: `lib/core/widgets/search_filter_bar.dart`
  - Input field pencarian dengan icon `search` dan tombol `clear`.
  - Menggunakan mekanisme *debouncing* (300ms) agar tidak membebani query backend.
  - Terintegrasi pada:
    1. `MemberTicketsScreen` (Tiket Saya).
    2. `QuestionListScreen` (Forum & Antrean Admin).
  - Menyaring teks pencarian pada: `ticketNumber`, `judul`, `isi`, dan nama pembuat.

### C. SLA & Visual Tracker (Timeline)
- **Komponen**: `lib/features/questions/widgets/ticket_timeline_tracker.dart`
  - Stepper visual 4 tahapan status:
    1. **Tiket Diajukan** (Status: `menunggu_lksdm`)
    2. **Verifikasi Kawasan** (Status: `ditangani_lksdm`)
    3. **Penanganan Pusat** (Status: `dialihkan_ke_pusat`)
    4. **Selesai** (Status: `selesai`)
  - Setiap langkah memiliki tanggal/waktu kejadian dan keterangan pelaku.
- **Komponen SLA Badge**:
  - Standar SLA: 48 jam dihitung dari `created_at`.
  - Jika belum selesai:
    - Sisa waktu > 12 jam: Badge Hijau ("SLA: Aman (Sisa 32 jam)").
    - Sisa waktu <= 12 jam: Badge Kuning ("SLA: Mendekati Batas (Sisa 8 jam)").
    - Waktu terlewati: Badge Merah ("SLA: Melewati Batas Waktu").
  - Jika sudah selesai:
    - Selesai <= 48 jam: Badge Hijau ("Selesai Tepat Waktu (28 jam)").
    - Selesai > 48 jam: Badge Oranye ("Selesai Melampaui SLA").

### D. Survei Kepuasan (CSAT / Rating)
- **Komponen**: `lib/features/questions/widgets/csat_rating_card.dart`
  - Ditampilkan di `QuestionDetailScreen` ketika `question.status == 'selesai'`.
  - Jika belum dinilai oleh pembuat tiket:
    - Bintang interaktif 1–5 dengan label kepuasan (1: Sangat Kecewa, 2: Kurang Puas, 3: Cukup, 4: Puas, 5: Sangat Puas).
    - Kolom catatan masukan/ulasan singkat (opsional).
    - Tombol "Kirim Penilaian".
  - Jika sudah dinilai:
    - Menampilkan ringkasan bintang yang telah diberikan dan ucapan terima kasih atas umpan balik layanan.

### E. Notifikasi Real-Time (In-App Notification Center)
- **Komponen AppBar**: `NotificationBellWidget`
  - Ikon lonceng di AppBar Dashboard Member & Admin.
  - Badge merah counter menampilkan jumlah notifikasi `is_read == false`.
- **Layar Notifikasi**: `lib/features/notifications/screens/notification_center_screen.dart`
  - Daftar pemberitahuan terurut dari yang terbaru.
  - Tanda pembeda visual antara notifikasi belum dibaca vs sudah dibaca.
  - Tombol "Tandai Semua Dibaca".
  - Mengetuk notifikasi langsung menavigasikan pengguna ke `QuestionDetailScreen` tiket terkait.
- **Pemicu Notifikasi**:
  - Dibuat otomatis saat disposisi tiket atau penambahan balasan jawaban di `QuestionService`.

### F. Ekspor Rekap Laporan (Admin & Ketua Tim)
- **Service**: `lib/features/reports/services/report_export_service.dart`
  - Menghasilkan berkas CSV berisi data tiket:
    - `No Tiket`, `Tanggal Dibuat`, `Nama Pegawai`, `Unit Kerja`, `Tim Penangan`, `Tugas & Fungsi`, `Status`, `Durasi Jam`, `Status SLA`, `Rating CSAT`, `Ulasan CSAT`.
- **Aksi UI**: Tombol "Unduh Rekap Laporan" pada dashboard Admin dan antrean Ketua Tim.
  - Mengunduh / membagikan file CSV menggunakan sistem native share / file saver.

---

## 4. Rencana Pengujian & Verifikasi

1. **Uji Fungsionalitas**:
   - Pengajuan tiket dengan lampiran berkas dan verifikasi tampilan di detail tiket.
   - Pencarian kata kunci dan filter status pada daftar tiket.
   - Pengecekan visual stepper dan penghitungan badge SLA 48 jam.
   - Pengiriman rating CSAT dan penguncian form setelah dinilai.
   - Pemicuan notifikasi lonceng saat ada disposisi / jawaban baru.
   - Unduh file rekap CSV dan verifikasi kelengkapan kolom data.
2. **Uji Regresi & Statis**:
   - `flutter analyze` untuk memastikan tidak ada lint error.
   - `flutter test` untuk memastikan test widget dan unit lulus.
