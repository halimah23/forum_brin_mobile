class BroadcastModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String lksdmScope;
  final String title;
  final String content;
  final String priority; // 'normal' | 'urgent'
  final String targetType; // 'all_lksdm' | 'unit_filter' | 'custom_users'
  final String? targetFilterValue;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentSize;
  final String? createdAt;
  final String? updatedAt;

  // Analitik / Status Keterbacaan
  final int? totalRecipients;
  final int? readCount;
  final bool isReadByMe;

  const BroadcastModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.lksdmScope,
    required this.title,
    required this.content,
    this.priority = 'normal',
    this.targetType = 'all_lksdm',
    this.targetFilterValue,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.createdAt,
    this.updatedAt,
    this.totalRecipients,
    this.readCount,
    this.isReadByMe = false,
  });

  bool get isUrgent => priority.toLowerCase() == 'urgent';
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;
  DateTime? get createdDateTime =>
      createdAt != null ? DateTime.tryParse(createdAt!) : null;

  factory BroadcastModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    int? totalRecipients,
    int? readCount,
    bool? isReadByMe,
  }) {
    bool readByCurrentUser = isReadByMe ?? false;

    // Jika Supabase join data relasi `broadcast_recipients`
    if (json['broadcast_recipients'] is List) {
      final list = json['broadcast_recipients'] as List;
      totalRecipients ??= list.length;
      readCount ??= list.where((r) => r['is_read'] == true).length;
      if (currentUserId != null) {
        final myRecord = list.firstWhere(
          (r) =>
              (r['user_id']?.toString().toLowerCase() ?? '') ==
              currentUserId.toLowerCase(),
          orElse: () => null,
        );
        if (myRecord != null) {
          readByCurrentUser = myRecord['is_read'] == true;
        }
      }
    }

    return BroadcastModel(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'Pengelola LKSDM',
      senderRole: json['sender_role']?.toString() ?? 'Admin LKSDM',
      lksdmScope: json['lksdm_scope']?.toString() ?? 'LKSDM 1',
      title: json['title']?.toString() ?? 'Pengumuman LKSDM',
      content: json['content']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'normal',
      targetType: json['target_type']?.toString() ?? 'all_lksdm',
      targetFilterValue: json['target_filter_value']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
      attachmentSize: json['attachment_size']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      totalRecipients: totalRecipients ??
          (json['total_recipients'] is int
              ? json['total_recipients']
              : int.tryParse(json['total_recipients']?.toString() ?? '')),
      readCount: readCount ??
          (json['read_count'] is int
              ? json['read_count']
              : int.tryParse(json['read_count']?.toString() ?? '')),
      isReadByMe: json['is_read'] == true || readByCurrentUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'lksdm_scope': lksdmScope,
      'title': title,
      'content': content,
      'priority': priority,
      'target_type': targetType,
      'target_filter_value': targetFilterValue,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'attachment_size': attachmentSize,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  BroadcastModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? lksdmScope,
    String? title,
    String? content,
    String? priority,
    String? targetType,
    String? targetFilterValue,
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentSize,
    String? createdAt,
    String? updatedAt,
    int? totalRecipients,
    int? readCount,
    bool? isReadByMe,
  }) {
    return BroadcastModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      lksdmScope: lksdmScope ?? this.lksdmScope,
      title: title ?? this.title,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      targetType: targetType ?? this.targetType,
      targetFilterValue: targetFilterValue ?? this.targetFilterValue,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentSize: attachmentSize ?? this.attachmentSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      readCount: readCount ?? this.readCount,
      isReadByMe: isReadByMe ?? this.isReadByMe,
    );
  }
}
