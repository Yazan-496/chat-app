import 'package:uuid/uuid.dart';
import 'package:my_chat_app/data/relationship_repository.dart';
import 'package:my_chat_app/model/user_relationship.dart';
import 'package:my_chat_app/services/database_service.dart';

class RelationshipService {
  final RelationshipRepository _relationshipRepository;
  final Uuid _uuid;

  RelationshipService({
    RelationshipRepository? relationshipRepository,
    Uuid? uuid,
  })  : _relationshipRepository =
            relationshipRepository ?? RelationshipRepository(),
        _uuid = uuid ?? const Uuid();

  Stream<List<UserRelationship>> streamForUser(String userId) {
    return _relationshipRepository.streamForUser(userId);
  }

  Future<UserRelationship> sendRequest({
    required String requesterId,
    required String receiverId,
    RelationshipType type = RelationshipType.friend,
  }) {
    final now = DateTime.now().toUtc();
    final relationship = UserRelationship(
      id: _uuid.v4(),
      requesterId: requesterId,
      receiverId: receiverId,
      type: type,
      status: RelationshipStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    return _sendRequestOfflineFirst(relationship);
  }

  Future<String> acceptRequest(String relationshipId) async {
    final updated = await _prepareStatusUpdate(
      relationshipId,
      RelationshipStatus.accepted,
    );
    if (updated == null) {
      return relationshipId;
    }
    final changeId = await DatabaseService.enqueueRelationshipChange(
      updated,
      action: 'update',
    );
    try {
      final result =
          await _relationshipRepository.acceptRelationship(relationshipId);
      await DatabaseService.saveRelationships([updated]);
      await DatabaseService.removePendingChange(changeId);
      return result;
    } catch (_) {
      return relationshipId;
    }
  }

  Future<void> rejectRequest(String relationshipId) async {
    final updated = await _prepareStatusUpdate(
      relationshipId,
      RelationshipStatus.rejected,
    );
    if (updated == null) {
      return;
    }
    final changeId = await DatabaseService.enqueueRelationshipChange(
      updated,
      action: 'update',
    );
    try {
      await _relationshipRepository.updateStatus(
        relationshipId,
        RelationshipStatus.rejected,
      );
      await DatabaseService.saveRelationships([updated]);
      await DatabaseService.removePendingChange(changeId);
    } catch (_) {}
  }

  Future<void> blockUser(String relationshipId) async {
    final updated = await _prepareStatusUpdate(
      relationshipId,
      RelationshipStatus.blocked,
    );
    if (updated == null) {
      return;
    }
    final changeId = await DatabaseService.enqueueRelationshipChange(
      updated,
      action: 'update',
    );
    try {
      await _relationshipRepository.updateStatus(
        relationshipId,
        RelationshipStatus.blocked,
      );
      await DatabaseService.saveRelationships([updated]);
      await DatabaseService.removePendingChange(changeId);
    } catch (_) {}
  }

  Future<UserRelationship> _sendRequestOfflineFirst(
    UserRelationship relationship,
  ) async {
    await DatabaseService.saveRelationships([relationship], pendingSync: true);
    final changeId = await DatabaseService.enqueueRelationshipChange(
      relationship,
      action: 'create',
    );
    try {
      final created = await _relationshipRepository.create(relationship);
      await DatabaseService.saveRelationships([created]);
      await DatabaseService.removePendingChange(changeId);
      return created;
    } catch (_) {
      return relationship;
    }
  }

  Future<UserRelationship?> _prepareStatusUpdate(
    String relationshipId,
    RelationshipStatus status,
  ) async {
    final now = DateTime.now().toUtc();
    final existing = await DatabaseService.getRelationship(relationshipId);
    if (existing == null) {
      return null;
    }
    return existing.copyWith(status: status, updatedAt: now);
  }
}
