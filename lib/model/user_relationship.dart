enum RelationshipType {
  friend,
  lover,
}

enum RelationshipStatus {
  pending,
  accepted,
  rejected,
  blocked,
}

extension RelationshipTypeJson on RelationshipType {
  String toJson() {
    switch (this) {
      case RelationshipType.friend:
        return 'FRIEND';
      case RelationshipType.lover:
        return 'LOVER';
    }
  }

  static RelationshipType fromJson(String? value) {
    switch (value?.toUpperCase()) {
      case 'LOVER':
        return RelationshipType.lover;
      case 'FRIEND':
      default:
        return RelationshipType.friend;
    }
  }
}

extension RelationshipStatusJson on RelationshipStatus {
  String toJson() {
    switch (this) {
      case RelationshipStatus.pending:
        return 'PENDING';
      case RelationshipStatus.accepted:
        return 'ACCEPTED';
      case RelationshipStatus.rejected:
        return 'REJECTED';
      case RelationshipStatus.blocked:
        return 'BLOCKED';
    }
  }

  static RelationshipStatus fromJson(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACCEPTED':
        return RelationshipStatus.accepted;
      case 'REJECTED':
        return RelationshipStatus.rejected;
      case 'BLOCKED':
        return RelationshipStatus.blocked;
      case 'PENDING':
      default:
        return RelationshipStatus.pending;
    }
  }
}

DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

class UserRelationship {
  final String id;
  final String requesterId;
  final String receiverId;
  final RelationshipType type;
  final RelationshipStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserRelationship({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    this.type = RelationshipType.friend,
    this.status = RelationshipStatus.pending,
    this.createdAt,
    this.updatedAt,
  });

  factory UserRelationship.fromMap(Map<String, dynamic> data) {
    return UserRelationship(
      id: data['id'] as String? ?? '',
      requesterId: data['requester_id'] as String? ?? '',
      receiverId: data['receiver_id'] as String? ?? '',
      type: RelationshipTypeJson.fromJson(data['type'] as String?),
      status: RelationshipStatusJson.fromJson(data['status'] as String?),
      createdAt: _parseDateTime(data['created_at']?.toString()),
      updatedAt: _parseDateTime(data['updated_at']?.toString()),
    );
  }

  factory UserRelationship.fromJson(Map<String, dynamic> json) {
    return UserRelationship.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requester_id': requesterId,
      'receiver_id': receiverId,
      'type': type.toJson(),
      'status': status.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  UserRelationship copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    RelationshipType? type,
    RelationshipStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserRelationship(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
