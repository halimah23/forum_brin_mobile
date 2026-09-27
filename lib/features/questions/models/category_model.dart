class CategoryModel {
  final int id;
  final String nama;

  const CategoryModel({
    required this.id,
    required this.nama,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nama: json['nama']?.toString() ?? json['name']?.toString() ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
    };
  }
}
