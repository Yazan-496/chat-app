import 'package:cloud_firestore/cloud_firestore.dart';
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
      id: data['id'] as String,
      userId1: data['userId1'] as String,
      userId2: data['userId2'] as String,
      type: RelationshipType.values.firstWhere(
          (e) => e.toString() == 'RelationshipType.' + data['type'] as String,
          orElse: () => RelationshipType.none),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId1': userId1,
      'userId2': userId2,
      'type': type.toString().split('.').last,
      'createdAt': createdAt,
    };
  }
}
