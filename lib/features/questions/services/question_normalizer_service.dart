class NormalizedQuestionResult {
  final String normalizedJudul;
  final String normalizedIsi;
  final String originalJudul;
  final String originalIsi;
  final String anonymizedAuthor;
  final List<String> appliedRules;

  const NormalizedQuestionResult({
    required this.normalizedJudul,
    required this.normalizedIsi,
    required this.originalJudul,
    required this.originalIsi,
    this.anonymizedAuthor = 'Pegawai',
    this.appliedRules = const [],
  });
}

class QuestionNormalizerService {
  /// Kamus kata informal/singkatan chat ke bahasa baku resmi
  static final Map<String, String> _wordDictionary = {
    // Kata Ganti & Percakapan
    'sy': 'saya',
    'aku': 'saya',
    'km': 'Anda',
    'kmu': 'Anda',
    'lu': 'Anda',
    'gw': 'saya',
    'gue': 'saya',
    'dr': 'dari',
    'kpd': 'kepada',
    'yg': 'yang',
    'dgn': 'dengan',
    'dg': 'dengan',
    'utk': 'untuk',
    'bwt': 'untuk',
    'buat': 'untuk',
    'krn': 'karena',
    'karna': 'karena',
    'gmn': 'bagaimana',
    'gimana': 'bagaimana',
    'bgm': 'bagaimana',
    'bgmn': 'bagaimana',
    'knp': 'mengapa',
    'kenapa': 'mengapa',
    'kpn': 'kapan',
    'd': 'di',
    'dmna': 'di mana',
    'dimana': 'di mana',
    'kemana': 'ke mana',
    'kmna': 'ke mana',
    'kalo': 'jika',
    'kl': 'jika',
    'klu': 'jika',
    'klo': 'jika',
    'blm': 'belum',
    'blom': 'belum',
    'sdh': 'sudah',
    'uda': 'sudah',
    'udah': 'sudah',
    'udh': 'sudah',
    'bs': 'dapat',
    'bisa': 'dapat',
    'bisa gak': 'apakah dimungkinkan',
    'bisa gk': 'apakah dimungkinkan',
    'bisa ga': 'apakah dimungkinkan',
    'bisa g ya': 'apakah dimungkinkan',
    'ga': 'tidak',
    'gak': 'tidak',
    'ngga': 'tidak',
    'nggak': 'tidak',
    'tak': 'tidak',
    'tdk': 'tidak',
    'bgt': 'sangat',
    'bgtt': 'sangat',
    'bgtu': 'begitu',
    'bener': 'benar',
    'beneran': 'sungguh',
    'gpp': 'tidak apa-apa',
    'ad': 'ada',
    'aja': 'saja',
    'aj': 'saja',
    'cuma': 'hanya',
    'cuman': 'hanya',
    'cm': 'hanya',
    'jd': 'jadi',
    'jdi': 'jadi',
    'trs': 'kemudian',
    'trus': 'kemudian',
    'pdhl': 'padahal',
    'pd': 'pada',
    'lg': 'sedang',
    'lagi': 'sedang',
    'hrs': 'harus',
    'mesti': 'harus',
    'tp': 'tetapi',
    'tpi': 'tetapi',
    'tapi': 'tetapi',
    'sm': 'dengan',
    'sama': 'dengan',
    'sampe': 'hingga',
    'sampeyan': 'Anda',
    'sampek': 'sampai',
    'bnyk': 'banyak',
    'banyak': 'banyak',
    'bbrp': 'beberapa',
    'tanya': 'ingin menanyakan',
    'nanya': 'ingin menanyakan',
    'mo': 'ingin',
    'mau': 'ingin',
    'pengen': 'ingin',
    'tolong': 'mohon bantuan',
    'tolong dong': 'mohon bantuan informasi',
    'pls': 'mohon',
    'please': 'mohon',
    'makasi': 'terima kasih',
    'makasih': 'terima kasih',
    'thx': 'terima kasih',
    'tq': 'terima kasih',

    // Akronim & Istilah Kepegawaian BRIN
    'tukin': 'Tunjangan Kinerja',
    'tubel': 'Tugas Belajar',
    'ibeli': 'Izin Belajar',
    'ujikom': 'Uji Kompetensi',
    'cltn': 'Cuti di Luar Tanggungan Negara',
    'pak': 'Penetapan Angka Kredit',
    'kgb': 'Kenaikan Gaji Berkala',
    'skp': 'Sasaran Kinerja Pegawai',
    'hkm': 'Hasil Kerja Minimal',
    'anjab': 'Analisis Jabatan',
    'evjab': 'Evaluasi Jabatan',
    'abk': 'Analisis Beban Kerja',
    'pns': 'PNS',
    'pppk': 'PPPK',
    'asn': 'ASN',
    'jpt': 'Jabatan Pimpinan Tinggi',
    'jf': 'Jabatan Fungsional',
    'lksdm': 'Layanan Kawasan SDM',
    'bosdm': 'BOSDM',
    'settama': 'Sekretariat Utama',
  };

