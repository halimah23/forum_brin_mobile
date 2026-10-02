class LksdmItem {
  final int id;
  final String name;
  final String shortName;
  final List<String> coverageUnits;
  final List<String> sebaranHbp;
  final List<String> jobdeskList;
  final String catatan;

  const LksdmItem({
    required this.id,
    required this.name,
    required this.shortName,
    required this.coverageUnits,
    required this.sebaranHbp,
    required this.jobdeskList,
    this.catatan = '',
  });
}

class LksdmCatalogData {
  static const List<String> standardJobdesk = [
    'Melaksanakan penegakan hukuman disiplin pegawai kategori ringan s.d sedang',
    'Memfasilitasi pemrosesan kenaikan gaji berkala (KGB)',
    'Melaksanakan monitoring pegawai tugas belajar',
    'Melaksanakan monitoring kehadiran pegawai',
    'Melaksanakan layanan kepegawaian kawasan',
    'Melaksanakan verifikasi layanan kepegawaian yang selesai di pusat',
  ];

  static const List<LksdmItem> allLksdm = [
    LksdmItem(
      id: 1,
      name: 'Layanan Kawasan SDM 1 : Thamrin I',
      shortName: 'LKSDM 1',
      coverageUnits: ['SETTAMA', 'PUSDATIN', 'INSPEKTORAT', 'KKB'],
      sebaranHbp: [
        'KA Thamrin (Bacharuddin Jusuf Habibie)',
        'KA Rawamangun (Harsono Wiryosumarto)',
        'KA Gunung Sindur (Soedjono Djoened Poesponegoro)',
        'KKB Bogor (Kusnoto Setjodiwirjo)',
        'KKB Denpasar',
        'KKB Magelang (Muhilal)',
        'KKB Makassar',
        'KPP Perumahan Serpong',
      ],
      jobdeskList: standardJobdesk,
      catatan: 'Pengelolaan Kawasan Kerja Bersama (KKB) secara keseluruhan ditarik ke LKSDM 1.',
    ),
    LksdmItem(
      id: 2,
      name: 'Layanan Kawasan SDM 2 : Thamrin II',
      shortName: 'LKSDM 2',
      coverageUnits: [
        'DKP', 'DKRI', 'DRID', 'DFRI', 'DPRI', 'DSDMI',
        'SESDEP DIRI', 'DPAKR', 'DPKIRI', 'DPLFRKST', 'DPKI'
      ],
      sebaranHbp: [
        'KA Thamrin (Bacharuddin Jusuf Habibie)',
        'KST Pasar Jumat (Gerrit Augustinus Siwabessy)',
        'KKE Wisma Teknologi',
        'KKE Wisma Pulau Pari',
        'KS Ancol (Aprilani Soegiarto)',
        'KST Cibinong (DPLFRKST)',
      ],
      jobdeskList: standardJobdesk,
      catatan: 'Pengelolaan Kawasan Kerja Eksternal (KKE) & DPLFRKST KST Cibinong ditarik ke LKSDM 2.',
    ),
    LksdmItem(
      id: 3,
      name: 'Layanan Kawasan SDM 3 : Gatot Subroto',
      shortName: 'LKSDM 3',
      coverageUnits: [
        'Settama (OR + KST Gastu)',
        'DPLFRKST OR ABASTRA',
        'OR TPKEKM',
        'OR IPSH'
      ],
      sebaranHbp: [
        'KST Gatot Subroto (Sarwono Prawirohardjo)',
        'KS Pasar Minggu (Raden Pandji Soejono)',
        'KS Ambon (Atjep Suwartana)',
      ],
      jobdeskList: standardJobdesk,
      catatan: 'Pengelolaan SDM Settama di OR mengikuti pembagian pengelolaan OR.',
    ),
    LksdmItem(
      id: 4,
      name: 'Layanan Kawasan SDM 4 : Serpong I',
      shortName: 'LKSDM 4',
      coverageUnits: [
        'Settama di OR',
        'Settama KST Tanjung Bintang',
        'DPLFRKST KST Tanjung Bintang',
        'OR TN',
        'OR EM'
      ],
      sebaranHbp: [
        'KST Serpong (Bacharuddin Jusuf Habibie)',
        'KST Tanjung Bintang (Iskandar Zulkarnain)',
      ],
      jobdeskList: standardJobdesk,
      catatan: 'Pengelolaan SDM Settama di OR mengikuti pembagian pengelolaan OR.',
    ),
    LksdmItem(
      id: 5,
      name: 'Layanan Kawasan SDM 5 : Serpong II',
      shortName: 'LKSDM 5',
      coverageUnits: [
        'Settama (OR, Serpong, Rumpin, Rancabungur, Tarogong)',
        'DPFK Serpong',
        'DPLFRKST Serpong',
        'OR NM',
        'OR PA'
      ],
      sebaranHbp: [
        'KST Serpong (Bacharuddin Jusuf Habibie)',
        'KST Rumpin (Jacob Salatun)',
        'KS Rancabungur (Ibnoe Soebroto)',
        'KS Tarogong (R. Sunaryo)',
      ],
      jobdeskList: standardJobdesk,
      catatan: 'Pengelolaan DPLFRKST KST Serpong & DPFK KST Serpong di bawah LKSDM 5.',
    ),
    LksdmItem(
      id: 6,
      name: 'Layanan Kawasan SDM 6 : Cibinong',
      shortName: 'LKSDM 6',
      coverageUnits: [
        'Settama (Pengelola OR + HB Cibinong)',
        'OR KES',
        'OR HL'
      ],
      sebaranHbp: [
        'KST Cibinong (Soekarno)',
      ],
      jobdeskList: standardJobdesk,
      catatan: 'Pengelolaan SDM Settama KST Cibinong berada di bawah LKSDM 6.',
    ),
    LksdmItem(
      id: 7,
      name: 'Layanan Kawasan SDM 7 : Bandung',
      shortName: 'LKSDM 7',
      coverageUnits: [
        'Settama (OR + KST Cisitu)',
        'DPLFRKST',
        'DPFK',
        'OR EI',
        'ORKM'
      ],
      sebaranHbp: [
        'KST Cisitu (Samaun Samadikun)',
        'KS Subang (Muhammadi Siswosudarmo)',
        'KS Tamansari',
        'KSL Gunung Timau',
        'KSL Anak Tuha',
        'KSL Cipanas',
        'KSL Pontianak',
        'KSL Biak',
        'KSL Agam',
        'KSL Parepare',
        'KSL Bumiayu',
        'KSL Pamengpeuk',
        'KSL Tilong',
      ],
      jobdeskList: standardJobdesk,
      catatan: 'Pengelolaan Kawasan Stasiun Lapangan (KSL) secara keseluruhan ditarik ke LKSDM 7.',
    ),
    LksdmItem(
      id: 8,
      name: 'Layanan Kawasan SDM 8 : Cibinong, Yogyakarta, Surabaya',
      shortName: 'LKSDM 8',
      coverageUnits: [
        'POLTEKNUKLIR',
        'Settama (OR + KSTE Babarsari, KST Gunung Kidul, KST Lombok, KST Surabaya)',
        'DPLFRKST',
        'DPFK',
        'DPKI',
        'OR PP',
        'KKI'
      ],
      sebaranHbp: [
        'KSTE Babarsari (Achmad Baiquni)',
        'KST Gunung Kidul (Umar Anggara Jenie)',
        'KST Lombok (Kurnaen Sumadiharga)',
        'KST Surabaya (Said Djauharsjah Jenie)',
        'KST Cibinong (Soekarno)',
        'KS Mlati (Subandono Diposaptono)',
        'KS Salatiga (M.F. Sustriayu Nalim)',
        'KS Tawangmangu (Soetarman)',
        'KKI Kebun Raya Bogor',
        'KKI Kebun Raya Cibinong',
        'KKI Kebun Raya Cibodas',
        'KKI Kebun Raya Eka Karya',
        'KKI Kawasan Geodiversitas Sukendar Asikin',
        'KKI Kebun Raya Purwodadi',
      ],
      jobdeskList: standardJobdesk,
      catatan: 'Pengelolaan SDM DPKI di KST Cibinong & KKI ditarik ke pengelolaan LKSDM 8.',
    ),
  ];

