class AnswerModel {
  final int? id;
  final int questionId;
  final String? userId;
  final String penjawabNama;
  final String penjawabRole;
  final String? senderRoleType; // pegawai, admin_lksdm, admin_pusat, ketua_tim, system
  final String isiJawaban;
  final String? attachmentUrl;
  final String? createdAt;

  String get senderName => penjawabNama;
  String get senderRole => penjawabRole;
  String get isiPesan => isiJawaban;

  const AnswerModel({
    this.id,
    required this.questionId,
    this.userId,
    String? penjawabNama,
    String? senderName,
    String? penjawabRole,
    String? senderRole,
    this.senderRoleType,
    String? isiJawaban,
    String? isiPesan,
    this.attachmentUrl,
    this.createdAt,
  })  : penjawabNama = penjawabNama ?? senderName ?? 'Pengguna',
        penjawabRole = penjawabRole ?? senderRole ?? 'Staf Admin LKSDM',
        isiJawaban = isiJawaban ?? isiPesan ?? '-';

  bool get isOfficial {
    final role = penjawabRole.toLowerCase();
    final type = senderRoleType?.toLowerCase() ?? '';
    return type == 'admin_lksdm' ||
        type == 'admin_pusat' ||
        type == 'ketua_tim' ||
        role.contains('tim') ||
        role.contains('ketua') ||
        role.contains('admin') ||
        role.contains('analis') ||
        role.contains('verifikator');
  }

  bool get isSystemEvent =>
      senderRoleType == 'system' ||
      senderRoleType == 'system_event' ||
      penjawabRole.toLowerCase() == 'sistem';

  bool get isAdminLksdm =>
      senderRoleType == 'admin_lksdm' ||
      penjawabRole.toLowerCase().contains('lksdm');

  bool get isAdminPusat =>
      senderRoleType == 'admin_pusat' ||
      (isOfficial && !isAdminLksdm && !isKetuaTim);

  bool get isKetuaTim =>
      senderRoleType == 'ketua_tim' ||
      penjawabRole.toLowerCase().contains('ketua');

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      questionId: json['question_id'] is int
          ? json['question_id']
          : int.parse(json['question_id']?.toString() ?? '0'),
      userId: json['user_id']?.toString(),
      penjawabNama: json['sender_name']?.toString() ??
          json['penjawab_nama']?.toString() ??
          'Staf Admin',
      penjawabRole: json['sender_role']?.toString() ??
          json['penjawab_role']?.toString() ??
          'Staf Admin LKSDM',
      senderRoleType: json['sender_role']?.toString() ??
          json['sender_role_type']?.toString(),
      isiJawaban: json['isi_pesan']?.toString() ??
          json['isi_jawaban']?.toString() ??
          '-',
      attachmentUrl: json['attachment_url']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'question_id': questionId,
      if (userId != null) 'user_id': userId,
      'sender_name': penjawabNama,
      'sender_role': senderRoleType ?? penjawabRole,
      'penjawab_nama': penjawabNama,
      'penjawab_role': penjawabRole,
      if (senderRoleType != null) 'sender_role_type': senderRoleType,
      'isi_pesan': isiJawaban,
      'isi_jawaban': isiJawaban,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      'created_at': createdAt,
    };
  }
}
