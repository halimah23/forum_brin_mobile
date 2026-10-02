import '../models/category_model.dart';

/// Katalog Master 14 Tim Pusat BOSDM BRIN dan Tugas Fungsi (Jobdesk) Resmi
class TusiCatalogData {
  static const List<String> centralTeams = [
    'Fungsi Organisasi dan Tatalaksana',
    'Fungsi Perencanaan dan Pengembangan Karir SDM',
    'Fungsi Mutasi Umum dan Kesejahteraan',
    'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I',
    'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional II',
    'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional III',
    'Fungsi Perencanaan dan Pengembangan Kompetensi SDM',
    'Fungsi Penilaian Kompetensi',
    'Fungsi Manajemen Kinerja dan Penghargaan ASN',
    'Fungsi Pembinaan dan Penegakkan Disiplin ASN',
    'Fungsi Pengelolaan data dan informasi SDM',
    'Fungsi Kesekretariat Majelis Profesor',
    'Fungsi Kesekretariatan RB',
    'Fungsi Pembinaan Karir SDM Pembinaan Ulang',
  ];

  static const List<String> allTeams = centralTeams;

  static const List<CategoryModel> allTugasFungsi = [
    // 1. Fungsi Organisasi dan Tatalaksana
    CategoryModel(id: 1, teamName: 'Fungsi Organisasi dan Tatalaksana', kode: 'ORTALA-01', nama: 'Evaluasi Organisasi'),
    CategoryModel(id: 2, teamName: 'Fungsi Organisasi dan Tatalaksana', kode: 'ORTALA-02', nama: 'Penataan Organisasi'),
    CategoryModel(id: 3, teamName: 'Fungsi Organisasi dan Tatalaksana', kode: 'ORTALA-03', nama: 'Analisis Jabatan (Anjab)'),
    CategoryModel(id: 4, teamName: 'Fungsi Organisasi dan Tatalaksana', kode: 'ORTALA-04', nama: 'Evaluasi Jabatan (Evjab)'),
    CategoryModel(id: 5, teamName: 'Fungsi Organisasi dan Tatalaksana', kode: 'ORTALA-05', nama: 'Penyusunan Peta Jabatan'),
    CategoryModel(id: 6, teamName: 'Fungsi Organisasi dan Tatalaksana', kode: 'ORTALA-06', nama: 'Penyusunan Pola Karir'),
    CategoryModel(id: 7, teamName: 'Fungsi Organisasi dan Tatalaksana', kode: 'ORTALA-07', nama: 'Penyusunan & Evaluasi Pedoman Sistem Kerja'),
    CategoryModel(id: 8, teamName: 'Fungsi Organisasi dan Tatalaksana', kode: 'ORTALA-08', nama: 'Penyusunan & Evaluasi Proses Bisnis'),
    CategoryModel(id: 9, teamName: 'Fungsi Organisasi dan Tatalaksana', kode: 'ORTALA-09', nama: 'Penyusunan & Evaluasi SOP'),
    CategoryModel(id: 10, teamName: 'Fungsi Organisasi dan Tatalaksana', kode: 'ORTALA-10', nama: 'Input & Penyesuaian Proses Bisnis SIA SPBE'),

    // 2. Fungsi Perencanaan dan Pengembangan Karir SDM
    CategoryModel(id: 11, teamName: 'Fungsi Perencanaan dan Pengembangan Karir SDM', kode: 'BANGKAR-01', nama: 'Analisis Beban Kerja (ABK)'),
    CategoryModel(id: 12, teamName: 'Fungsi Perencanaan dan Pengembangan Karir SDM', kode: 'BANGKAR-02', nama: 'Perencanaan SDM ASN'),
    CategoryModel(id: 13, teamName: 'Fungsi Perencanaan dan Pengembangan Karir SDM', kode: 'BANGKAR-03', nama: 'Pengadaan ASN (CPNS, PPPK, Open Call)'),
    CategoryModel(id: 14, teamName: 'Fungsi Perencanaan dan Pengembangan Karir SDM', kode: 'BANGKAR-04', nama: 'Seleksi Terbuka JPT dan Organisasi Riset'),
    CategoryModel(id: 15, teamName: 'Fungsi Perencanaan dan Pengembangan Karir SDM', kode: 'BANGKAR-05', nama: 'Penempatan CASN (Mutasi Internal, Aktif Tubel, CLTN)'),
    CategoryModel(id: 16, teamName: 'Fungsi Perencanaan dan Pengembangan Karir SDM', kode: 'BANGKAR-06', nama: 'Pengembangan Karier (Mutasi, Rotasi, Promosi, Konversi Jabatan)'),
    CategoryModel(id: 17, teamName: 'Fungsi Perencanaan dan Pengembangan Karir SDM', kode: 'BANGKAR-07', nama: 'Pembuatan SK Penempatan Mutasi Internal'),

    // 3. Fungsi Mutasi Umum dan Kesejahteraan
    CategoryModel(id: 18, teamName: 'Fungsi Mutasi Umum dan Kesejahteraan', kode: 'MUTASI-01', nama: 'Pengaktifan Kembali Penugasan Luar BRIN'),
    CategoryModel(id: 19, teamName: 'Fungsi Mutasi Umum dan Kesejahteraan', kode: 'MUTASI-02', nama: 'Penerbitan SK PNS'),
    CategoryModel(id: 20, teamName: 'Fungsi Mutasi Umum dan Kesejahteraan', kode: 'MUTASI-03', nama: 'Pelantikan dan Sumpah Jabatan'),
    CategoryModel(id: 21, teamName: 'Fungsi Mutasi Umum dan Kesejahteraan', kode: 'MUTASI-04', nama: 'Mutasi Eksternal / Penugasan ke Instansi Luar'),
    CategoryModel(id: 22, teamName: 'Fungsi Mutasi Umum dan Kesejahteraan', kode: 'MUTASI-05', nama: 'Pemberhentian SDM'),
    CategoryModel(id: 23, teamName: 'Fungsi Mutasi Umum dan Kesejahteraan', kode: 'MUTASI-06', nama: 'Kenaikan Pangkat'),
    CategoryModel(id: 24, teamName: 'Fungsi Mutasi Umum dan Kesejahteraan', kode: 'MUTASI-07', nama: 'Peninjauan Masa Kerja (PMK)'),
    CategoryModel(id: 25, teamName: 'Fungsi Mutasi Umum dan Kesejahteraan', kode: 'MUTASI-08', nama: 'Penetapan Tewas & Kecelakaan Kerja / PAK'),
    CategoryModel(id: 26, teamName: 'Fungsi Mutasi Umum dan Kesejahteraan', kode: 'MUTASI-09', nama: 'Pengurusan Jamkestama / Jasindo'),

    // 4. Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I
    CategoryModel(id: 27, teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I', kode: 'JF1-01', nama: 'Penilaian Usulan HKM Peneliti'),
    CategoryModel(id: 28, teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I', kode: 'JF1-02', nama: 'Kenaikan Jenjang & Perpindahan Jabatan Peneliti'),
    CategoryModel(id: 29, teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I', kode: 'JF1-03', nama: 'Pengusulan Kenaikan Jenjang Peneliti Ahli Utama'),
    CategoryModel(id: 30, teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I', kode: 'JF1-04', nama: 'Fasilitasi Uji Kompetensi JF Peneliti'),
    CategoryModel(id: 31, teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I', kode: 'JF1-05', nama: 'Pemberhentian & Pengaktifan Kembali JF Peneliti'),

    // 5. Fungsi Mutasi dan Pengelolaan Jabatan Fungsional II
    CategoryModel(id: 32, teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional II', kode: 'JF2-01', nama: 'Penilaian Usulan HKM & Penyertaan Diklat'),
    CategoryModel(id: 33, teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional II', kode: 'JF2-02', nama: 'Kenaikan Jenjang & Perpindahan Jabatan Ahli Utama'),
    CategoryModel(id: 34, teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional II', kode: 'JF2-03', nama: 'Fasilitasi Uji Kompetensi JF II'),
    CategoryModel(id: 35, teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional II', kode: 'JF2-04', nama: 'Pemberhentian & Pengaktifan Kembali JF II'),

    // 6. Fungsi Mutasi dan Pengelolaan Jabatan Fungsional III
    CategoryModel(id: 36, teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional III', kode: 'JF3-01', nama: 'Fasilitasi Uji Kompetensi JF III'),
    CategoryModel(id: 37, teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional III', kode: 'JF3-02', nama: 'Pengangkatan dan Pemberhentian JF III'),
    CategoryModel(id: 38, teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional III', kode: 'JF3-03', nama: 'Pengusulan Kenaikan Jenjang & Pangkat JF III'),

    // 7. Fungsi Perencanaan dan Pengembangan Kompetensi SDM
    CategoryModel(id: 39, teamName: 'Fungsi Perencanaan dan Pengembangan Kompetensi SDM', kode: 'BANGKOM-01', nama: 'Penyusunan Kamus & Rencana Pengembangan Kompetensi'),
    CategoryModel(id: 40, teamName: 'Fungsi Perencanaan dan Pengembangan Kompetensi SDM', kode: 'BANGKOM-02', nama: 'Pelaksanaan Pengembangan Kompetensi'),
    CategoryModel(id: 41, teamName: 'Fungsi Perencanaan dan Pengembangan Kompetensi SDM', kode: 'BANGKOM-03', nama: 'Pengelolaan & Evaluasi Tugas Belajar (Tubel)'),

    // 8. Fungsi Penilaian Kompetensi
    CategoryModel(id: 42, teamName: 'Fungsi Penilaian Kompetensi', kode: 'NILAIKOM-01', nama: 'Pelaksanaan Penilaian Kompetensi (Assessment)'),
    CategoryModel(id: 43, teamName: 'Fungsi Penilaian Kompetensi', kode: 'NILAIKOM-02', nama: 'Pelaksanaan Manajemen Talenta ASN'),
    CategoryModel(id: 44, teamName: 'Fungsi Penilaian Kompetensi', kode: 'NILAIKOM-03', nama: 'Standar Kompetensi JPT & Pejabat Administrator'),
    CategoryModel(id: 45, teamName: 'Fungsi Penilaian Kompetensi', kode: 'NILAIKOM-04', nama: 'Bimbingan dan Konseling SDM'),

    // 9. Fungsi Manajemen Kinerja dan Penghargaan ASN
    CategoryModel(id: 46, teamName: 'Fungsi Manajemen Kinerja dan Penghargaan ASN', kode: 'KINERJA-01', nama: 'Perencanaan & Pemantauan Kinerja ASN'),
    CategoryModel(id: 47, teamName: 'Fungsi Manajemen Kinerja dan Penghargaan ASN', kode: 'KINERJA-02', nama: 'Penilaian Kinerja & SK Tunjangan Kinerja (Tukin)'),
    CategoryModel(id: 48, teamName: 'Fungsi Manajemen Kinerja dan Penghargaan ASN', kode: 'KINERJA-03', nama: 'Pemberian Penghargaan (SLKS, Wirakarya, ASN Berprestasi)'),
    CategoryModel(id: 49, teamName: 'Fungsi Manajemen Kinerja dan Penghargaan ASN', kode: 'KINERJA-04', nama: 'Manajemen Resiko & Evaluasi Kinerja Periodik'),

    // 10. Fungsi Pembinaan dan Penegakkan Disiplin ASN
    CategoryModel(id: 50, teamName: 'Fungsi Pembinaan dan Penegakkan Disiplin ASN', kode: 'DISIPLIN-01', nama: 'Pengelolaan Cuti di Luar Tanggungan Negara (CLTN)'),
    CategoryModel(id: 51, teamName: 'Fungsi Pembinaan dan Penegakkan Disiplin ASN', kode: 'DISIPLIN-02', nama: 'Pembinaan & Evaluasi Disiplin Pegawai'),
    CategoryModel(id: 52, teamName: 'Fungsi Pembinaan dan Penegakkan Disiplin ASN', kode: 'DISIPLIN-03', nama: 'Penanganan Proses Perceraian & Izin Pasangan'),
    CategoryModel(id: 53, teamName: 'Fungsi Pembinaan dan Penegakkan Disiplin ASN', kode: 'DISIPLIN-04', nama: 'Penegakan Kode Etik & Kasus Kepegawaian (PTUN, KASN, BPK)'),

    // 11. Fungsi Pengelolaan data dan informasi SDM
    CategoryModel(id: 54, teamName: 'Fungsi Pengelolaan data dan informasi SDM', kode: 'DATA-01', nama: 'Pengelolaan Tata Naskah & Pelayanan Informasi SDM'),
    CategoryModel(id: 55, teamName: 'Fungsi Pengelolaan data dan informasi SDM', kode: 'DATA-02', nama: 'Perbaikan Data Kehadiran & Updating Data SIMPEG'),
    CategoryModel(id: 56, teamName: 'Fungsi Pengelolaan data dan informasi SDM', kode: 'DATA-03', nama: 'Penerbitan Karis/Karsu & Sinkronisasi SIASN / IDIS'),
    CategoryModel(id: 57, teamName: 'Fungsi Pengelolaan data dan informasi SDM', kode: 'DATA-04', nama: 'Pemberian Role Akses Pegawai & Data Tapera'),

    // 12. Fungsi Kesekretariat Majelis Profesor
    CategoryModel(id: 58, teamName: 'Fungsi Kesekretariat Majelis Profesor', kode: 'PROF-01', nama: 'Penyelenggaraan Orasi Profesor Riset'),
    CategoryModel(id: 59, teamName: 'Fungsi Kesekretariat Majelis Profesor', kode: 'PROF-02', nama: 'Sidang Penilaian & Layout Naskah Orasi'),

    // 13. Fungsi Kesekretariatan RB
    CategoryModel(id: 60, teamName: 'Fungsi Kesekretariatan RB', kode: 'RB-01', nama: 'Penyusunan Rencana Kerja & Roadmap RB'),
    CategoryModel(id: 61, teamName: 'Fungsi Kesekretariatan RB', kode: 'RB-02', nama: 'Monev Triwulan & Pembangunan Zona Integritas (ZI)'),

    // 14. Fungsi Pembinaan Karir SDM Pembinaan Ulang
    CategoryModel(id: 62, teamName: 'Fungsi Pembinaan Karir SDM Pembinaan Ulang', kode: 'REENTRY-01', nama: 'Pembinaan Karir SDM Re-entry / Pembinaan Ulang'),
  ];

  static List<CategoryModel> getTugasFungsiByTeam(String teamName) {
    return allTugasFungsi
        .where((t) => t.teamName?.toLowerCase() == teamName.toLowerCase())
        .toList();
  }

  static String resolveTeam(String? text) {
    if (text == null || text.trim().isEmpty) return 'Fungsi Pengelolaan data dan informasi SDM';
    final query = text.toUpperCase();

    for (final item in allTugasFungsi) {
      if (item.kode != null && query.contains(item.kode!.toUpperCase())) {
        return item.teamName ?? 'Fungsi Pengelolaan data dan informasi SDM';
      }
      if (item.nama.isNotEmpty && query.contains(item.nama.toUpperCase())) {
        return item.teamName ?? 'Fungsi Pengelolaan data dan informasi SDM';
      }
    }

    if (query.contains('ORTALA') || query.contains('ORGANISASI') || query.contains('SOP') || query.contains('ANJAB')) return 'Fungsi Organisasi dan Tatalaksana';
    if (query.contains('PENGADAAN') || query.contains('OPEN CALL') || query.contains('JPT')) return 'Fungsi Perencanaan dan Pengembangan Karir SDM';
    if (query.contains('MUTASI') || query.contains('SK PNS') || query.contains('SUMPAH')) return 'Fungsi Mutasi Umum dan Kesejahteraan';
    if (query.contains('PENELITI') || query.contains('JF1')) return 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I';
    if (query.contains('JF2') || query.contains('AHLI UTAMA')) return 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional II';
    if (query.contains('JF3') || query.contains('FUNGSIIONAL III')) return 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional III';
    if (query.contains('TUBEL') || query.contains('BELAJAR') || query.contains('DIKLAT')) return 'Fungsi Perencanaan dan Pengembangan Kompetensi SDM';
    if (query.contains('ASSESSMENT') || query.contains('TALENTA')) return 'Fungsi Penilaian Kompetensi';
    if (query.contains('TUKIN') || query.contains('KINERJA') || query.contains('SKP')) return 'Fungsi Manajemen Kinerja dan Penghargaan ASN';
    if (query.contains('CLTN') || query.contains('DISIPLIN') || query.contains('CERAI')) return 'Fungsi Pembinaan dan Penegakkan Disiplin ASN';
    if (query.contains('TAPERA') || query.contains('SIASN') || query.contains('SIMPEG')) return 'Fungsi Pengelolaan data dan informasi SDM';
    if (query.contains('ORASI') || query.contains('PROFESOR')) return 'Fungsi Kesekretariat Majelis Profesor';
    if (query.contains('RB') || query.contains('ZONA INTEGRITAS')) return 'Fungsi Kesekretariatan RB';
    if (query.contains('REENTRY') || query.contains('PEMBINAAN ULANG')) return 'Fungsi Pembinaan Karir SDM Pembinaan Ulang';

    return 'Fungsi Pengelolaan data dan informasi SDM';
  }
}