  /// Identifikasi LKSDM 1 - 8 secara otomatis berdasarkan unit/lokasi kerja pegawai
  static LksdmItem identifyLksdmFromUserUnit(String? unit, [String? location]) {
    final query = '${unit ?? ""} ${location ?? ""}'.toLowerCase();

    if (query.contains('pusdatin') || query.contains('inspektorat') || query.contains('rawamangun') || query.contains('gunung sindur') || query.contains('magelang') || query.contains('makassar')) {
      return allLksdm[0]; // LKSDM 1
    }
    if (query.contains('dkp') || query.contains('dkri') || query.contains('drid') || query.contains('dfri') || query.contains('dpri') || query.contains('dsdmi') || query.contains('pasar jumat') || query.contains('ancol')) {
      return allLksdm[1]; // LKSDM 2
    }
    if (query.contains('gatot subroto') || query.contains('gastu') || query.contains('abastra') || query.contains('tpkekm') || query.contains('ipsh') || query.contains('pasar minggu') || query.contains('ambon')) {
      return allLksdm[2]; // LKSDM 3
    }
    if (query.contains('tanjung bintang') || query.contains('or tn') || query.contains('or em')) {
      return allLksdm[3]; // LKSDM 4
    }
    if (query.contains('rumpin') || query.contains('rancabungur') || query.contains('tarogong') || query.contains('or nm') || query.contains('or pa')) {
      return allLksdm[4]; // LKSDM 5
    }
    if (query.contains('or kes') || query.contains('or hl') || query.contains('cibinong')) {
      return allLksdm[5]; // LKSDM 6
    }
    if (query.contains('bandung') || query.contains('cisitu') || query.contains('subang') || query.contains('or ei') || query.contains('orkm') || query.contains('ksl') || query.contains('biak') || query.contains('agam') || query.contains('parepare')) {
      return allLksdm[6]; // LKSDM 7
    }
    if (query.contains('polteknuklir') || query.contains('babarsari') || query.contains('gunung kidul') || query.contains('surabaya') || query.contains('yogyakarta') || query.contains('kki') || query.contains('kebun raya') || query.contains('or pp')) {
      return allLksdm[7]; // LKSDM 8
    }

    // Default LKSDM 1 jika tidak ada kata kunci spesifik
    return allLksdm[0];
  }
}
