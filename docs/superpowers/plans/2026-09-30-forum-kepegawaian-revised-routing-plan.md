# Implementation Plan: Forum Kepegawaian BOSDM Connect (Revisi Alur Routing & Bubble Chat)

**Spec:** `docs/superpowers/specs/2026-09-30-forum-kepegawaian-revised-routing-design.md`  
**Goal:** Mengakomodir alur routing otomatis LKSDM, eskalasi cerdas 14 Tim Pusat, ruang chat tripartit, dan Dasbor Eksekutif/Super Admin.

---

### Task 1: Domain & Role Models Update
- [ ] Modifikasi `lib/features/auth/models/user_role.dart` untuk menambahkan `UserRole.eksekutif`.
- [ ] Modifikasi `lib/features/auth/models/user_model.dart` dengan getter `isAdminLksdm`, `isAdminPusat`, `isEksekutif`.
- [ ] Modifikasi `lib/features/questions/models/question_model.dart` untuk mendukung `lksdmWilayah`, `escalatedToTeam`, dan status alur baru (`menunggu_lksdm`, `ditangani_lksdm`, `eskalasi_pusat`).
- [ ] Modifikasi `lib/features/questions/models/answer_model.dart` untuk mendukung `senderRoleType`.

### Task 2: Service & Data Layer Updates
- [ ] Buat `lib/features/questions/data/trending_issues_data.dart` untuk catalog data analitik & FAQ.
- [ ] Update `lib/features/questions/services/question_service.dart` dengan metode eskalasi, feedback konfirmasi, dan tren isu.

### Task 3: Refactor Form Pengajuan Pertanyaan (`AskQuestionScreen`)
- [ ] Sederhanakan `lib/features/questions/screens/ask_question_screen.dart`: auto-routing ke LKSDM tanpa formulir manual 14 Tim dan Tusi.

### Task 4: Redesign Dynamic Tripartite Bubble Chat (`QuestionDetailScreen`)
- [ ] Perbarui `lib/features/questions/screens/question_detail_screen.dart` dengan UI bubble chat per-peran.
- [ ] Tambahkan Kartu Konfirmasi Interaktif *"Apakah pertanyaan sudah terjawab? [Ya]/[Tidak]"*.
- [ ] Integrasikan rekomendasi otomatis 14 Tim Pusat saat opsi [Tidak] dipilih.

### Task 5: Dashboard Peran & Routing
- [ ] Buat `lib/features/dashboard/screens/eksekutif_dashboard_screen.dart` (read-only + tren isu).
- [ ] Perbarui `lib/features/dashboard/screens/role_router_screen.dart` untuk mengarahkan `UserRole.eksekutif`.
- [ ] Perbarui `lib/features/dashboard/screens/super_admin_dashboard_screen.dart` dan `admin_dashboard_screen.dart`.

### Task 6: Static Analysis & Testing Verification
- [ ] Jalankan `flutter analyze`
- [ ] Jalankan `flutter test`
