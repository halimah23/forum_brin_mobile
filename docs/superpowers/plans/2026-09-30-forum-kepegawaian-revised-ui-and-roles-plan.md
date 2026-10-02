# Implementation Plan: Forum Kepegawaian (Penyesuaian Chat Publik, Role Eksekutif, Floating Menu, Trending Chart & Supabase v2)

**Goal:**
1. Hilangkan bagian privat & publik — semua pertanyaan bersifat publik ke LKSDM-nya & dapat dipantau oleh Eksekutif dan Super Admin.
2. Sempurnakan Role Eksekutif untuk melihat semua pertanyaan yang telah dijawab oleh Staf dan Ketua Tim.
3. Ubah tampilan detail percakapan menjadi **Bubble Chat** penuh dengan Pop-up / Dialog kepuasan: *"Apakah pertanyaan sudah cukup? [Ya] / [Tidak]"*.
4. Tambahkan **Trending Chart Widget** (Chart Topik Pertanyaan Terbanyak) di dasbor semua peran pengguna.
5. Buat **Floating Bottom Action Menu** (tombol melayang bulat di tengah bawah layar) untuk menu layanan sesuai fitur masing-masing role.
6. Sesuaikan kueri Supabase ke sintaks `supabase_flutter` v2 terbaru.

---

### Task Breakdown:

#### Task 1: Domain & Question Model Simplification
- Remove `isPublic` toggles and privat/public filters from `QuestionModel`, `QuestionService`, and `QuestionListScreen`.
- Ensure all questions are routed to LKSDM and accessible to Eksekutif & Super Admin.

#### Task 2: Supabase v2 Service Sync & Query Cleanup
- Review `lib/features/questions/services/question_service.dart` for Supabase v2 compatibility.
- Ensure error handling gracefully falls back to updated mock data if Supabase tables are offline.

#### Task 3: Trending Chart Widget (`TrendingChartWidget`)
- Create `lib/features/dashboard/widgets/trending_chart_widget.dart` to render visual bar charts for top asked topics.

#### Task 4: Floating Bottom Action Menu Widget (`BottomActionMenu`)
- Create `lib/features/dashboard/widgets/bottom_action_menu.dart` providing circular bottom action buttons at the bottom center of the screen tailored per role.

#### Task 5: Refactor Dashboards for All 5 Roles
- Update `MemberDashboardScreen`: Add `TrendingChartWidget` and `BottomActionMenu` (Ajukan Pertanyaan, Forum, Pertanyaan Saya).
- Update `AdminDashboardScreen`: Add `TrendingChartWidget` and `BottomActionMenu` for LKSDM / Central Admin.
- Update `KetuaTimDashboardScreen`: Add `TrendingChartWidget` and `BottomActionMenu` for Ketua Tim.
- Update `EksekutifDashboardScreen`: Add `TrendingChartWidget`, `BottomActionMenu`, and interactive list of answered questions.
- Update `SuperAdminDashboardScreen`: Add `TrendingChartWidget` and `BottomActionMenu`.

#### Task 6: Refactor Ask Question & Detail Screen into Sleek Bubble Chat with Pop-up Dialog
- Update `AskQuestionScreen`: Clean layout without public/private toggle.
- Update `QuestionDetailScreen`: Full bubble chat layout with Pop-up Dialog trigger asking *"Apakah pertanyaan sudah cukup?"*.

#### Task 7: Verification & Testing
- Run `flutter analyze`
- Run `flutter test`
