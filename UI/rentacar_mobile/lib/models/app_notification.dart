import 'package:json_annotation/json_annotation.dart';

part 'app_notification.g.dart';

@JsonSerializable(createToJson: false)
class AppNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  AppNotification asRead() =>
      AppNotification(id: id, title: title, message: message, isRead: true, createdAt: createdAt);

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
}
