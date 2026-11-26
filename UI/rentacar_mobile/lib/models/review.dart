import 'package:json_annotation/json_annotation.dart';

part 'review.g.dart';

@JsonSerializable(createToJson: false)
class Review {
  final int id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String userFullName;

  Review({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.userFullName,
  });

  String get authorName {
    final parts = userFullName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return userFullName.trim();
    }
    return '${parts.first} ${parts.last[0]}.';
  }

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
}
