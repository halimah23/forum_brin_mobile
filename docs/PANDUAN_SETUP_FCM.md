# Panduan Integrasi Firebase Cloud Messaging (FCM) BOSDM Connect

Dokumentasi ini menjelaskan langkah-langkah yang diperlukan untuk mengaktifkan Push Notification agar notifikasi tetap muncul di bar notifikasi saat aplikasi **ditutup (terminated)** maupun saat **membuka aplikasi lain (background)**.

---

## 1. Langkah di Firebase Console (Hanya Sekali)

1. Buka browser dan kunjungi [Firebase Console](https://console.firebase.google.com/).
2. Login menggunakan akun Google Anda, lalu klik **"Add project"** (atau **"Tambahkan project"**).
3. Beri nama project, misalnya: `bosdm-connect-brin` lalu ikuti petunjuk sampai selesai.
4. Di dashboard Firebase project yang baru dibuat, klik ikon **Android** untuk menambahkan aplikasi Android:
   - **Android package name**: `com.example.forum_brin_mobile` *(wajib persis sama)*
   - **App nickname**: `BOSDM Connect`
   - Klik **Register app**.
5. Klik **Download google-services.json**.
6. Pindahkan file `google-services.json` tersebut ke dalam folder:
   ```
   android/app/google-services.json
   ```
   *(Kode Gradle di `android/app/build.gradle` sudah dikonfigurasi otomatis mendeteksi file ini jika sudah diletakkan di folder tersebut).*

---

## 2. Langkah di Database Supabase

Jalankan script SQL migrasi yang telah disiapkan di file:
[`supabase/migrations/supabase_migration_fcm_tokens.sql`](../supabase/migrations/supabase_migration_fcm_tokens.sql)

Script ini membuat tabel `public.user_fcm_tokens` untuk menyimpan Device Token setiap user:
```sql
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL REFERENCES public.users(id_user) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_type VARCHAR(20) DEFAULT 'android',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_user_fcm UNIQUE (user_id, fcm_token)
);

CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON public.user_fcm_tokens(user_id);
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anon and auth user_fcm_tokens" 
ON public.user_fcm_tokens FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
```

---

## 3. Komponen yang Telah Diterapkan di Aplikasi Flutter

1. **Dependencies (`pubspec.yaml`)**:
   - `firebase_core: ^5.1.0`
   - `firebase_messaging: ^17.0.1`

2. **Android Native Configuration**:
   - `android/build.gradle`: Classpath `com.google.gms:google-services:4.4.2` telah ditambahkan.
   - `android/app/build.gradle`: Plugin `com.google.gms.google-services` diaktifkan otomatis jika `google-services.json` ada.
   - `android/app/src/main/AndroidManifest.xml`: Konfigurasi default notification channel (`bosdm_connect_high_importance`) dan icon notifikasi.

3. **Service Notifikasi (`lib/core/services/notifications/fcm_service.dart`)**:
   - `@pragma('vm:entry-point') firebaseMessagingBackgroundHandler`: Menangani notifikasi saat app berada di latar belakang atau ditutup total.
   - `onMessage`: Menampilkan pop-up heads-up saat app sedang terbuka.
   - `onMessageOpenedApp` & `getInitialMessage`: Mengarahkan navigasi langsung ke halaman detail tiket (`QuestionDetailScreen`) saat notifikasi di status bar diklik.
   - `syncTokenWithUser`: Mengambil token FCM perangkat dan menyimpannya ke Supabase setiap kali user login.

4. **Inisialisasi Global**:
   - `lib/main.dart`: Menginisialisasi `FcmService.initialize()` sebelum `runApp()`.
   - `lib/features/notifications/services/notification_service.dart`: Memanggil `syncTokenWithUser` saat subscription realtime dimulai.

---

## 4. Format Payload Pengiriman FCM dari Backend / Supabase

Ketika mengirim push notification dari server ke FCM Token user (menggunakan FCM HTTP v1 API):

```json
{
  "message": {
    "token": "<FCM_DEVICE_TOKEN_USER>",
    "notification": {
      "title": "Tanggapan Tiket Baru",
      "body": "Admin telah menanggapi tiket konsultasi Anda."
    },
    "data": {
      "question_id": "123",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "bosdm_connect_high_importance",
        "icon": "ic_launcher"
      }
    }
  }
}
```
*(Dengan format di atas, Android OS akan memunculkan banner status bar secara native meski aplikasi ditutup total, dan saat di-tap akan langsung membuka tiket dengan ID `123`).*
