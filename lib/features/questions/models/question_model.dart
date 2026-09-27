import '../../auth/models/user_model.dart';
import 'category_model.dart';

class QuestionModel {
  final int? id;
  final String judul;
  final String isi;
  final String status;
  final bool isPublic;
  final UserModel? user;
  final List<CategoryModel>? tugasFungsi;
  final String? createdAt;

  const QuestionModel({
    this.id,
    required this.judul,
    required this.isi,
    required this.status,
    this.isPublic = true,
    this.user,
    this.tugasFungsi,
    this.createdAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    UserModel? author;
    if (json['user'] is Map<String, dynamic>) {
      author = UserModel.fromJson(Map<String, dynamic>.from(json['user']));
    } else if (json['user'] != null) {
      author = UserModel(name: json['user'].toString(), email: '');
    }

    List<CategoryModel>? categories;
    if (json['tugas_fungsi'] is List) {
      categories = (json['tugas_fungsi'] as List)
          .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return QuestionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      judul: json['judul']?.toString() ?? '-',
      isi: json['isi']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'diajukan',
      isPublic: json['is_public'] == true || json['is_public'] == 1,
      user: author,
      tugasFungsi: categories,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'isi': isi,
      'status': status,
      'is_public': isPublic,
      'user': user?.toJson(),
      'tugas_fungsi': tugasFungsi?.map((c) => c.toJson()).toList(),
      'created_at': createdAt,
    };
  }
}
