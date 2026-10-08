import '../../auth/models/user_model.dart';
import 'answer_model.dart';
import 'category_model.dart';
import 'ticket_status.dart';

class QuestionModel {
  final int? id;
  final String? ticketNumber;
  final String judul;
  final String isi;
  final String status;
  final String? lksdmWilayah;
  final String? targetTimPusat;
  final String? targetTim;
  final String? adminLksdmId;
  final String? adminPusatId;
  final String? assignedTo;
  final String? tugasFungsiNama;
  final bool isPublic;
  final bool isPinned;
  final UserModel? user;
  final List<CategoryModel>? tugasFungsi;
  final List<AnswerModel>? answers;
  final String? createdAt;

  String? get lksdmKawasan => lksdmWilayah;
  String? get escalatedToTeam => targetTimPusat;

  TicketStatus get ticketStatus => TicketStatus.fromString(status);
  bool get isClosed => ticketStatus.isClosed;
  bool get isActive => ticketStatus.isActive;

  const QuestionModel({
    this.id,
    this.ticketNumber,
    required this.judul,
    required this.isi,
    required this.status,
    String? lksdmWilayah,
    String? lksdmKawasan,
    String? targetTimPusat,
    String? escalatedToTeam,
    this.targetTim,
    this.adminLksdmId,
    this.adminPusatId,
    this.assignedTo,
    this.tugasFungsiNama,
    this.isPublic = true,
    this.isPinned = false,
    this.user,
    this.tugasFungsi,
    this.answers,
    this.createdAt,
  })  : lksdmWilayah = lksdmWilayah ?? lksdmKawasan,
        targetTimPusat = targetTimPusat ?? escalatedToTeam;

  bool get isEscalated =>
      status == 'dialihkan_ke_pusat' ||
      status == 'eskalasi_pusat' ||
      adminPusatId != null;

  bool get isWaitingConfirmation =>
      status == 'ditangani_lksdm' || status == 'menunggu_konfirmasi_pegawai';

  String get effectiveTargetTim =>
      targetTimPusat ?? targetTim ?? 'Layanan Kawasan SDM';

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
        if (item is Map &&
            item.containsKey('tugas_fungsi') &&
            item['tugas_fungsi'] is Map) {
          return CategoryModel.fromJson(
              Map<String, dynamic>.from(item['tugas_fungsi']));
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

    final int? parsedId =
        json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    final String generatedTicketNumber = json['ticket_number']?.toString() ??
        (parsedId != null ? 'TKT-${parsedId.toString().padLeft(4, '0')}' : 'TKT-NEW');

    final lksdmVal = json['lksdm_kawasan']?.toString() ??
        json['lksdm_wilayah']?.toString() ??
        json['lksdm']?.toString() ??
        'Layanan Kawasan SDM 1 : Thamrin I';

    final targetPusatVal = json['target_tim_pusat']?.toString() ??
        json['escalated_to_team']?.toString() ??
        json['target_tim']?.toString();

    return QuestionModel(
      id: parsedId,
      ticketNumber: generatedTicketNumber,
      judul: json['judul']?.toString() ?? '-',
      isi: json['isi']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'menunggu_lksdm',
      lksdmWilayah: lksdmVal,
      targetTimPusat: targetPusatVal,
      targetTim: json['target_tim']?.toString() ?? targetPusatVal ?? lksdmVal,
      adminLksdmId: json['admin_lksdm_id']?.toString(),
      adminPusatId: json['admin_pusat_id']?.toString(),
      assignedTo: json['assigned_to']?.toString() ?? json['assignedTo']?.toString(),
      tugasFungsiNama: json['tugas_fungsi_nama']?.toString(),
      isPublic: json['is_public'] == true || json['is_public'] == 1,
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1,
      user: author,
      tugasFungsi: categories,
      answers: answersList,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ticket_number': ticketNumber,
      'judul': judul,
      'isi': isi,
      'status': status,
      'lksdm_kawasan': lksdmWilayah,
      'lksdm_wilayah': lksdmWilayah,
      'target_tim_pusat': targetTimPusat,
      'target_tim': targetTim,
      'admin_lksdm_id': adminLksdmId,
      'admin_pusat_id': adminPusatId,
      'assigned_to': assignedTo,
      'tugas_fungsi_nama': tugasFungsiNama,
      'is_public': isPublic,
      'is_pinned': isPinned,
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
    String? lksdmWilayah,
    String? lksdmKawasan,
    String? targetTimPusat,
    String? escalatedToTeam,
    String? targetTim,
    String? adminLksdmId,
    String? adminPusatId,
    String? assignedTo,
    String? tugasFungsiNama,
    bool? isPublic,
    bool? isPinned,
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
      lksdmWilayah: lksdmWilayah ?? lksdmKawasan ?? this.lksdmWilayah,
      targetTimPusat: targetTimPusat ?? escalatedToTeam ?? this.targetTimPusat,
      targetTim: targetTim ?? this.targetTim,
      adminLksdmId: adminLksdmId ?? this.adminLksdmId,
      adminPusatId: adminPusatId ?? this.adminPusatId,
      assignedTo: assignedTo ?? this.assignedTo,
      tugasFungsiNama: tugasFungsiNama ?? this.tugasFungsiNama,
      isPublic: isPublic ?? this.isPublic,
      isPinned: isPinned ?? this.isPinned,
      user: user ?? this.user,
      tugasFungsi: tugasFungsi ?? this.tugasFungsi,
      answers: answers ?? this.answers,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
