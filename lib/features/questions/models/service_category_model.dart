class ServiceCategoryModel {
  final int id;
  final String nama;
  final String kode;
  final String? deskripsi;
  final bool isActive;
  final int sortOrder;

  const ServiceCategoryModel({
    required this.id,
    required this.nama,
    required this.kode,
    this.deskripsi,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nama: json['nama']?.toString() ?? json['name']?.toString() ?? '-',
      kode: json['kode']?.toString() ?? json['code']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString() ?? json['description']?.toString(),
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : (json['is_active']?.toString().toLowerCase() != 'false'),
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'kode': kode,
      if (deskripsi != null) 'deskripsi': deskripsi,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceCategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServiceCategoryModel(id: $id, nama: $nama, kode: $kode)';
}
