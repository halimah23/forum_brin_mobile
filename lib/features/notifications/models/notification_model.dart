import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final int? questionId;
  final bool isRead;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.questionId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      title: json['title']?.toString() ?? 'Pemberitahuan Forum',
      message: json['message']?.toString() ?? json['isi']?.toString() ?? '',
      questionId: json['question_id'] is int ? json['question_id'] : int.tryParse(json['question_id']?.toString() ?? ''),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}
