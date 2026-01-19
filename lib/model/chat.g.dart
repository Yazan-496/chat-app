// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetChatCollection on Isar {
  IsarCollection<Chat> get chats => this.collection();
}

const ChatSchema = CollectionSchema(
  name: r'Chat',
  id: -4292359458225261721,
  properties: {
    r'avatarColor': PropertySchema(
      id: 0,
      name: r'avatarColor',
      type: IsarType.long,
    ),
    r'displayName': PropertySchema(
      id: 1,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 2,
      name: r'id',
      type: IsarType.string,
    ),
    r'isActuallyOnline': PropertySchema(
      id: 3,
      name: r'isActuallyOnline',
      type: IsarType.bool,
    ),
    r'lastMessageContent': PropertySchema(
      id: 4,
      name: r'lastMessageContent',
      type: IsarType.string,
    ),
    r'lastMessageSenderId': PropertySchema(
      id: 5,
      name: r'lastMessageSenderId',
      type: IsarType.string,
    ),
    r'lastMessageStatus': PropertySchema(
      id: 6,
      name: r'lastMessageStatus',
      type: IsarType.byte,
      enumMap: _ChatlastMessageStatusEnumValueMap,
    ),
    r'lastMessageTime': PropertySchema(
      id: 7,
      name: r'lastMessageTime',
      type: IsarType.dateTime,
    ),
    r'participantIds': PropertySchema(
      id: 8,
      name: r'participantIds',
      type: IsarType.stringList,
    ),
    r'profilePictureUrl': PropertySchema(
      id: 9,
      name: r'profilePictureUrl',
      type: IsarType.string,
    ),
    r'relationshipType': PropertySchema(
      id: 10,
      name: r'relationshipType',
      type: IsarType.byte,
      enumMap: _ChatrelationshipTypeEnumValueMap,
    ),
    r'unreadCount': PropertySchema(
      id: 11,
      name: r'unreadCount',
      type: IsarType.long,
    )
  },
  estimateSize: _chatEstimateSize,
  serialize: _chatSerialize,
  deserialize: _chatDeserialize,
  deserializeProp: _chatDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _chatGetId,
  getLinks: _chatGetLinks,
  attach: _chatAttach,
  version: '3.1.0+1',
);

