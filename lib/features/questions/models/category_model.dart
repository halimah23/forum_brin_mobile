class CategoryModel {
  final int id;
  final String nama;
  final String? kode;
  final String? teamName;

  const CategoryModel({
    required this.id,
    required this.nama,
    this.kode,
    this.teamName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      nama: json['nama']?.toString() ?? json['name']?.toString() ?? '-',
      kode: json['kode']?.toString(),
      teamName: json['team_nama']?.toString() ?? json['teamName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
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
