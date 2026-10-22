import '../../auth/models/user_model.dart';
import '../../auth/models/user_role.dart';
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
  final String? originalJudul;
  final String? originalIsi;
  final bool isAnonymized;
  final String? attachmentUrl;
  final String? attachmentName;
  final int? rating;
  final String? ratingFeedback;
  final String? ratingSubmittedAt;
  final String? ratingTags;
  final String? resolvedAt;

  List<String> get ratingTagsList =>
      ratingTags?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];

  String? get lksdmKawasan => lksdmWilayah;
  String? get escalatedToTeam => targetTimPusat;
  UserModel? get author => user;
  String? get userId => user?.id;

  TicketStatus get ticketStatus => TicketStatus.fromString(status);
  bool get isClosed => ticketStatus.isClosed;
  bool get isActive => ticketStatus.isActive;

  /// Penanda apakah pertanyaan telah dibakukan dari teks aslinya
  bool get isStandardized =>
      (originalJudul != null && originalJudul!.isNotEmpty && originalJudul != judul) ||
      (originalIsi != null && originalIsi!.isNotEmpty && originalIsi != isi);

  /// Nama yang ditampilkan di ruang publik (disamarkan menjadi Pegawai demi privasi saat dipublikasikan)
  String get displayAuthorName {
    if (isAnonymized || isPublic) {
      return 'Pegawai';
    }
    return user?.name ?? 'Pegawai';
  }

  /// Nama asli untuk kebutuhan inspeksi audit internal Superadmin
  String get auditAuthorName => user?.name ?? 'Pegawai';

  /// Asal LKSDM Kawasan tempat pengaju mengajukan pertanyaan atau unit kerjanya
  String get authorAsalLksdm {
    if (lksdmKawasan != null && lksdmKawasan!.isNotEmpty) return lksdmKawasan!;
    if (lksdmWilayah != null && lksdmWilayah!.isNotEmpty) return lksdmWilayah!;
    if (user?.lksdm != null && user!.lksdm!.isNotEmpty) return user!.lksdm!;
    if (user?.effectiveLksdm != null && user!.effectiveLksdm.isNotEmpty) return user!.effectiveLksdm;
    return 'Layanan Kawasan SDM';
  }

  /// Nama lengkap pegawai pengaju untuk peran staf/manajemen (Staf LKSDM, Staf Pusat, Ketua Tim, Eksekutif, Superadmin)
  String get officialAuthorName => user?.name ?? 'Pegawai BRIN';

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
    this.isAnonymized = false,
    this.originalJudul,
    this.originalIsi,
    this.user,
    this.tugasFungsi,
    this.answers,
    this.createdAt,
    this.attachmentUrl,
    this.attachmentName,
    this.rating,
    this.ratingFeedback,
    this.ratingSubmittedAt,
    this.ratingTags,
    this.resolvedAt,
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

  DateTime? get createdDateTime =>
      createdAt != null ? DateTime.tryParse(createdAt!) : null;

  DateTime? get resolvedDateTime =>
      resolvedAt != null ? DateTime.tryParse(resolvedAt!) : null;

  /// SLA standar adalah 48 jam kerja
  int get slaDurationHours => 48;

  /// Durasi yang telah berjalan sejak tiket dibuat hingga sekarang (atau hingga selesai jika sudah closed)
  Duration get durationWorked {
    final start = createdDateTime ?? DateTime.now();
    final end = (isClosed && resolvedDateTime != null)
        ? resolvedDateTime!
        : DateTime.now();
    return end.isAfter(start) ? end.difference(start) : Duration.zero;
  }

  /// Sisa waktu sebelum batas SLA 48 jam terlewati
  Duration get remainingSlaDuration {
    final start = createdDateTime ?? DateTime.now();
    final deadline = start.add(Duration(hours: slaDurationHours));
    final now = DateTime.now();
    return deadline.isAfter(now) ? deadline.difference(now) : Duration.zero;
  }

  /// Apakah tiket telah melampaui batas SLA 48 jam
  bool get isSlaBreached {
    return durationWorked.inHours >= slaDurationHours;
  }

  /// Mengembalikan nama tampilan penanya berdasarkan hak akses viewer (currentUser):
  /// - Jika penanya adalah diri sendiri: Tampilkan nama asli + '(Anda)'
  /// - Jika penanya adalah pegawai lain dan pertanyaan telah di-up / publik: Sembunyikan nama ('Pegawai BRIN')
  /// - Jika penanya dilihat oleh Staf/Manajemen (Admin, Superadmin, Ketua Tim): Tampilkan nama asli untuk verifikasi
  String getAuthorDisplayName(UserModel? currentUser) {
    final String rawName = user?.name ?? 'Pegawai BRIN';

    if (currentUser == null) {
      return isPublic ? 'Pegawai BRIN' : rawName;
    }

    // 1. Jika dilihat oleh Petugas / Manajemen (Admin LKSDM, Admin Pusat, Super Admin, Ketua Tim, Eksekutif)
    final bool isStaffOrOfficer = currentUser.isAdminLksdm ||
        currentUser.isAdminPusat ||
        currentUser.isSuperAdmin ||
        currentUser.isEksekutif ||
        currentUser.userRole == UserRole.admin ||
        currentUser.userRole == UserRole.ketuaTim ||
        currentUser.userRole == UserRole.superAdmin;

    if (isStaffOrOfficer) {
      return rawName;
    }

    // 2. Jika dilihat oleh Penanya Sendiri (Diri Sendiri)
    final bool isSelf = (user?.id != null && currentUser.id != null && user!.id.toString() == currentUser.id.toString()) ||
        (user?.name != null && currentUser.name.isNotEmpty && user!.name.trim().toLowerCase() == currentUser.name.trim().toLowerCase());

    if (isSelf) {
      return '$rawName (Anda)';
    }

    // 3. Jika penanya adalah Pegawai Lain dan pertanyaan bersifat publik / di-up superadmin
    return 'Pegawai BRIN';
  }

  /// Inisial avatar penanya sesuai dengan nama tampilan
  String getAuthorInitial(UserModel? currentUser) {
    final displayName = getAuthorDisplayName(currentUser);
    if (displayName.startsWith('Pegawai BRIN')) return 'P';
    if (displayName.isNotEmpty) return displayName[0].toUpperCase();
    return 'P';
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    UserModel? author;
    if (json['users'] is Map<String, dynamic>) {
      author = UserModel.fromJson(Map<String, dynamic>.from(json['users']));
    } else if (json['author'] is Map<String, dynamic>) {
      author = UserModel.fromJson(Map<String, dynamic>.from(json['author']));
    } else if (json['profiles'] is Map<String, dynamic>) {
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
    } else if (json['tugas_fungsi'] is Map) {
      categories = [
        CategoryModel.fromJson(Map<String, dynamic>.from(json['tugas_fungsi']))
      ];
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

    final int? parsedRating = json['rating'] is int
        ? json['rating']
        : int.tryParse(json['rating']?.toString() ?? '');

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
      isAnonymized: json['is_anonymized'] == true || json['is_anonymized'] == 1,
      originalJudul: json['original_judul']?.toString(),
      originalIsi: json['original_isi']?.toString(),
      user: author,
      tugasFungsi: categories,
      answers: answersList,
      createdAt: json['created_at']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
      rating: parsedRating,
      ratingFeedback: json['rating_feedback']?.toString(),
      ratingSubmittedAt: json['rating_submitted_at']?.toString(),
      ratingTags: json['rating_tags']?.toString(),
      resolvedAt: json['resolved_at']?.toString(),
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
      'is_anonymized': isAnonymized,
      if (originalJudul != null) 'original_judul': originalJudul,
      if (originalIsi != null) 'original_isi': originalIsi,
      'user': user?.toJson(),
      'tugas_fungsi': tugasFungsi?.map((c) => c.toJson()).toList(),
      'answers': answers?.map((a) => a.toJson()).toList(),
      'created_at': createdAt,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'rating': rating,
      'rating_feedback': ratingFeedback,
      'rating_submitted_at': ratingSubmittedAt,
      'rating_tags': ratingTags,
      'resolved_at': resolvedAt,
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
    bool? isAnonymized,
    String? originalJudul,
    String? originalIsi,
    UserModel? user,
    List<CategoryModel>? tugasFungsi,
    List<AnswerModel>? answers,
    String? createdAt,
    String? attachmentUrl,
    String? attachmentName,
    int? rating,
    String? ratingFeedback,
    String? ratingSubmittedAt,
    String? ratingTags,
    String? resolvedAt,
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
      isAnonymized: isAnonymized ?? this.isAnonymized,
      originalJudul: originalJudul ?? this.originalJudul,
      originalIsi: originalIsi ?? this.originalIsi,
      user: user ?? this.user,
      tugasFungsi: tugasFungsi ?? this.tugasFungsi,
      answers: answers ?? this.answers,
      createdAt: createdAt ?? this.createdAt,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      rating: rating ?? this.rating,
      ratingFeedback: ratingFeedback ?? this.ratingFeedback,
      ratingSubmittedAt: ratingSubmittedAt ?? this.ratingSubmittedAt,
      ratingTags: ratingTags ?? this.ratingTags,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
