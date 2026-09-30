class AnswerModel {
  final int? id;
  final int questionId;
  final String? userId;
  final String penjawabNama;
  final String penjawabRole;
  final String isiJawaban;
  final String? createdAt;

  const AnswerModel({
    this.id,
    required this.questionId,
    this.userId,
    required this.penjawabNama,
    this.penjawabRole = 'Tim Layanan SDM BRIN',
    required this.isiJawaban,
    this.createdAt,
  });

  bool get isOfficial {
    final role = penjawabRole.toLowerCase();
    return role.contains('tim') ||
        role.contains('ketua') ||
        role.contains('admin') ||
        role.contains('analis') ||
        role.contains('verifikator');
  }

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      questionId: json['question_id'] is int
          ? json['question_id']
          : int.parse(json['question_id']?.toString() ?? '0'),
      userId: json['user_id']?.toString(),
      penjawabNama: json['penjawab_nama']?.toString() ?? 'Tim Layanan SDM',
      penjawabRole: json['penjawab_role']?.toString() ?? 'Tim Layanan SDM BRIN',
      isiJawaban: json['isi_jawaban']?.toString() ?? '-',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'question_id': questionId,
      if (userId != null) 'user_id': userId,
      'penjawab_nama': penjawabNama,
      'penjawab_role': penjawabRole,
      'isi_jawaban': isiJawaban,
      'created_at': createdAt,
    };
  }
}
