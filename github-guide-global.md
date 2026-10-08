# GitHub Flow Guide (Global)

This document is the highest-priority Git instruction. If any user request conflicts with this guide, ask for confirmation before violating the guide. Never silently ignore these rules.

## Overview

Guide ini adalah Standard Operating Procedure (SOP) untuk seluruh aktivitas Git pada project.

Guide ini mendukung **3 style workflow**. Style dipilih user di awal sesi (lihat *Session Setup*). Aturan keamanan, Stop Policy, dan standar PR berlaku untuk **semua style**.

Prioritas utama adalah **keamanan data, history Git yang rapi, dan kemudahan review**, bukan kecepatan.

---

# 🧠 Core Principles (Highest Priority)

1. Never lose user changes.
2. Safety is always more important than speed.
3. Plan before executing.
4. Prefer many small commits over one large commit.
5. Only group files that are truly related.
6. Never use destructive Git commands unless explicitly requested.
7. If uncertain, stop and ask.
8. Every action must be reversible.
9. Preserve a clean and readable Git history.
10. Think like a senior engineer preparing code for code review.
11. **Never touch user stashes** — they are backups, not part of the workflow.

---

# 🛑 Mandatory Stop Policy (Highest Priority)

Setelah berhasil membuat **SATU Pull Request**, AI WAJIB BERHENTI.

Status selesai adalah ketika:

- Branch sudah di-push
- Pull Request sudah dibuat
- Link PR sudah ditampilkan

Setelah itu AI HARUS STOP.

Tidak boleh otomatis:

- membuat branch berikutnya
- checkout base branch
- fetch origin
- commit berikutnya
- push berikutnya
- PR berikutnya (termasuk PR release ke `main`)
- membuat tag atau release

AI hanya boleh melanjutkan jika user memberikan instruksi eksplisit seperti:

- Lanjut
- Continue
- Next
- Lanjut branch berikutnya

Tanpa instruksi tersebut, AI HARUS berhenti.

---

# 🔒 Data Safety Policy

Seluruh perubahan yang belum di-commit dianggap sangat penting.

Prioritas:

User Data
>
Git History
>
Kecepatan

Jika ada pilihan:

A. Lebih cepat

atau

B. Lebih aman

Selalu pilih B.

Tidak boleh ada perubahan user yang hilang.

---

# 🛡️ Branch Switching Safety

**PERINGATAN: Jangan pernah berpindah branch saat ada perubahan yang belum di-commit!**

Sebelum berpindah branch:

1. WAJIB jalankan:
   ```bash
   git status
   git diff
   git diff --cached
   ```

2. Jika ada perubahan yang belum di-commit:
   - **KOMIT dulu** perubahan tersebut, ATAU
   - **Tanya user** sebelum melanjutkan

3. Jangan pernah:
   - Checkout ke branch lain dengan working changes
   - Reset/clean yang bisa menghilangkan perubahan

**Stash adalah backup user — JANGAN disentuh tanpa izin eksplisit.**

---

# 🚫 Forbidden Commands

AI TIDAK BOLEH menjalankan command berikut tanpa izin eksplisit dari user.

```bash
git reset --hard
git clean -fd
git checkout -- .
git restore .
git stash drop
git stash clear
git push --force
```

Tambahan (history dan remote):

```bash
git push --force-with-lease
git push origin --delete <branch>
git branch -D <branch>
git tag -d <tag>
git rebase ...          # pada commit yang sudah di-push
git commit --amend      # pada commit yang sudah di-push
```

Membuat atau mem-push **tag/release** juga hanya boleh atas instruksi eksplisit user.

Jika menurut AI command tersebut diperlukan, AI harus berhenti dan meminta konfirmasi user.

**CATATAN:**
- `rm -rf` dan `sudo rm` adalah shell commands, bukan git commands
- Stash commands (`drop`, `clear`) FORBIDDEN karena stash adalah backup user

---

