class BroadcastRecipientModel {
  final int id;
  final String broadcastId;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? userUnit;
  final bool isRead;
  final String? readAt;
  final String? createdAt;

  const BroadcastRecipientModel({
    required this.id,
    required this.broadcastId,
    required this.userId,
    this.userName,
    this.userEmail,
    this.userUnit,
    this.isRead = false,
    this.readAt,
    this.createdAt,
  });

  DateTime? get readDateTime =>
      readAt != null ? DateTime.tryParse(readAt!) : null;

  factory BroadcastRecipientModel.fromJson(Map<String, dynamic> json) {
    String? name;
    String? email;
    String? unit;

    if (json['users'] is Map) {
      final u = json['users'] as Map;
      name = u['first_name']?.toString() ?? u['name']?.toString();
      email = u['email']?.toString();
      unit = u['satuan_kerja']?.toString() ?? u['unit']?.toString();
    }

    return BroadcastRecipientModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      broadcastId: json['broadcast_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: name ?? json['user_name']?.toString(),
      userEmail: email ?? json['user_email']?.toString(),
      userUnit: unit ?? json['user_unit']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      readAt: json['read_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'broadcast_id': broadcastId,
      'user_id': userId,
      'is_read': isRead,
      'read_at': readAt,
      'created_at': createdAt,
    };
  }
}
