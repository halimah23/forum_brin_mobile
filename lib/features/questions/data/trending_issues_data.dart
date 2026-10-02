import 'tusi_catalog_data.dart';

class TrendingIssueItem {
  final String title;
  final String category;
  final int count;
  final String suggestedCentralTeam;
  final String description;

  const TrendingIssueItem({
    required this.title,
    required this.category,
    required this.count,
    required this.suggestedCentralTeam,
    required this.description,
  });
}

class FaqItem {
  final String question;
  final String answer;
  final String category;
  final String teamName;

  const FaqItem({
    required this.question,
    required this.answer,
    required this.category,
    required this.teamName,
  });
}

class TrendingIssuesData {
  static const List<TrendingIssueItem> defaultTrendingIssues = [
    TrendingIssueItem(
      title: 'Prosedur Uji Kompetensi & Kenaikan Jenjang Peneliti Utama',
      category: 'Jabatan Fungsional I',
      count: 48,
      suggestedCentralTeam: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I',
      description: 'Pertanyaan seputar pendaftaran ujikom, portofolio karya HKM, dan penilaian PAK.',
    ),
    TrendingIssueItem(
      title: 'Ketentuan Cuti Alasan Penting & Cuti Luar Tanggungan Negara (CLTN)',
      category: 'Pembinaan Disiplin',
      count: 35,
      suggestedCentralTeam: 'Fungsi Pembinaan dan Penegakkan Disiplin ASN',
      description: 'Pengajuan CLTN, kelengkapan syarat administrasi, dan prosedur perizinan.',
    ),
    TrendingIssueItem(
      title: 'Pencairan Tunjangan Kinerja & Penyesuaian SK Tukin',
      category: 'Manajemen Kinerja',
      count: 29,
      suggestedCentralTeam: 'Fungsi Manajemen Kinerja dan Penghargaan ASN',
      description: 'Pertanyaan mengenai selisih tunjangan kinerja dan pencairan rapel kelas jabatan.',
    ),
    TrendingIssueItem(
      title: 'Persyaratan Mutasi Penugasan ke Instansi Luar BRIN',
      category: 'Mutasi Umum',
      count: 22,
      suggestedCentralTeam: 'Fungsi Mutasi Umum dan Kesejahteraan',
      description: 'Prosedur pengajuan mutasi eksternal, penugasan luar BRIN, dan SK PNS.',
    ),
    TrendingIssueItem(
      title: 'Pendaftaran & Evaluasi Tugas Belajar (Tubel) SDM',
      category: 'Pengembangan Kompetensi',
      count: 18,
      suggestedCentralTeam: 'Fungsi Perencanaan dan Pengembangan Kompetensi SDM',
      description: 'Syarat perpanjangan tugas belajar, surat pengantar SP Setneg, dan progres belajar.',
    ),
  ];

  static const List<FaqItem> defaultFaqs = [
    FaqItem(
      question: 'Bagaimana cara mengajukan perpanjangan Tugas Belajar (Tubel)?',
      answer: 'Permohonan perpanjangan studi diajukan paling lambat 3 bulan sebelum masa tugas belajar berakhir via Portal BOSDM dengan melampirkan Progress Report Akademik.',
      category: 'Pengembangan Kompetensi',
      teamName: 'Fungsi Perencanaan dan Pengembangan Kompetensi SDM',
    ),
    FaqItem(
      question: 'Apa syarat utama pengusulan Kenaikan Pangkat Pilihan bagi Jabatan Fungsional Peneliti?',
      answer: 'Memiliki Penetapan Angka Kredit (PAK) kumulatif, Surat Keabsahan Karya HKM, dan Penilaian Kinerja minimal berpredikat Baik.',
      category: 'Jabatan Fungsional',
      teamName: 'Fungsi Mutasi dan Pengelolaan Jabatan Fungsional I',
    ),
    FaqItem(
      question: 'Berapa lama proses verifikasi administrasi pengusulan Cuti Besar di LKSDM?',
      answer: 'Proses verifikasi oleh Staf Admin LKSDM membutuhkan waktu 1-2 hari kerja sebelum diteruskan ke tim pusat jika memerlukan penetapan SK.',
      category: 'Disiplin ASN',
      teamName: 'Fungsi Pembinaan dan Penegakkan Disiplin ASN',
    ),
  ];

  /// Analisis kata kunci cerdas untuk merekomendasikan 1 dari 14 Tim Pusat
  static String suggestCentralTeam(String title, String content) {
    return TusiCatalogData.resolveTeam('$title $content');
  }
}
