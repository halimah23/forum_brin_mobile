import '../../auth/models/user_model.dart';
import 'answer_model.dart';
import 'category_model.dart';

class QuestionModel {
  final int? id;
  final String? ticketNumber;
  final String judul;
  final String isi;
  final String status;
  final String? targetTim;
  final String? assignedTo;
  final String? tugasFungsiNama;
  final bool isPublic;
  final UserModel? user;
  final List<CategoryModel>? tugasFungsi;
  final List<AnswerModel>? answers;
  final String? createdAt;

  const QuestionModel({
    this.id,
    this.ticketNumber,
    required this.judul,
    required this.isi,
    required this.status,
    this.targetTim,
    this.assignedTo,
    this.tugasFungsiNama,
    this.isPublic = true,
    this.user,
    this.tugasFungsi,
    this.answers,
    this.createdAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    UserModel? author;
    if (json['profiles'] is Map<String, dynamic>) {
      author = UserModel.fromJson(Map<String, dynamic>.from(json['profiles']));
    } else if (json['user'] is Map<String, dynamic>) {
      author = UserModel.fromJson(Map<String, dynamic>.from(json['user']));
    } else if (json['user'] != null) {
      author = UserModel(name: json['user'].toString(), email: '');
    }

    List<CategoryModel>? categories;
    if (json['question_tugas_fungsi'] is List) {
      categories = (json['question_tugas_fungsi'] as List).map((item) {
        if (item is Map && item.containsKey('tugas_fungsi') && item['tugas_fungsi'] is Map) {
          return CategoryModel.fromJson(Map<String, dynamic>.from(item['tugas_fungsi']));
        } else if (item is Map) {
          return CategoryModel.fromJson(Map<String, dynamic>.from(item));
        }
        return const CategoryModel(id: 0, nama: '-');
      }).toList();
    } else if (json['tugas_fungsi'] is List) {
      categories = (json['tugas_fungsi'] as List)
          .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    List<AnswerModel>? answersList;
    if (json['answers'] is List) {
      answersList = (json['answers'] as List)
          .map((item) => AnswerModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    final int? parsedId = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    final String generatedTicketNumber = json['ticket_number']?.toString() ??
        (parsedId != null ? 'TKT-${parsedId.toString().padLeft(4, '0')}' : 'TKT-NEW');

    return QuestionModel(
      id: parsedId,
      ticketNumber: generatedTicketNumber,
      judul: json['judul']?.toString() ?? '-',
      isi: json['isi']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'menunggu_disposisi',
      targetTim: json['target_tim']?.toString() ?? json['targetTim']?.toString(),
      assignedTo: json['assigned_to']?.toString() ?? json['assignedTo']?.toString(),
      tugasFungsiNama: json['tugas_fungsi_nama']?.toString(),
      isPublic: json['is_public'] == true || json['is_public'] == 1,
      user: author,
      tugasFungsi: categories,
      answers: answersList,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'judul': judul,
      'isi': isi,
      'status': status,
      'target_tim': targetTim,
      'assigned_to': assignedTo,
      'tugas_fungsi_nama': tugasFungsiNama,
      'is_public': isPublic,
      'user': user?.toJson(),
      'tugas_fungsi': tugasFungsi?.map((c) => c.toJson()).toList(),
      'answers': answers?.map((a) => a.toJson()).toList(),
      'created_at': createdAt,
    };
  }

  QuestionModel copyWith({
    int? id,
    String? ticketNumber,
    String? judul,
    String? isi,
    String? status,
    String? targetTim,
    String? assignedTo,
    String? tugasFungsiNama,
    bool? isPublic,
    UserModel? user,
    List<CategoryModel>? tugasFungsi,
    List<AnswerModel>? answers,
    String? createdAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      judul: judul ?? this.judul,
      isi: isi ?? this.isi,
      status: status ?? this.status,
      targetTim: targetTim ?? this.targetTim,
      assignedTo: assignedTo ?? this.assignedTo,
      tugasFungsiNama: tugasFungsiNama ?? this.tugasFungsiNama,
      isPublic: isPublic ?? this.isPublic,
      user: user ?? this.user,
      tugasFungsi: tugasFungsi ?? this.tugasFungsi,
      answers: answers ?? this.answers,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