# 🎛️ Session Setup (WAJIB — sebelum implementasi apapun)

Sebelum membuat branch, commit, push, atau PR, AI WAJIB bertanya ke user. Kirim **satu pesan** berisi semua pertanyaan, dengan default yang jelas supaya user cukup menjawab singkat:

```
Sebelum mulai, mohon konfirmasi:

1. Style workflow?
   1 = Emoji + Versioned Develop  (dev/<fitur> → develop/<versi> → main)
   2 = Conventional + Versioned Dev (<type>/<fitur> → dev/<versi> → main)
   3 = Trunk-based GitHub Flow    (<type>/<fitur> → main)

2. Target versi / base branch? (Style 1 & 2)
   Usulan saya: <versi> karena <alasan SemVer>. Branch <base> sudah ada di remote? <ya/tidak>

3. Nomor issue/ticket? (opsional, mis. #123 atau PROJ-123)

4. Format PR?
   Default: template standar guide ini (title EN, description ID).
   Alternatif: ikuti template repo (.github/pull_request_template.md).
```

Aturan:

- Pertanyaan 1 **hanya boleh dilewati** jika user sudah menyebut style secara eksplisit di instruksinya. Jangan menebak style dari kondisi repository.
- Pertanyaan 2 tidak berlaku untuk Style 3 (target selalu `main`).
- Style yang dipilih berlaku untuk seluruh sesi. Ganti style hanya atas permintaan user.
- Jangan membuat branch integrasi (`develop/<versi>` atau `dev/<versi>`) sendiri. Jika belum ada, tanya user.

## Ringkasan Style

| | Style 1 | Style 2 | Style 3 |
|---|---|---|---|
| Nama | Emoji + Versioned Develop | Conventional + Versioned Dev | Trunk-based GitHub Flow |
| Branch kerja | `dev/<nama-fitur>` | `<type>/<nama-fitur>` | `<type>/<nama-fitur>` |
| Branch integrasi | `develop/<versi>` | `dev/<versi>` | — (langsung `main`) |
| Commit | Emoji | Conventional Commits | Conventional Commits |
| Alur PR | fitur → `develop/<versi>` → `main` | fitur → `dev/<versi>` → `main` | fitur → `main` |
| Merge (PR fitur) | Rebase and merge | Rebase and merge | Squash and merge |
| Merge (PR release) | Merge commit | Merge commit | — |
| Rilis | Tag `v<versi>` setelah merge ke `main` | Sama | Tag `v<versi>` di `main` |

Alasan merge strategy: Style 1 dan 2 memprioritaskan **history commit kecil yang rapi**, sehingga commit tidak boleh di-squash. Style 3 memakai PR sebagai unit history, jadi title PR menjadi satu-satunya commit di `main`.

---

# 🎨 Style 1 — Emoji + Versioned Develop

## Branch

| Jenis | Format | Contoh |
|---|---|---|
| Branch kerja | `dev/<nama-fitur>` | `dev/admin-dashboard`, `dev/auth-refactor`, `dev/fix-issue-role` |
| Branch integrasi | `develop/<versi-semver>` | `develop/1.9.2` |

- `<nama-fitur>`: huruf kecil, kebab-case, singkat, menggambarkan satu objective.
- `<versi-semver>`: format SemVer tanpa prefix `v` (lihat bagian *Versioning*).
- **Jangan** memakai prefix `feat/`, `fix/`, `hotfix/` pada style ini.

## Alur

```
dev/<fitur> ──PR──▶ develop/<versi> ──PR (setelah stabil + konfirmasi user)──▶ main ──(instruksi user)──▶ tag v<versi>
```

- PR fitur **tidak boleh langsung ke `main`**. Targetnya selalu `develop/<versi>`.
- `develop/<versi>` dianggap **aman/stabil** jika: semua PR fitur untuk versi tersebut sudah merged, CI hijau, testing di branch tersebut selesai, dan **user mengonfirmasi secara eksplisit**.
- Setelah stabil, PR `develop/<versi>` → `main` dibuat sebagai PR release (satu PR, tunduk pada Stop Policy).

