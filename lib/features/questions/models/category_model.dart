class CategoryModel {
  final int id;
  final String? idTusi;
  final String nama;
  final String? kode;
  final String? teamName;

  const CategoryModel({
    required this.id,
    this.idTusi,
    required this.nama,
    this.kode,
    this.teamName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawIdTusi = json['id_tusi']?.toString() ?? json['id']?.toString();
    final parsedIntId = json['id'] is int
        ? json['id'] as int
        : (int.tryParse(json['id']?.toString() ?? '') ??
            int.tryParse(json['id_tusi']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ??
            0);

    return CategoryModel(
      id: parsedIntId,
      idTusi: rawIdTusi,
      nama: json['tugas_fungsi']?.toString() ??
          json['nama']?.toString() ??
          json['name']?.toString() ??
          '-',
      kode: json['kode']?.toString() ?? json['id_tusi']?.toString(),
      teamName: json['detail_nama_tim']?.toString() ??
          json['team_nama']?.toString() ??
          json['tim']?.toString() ??
          json['teamName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (idTusi != null) 'id_tusi': idTusi,
      'nama': nama,
      'tugas_fungsi': nama,
      if (kode != null) 'kode': kode,
      if (teamName != null) 'team_nama': teamName,
    };
  }

  String get fullDisplayName {
    if (kode != null && kode!.isNotEmpty) {
      return '$kode - $nama';
    }
    return nama;
  }
}