  /// Bakukan kalimat judul dan isi pertanyaan
  static NormalizedQuestionResult normalize({
    required String judul,
    required String isi,
  }) {
    final List<String> appliedRules = [];

    // 1. Normalisasi Isi Pertanyaan
    String normalizedIsi = _normalizeText(isi, appliedRules);

    // 2. Normalisasi Judul Pertanyaan
    String normalizedJudul = _normalizeJudul(judul, normalizedIsi, appliedRules);

    return NormalizedQuestionResult(
      normalizedJudul: normalizedJudul,
      normalizedIsi: normalizedIsi,
      originalJudul: judul,
      originalIsi: isi,
      anonymizedAuthor: 'Pegawai',
      appliedRules: appliedRules,
    );
  }

  static String _normalizeText(String text, List<String> appliedRules) {
    if (text.trim().isEmpty) return text;

    String result = text.trim();

    // A. Normalisasi Spasi dan Tanda Baca Berulang
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    result = result.replaceAll(RegExp(r'\?{2,}'), '?');
    result = result.replaceAll(RegExp(r'!{2,}'), '!');
    result = result.replaceAll(RegExp(r'\.{3,}'), '...');

    // B. Penggantian Kata via Kamus Baku
    final words = result.split(' ');
    final List<String> convertedWords = [];

    for (final rawWord in words) {
      if (rawWord.isEmpty) continue;

      // Pisahkan tanda baca di akhir kata jika ada
      final match = RegExp(r'^([a-zA-Z0-9_\-]+)([\,\.\?\!\:\;]*)$').firstMatch(rawWord);
      if (match != null) {
        final coreWord = match.group(1)!;
        final punctuation = match.group(2) ?? '';
        final lower = coreWord.toLowerCase();

        if (_wordDictionary.containsKey(lower)) {
          final replacement = _wordDictionary[lower]!;
          appliedRules.add('$coreWord ➔ $replacement');
          convertedWords.add('$replacement$punctuation');
        } else {
          convertedWords.add(rawWord);
        }
      } else {
        convertedWords.add(rawWord);
      }
    }

    result = convertedWords.join(' ');

    // C. Pastikan huruf pertama kalimat berkapital
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    // D. Pastikan kalimat pertanyaan diakhiri tanda tanya jika mengandung kata tanya
    final lowerResult = result.toLowerCase();
    final containsQuestionWord = lowerResult.contains('bagaimana') ||
        lowerResult.contains('apakah') ||
        lowerResult.contains('mengapa') ||
        lowerResult.contains('kapan') ||
        lowerResult.contains('di mana') ||
        lowerResult.contains('siapa') ||
        lowerResult.contains('prosedur') ||
        lowerResult.contains('syarat');

    if (containsQuestionWord && !result.endsWith('?') && !result.endsWith('.')) {
      result = '$result?';
    }

    return result;
  }

  static String _normalizeJudul(String judul, String isi, List<String> appliedRules) {
    String cleanJudul = _normalizeText(judul, appliedRules);

    // Hilangkan tanda tanya di judul agar bernuansa topik formal
    if (cleanJudul.endsWith('?')) {
      cleanJudul = cleanJudul.substring(0, cleanJudul.length - 1).trim();
    }

    // Hilangkan kata-kata santai di awal judul seperti "tanya", "mau nanya", "info dong"
    cleanJudul = cleanJudul.replaceFirst(RegExp(r'^(ingin menanyakan|menanyakan|tanya|nanya|mau tanya|info dong|tanya dong)\s+', caseSensitive: false), '');
    cleanJudul = cleanJudul.trim();

    if (cleanJudul.isEmpty) {
      cleanJudul = 'Konsultasi Layanan Kepegawaian BRIN';
    }

    // Jika judul terlalu pendek atau tidak formal, berikan prefiks formal
    final lower = cleanJudul.toLowerCase();
    if (!lower.startsWith('prosedur') &&
        !lower.startsWith('ketentuan') &&
        !lower.startsWith('persyaratan') &&
        !lower.startsWith('penjelasan') &&
        !lower.startsWith('mekanisme') &&
        !lower.startsWith('klarifikasi') &&
        !lower.startsWith('permohonan') &&
        !lower.startsWith('pertanyaan')) {
      cleanJudul = 'Prosedur & Ketentuan $cleanJudul';
    }

    // Kapitalisasi tiap kata pada judul (Title Case)
    cleanJudul = _toTitleCase(cleanJudul);

    return cleanJudul;
  }

  static String _toTitleCase(String text) {
    final minorWords = {'dan', 'di', 'ke', 'dari', 'untuk', 'yang', 'pada', 'atau', 'dengan'};
    final words = text.split(' ');
    final buffer = StringBuffer();

    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      if (w.isEmpty) continue;

      final lower = w.toLowerCase();
      if (i > 0 && minorWords.contains(lower)) {
        buffer.write('$lower ');
      } else {
        // Jangan ubah akronim huruf besar (misal ASN, BRIN, PNS, PPPK, LKSDM, SKP, PAK)
        if (w == w.toUpperCase() && w.length > 1) {
          buffer.write('$w ');
        } else {
          buffer.write('${w[0].toUpperCase()}${w.substring(1).toLowerCase()} ');
        }
      }
    }

    return buffer.toString().trim();
  }
}
