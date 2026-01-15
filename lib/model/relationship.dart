import 'package:flutter/material.dart';

enum RelationshipType {
  none,
  friend,
  blocked,
  pending,
}

extension RelationshipExtension on RelationshipType {
  Color get primaryColor {
    switch (this) {
      case RelationshipType.friend:
        return Colors.blue;
      case RelationshipType.blocked:
        return Colors.red;
      case RelationshipType.pending:
        return Colors.orange;
      case RelationshipType.none:
      default:
        return Colors.grey;
    }
  }

  Color get textColor {
    switch (this) {
      case RelationshipType.friend:
        return Colors.blue.shade700;
      case RelationshipType.blocked:
        return Colors.red.shade700;
      case RelationshipType.pending:
        return Colors.orange.shade700;
      case RelationshipType.none:
      default:
        return Colors.grey.shade700;
    }
  }
}

class Relationship {
  final String id;
  final String userId1;
  final String userId2;
  RelationshipType type;
  final DateTime createdAt;

  Relationship({
    required this.id,
    required this.userId1,
    required this.userId2,
    this.type = RelationshipType.none,
    required this.createdAt,
  });

  factory Relationship.fromMap(Map<String, dynamic> data) {
    return Relationship(
      id: data['id'] as String? ?? '',
      userId1: data['user_id1'] as String? ?? '',
      userId2: data['user_id2'] as String? ?? '',
      type: RelationshipType.values.firstWhere(
          (e) => e.name == (data['type'] as String? ?? 'none'),
          orElse: () => RelationshipType.none),
      createdAt: data['created_at'] != null 
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id1': userId1,
      'user_id2': userId2,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
