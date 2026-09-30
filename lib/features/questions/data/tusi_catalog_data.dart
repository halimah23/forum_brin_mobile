import '../models/category_model.dart';

/// Katalog Data Master 15 Tim & Kode Tugas Fungsi (Tusi) BOSDM BRIN
class TusiCatalogData {
  static const List<String> allTeams = [
    'Tim Ortala',
    'Tim Sekretariat RB',
    'Tim Perencanaan dan Pengembangan Karier',
    'Tim Penilaian Kompetensi',
    'Tim Perencanaan dan Pengembangan Kompetensi',
    'Tim Mutasi Umum dan Kesejahteraan',
    'Tim Mutasi dan Pengelolaan JF 1',
    'Tim Mutasi dan Pengelolaan JF 2',
    'Tim Mutasi dan Pengelolaan JF 3',
    'Tim Sekretariat Majelis Profesor Riset',
    'Tim Manajemen Kinerja',
    'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN',
    'Tim Pengelolaan Data dan Informasi SDM',
    'Tim Program Pembinaan dan Penugasan Ulang',
    'Tim LKSDM',
  ];

  static const List<CategoryModel> allTugasFungsi = [
    // 1. Tim Ortala
    CategoryModel(id: 1, teamName: 'Tim Ortala', kode: 'BRIN-04.03.01.01', nama: 'Evaluasi Organisasi'),
    CategoryModel(id: 2, teamName: 'Tim Ortala', kode: 'BRIN-04.03.01.02', nama: 'Penataan Organisasi'),
    CategoryModel(id: 3, teamName: 'Tim Ortala', kode: 'BRIN-04.03.01.03', nama: 'Penyusunan Analisis Jabatan'),
    CategoryModel(id: 4, teamName: 'Tim Ortala', kode: 'BRIN-04.03.01.04', nama: 'Penyusunan Evaluasi Jabatan'),
    CategoryModel(id: 5, teamName: 'Tim Ortala', kode: 'BRIN-04.03.01.05', nama: 'Penyusunan Peta Jabatan'),
    CategoryModel(id: 6, teamName: 'Tim Ortala', kode: 'BRIN-04.03.01.06', nama: 'Sistem Kerja'),
    CategoryModel(id: 7, teamName: 'Tim Ortala', kode: 'BRIN-04.03.02.01', nama: 'Pemetaan Proses Bisnis'),
    CategoryModel(id: 8, teamName: 'Tim Ortala', kode: 'BRIN-04.03.02.01.04', nama: 'Penyusunan SOP'),
    CategoryModel(id: 9, teamName: 'Tim Ortala', kode: 'BRIN-04.03.02.01.05', nama: 'Evaluasi SOP'),
    CategoryModel(id: 10, teamName: 'Tim Ortala', kode: 'BRIN-04.03.02.02', nama: 'Pengelolaan Layanan SDM Kawasan'),

    // 2. Tim Sekretariat RB
    CategoryModel(id: 11, teamName: 'Tim Sekretariat RB', kode: 'BRIN-04.03.03', nama: 'Pelaksanaan Reformasi Birokrasi'),
    CategoryModel(id: 12, teamName: 'Tim Sekretariat RB', kode: 'BRIN-04.03.03.01', nama: 'Pelaksanaan Reformasi Birokrasi Sub-Unit'),
    CategoryModel(id: 13, teamName: 'Tim Sekretariat RB', kode: 'BRIN-04.03.03.02', nama: 'Zona Integritas'),

    // 3. Tim Perencanaan dan Pengembangan Karier
    CategoryModel(id: 14, teamName: 'Tim Perencanaan dan Pengembangan Karier', kode: 'BRIN-04.03.04', nama: 'Perencanaan dan Pengembangan Karier SDM'),
    CategoryModel(id: 15, teamName: 'Tim Perencanaan dan Pengembangan Karier', kode: 'BRIN-04.03.04.01', nama: 'Penyusunan Analisis Beban Kerja'),
    CategoryModel(id: 16, teamName: 'Tim Perencanaan dan Pengembangan Karier', kode: 'BRIN-04.03.04.02', nama: 'Perencanaan ASN'),
    CategoryModel(id: 17, teamName: 'Tim Perencanaan dan Pengembangan Karier', kode: 'BRIN-04.03.04.03', nama: 'Pengadaan SDM'),
    CategoryModel(id: 18, teamName: 'Tim Perencanaan dan Pengembangan Karier', kode: 'BRIN-04.03.04.04', nama: 'Penempatan CASN'),
    CategoryModel(id: 19, teamName: 'Tim Perencanaan dan Pengembangan Karier', kode: 'BRIN-04.03.04.05', nama: 'Penataan SDM'),
    CategoryModel(id: 20, teamName: 'Tim Perencanaan dan Pengembangan Karier', kode: 'BRIN-04.03.04.06', nama: 'Pengembangan Karier'),
    CategoryModel(id: 21, teamName: 'Tim Perencanaan dan Pengembangan Karier', kode: 'BRIN-04.03.04.07', nama: 'Pelaksanaan Sidang Tim Penilai Kinerja Pegawai (Baperjakat)'),
    CategoryModel(id: 22, teamName: 'Tim Perencanaan dan Pengembangan Karier', kode: 'BRIN-04.03.04.08', nama: 'Lokasi Kerja Eksternal Periset BRIN'),

    // 4. Tim Penilaian Kompetensi
    CategoryModel(id: 23, teamName: 'Tim Penilaian Kompetensi', kode: 'BRIN-04.03.05', nama: 'Penilaian dan Pengembangan SDM'),
    CategoryModel(id: 24, teamName: 'Tim Penilaian Kompetensi', kode: 'BRIN-04.03.05.01', nama: 'Standarisasi Jabatan'),
    CategoryModel(id: 25, teamName: 'Tim Penilaian Kompetensi', kode: 'BRIN-04.03.05.02', nama: 'Penilaian Kompetensi'),
    CategoryModel(id: 26, teamName: 'Tim Penilaian Kompetensi', kode: 'BRIN-04.03.05.06', nama: 'Manajemen Talenta ASN BRIN'),

    // 5. Tim Perencanaan dan Pengembangan Kompetensi
    CategoryModel(id: 27, teamName: 'Tim Perencanaan dan Pengembangan Kompetensi', kode: 'BRIN-04.03.05.03', nama: 'Penyusunan Rencana Kebutuhan & Pengembangan Kompetensi'),
    CategoryModel(id: 28, teamName: 'Tim Perencanaan dan Pengembangan Kompetensi', kode: 'BRIN-04.03.05.04', nama: 'Pelaksanaan Pengembangan Kompetensi'),
    CategoryModel(id: 29, teamName: 'Tim Perencanaan dan Pengembangan Kompetensi', kode: 'BRIN-04.03.05.05', nama: 'Evaluasi Pengembangan Kompetensi'),
    CategoryModel(id: 30, teamName: 'Tim Perencanaan dan Pengembangan Kompetensi', kode: 'BRIN-04.03.05.08', nama: 'Ujian Penyesuaian Kenaikan Pangkat (UPKP)'),
    CategoryModel(id: 31, teamName: 'Tim Perencanaan dan Pengembangan Kompetensi', kode: 'BRIN-04.03.05.09', nama: 'Pencantuman Gelar Akademik'),

    // 6. Tim Mutasi Umum dan Kesejahteraan
    CategoryModel(id: 32, teamName: 'Tim Mutasi Umum dan Kesejahteraan', kode: 'BRIN-04.03.06', nama: 'Pengelolaan Mutasi SDM'),
    CategoryModel(id: 33, teamName: 'Tim Mutasi Umum dan Kesejahteraan', kode: 'BRIN-04.03.06.01.01', nama: 'Pengaktifan Kembali'),
    CategoryModel(id: 34, teamName: 'Tim Mutasi Umum dan Kesejahteraan', kode: 'BRIN-04.03.06.01.02', nama: 'Penerbitan SK PNS'),
    CategoryModel(id: 35, teamName: 'Tim Mutasi Umum dan Kesejahteraan', kode: 'BRIN-04.03.06.01.03', nama: 'Pelantikan & Sumpah Jabatan'),
    CategoryModel(id: 36, teamName: 'Tim Mutasi Umum dan Kesejahteraan', kode: 'BRIN-04.03.06.01.04', nama: 'Mutasi Pegawai'),
    CategoryModel(id: 37, teamName: 'Tim Mutasi Umum dan Kesejahteraan', kode: 'BRIN-04.03.06.01.05', nama: 'Pemberhentian SDM'),
    CategoryModel(id: 38, teamName: 'Tim Mutasi Umum dan Kesejahteraan', kode: 'BRIN-04.03.06.01.06', nama: 'Kenaikan Pangkat'),
    CategoryModel(id: 39, teamName: 'Tim Mutasi Umum dan Kesejahteraan', kode: 'BRIN-04.03.06.01.07', nama: 'Peninjauan Masa Kerja'),
    CategoryModel(id: 40, teamName: 'Tim Mutasi Umum dan Kesejahteraan', kode: 'BRIN-04.03.06.01.08', nama: 'Penugasan ke Instansi Luar'),
    CategoryModel(id: 41, teamName: 'Tim Mutasi Umum dan Kesejahteraan', kode: 'BRIN-04.03.06.01.09', nama: 'Penetapan Tewas'),
    CategoryModel(id: 42, teamName: 'Tim Mutasi Umum dan Kesejahteraan', kode: 'BRIN-04.03.06.01.10', nama: 'Jamkestama/Jamkesmen'),
    CategoryModel(id: 43, teamName: 'Tim Mutasi Umum dan Kesejahteraan', kode: 'BRIN-04.03.06.01.11', nama: 'Penetapan Kecelakaan Kerja & Penyakit Akibat Kerja'),

    // 7. Tim Mutasi dan Pengelolaan JF 1
    CategoryModel(id: 44, teamName: 'Tim Mutasi dan Pengelolaan JF 1', kode: 'BRIN-04.03.06.02.01.01', nama: 'Penilaian Usulan HKM'),
    CategoryModel(id: 45, teamName: 'Tim Mutasi dan Pengelolaan JF 1', kode: 'BRIN-04.03.06.02.01.02', nama: 'Fasilitasi Uji Kompetensi (Kenaikan Jenjang Jabatan)'),
    CategoryModel(id: 46, teamName: 'Tim Mutasi dan Pengelolaan JF 1', kode: 'BRIN-04.03.06.02.01.03', nama: 'Fasilitasi Uji Kompetensi (Perpindahan Jabatan)'),
    CategoryModel(id: 47, teamName: 'Tim Mutasi dan Pengelolaan JF 1', kode: 'BRIN-04.03.06.02.01.04', nama: 'Pemberhentian JF Peneliti'),
    CategoryModel(id: 48, teamName: 'Tim Mutasi dan Pengelolaan JF 1', kode: 'BRIN-04.03.06.02.01.05', nama: 'Pengangkatan Kembali'),

    // 8. Tim Mutasi dan Pengelolaan JF 2
    CategoryModel(id: 49, teamName: 'Tim Mutasi dan Pengelolaan JF 2', kode: 'BRIN-04.03.06.02.02.02.01', nama: 'Penyusunan PAK'),
    CategoryModel(id: 50, teamName: 'Tim Mutasi dan Pengelolaan JF 2', kode: 'BRIN-04.03.06.02.02.02.02', nama: 'Uji Kompetensi'),
    CategoryModel(id: 51, teamName: 'Tim Mutasi dan Pengelolaan JF 2', kode: 'BRIN-04.03.06.02.02.02.03', nama: 'Pemberhentian JF'),
    CategoryModel(id: 52, teamName: 'Tim Mutasi dan Pengelolaan JF 2', kode: 'BRIN-04.03.06.02.02.02.04', nama: 'Pengangkatan Kembali JF'),
    CategoryModel(id: 53, teamName: 'Tim Mutasi dan Pengelolaan JF 2', kode: 'BRIN-04.03.06.02.02.02.05', nama: 'Kenaikan Pangkat karena Peningkatan Pendidikan'),

    // 9. Tim Mutasi dan Pengelolaan JF 3
    CategoryModel(id: 54, teamName: 'Tim Mutasi dan Pengelolaan JF 3', kode: 'BRIN-04.03.06.02.03.01', nama: 'Penyusunan PAK'),
    CategoryModel(id: 55, teamName: 'Tim Mutasi dan Pengelolaan JF 3', kode: 'BRIN-04.03.06.02.03.02', nama: 'Uji Kompetensi'),
    CategoryModel(id: 56, teamName: 'Tim Mutasi dan Pengelolaan JF 3', kode: 'BRIN-04.03.06.02.03.03', nama: 'Pemberhentian JF'),
    CategoryModel(id: 57, teamName: 'Tim Mutasi dan Pengelolaan JF 3', kode: 'BRIN-04.03.06.02.03.04', nama: 'Pengangkatan Kembali JF'),
    CategoryModel(id: 58, teamName: 'Tim Mutasi dan Pengelolaan JF 3', kode: 'BRIN-04.03.06.02.03.05', nama: 'Kenaikan Pangkat karena Peningkatan Pendidikan'),

    // 10. Tim Sekretariat Majelis Profesor Riset
    CategoryModel(id: 59, teamName: 'Tim Sekretariat Majelis Profesor Riset', kode: 'BRIN-04.03.06.03', nama: 'Penilaian Naskah Orasi Profesor Riset'),

    // 11. Tim Manajemen Kinerja
    CategoryModel(id: 60, teamName: 'Tim Manajemen Kinerja', kode: 'BRIN-04.03.07.01', nama: 'Perencanaan Kinerja'),
    CategoryModel(id: 61, teamName: 'Tim Manajemen Kinerja', kode: 'BRIN-04.03.07.02', nama: 'Pemantauan Kinerja'),
    CategoryModel(id: 62, teamName: 'Tim Manajemen Kinerja', kode: 'BRIN-04.03.07.03', nama: 'Penilaian dan Evaluasi Kinerja'),
    CategoryModel(id: 63, teamName: 'Tim Manajemen Kinerja', kode: 'BRIN-04.03.07.04', nama: 'Tindak Lanjut Kinerja'),
    CategoryModel(id: 64, teamName: 'Tim Manajemen Kinerja', kode: 'BRIN-04.03.07.05', nama: 'Penghargaan'),
    CategoryModel(id: 65, teamName: 'Tim Manajemen Kinerja', kode: 'BRIN-04.03.07.06', nama: 'Manajemen Resiko'),
    CategoryModel(id: 66, teamName: 'Tim Manajemen Kinerja', kode: 'BRIN-04.03.07.07', nama: 'Evaluasi Periodik'),
    CategoryModel(id: 67, teamName: 'Tim Manajemen Kinerja', kode: 'BRIN-04.03.07.08', nama: 'Pendokumentasian Hasil Kerja pada SIMARIN'),

    // 12. Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN
    CategoryModel(id: 68, teamName: 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', kode: 'BRIN-04.03.08.01', nama: 'CLTN (Cuti di Luar Tanggungan Negara)'),
    CategoryModel(id: 69, teamName: 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', kode: 'BRIN-04.03.08.02', nama: 'Pembinaan Disiplin'),
    CategoryModel(id: 70, teamName: 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', kode: 'BRIN-04.03.08.03', nama: 'Perceraian'),
    CategoryModel(id: 71, teamName: 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', kode: 'BRIN-04.03.08.04', nama: 'Monitoring dan Evaluasi Pemberian Cuti ASN'),
    CategoryModel(id: 72, teamName: 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', kode: 'BRIN-04.03.08.05', nama: 'Pemberhentian Sementara PNS (Tersangka Dugaan Pidana)'),
    CategoryModel(id: 73, teamName: 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', kode: 'BRIN-04.03.08.06', nama: 'Permohonan PNS Pria Beristri Lebih dari Satu'),
    CategoryModel(id: 74, teamName: 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', kode: 'BRIN-04.03.08.07', nama: 'Aktif Kembali setelah Menjalani Hukuman Pidana'),
    CategoryModel(id: 75, teamName: 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', kode: 'BRIN-04.03.08.08', nama: 'Pemberhentian PNS Lain-Lain'),
    CategoryModel(id: 76, teamName: 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', kode: 'BRIN-04.03.08.09', nama: 'Pemberhentian karena Terbukti Menggunakan Ijazah Palsu'),
    CategoryModel(id: 77, teamName: 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN', kode: 'BRIN-04.03.08.14', nama: 'Penanganan Aduan/Laporan Dugaan Pelanggaran Disiplin & Kode Etik'),

    // 13. Tim Pengelolaan Data dan Informasi SDM
    CategoryModel(id: 78, teamName: 'Tim Pengelolaan Data dan Informasi SDM', kode: 'BRIN-04.03.09.01', nama: 'Pemutakhiran Dokumen'),
    CategoryModel(id: 79, teamName: 'Tim Pengelolaan Data dan Informasi SDM', kode: 'BRIN-04.03.09.02', nama: 'Permintaan Data dan Informasi SDM'),
    CategoryModel(id: 80, teamName: 'Tim Pengelolaan Data dan Informasi SDM', kode: 'BRIN-04.03.09.03', nama: 'Penerbitan Karis/Karsu Virtual'),
    CategoryModel(id: 81, teamName: 'Tim Pengelolaan Data dan Informasi SDM', kode: 'BRIN-04.03.09.04', nama: 'Pencetakan Ulang ID Card Baru/Karena Hilang/Rusak'),
    CategoryModel(id: 82, teamName: 'Tim Pengelolaan Data dan Informasi SDM', kode: 'BRIN-04.03.09.05', nama: 'Perbaikan Identitas (Nama, Tanggal Lahir) PNS'),
    CategoryModel(id: 83, teamName: 'Tim Pengelolaan Data dan Informasi SDM', kode: 'BRIN-04.03.09.06', nama: 'Pelaksanaan Updating Data Pegawai'),
    CategoryModel(id: 84, teamName: 'Tim Pengelolaan Data dan Informasi SDM', kode: 'BRIN-04.03.09.07', nama: 'Pemberian Role Akses Pegawai'),
    CategoryModel(id: 85, teamName: 'Tim Pengelolaan Data dan Informasi SDM', kode: 'BRIN-04.03.09.08', nama: 'Pemutakhiran Status Pekerjaan pada Tapera'),
    CategoryModel(id: 86, teamName: 'Tim Pengelolaan Data dan Informasi SDM', kode: 'BRIN-04.03.09.09', nama: 'Penyampaian Output Layanan melalui Perubahan Faktor Gaji SIMPEG'),
    CategoryModel(id: 87, teamName: 'Tim Pengelolaan Data dan Informasi SDM', kode: 'BRIN-04.03.09.10', nama: 'Pengelolaan Cuti ASN'),
    CategoryModel(id: 88, teamName: 'Tim Pengelolaan Data dan Informasi SDM', kode: 'BRIN-04.03.09.11', nama: 'Permohonan Pemberhentian Role Akses'),

    // 14. Tim Program Pembinaan dan Penugasan Ulang
    CategoryModel(id: 89, teamName: 'Tim Program Pembinaan dan Penugasan Ulang', kode: 'BRIN-04.03.11', nama: 'Program Pembinaan dan Penugasan Ulang Pegawai'),

    // 15. Tim LKSDM
    CategoryModel(id: 90, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01', nama: 'Layanan Selesai di Kawasan'),
    CategoryModel(id: 91, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.01', nama: 'Layanan Otomatis Selesai di Kawasan'),
    CategoryModel(id: 92, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.01.01', nama: 'Hukuman Disiplin Pegawai Ringan'),
    CategoryModel(id: 93, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.01.02', nama: 'Fasilitasi Kenaikan Gaji Berkala (KGB)'),
    CategoryModel(id: 94, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.01.03', nama: 'Monitoring Pegawai Tubel'),
    CategoryModel(id: 95, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.01.04', nama: 'Monitoring Kehadiran Pegawai'),
    CategoryModel(id: 96, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.02.01', nama: 'Laporan Kelahiran Anak/ Perkawinan/ Perceraian'),
    CategoryModel(id: 97, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.02.02', nama: 'Laporan Pembayaran Gaji/Uang Makan Tidak Sesuai'),
    CategoryModel(id: 98, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.02.03', nama: 'Penerbitan Surat Izin Cerai/Keterangan Perceraian'),
    CategoryModel(id: 99, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.02.04', nama: 'Pelaporan Perpanjangan Tunjangan/Hak PNS'),
    CategoryModel(id: 100, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.02.05', nama: 'Tugas Belajar'),
    CategoryModel(id: 101, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.02.06', nama: 'Penerbitan Surat Pengantar SP Setneg Tugas Belajar'),
    CategoryModel(id: 102, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.02.07', nama: 'Laporan Perceraian/Meninggalnya Suami/Istri/Anak PNS'),
    CategoryModel(id: 103, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.02.08', nama: 'Laporan Penghentian Tunjangan Anak PNS'),
    CategoryModel(id: 104, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.02.09', nama: 'Pendaftaran BPJS untuk Anggota Keluarga Lainnya'),
    CategoryModel(id: 105, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.02.10', nama: 'Pendaftaran BPJS untuk PNS Baru / Anak 1-3 / Perpanjangan BPJS'),
    CategoryModel(id: 106, teamName: 'Tim LKSDM', kode: 'BRIN-04.03.10.01.02.11', nama: 'Pengajuan Cuti Besar'),
  ];

  /// Cari daftar Tusi berdasarkan nama tim
  static List<CategoryModel> getTugasFungsiByTeam(String teamName) {
    return allTugasFungsi
        .where((t) => t.teamName?.toLowerCase() == teamName.toLowerCase())
        .toList();
  }

  /// Identifikasi tim berdasarkan nama atau kode tugas fungsi
  static String resolveTeam(String? text) {
    if (text == null || text.trim().isEmpty) return 'Tim Layanan SDM BOSDM';
    final query = text.toUpperCase();

    // Urutkan berdasarkan kepanjangan kode terpanjang agar kode paling spesifik terpilih lebih dulu
    final sortedByCode = List<CategoryModel>.from(allTugasFungsi)
      ..sort((a, b) => (b.kode?.length ?? 0).compareTo(a.kode?.length ?? 0));

    for (final item in sortedByCode) {
      if (item.kode != null && item.kode!.isNotEmpty && query.contains(item.kode!.toUpperCase())) {
        return item.teamName ?? 'Tim Layanan SDM BOSDM';
      }
    }

    for (final item in allTugasFungsi) {
      if (item.nama.isNotEmpty && query.contains(item.nama.toUpperCase())) {
        return item.teamName ?? 'Tim Layanan SDM BOSDM';
      }
    }

    if (query.contains('ORTALA') || query.contains('ORGANISASI')) return 'Tim Ortala';
    if (query.contains('REFORMASI BIROKRASI') || query.contains('RB')) return 'Tim Sekretariat RB';
    if (query.contains('KARIER') || query.contains('BEBAN KERJA')) return 'Tim Perencanaan dan Pengembangan Karier';
    if (query.contains('TALENTA') || query.contains('PENILAIAN KOMPETENSI')) return 'Tim Penilaian Kompetensi';
    if (query.contains('KOMPETENSI') || query.contains('UPKP') || query.contains('GELAR')) return 'Tim Perencanaan dan Pengembangan Kompetensi';
    if (query.contains('MUTASI') || query.contains('KESEJAHTERAAN') || query.contains('PANGKAT')) return 'Tim Mutasi Umum dan Kesejahteraan';
    if (query.contains('JF 1') || query.contains('HKM') || query.contains('PENELITI')) return 'Tim Mutasi dan Pengelolaan JF 1';
    if (query.contains('JF 2') || query.contains('PAK')) return 'Tim Mutasi dan Pengelolaan JF 2';
    if (query.contains('JF 3')) return 'Tim Mutasi dan Pengelolaan JF 3';
    if (query.contains('PROFESOR')) return 'Tim Sekretariat Majelis Profesor Riset';
    if (query.contains('KINERJA') || query.contains('SIMARIN')) return 'Tim Manajemen Kinerja';
    if (query.contains('BERAKHLAK') || query.contains('DISIPLIN') || query.contains('CUTI')) return 'Tim Internalisasi BerAKHLAK dan Pembinaan Disiplin ASN';
    if (query.contains('DATA') || query.contains('INFORMASI') || query.contains('ID CARD')) return 'Tim Pengelolaan Data dan Informasi SDM';
    if (query.contains('PENUGASAN ULANG')) return 'Tim Program Pembinaan dan Penugasan Ulang';
    if (query.contains('LKSDM') || query.contains('KAWASAN')) return 'Tim LKSDM';

    return 'Tim Layanan SDM BOSDM';
  }
}
