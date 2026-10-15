class NotificationModel {
  final int? id;
  final String userId;
  final int? questionId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? createdAt;

  const NotificationModel({
    this.id,
    required this.userId,
    this.questionId,
    required this.title,
    required this.message,
    this.type = 'status_update',
    this.isRead = false,
    this.createdAt,
  });

  DateTime? get createdDateTime =>
      createdAt != null ? DateTime.tryParse(createdAt!) : null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['user_id']?.toString() ?? '',
      questionId: json['question_id'] is int
          ? json['question_id']
          : int.tryParse(json['question_id']?.toString() ?? ''),
      title: json['title']?.toString() ?? 'Pemberitahuan Layanan',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'status_update',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (questionId != null) 'question_id': questionId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? userId,
    int? questionId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    String? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