int _chatEstimateSize(
  Chat object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.displayName.length * 3;
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.lastMessageContent;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lastMessageSenderId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.participantIds.length * 3;
  {
    for (var i = 0; i < object.participantIds.length; i++) {
      final value = object.participantIds[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.profilePictureUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _chatSerialize(
  Chat object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.avatarColor);
  writer.writeString(offsets[1], object.displayName);
  writer.writeString(offsets[2], object.id);
  writer.writeBool(offsets[3], object.isActuallyOnline);
  writer.writeString(offsets[4], object.lastMessageContent);
  writer.writeString(offsets[5], object.lastMessageSenderId);
  writer.writeByte(offsets[6], object.lastMessageStatus.index);
  writer.writeDateTime(offsets[7], object.lastMessageTime);
  writer.writeStringList(offsets[8], object.participantIds);
  writer.writeString(offsets[9], object.profilePictureUrl);
  writer.writeByte(offsets[10], object.relationshipType.index);
  writer.writeLong(offsets[11], object.unreadCount);
}

Chat _chatDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Chat(
    avatarColor: reader.readLongOrNull(offsets[0]),
    displayName: reader.readString(offsets[1]),
    id: reader.readString(offsets[2]),
    lastMessageContent: reader.readStringOrNull(offsets[4]),
    lastMessageSenderId: reader.readStringOrNull(offsets[5]),
    lastMessageStatus:
        _ChatlastMessageStatusValueEnumMap[reader.readByteOrNull(offsets[6])] ??
            MessageStatus.sent,
    lastMessageTime: reader.readDateTime(offsets[7]),
    participantIds: reader.readStringList(offsets[8]) ?? [],
    profilePictureUrl: reader.readStringOrNull(offsets[9]),
    relationshipType:
        _ChatrelationshipTypeValueEnumMap[reader.readByteOrNull(offsets[10])] ??
            RelationshipType.none,
    unreadCount: reader.readLongOrNull(offsets[11]) ?? 0,
  );
  return object;
}

P _chatDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (_ChatlastMessageStatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          MessageStatus.sent) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readStringList(offset) ?? []) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (_ChatrelationshipTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          RelationshipType.none) as P;
    case 11:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ChatlastMessageStatusEnumValueMap = {
  'sending': 0,
  'sent': 1,
  'delivered': 2,
  'read': 3,
};
const _ChatlastMessageStatusValueEnumMap = {
  0: MessageStatus.sending,
  1: MessageStatus.sent,
  2: MessageStatus.delivered,
  3: MessageStatus.read,
};
const _ChatrelationshipTypeEnumValueMap = {
  'none': 0,
  'friend': 1,
  'blocked': 2,
  'pending': 3,
};
const _ChatrelationshipTypeValueEnumMap = {
  0: RelationshipType.none,
  1: RelationshipType.friend,
  2: RelationshipType.blocked,
  3: RelationshipType.pending,
};

Id _chatGetId(Chat object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _chatGetLinks(Chat object) {
  return [];
}

void _chatAttach(IsarCollection<dynamic> col, Id id, Chat object) {}

extension ChatByIndex on IsarCollection<Chat> {
  Future<Chat?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  Chat? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<Chat?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<Chat?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(Chat object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(Chat object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<Chat> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<Chat> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension ChatQueryWhereSort on QueryBuilder<Chat, Chat, QWhere> {
  QueryBuilder<Chat, Chat, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ChatQueryWhere on QueryBuilder<Chat, Chat, QWhereClause> {
  QueryBuilder<Chat, Chat, QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> isarIdGreaterThan(Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> isarIdLessThan(Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ChatQueryFilter on QueryBuilder<Chat, Chat, QFilterCondition> {
  QueryBuilder<Chat, Chat, QAfterFilterCondition> avatarColorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avatarColor',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> avatarColorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avatarColor',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> avatarColorEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarColor',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> avatarColorGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avatarColor',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> avatarColorLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avatarColor',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> avatarColorBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avatarColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> displayNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> displayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> displayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> displayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> displayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> displayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> displayNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> displayNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> isActuallyOnlineEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActuallyOnline',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageContentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastMessageContent',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      lastMessageContentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastMessageContent',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageContentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageContentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessageContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageContentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessageContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageContentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessageContent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageContentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastMessageContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageContentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastMessageContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageContentContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastMessageContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageContentMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastMessageContent',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageContentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageContent',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      lastMessageContentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastMessageContent',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageSenderIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastMessageSenderId',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      lastMessageSenderIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastMessageSenderId',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageSenderIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageSenderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      lastMessageSenderIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessageSenderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageSenderIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessageSenderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageSenderIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessageSenderId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageSenderIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastMessageSenderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageSenderIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastMessageSenderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageSenderIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastMessageSenderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageSenderIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastMessageSenderId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageSenderIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageSenderId',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      lastMessageSenderIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastMessageSenderId',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageStatusEqualTo(
      MessageStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageStatusGreaterThan(
    MessageStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessageStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageStatusLessThan(
    MessageStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessageStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageStatusBetween(
    MessageStatus lower,
    MessageStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessageStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageTimeEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessageTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessageTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessageTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'participantIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      participantIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'participantIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'participantIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'participantIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      participantIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'participantIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'participantIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantIdsElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'participantIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantIdsElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'participantIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      participantIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'participantIds',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      participantIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'participantIds',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantIdsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participantIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participantIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participantIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participantIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      participantIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participantIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participantIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> profilePictureUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'profilePictureUrl',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> profilePictureUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'profilePictureUrl',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> profilePictureUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profilePictureUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> profilePictureUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'profilePictureUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> profilePictureUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'profilePictureUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> profilePictureUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'profilePictureUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> profilePictureUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'profilePictureUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> profilePictureUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'profilePictureUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> profilePictureUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'profilePictureUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> profilePictureUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'profilePictureUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> profilePictureUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profilePictureUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      profilePictureUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'profilePictureUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> relationshipTypeEqualTo(
      RelationshipType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relationshipType',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> relationshipTypeGreaterThan(
    RelationshipType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'relationshipType',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> relationshipTypeLessThan(
    RelationshipType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'relationshipType',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> relationshipTypeBetween(
    RelationshipType lower,
    RelationshipType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'relationshipType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> unreadCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unreadCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> unreadCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unreadCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> unreadCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unreadCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> unreadCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unreadCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ChatQueryObject on QueryBuilder<Chat, Chat, QFilterCondition> {}

extension ChatQueryLinks on QueryBuilder<Chat, Chat, QFilterCondition> {}

extension ChatQuerySortBy on QueryBuilder<Chat, Chat, QSortBy> {
  QueryBuilder<Chat, Chat, QAfterSortBy> sortByAvatarColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarColor', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByAvatarColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarColor', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByIsActuallyOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActuallyOnline', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByIsActuallyOnlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActuallyOnline', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByLastMessageContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageContent', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByLastMessageContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageContent', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByLastMessageSenderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageSenderId', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByLastMessageSenderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageSenderId', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByLastMessageStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageStatus', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByLastMessageStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageStatus', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByLastMessageTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageTime', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByLastMessageTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageTime', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByProfilePictureUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profilePictureUrl', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByProfilePictureUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profilePictureUrl', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByRelationshipType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationshipType', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByRelationshipTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationshipType', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByUnreadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.desc);
    });
  }
}

extension ChatQuerySortThenBy on QueryBuilder<Chat, Chat, QSortThenBy> {
  QueryBuilder<Chat, Chat, QAfterSortBy> thenByAvatarColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarColor', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByAvatarColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarColor', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByIsActuallyOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActuallyOnline', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByIsActuallyOnlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActuallyOnline', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByLastMessageContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageContent', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByLastMessageContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageContent', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByLastMessageSenderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageSenderId', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByLastMessageSenderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageSenderId', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByLastMessageStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageStatus', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByLastMessageStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageStatus', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByLastMessageTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageTime', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByLastMessageTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageTime', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByProfilePictureUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profilePictureUrl', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByProfilePictureUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profilePictureUrl', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByRelationshipType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationshipType', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByRelationshipTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationshipType', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByUnreadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.desc);
    });
  }
}

extension ChatQueryWhereDistinct on QueryBuilder<Chat, Chat, QDistinct> {
  QueryBuilder<Chat, Chat, QDistinct> distinctByAvatarColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatarColor');
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByDisplayName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByIsActuallyOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActuallyOnline');
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByLastMessageContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageContent',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByLastMessageSenderId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageSenderId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByLastMessageStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageStatus');
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByLastMessageTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageTime');
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByParticipantIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'participantIds');
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByProfilePictureUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profilePictureUrl',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByRelationshipType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relationshipType');
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unreadCount');
    });
  }
}

extension ChatQueryProperty on QueryBuilder<Chat, Chat, QQueryProperty> {
  QueryBuilder<Chat, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<Chat, int?, QQueryOperations> avatarColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatarColor');
    });
  }

  QueryBuilder<Chat, String, QQueryOperations> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<Chat, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Chat, bool, QQueryOperations> isActuallyOnlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActuallyOnline');
    });
  }

  QueryBuilder<Chat, String?, QQueryOperations> lastMessageContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageContent');
    });
  }

  QueryBuilder<Chat, String?, QQueryOperations> lastMessageSenderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageSenderId');
    });
  }

  QueryBuilder<Chat, MessageStatus, QQueryOperations>
      lastMessageStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageStatus');
    });
  }

  QueryBuilder<Chat, DateTime, QQueryOperations> lastMessageTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageTime');
    });
  }

  QueryBuilder<Chat, List<String>, QQueryOperations> participantIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'participantIds');
    });
  }

  QueryBuilder<Chat, String?, QQueryOperations> profilePictureUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profilePictureUrl');
    });
  }

  QueryBuilder<Chat, RelationshipType, QQueryOperations>
      relationshipTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relationshipType');
    });
  }

  QueryBuilder<Chat, int, QQueryOperations> unreadCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unreadCount');
    });
  }
}