## Commit Message

Format:

```
EMOJI + spasi + pesan singkat
```

Maksimal sekitar 10 kata. Bahasa Inggris, imperative, huruf kecil.

| Emoji | Meaning |
|--------|----------|
| ✨ | feature |
| 🛠️ | bug fix |
| ♻️ | refactor |
| 💄 | UI |
| 📝 | docs |
| 🧹 | cleanup / chore |
| ⚙️ | config |
| 📦 | assets |
| 🔥 | remove |

Contoh:

```
✨ add scanner service

⚙️ update analysis options

♻️ simplify auth repository

📝 update installation guide
```

## PR Title

Sama dengan format commit:

```
✨ add admin dashboard
🛠️ fix role permission check
🧹 release 1.9.2          ← PR release develop/<versi> → main
```

## Dampak SemVer

✨ → MINOR, 🛠️ → PATCH, dan perubahan breaking → MAJOR. Karena emoji tidak punya penanda breaking, breaking change **wajib** ditandai di PR description (`Breaking change: Ya`).

---

# 🎨 Style 2 — Conventional Commits + Versioned Dev

## Branch

| Jenis | Format | Contoh |
|---|---|---|
| Branch kerja | `<type>/<nama-fitur>` atau `<type>/<TICKET>-<nama-fitur>` | `feat/attendance-export`, `fix/PAY-214-duplicate-submit` |
| Branch integrasi | `dev/<versi-semver>` | `dev/1.9.2` |

