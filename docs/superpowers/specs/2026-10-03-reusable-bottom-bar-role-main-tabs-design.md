# Design Spec: Reusable Bottom Bar & Role-Based Main Tab Pages

## Overview
Implementasi arsitektur navigasi utama berbasis tab (`lib/features/main/presentation/pages/`) yang terpisah per role sesuai referensi `ref/main`, dengan sistem desain bottom bar yang konsisten, elegan, dan reusable di seluruh peran pengguna (Pegawai/Member, Staf Admin LKSDM & Pusat, Ketua Tim, Eksekutif, dan Super Admin).

---

## 1. Architecture & Component Structure

### Directory: `lib/features/main/`
```
lib/features/main/
├── presentation/
│   ├── pages/
│   │   ├── member_main_tab_page.dart
│   │   ├── admin_main_tab_page.dart
│   │   ├── ketua_tim_main_tab_page.dart
│   │   ├── eksekutif_main_tab_page.dart
│   │   ├── super_admin_main_tab_page.dart
│   │   ├── menu_types.dart (Enums per role: MemberMenuType, AdminMenuType, etc.)
│   │   └── pages.dart (barrel export)
│   └── widgets/
│       ├── app_bottom_navigation_bar.dart (Reusable bottom nav bar component)
│       └── main_tab_scaffold.dart (Standard tab shell with IndexedStack)
```

### Role Router Update
- `lib/features/dashboard/screens/role_router_screen.dart` akan mengarahkan pengguna ke Main Tab Page masing-masing role:
  - `UserRole.member` $\rightarrow$ `MemberMainTabPage`
  - `UserRole.admin` $\rightarrow$ `AdminMainTabPage`
  - `UserRole.ketuaTim` $\rightarrow$ `KetuaTimMainTabPage`
  - `UserRole.eksekutif` $\rightarrow$ `EksekutifMainTabPage`
  - `UserRole.superAdmin` $\rightarrow$ `SuperAdminMainTabPage`

---

## 2. Menu Breakdown Per Role

### 1. Pegawai / Member (`MemberMenuType`)
- **Beranda (`home`)**: Widget beranda pegawai (Greeting, UserInfoCard, Quick Actions jika relevan, Trending Chart).
- **Tanya LKSDM (`ask`)**: Halaman `AskQuestionScreen` (embedded sebagai tab / form pembuatan tiket).
- **Forum Diskusi (`forum`)**: Halaman `QuestionListScreen` (seluruh pertanyaan publik).
- **Tiket Saya (`myQuestions`)**: Halaman `MyQuestionsScreen` (pantau status tiket & pertanyaan sendiri).

### 2. Staf Admin LKSDM & Pusat (`AdminMenuType`)
- **Beranda (`home`)**: Dashboard admin, UserInfoCard, Jobdesk Scope, Trending Chart.
- **Antrean (`queue`)**: `QuestionListScreen` (filter: antrean menunggu respon).
- **Aktif (`active`)**: `QuestionListScreen` (filter: percakapan aktif/ditangani).
- **Selesai (`completed`)**: `QuestionListScreen` (filter: tiket selesai).
- **Forum (`forum`)**: `QuestionListScreen` (forum publik).

### 3. Ketua Tim (`KetuaTimMenuType`)
- **Beranda (`home`)**: Overview tim & disposisi.
- **Disposisi (`disposition`)**: `QuestionListScreen` (filter: `menunggu_disposisi`).
- **Proses (`inProgress`)**: `QuestionListScreen` (filter: `sedang_diproses`).
- **Selesai (`completed`)**: `QuestionListScreen` (filter: `selesai`).
- **Forum (`forum`)**: `QuestionListScreen` (forum publik).

### 4. Eksekutif / Pimpinan (`EksekutifMenuType`)
- **Beranda (`home`)**: KPI metrics overview & trending topics.
- **Pantau Forum (`monitor`)**: `QuestionListScreen` (semua obrolan publik).
- **Sedang Proses (`inProgress`)**: `QuestionListScreen` (filter: `sedang_diproses`).
- **Terjawab (`completed`)**: `QuestionListScreen` (filter: `selesai`).

### 5. Super Admin (`SuperAdminMenuType`)
- **Beranda (`home`)**: Panel overview sistem.
- **Audit (`audit`)**: `QuestionListScreen` (seluruh audit tiket sistem).
- **Bank FAQ (`faq`)**: FAQ / Knowledge Base analitik.
- **Forum (`forum`)**: Forum diskusi publik.

---

## 3. Reusable UI Components & Design System

### `AppBottomNavigationBar`
- Tipe: Material 3 clean / curved styling dengan active indicator & badge support.
- Membaca item terdefinisi dengan `icon`, `selectedIcon`, `label`, `badgeCount` (opsional).
- Menghormati warna tema BRIN (`AppColors.primaryRed`, `AppColors.primaryBlue`, atau role accent color).
- Animasi transisi halus dan mempertahankan state tiap halaman dengan `IndexedStack`.

### Top AppBar & Profil
- AppBar konsisten di setiap tab atau dikelola secara modular oleh tab shell.
- Profil pengguna diakses cepat via avatar popup / bottom sheet di AppBar.
