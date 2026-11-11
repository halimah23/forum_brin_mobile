/// Helper untuk manajemen Jam Operasional Layanan Kepegawaian (BOSDM Connect)
/// Waktu Operasional Resmi: Senin s/d Jumat, Pukul 08:00 - 16:00 WIB.
class OperationalHoursHelper {
  static const int openHour = 8;
  static const int closeHour = 16;
  static const String scheduleText = 'Senin – Jumat, 08:00 – 16:00 WIB';

  /// Variabel bantuan untuk mock pengujian unit test
  static DateTime? mockNow;

  /// Mengambil waktu lokal aplikasi (atau mock time jika diset saat testing)
  static DateTime get currentTime => mockNow ?? DateTime.now();

  /// Mendapatkan waktu saat ini dalam zona waktu WIB (UTC+7)
  static DateTime nowWib() {
    if (mockNow != null) {
      return mockNow!.toUtc().add(const Duration(hours: 7));
    }
    return DateTime.now().toUtc().add(const Duration(hours: 7));
  }

  /// Mengecek apakah suatu waktu berada di dalam jam operasional layanan (Senin-Jumat, 08:00 - 16:00 WIB)
  static bool isWithinWorkingHours([DateTime? dateTime]) {
    final dt = dateTime != null
        ? dateTime.toUtc().add(const Duration(hours: 7))
        : nowWib();

    // Cek Hari Sabtu (6) atau Minggu (7)
    if (dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday) {
      return false;
    }

    // Cek Jam Kerja 08:00 s/d sebelum 16:00 WIB
    final hour = dt.hour;
    return hour >= openHour && hour < closeHour;
  }

  /// Menghitung kapan penghitungan SLA pertama kali dimulai untuk tiket luar jam kerja
  /// Jika tiket dibuat di luar jam dinas, SLA baru mulai berjalan pada hari kerja berikutnya pukul 08:00 WIB.
  static DateTime getNextSlaStartTime([DateTime? dateTime]) {
    if (isWithinWorkingHours(dateTime)) {
      final dt = dateTime != null
          ? dateTime.toUtc().add(const Duration(hours: 7))
          : nowWib();
      return dt;
    }

    final dt = dateTime != null
        ? dateTime.toUtc().add(const Duration(hours: 7))
        : nowWib();

    DateTime target;
    if (dt.hour < openHour && dt.weekday >= DateTime.monday && dt.weekday <= DateTime.friday) {
      // Dibuat hari kerja sebelum pukul 08:00 WIB -> SLA mulai hari yang sama pukul 08:00 WIB
      target = DateTime(dt.year, dt.month, dt.day, openHour, 0);
    } else {
      // Dibuat setelah pukul 16:00 WIB atau di akhir pekan -> cari hari kerja berikutnya
      target = DateTime(dt.year, dt.month, dt.day, openHour, 0).add(const Duration(days: 1));
    }

    // Geser jika jatuh pada hari Sabtu atau Minggu
    while (target.weekday == DateTime.saturday || target.weekday == DateTime.sunday) {
      target = target.add(const Duration(days: 1));
    }

    return target;
  }

  /// Pesan keterangan ramah saat pengguna membuat tiket di luar jam dinas
  static String get offHoursNotice =>
      'Layanan Kepegawaian saat ini berada di luar jam operasional ($scheduleText). '
      'Tiket Anda tetap tersimpan dan masuk antrean sistem, serta mulai ditangani pada hari kerja berikutnya pukul 08:00 WIB.';
}