- `<type>` sama dengan type commit di bawah (`feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `chore`, `style`, `revert`).
- `<nama-fitur>`: huruf kecil, kebab-case, singkat (maksimal sekitar 50 karakter), satu objective.
- Type di nama branch **harus konsisten** dengan type commit utama di dalamnya.
- Hotfix production diperlakukan sebagai PATCH: branch integrasi baru `dev/<patch-berikutnya>` dari `main`, lalu PR `fix/...` ke sana.

## Alur

```
<type>/<fitur> ──PR──▶ dev/<versi> ──PR (setelah stabil + konfirmasi user)──▶ main ──(instruksi user)──▶ tag v<versi>
```

Kriteria "stabil" dan larangan PR langsung ke `main` sama dengan Style 1.

## Commit Message ([Conventional Commits](https://www.conventionalcommits.org))

```
<type>(<scope>)!: <description>

[body opsional: jelaskan KENAPA, bukan APA]

[footer opsional]
```

- Bahasa Inggris, imperative, huruf kecil, tanpa titik, maksimal 72 karakter di baris pertama.
- `scope` opsional (mis. `auth`, `payment`).
- Breaking change: tambahkan `!` setelah type/scope **dan** footer `BREAKING CHANGE: <penjelasan>`.
- Referensi issue di footer: `Refs #123`.
- Satu commit = satu tujuan (lihat *Commit Strategy*).

| Type | Untuk | Dampak SemVer |
|---|---|---|
| `feat` | Fitur baru | MINOR |
| `fix` | Perbaikan bug | PATCH |
| `perf` | Optimasi performa | PATCH |
| `refactor` | Restrukturisasi tanpa perubahan behavior | — |
| `docs` | Dokumentasi | — |
| `test` | Menambah/memperbaiki test | — |
| `style` | Format saja, tanpa perubahan logic | — |
| `build` | Build system dan dependency (`build(deps): ...`) | — / lihat *Versioning* |
| `ci` | Pipeline CI/CD | — |
| `chore` | Maintenance lain | — |
| `revert` | Membatalkan commit sebelumnya | Mengikuti yang dibatalkan |
| `<type>!` | Breaking change | MAJOR |

**Dilarang:** `update`, `fix bug`, `changes`, `final`, `wip`, `fix lagi`.

## PR Title

Sama dengan format commit:

```
feat(admin): add attendance export
fix(payment): prevent duplicate submission
chore(release): 1.9.2          ← PR release dev/<versi> → main
```

---

# 🎨 Style 3 — Trunk-based GitHub Flow (Industry Standard)

Model paling ringan dan umum di industri: `main` selalu deployable, branch pendek, review via PR, rilis lewat tag SemVer.

## Aturan

- **Branch kerja** dari `main`: `<type>/<TICKET>-<nama-fitur>` (ticket opsional). Type sama dengan Style 2.
- **Branch pendek**: idealnya merge dalam 1–3 hari. Pekerjaan besar dipecah menjadi PR kecil; fitur yang belum selesai disembunyikan di balik feature flag.
- **`main` selalu deployable.** Tidak ada branch integrasi. PR langsung ke `main`.
- **Commit** dalam branch mengikuti Conventional Commits (format dan tabel type sama dengan Style 2) dan tetap atomic supaya mudah direview per commit.
- **Squash and merge.** Title PR menjadi satu-satunya commit di `main`, jadi title **wajib** valid Conventional Commits dan description PR menjadi body-nya.
- **Rilis:** tag `v<versi>` pada `main`. Versi diturunkan dari commit sejak tag terakhir (`feat` → MINOR, `fix` → PATCH, `!` → MAJOR). Sangat disarankan otomatis (mis. `release-please` atau `semantic-release`). Manual hanya atas instruksi user.
- **Hotfix:** alur yang sama (`fix/...` dari `main`), dengan review dipercepat.
- **Dukungan versi lama:** branch `release/<major>.<minor>` dibuat hanya bila benar-benar perlu, dan hanya atas keputusan user.
- **Wajib di repository:** branch protection (required review + required checks), `CODEOWNERS` untuk area sensitif.

## PR Title

```
feat(admin): add attendance export
fix(payment): prevent duplicate submission
```

---

# 🔢 Versioning (Semantic Versioning 2.0.0)

Berlaku untuk nama branch integrasi, PR release, dan tag. Sumber: <https://semver.org> (CC BY 3.0).

## Format

`MAJOR.MINOR.PATCH`, semuanya bilangan bulat non-negatif, **tanpa leading zero**, dibandingkan secara numerik (`1.9.0` → `1.10.0` → `1.11.0`).

## Kapan menaikkan versi

| Naikkan | Jika | Reset |
|---|---|---|
| **MAJOR** | Ada perubahan yang tidak kompatibel pada public API | MINOR dan PATCH menjadi 0 |
| **MINOR** | Ada fungsionalitas baru yang backward compatible, atau ada fitur public API yang di-deprecate | PATCH menjadi 0 |
| **PATCH** | Hanya bug fix yang backward compatible | — |

Contoh: `1.9.2` + bug fix → `1.9.3`, + fitur baru → `1.10.0`, + breaking change → `2.0.0`.

## Aturan penting

1. **Public API harus jelas** (di kode atau dokumentasi). Jika tidak jelas apa yang dianggap public API, AI bertanya ke user.
2. **Versi yang sudah dirilis tidak boleh diubah.** Perbaikan apa pun dirilis sebagai versi baru. Jangan retag atau menimpa tag yang sudah ada.
3. **`0.y.z` = fase pengembangan awal**: API belum dianggap stabil. Mulai dari `0.1.0`, naikkan MINOR untuk tiap rilis. Rilis `1.0.0` saat software dipakai di production atau API sudah stabil dan dipakai pihak lain.
4. **Pre-release** memakai tanda hubung: `2.0.0-alpha.1`, `2.0.0-rc.1`. Presedensinya lebih rendah daripada versi normal (`1.0.0-alpha < 1.0.0`).
5. **Build metadata** memakai `+` (mis. `1.0.0+sha.5114f85`) dan diabaikan dalam presedensi. Jangan dipakai di nama branch.
6. **Deprecation:** dokumentasikan, lalu rilis MINOR yang memuat deprecation tersebut. Penghapusan baru dilakukan di rilis MAJOR berikutnya.
7. **Update dependency:** PATCH jika untuk memperbaiki bug, MINOR jika untuk menambah fungsionalitas, dan tidak mengubah versi jika tidak memengaruhi public API.
8. **Rilis melanggar SemVer** (mis. breaking change masuk sebagai MINOR): rilis versi baru yang memperbaikinya, jangan ubah versi lama.
9. **Prefix `v`** hanya konvensi nama tag (`v1.9.2`). Nama branch dan versi tidak memakai `v`.

## Peran AI

- AI **mengusulkan** versi berdasarkan perubahan, menjelaskan alasannya, dan **menunggu konfirmasi user**. AI tidak menentukan versi sendiri.
- Dampak tertinggi di antara semua perubahan menentukan kenaikan versi (ada satu breaking change → MAJOR).
- Jika isi branch tidak sesuai versinya (mis. `develop/1.9.2` ternyata berisi fitur baru sehingga seharusnya `1.10.0`), AI memperingatkan user. Rename atau hapus branch adalah keputusan user.

---

# 📦 Commit Strategy

JANGAN membuat commit besar.

AI WAJIB:

- memecah commit sekecil mungkin
- satu commit = satu tujuan
- satu perubahan logis = satu commit
- memakai format commit sesuai style yang dipilih

File hanya boleh digabung apabila memang saling berkaitan.

Contoh (Style 1):

Commit 1

```
⚙️ update flutter config
```

Commit 2

```
✨ add scanner controller
```

Commit 3

```
📝 update scanner documentation
```

Lebih banyak commit kecil jauh lebih baik daripada satu commit besar.

---

# 🌳 Branch Strategy

Satu branch hanya memiliki SATU objective.

Contoh:

Branch:

```
dev/auth
```

Berisi:

- auth service
- auth repository
- auth tests

Jangan mencampur:

- auth
- scanner
- settings
- ui

ke dalam satu branch.

---

# 📋 Planning Phase (WAJIB)

Ketika user meminta:

```
Up changes
```

AI TIDAK BOLEH langsung commit. (Session Setup harus sudah selesai.)

AI harus:

## Step 1

Analisa repository.

Jalankan:

```bash
git status
git diff
git diff --cached
```

## Step 2

Kelompokkan perubahan.

Tentukan:

- branch apa saja
- commit apa saja
- file apa saja
- urutan pengerjaan
- dampak SemVer tiap branch dan usulan versi (Style 1 & 2)

## Step 3

Tampilkan PLAN kepada user.

Contoh (Style 1, target `develop/1.9.2`):

```
Style: 1 | Base: develop/1.9.2 | Usulan versi: 1.9.2 (PATCH, hanya bug fix)

Branch 1

dev/auth
PR title: 🛠️ fix role permission check

Commit 1
🛠️ fix role check on auth repository

Commit 2
📝 update auth documentation

--------------------------------

Branch 2

dev/scanner
PR title: ✨ add scanner page

Commit 1
✨ add scanner page

Commit 2
📝 update scanner docs
```

Setelah user setuju, baru mulai eksekusi. Hanya **Branch 1** yang dieksekusi (lihat Stop Policy).

---

# 🔄 Git Workflow

`<base>` adalah branch tujuan PR: `develop/<versi>` (Style 1), `dev/<versi>` (Style 2), atau `main` (Style 3).

## Step 1

Buat branch dari base di remote

```bash
git fetch origin
git rev-parse --verify origin/<base>
git checkout -b <branch-name> origin/<base>
```

- Branch dibuat langsung dari `origin/<base>`, sehingga branch lokal `<base>` **tidak di-reset** dan tidak ada commit lokal yang bisa terlepas.
- Jika `<base>` tidak ada di remote, **stop dan tanya user**.
- Jika Git menolak checkout karena bentrok dengan perubahan lokal, **stop dan tanya user**.

---

## Step 2

Commit

Commit sesuai grouping yang sudah direncanakan.

Gunakan commit kecil dengan format sesuai style.

---

## Step 3

Push

```bash
git push -u origin <branch-name>
```

Tanpa `--force`.

---

## Step 4

Create Pull Request

Gunakan GitHub CLI. Path mengandung spasi, jadi **wajib di-quote**. Description dikirim lewat stdin agar aman untuk multi-line dan karakter khusus.

WSL Path:

```bash
GH="/mnt/c/Program Files/GitHub CLI/gh.exe"

"$GH" pr create \
  --title "<PR title sesuai style>" \
  --base <base> \
  --head <branch-name> \
  --body-file - <<'EOF'
<isi description sesuai template di bagian Pull Request Standard>
EOF
```

---

## Step 5

Tampilkan:

- style yang dipakai
- nama branch dan base branch
- daftar commit
- link Pull Request

---

## Step 6

🛑 STOP

Jangan melakukan apapun lagi.

Tunggu instruksi user:

```
Lanjut
```

Baru ulangi workflow dari Step 1 untuk branch berikutnya.

Jika branch berikutnya bergantung pada branch yang PR-nya belum di-merge, **tanya user**. Jangan membuat stacked branch tanpa izin.

---

# 🔀 Pull Request Standard

Tujuan: reviewer manusia bisa memahami, me-review, dan men-test PR **tanpa menebak-nebak**.

## Prinsip

- **Satu PR = satu tujuan** (sejalan dengan Branch Strategy).
- **Kecil dan reviewable:** maksimal ±400 baris berubah (di luar lockfile, generated code, snapshot). Jika lebih, pecah per vertical slice atau pakai feature flag. Jika tidak bisa dipecah, jelaskan alasannya di Summary. PR release (integrasi → `main`) dikecualikan dari batas ini.
- **Jujur:** jangan menandai test sudah dijalankan jika belum. Jangan mengarang hasil. Hal yang tidak pasti ditulis di `Assumptions`.
- **Jelaskan behavior, bukan diff.** Reviewer bisa membaca diff sendiri.
- **Bahasa:** title dan commit dalam bahasa Inggris, description dalam bahasa Indonesia (kecuali user memilih lain di Session Setup).

## Target dan Merge

| Jenis PR | Style 1 | Style 2 | Style 3 |
|---|---|---|---|
| PR fitur/fix | `dev/*` → `develop/<versi>` | `<type>/*` → `dev/<versi>` | `<type>/*` → `main` |
| PR release | `develop/<versi>` → `main` | `dev/<versi>` → `main` | — |
| Merge PR fitur | Rebase and merge | Rebase and merge | Squash and merge |
| Merge PR release | Merge commit | Merge commit | — |

AI **tidak boleh** meng-approve atau merge PR sendiri.

## Sebelum Membuka PR

- [ ] Lint, type check, dan test relevan sudah dijalankan lokal dan lulus.
- [ ] Tidak ada debug code, komentar sementara, atau file tidak terkait.
- [ ] Tidak ada secret, credential, atau data pribadi/production di kode, log, maupun screenshot.
- [ ] Tidak ada perubahan dependency, config, atau format file tanpa alasan dan tanpa dijelaskan.
- [ ] Branch sudah bebas conflict dengan base.

## Format Description

Gunakan template ini (atau `.github/pull_request_template.md` jika user memilih template repo).

Aturan pengisian:

- Section inti **selalu diisi**.
- Section kondisional **hanya ditambahkan bila relevan**. Jangan menulis `N/A`, hapus saja.
- Checkbox hanya dicentang jika benar-benar dilakukan. Jika tidak, biarkan kosong dan beri alasan.
- PR release: `Changes` berisi daftar PR yang termasuk (`#123 judul`), lalu tambahkan Deployment Notes dan Risks untuk keseluruhan rilis.

````md
## Summary
<!-- 1–3 kalimat: apa yang berubah dan dampaknya bagi user/sistem. -->

## Why
<!-- Masalah atau requirement. Bug fix: tulis root cause. Refactor: tegaskan behavior tidak berubah. -->

## Changes
- <!-- Tulis dalam bentuk behavior/kemampuan, bukan nama file. -->

## How to Test
1. <!-- Langkah konkret dan berurutan, termasuk role/data awal. -->
2.

**Expected result**
- <!-- Hasil yang bisa diverifikasi: status code, data, tampilan. -->

## Test Evidence
- [ ] Automated test ditambahkan/diperbarui: `<nama test>`
- [ ] Dijalankan lokal: `<command>` → <hasil ringkas>
- [ ] CI hijau
- [ ] Manual verification (untuk perubahan yang bisa diamati user)

## Risks & Rollback
- **SemVer impact:** MAJOR | MINOR | PATCH | None
- **Risk level:** Low | Medium | High
- **Breaking change:** Tidak | Ya (jelaskan)
- **Rollback:** Revert aman | Perlu langkah tambahan (jelaskan)

## Assumptions & Review Focus
- <!-- Asumsi yang diambil, hal yang tidak pasti, dan area yang paling perlu dicek reviewer. -->

## Related Issue
Closes #
````

## Section Kondisional

Tambahkan hanya jika PR menyentuh area tersebut.

**Database Changes** (migration, schema, backfill)
- Sebutkan perubahan schema dan apakah ada data migration/backfill.
- Migration harus kompatibel dengan versi aplikasi sebelumnya (pola expand/contract) dan reversible.
- Jelaskan risiko lock, downtime, dan waktu eksekusi di data besar.
- Sebutkan urutan deploy jika penting.

**API Changes**
- Tampilkan request/response *before* dan *after*.
- Nyatakan **backward compatible** atau **breaking** (breaking → MAJOR).

**Security Notes** (auth, permission, payment, data sensitif)
- Jelaskan perubahan authentication/authorization dan siapa yang bisa mengakses apa.
- Sebutkan potensi eksposur data dan validasi input yang ditambahkan.
- Tidak ada credential nyata di PR.

**Dependency Changes**
- Package, versi lama → baru, alasan, dan catatan breaking dari changelog upstream.

**Deployment Notes**
- Langkah khusus saat deploy (migration, clear cache, restart worker, env var baru), berurutan.

**Screenshots / Evidence**
- UI: before/after. API: contoh response.
- **Sanitasi dulu**: tidak ada PII, token, atau data production.

## Aturan Test

- **Bug fix** wajib punya *regression test* yang gagal sebelum fix dan lulus sesudahnya.
- **Fitur baru** wajib mencakup happy path dan minimal satu kasus error/edge/authorization.
- **Refactor** tidak boleh mengubah test existing kecuali karena struktur. Buktikan dengan test existing yang tetap lulus.
- Test otomatis dijalankan oleh CI. `How to Test` ditujukan untuk verifikasi behavior yang bisa diamati.
- Sertakan command dan hasil ringkas yang **benar-benar dijalankan**, bukan hasil rekaan.
- Jika project belum punya test untuk area tersebut, tulis alasannya. Jangan mencentang.

## Contoh Description (Bug Fix)

````md
## Summary
Registrasi kini menolak email yang sudah terdaftar di level backend dan database.

## Why
Validasi duplikat hanya ada di frontend, sehingga request langsung ke API
masih bisa membuat user dengan email yang sama.
**Root cause:** backend belum punya validasi unique maupun constraint di database.

## Changes
- Registrasi dengan email yang sudah ada ditolak dengan HTTP 422.
- Email dinormalisasi (lowercase, trim) sebelum dicek.
- Database menolak duplikat email sebagai lapisan pengaman terakhir.

## How to Test
1. Pastikan ada user dengan email `test@example.com`.
2. Buka halaman registrasi dan submit dengan `Test@Example.com`.

**Expected result**
- API mengembalikan 422 dan UI menampilkan error di field email.
- Tidak ada user baru yang dibuat.

## Test Evidence
- [x] Automated test ditambahkan: `RegistrationTest::duplicate_email_is_rejected`
- [x] Dijalankan lokal: `php artisan test --filter=RegistrationTest` → 4 passed
- [x] CI hijau
- [ ] Manual verification: tidak dilakukan, sudah tercakup feature test

## Risks & Rollback
- **SemVer impact:** PATCH
- **Risk level:** Medium
- **Breaking change:** Tidak
- **Rollback:** Perlu langkah tambahan (drop unique index)

## Database Changes
- Menambah unique index pada `users.email`.
- Data duplikat existing harus dibersihkan sebelum migration di production.

## Assumptions & Review Focus
- Asumsi: email dibandingkan case-insensitive.
- Mohon cek penanganan race condition saat dua request bersamaan.

## Related Issue
Closes #123
````

## Review dan Approval

- Wajib minimal 1 approval manusia (via `CODEOWNERS` bila ada). Perubahan di area database, security, dan payment direview oleh domain owner.
- Perbaikan dari feedback dikirim sebagai **commit baru**. Jangan force-push atau rewrite history setelah review dimulai.
- Reviewer memakai prefix komentar `blocking:`, `nit:`, atau `question:`.
- PR siap di-approve jika: tujuan dan scope jelas, requirement terpenuhi, CI wajib hijau, tidak ada thread blocking, dan risikonya sudah diketahui.
- Target respon review pertama: 1 hari kerja.

## Enforcement Otomatis (Direkomendasikan)

Aturan yang hanya mengandalkan kepatuhan tidak akan bertahan. Otomatiskan:

- Lint title PR dan commit sesuai style (Style 1 butuh regex kustom untuk emoji; Style 2 dan 3 memakai commitlint / `action-semantic-pull-request`). Validasi nama branch dengan pola style yang dipakai.
- Branch protection: required status checks, wajib review, dismiss stale approval, larangan push langsung ke `main` dan branch integrasi.
- Secret scanning dengan push protection dan dependency scanning.
- Template PR di `.github/pull_request_template.md`.

---

# ❌ Never Batch Multiple PRs

Dalam satu sesi eksekusi:

Maksimal membuat SATU Pull Request.

Walaupun AI sudah mengetahui seluruh rencana branch berikutnya,
AI TIDAK BOLEH membuat PR kedua.

Branch berikutnya hanya boleh berupa PLAN.

Eksekusi berikutnya hanya boleh dilakukan setelah user memberikan konfirmasi.

---

# 📌 Notes

- Generated files (`.g.dart`, `.freezed.dart`, `lib/generated/`) biasanya di-gitignore.
- `android/build/` biasanya di-gitignore.
- Jika conflict saat checkout base, tanyakan ke user terlebih dahulu.
- GitHub CLI sudah login menggunakan akun yang tersedia.
- Git tidak mengizinkan branch `dev` dan `dev/<sesuatu>` (atau `develop` dan `develop/<versi>`) ada bersamaan. Jangan membuat branch bernama polos `dev` atau `develop`.
- Selalu prioritaskan keamanan perubahan user dibanding kecepatan workflow.
- **Stashes adalah backup user — JANGAN disentuh, di-clean, atau di-drop.**

---

# ✅ Definition of Done

Satu branch dianggap selesai jika:

- Session Setup sudah dikonfirmasi user
- Commit selesai (format sesuai style)
- Push selesai
- Pull Request selesai (title dan description sesuai standar)
- Link PR ditampilkan
- AI berhenti menunggu instruksi user

Workflow baru hanya boleh dimulai setelah user memberikan konfirmasi.
