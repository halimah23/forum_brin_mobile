class AnswerModel {
  final int? id;
  final int questionId;
  final String? userId;
  final String penjawabNama;
  final String penjawabRole;
  final String? senderRoleType; // pegawai, admin_lksdm, admin_pusat, ketua_tim, system
  final String isiJawaban;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? senderPhotoUrl;
  final String? senderEmail;
  final String? senderJabatan;
  final String? senderUnit;
  final String? senderLksdm;
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
    this.attachmentName,
    this.senderPhotoUrl,
    this.senderEmail,
    this.senderJabatan,
    this.senderUnit,
    this.senderLksdm,
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

  bool get isResolutionEvent {
    final text = isiJawaban.toLowerCase();
    return text.contains('pegawai mengonfirmasi bahwa pertanyaan sudah terjawab') ||
        text.contains('sudah terjawab dengan tuntas') ||
        text.contains('pertanyaan sudah terjawab') ||
        (text.contains('pegawai mengonfirmasi') && text.contains('terjawab'));
  }

  bool get isSystemEvent =>
      senderRoleType == 'system' ||
      senderRoleType == 'system_event' ||
      penjawabRole.toLowerCase() == 'sistem' ||
      penjawabRole.toLowerCase() == 'system' ||
      isResolutionEvent;

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
    final rawRole = json['sender_role']?.toString() ??
        json['sender_role_type']?.toString() ??
        json['penjawab_role']?.toString() ??
        'pegawai';

    String formattedRole;
    if (rawRole == 'admin_lksdm') {
      formattedRole = 'Staf Admin LKSDM';
    } else if (rawRole == 'admin_pusat') {
      formattedRole = 'Staf Admin Pusat';
    } else if (rawRole == 'ketua_tim') {
      formattedRole = 'Ketua Tim';
    } else if (rawRole == 'system' || rawRole == 'system_event') {
      formattedRole = 'Sistem';
    } else if (rawRole == 'pegawai') {
      formattedRole = 'Pegawai';
    } else {
      formattedRole = rawRole;
    }

    return AnswerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      questionId: json['question_id'] is int
          ? json['question_id']
          : int.parse(json['question_id']?.toString() ?? '0'),
      userId: json['user_id']?.toString(),
      penjawabNama: json['sender_name']?.toString() ??
          json['penjawab_nama']?.toString() ??
          'Pengguna',
      penjawabRole: formattedRole,
      senderRoleType: rawRole,
      isiJawaban: json['isi_pesan']?.toString() ??
          json['isi_jawaban']?.toString() ??
          '-',
      attachmentUrl: json['attachment_url']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
      senderPhotoUrl: json['sender_photo_url']?.toString() ??
          json['photo_url']?.toString() ??
          json['avatar_url']?.toString(),
      senderEmail: json['sender_email']?.toString() ?? json['email']?.toString(),
      senderJabatan: json['sender_jabatan']?.toString() ?? json['jabatan']?.toString(),
      senderUnit: json['sender_unit']?.toString() ??
          json['unit']?.toString() ??
          json['satuan_kerja']?.toString(),
      senderLksdm: json['sender_lksdm']?.toString() ??
          json['lksdm']?.toString() ??
          json['kawasan']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    String dbRole = senderRoleType ?? 'pegawai';
    final roleLow = penjawabRole.toLowerCase();
    if (roleLow.contains('lksdm')) {
      dbRole = 'admin_lksdm';
    } else if (roleLow.contains('pusat')) {
      dbRole = 'admin_pusat';
    } else if (roleLow.contains('ketua')) {
      dbRole = 'ketua_tim';
    } else if (roleLow.contains('sistem') || roleLow.contains('system')) {
      dbRole = 'system';
    }

    return {
      if (id != null) 'id': id,
      'question_id': questionId,
      if (userId != null) 'user_id': userId,
      'sender_name': penjawabNama,
      'sender_role': dbRole,
      'isi_pesan': isiJawaban,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      if (attachmentName != null) 'attachment_name': attachmentName,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  AnswerModel copyWith({
    int? id,
    int? questionId,
    String? userId,
    String? penjawabNama,
    String? penjawabRole,
    String? senderRoleType,
    String? isiJawaban,
    String? attachmentUrl,
    String? attachmentName,
    String? senderPhotoUrl,
    String? senderEmail,
    String? senderJabatan,
    String? senderUnit,
    String? senderLksdm,
    String? createdAt,
  }) {
    return AnswerModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      userId: userId ?? this.userId,
      penjawabNama: penjawabNama ?? this.penjawabNama,
      penjawabRole: penjawabRole ?? this.penjawabRole,
      senderRoleType: senderRoleType ?? this.senderRoleType,
      isiJawaban: isiJawaban ?? this.isiJawaban,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      senderEmail: senderEmail ?? this.senderEmail,
      senderJabatan: senderJabatan ?? this.senderJabatan,
      senderUnit: senderUnit ?? this.senderUnit,
      senderLksdm: senderLksdm ?? this.senderLksdm,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
