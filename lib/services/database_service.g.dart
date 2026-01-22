// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_service.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalMessageCollection on Isar {
  IsarCollection<LocalMessage> get localMessages => this.collection();
}

const LocalMessageSchema = CollectionSchema(
  name: r'LocalMessage',
  id: 1045835317208282169,
  properties: {
    r'chatId': PropertySchema(
      id: 0,
      name: r'chatId',
      type: IsarType.string,
    ),
    r'content': PropertySchema(
      id: 1,
      name: r'content',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isDeleted': PropertySchema(
      id: 3,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isEdited': PropertySchema(
      id: 4,
      name: r'isEdited',
      type: IsarType.bool,
    ),
    r'messageId': PropertySchema(
      id: 5,
      name: r'messageId',
      type: IsarType.string,
    ),
    r'pendingSync': PropertySchema(
      id: 6,
      name: r'pendingSync',
      type: IsarType.bool,
    ),
    r'replyToMessageId': PropertySchema(
      id: 7,
      name: r'replyToMessageId',
      type: IsarType.string,
    ),
    r'senderId': PropertySchema(
      id: 8,
      name: r'senderId',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 9,
      name: r'type',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 10,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _localMessageEstimateSize,
  serialize: _localMessageSerialize,
  deserialize: _localMessageDeserialize,
  deserializeProp: _localMessageDeserializeProp,
  idName: r'id',
  indexes: {
    r'messageId': IndexSchema(
      id: -635287409172016016,
      name: r'messageId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'messageId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'chatId': IndexSchema(
      id: 1909629659142158609,
      name: r'chatId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'chatId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localMessageGetId,
  getLinks: _localMessageGetLinks,
  attach: _localMessageAttach,
  version: '3.1.0+1',
);

int _localMessageEstimateSize(
  LocalMessage object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.chatId.length * 3;
  {
    final value = object.content;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.messageId.length * 3;
  {
    final value = object.replyToMessageId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.senderId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _localMessageSerialize(
  LocalMessage object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.chatId);
  writer.writeString(offsets[1], object.content);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeBool(offsets[3], object.isDeleted);
  writer.writeBool(offsets[4], object.isEdited);
  writer.writeString(offsets[5], object.messageId);
  writer.writeBool(offsets[6], object.pendingSync);
  writer.writeString(offsets[7], object.replyToMessageId);
  writer.writeString(offsets[8], object.senderId);
  writer.writeString(offsets[9], object.type);
  writer.writeDateTime(offsets[10], object.updatedAt);
}

LocalMessage _localMessageDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalMessage(
    chatId: reader.readString(offsets[0]),
    content: reader.readStringOrNull(offsets[1]),
    createdAt: reader.readDateTimeOrNull(offsets[2]),
    isDeleted: reader.readBoolOrNull(offsets[3]) ?? false,
    isEdited: reader.readBoolOrNull(offsets[4]) ?? false,
    messageId: reader.readString(offsets[5]),
    pendingSync: reader.readBoolOrNull(offsets[6]) ?? false,
    replyToMessageId: reader.readStringOrNull(offsets[7]),
    senderId: reader.readStringOrNull(offsets[8]),
    type: reader.readString(offsets[9]),
    updatedAt: reader.readDateTimeOrNull(offsets[10]),
  );
  object.id = id;
  return object;
}

P _localMessageDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 4:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localMessageGetId(LocalMessage object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localMessageGetLinks(LocalMessage object) {
  return [];
}

void _localMessageAttach(
    IsarCollection<dynamic> col, Id id, LocalMessage object) {
  object.id = id;
}

extension LocalMessageByIndex on IsarCollection<LocalMessage> {
  Future<LocalMessage?> getByMessageId(String messageId) {
    return getByIndex(r'messageId', [messageId]);
  }

  LocalMessage? getByMessageIdSync(String messageId) {
    return getByIndexSync(r'messageId', [messageId]);
  }

  Future<bool> deleteByMessageId(String messageId) {
    return deleteByIndex(r'messageId', [messageId]);
  }

  bool deleteByMessageIdSync(String messageId) {
    return deleteByIndexSync(r'messageId', [messageId]);
  }

  Future<List<LocalMessage?>> getAllByMessageId(List<String> messageIdValues) {
    final values = messageIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'messageId', values);
  }

  List<LocalMessage?> getAllByMessageIdSync(List<String> messageIdValues) {
    final values = messageIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'messageId', values);
  }

  Future<int> deleteAllByMessageId(List<String> messageIdValues) {
    final values = messageIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'messageId', values);
  }

  int deleteAllByMessageIdSync(List<String> messageIdValues) {
    final values = messageIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'messageId', values);
  }

  Future<Id> putByMessageId(LocalMessage object) {
    return putByIndex(r'messageId', object);
  }

  Id putByMessageIdSync(LocalMessage object, {bool saveLinks = true}) {
    return putByIndexSync(r'messageId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMessageId(List<LocalMessage> objects) {
    return putAllByIndex(r'messageId', objects);
  }

  List<Id> putAllByMessageIdSync(List<LocalMessage> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'messageId', objects, saveLinks: saveLinks);
  }
}

extension LocalMessageQueryWhereSort
    on QueryBuilder<LocalMessage, LocalMessage, QWhere> {
  QueryBuilder<LocalMessage, LocalMessage, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalMessageQueryWhere
    on QueryBuilder<LocalMessage, LocalMessage, QWhereClause> {
  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> messageIdEqualTo(
      String messageId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'messageId',
        value: [messageId],
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause>
      messageIdNotEqualTo(String messageId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'messageId',
              lower: [],
              upper: [messageId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'messageId',
              lower: [messageId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'messageId',
              lower: [messageId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'messageId',
              lower: [],
              upper: [messageId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> chatIdEqualTo(
      String chatId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'chatId',
        value: [chatId],
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterWhereClause> chatIdNotEqualTo(
      String chatId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatId',
              lower: [],
              upper: [chatId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatId',
              lower: [chatId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatId',
              lower: [chatId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatId',
              lower: [],
              upper: [chatId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalMessageQueryFilter
    on QueryBuilder<LocalMessage, LocalMessage, QFilterCondition> {
  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> chatIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chatId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      chatIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chatId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      chatIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chatId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> chatIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chatId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      chatIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'chatId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      chatIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'chatId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      chatIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'chatId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> chatIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'chatId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      chatIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chatId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      chatIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'chatId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'content',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'content',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'content',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      isEditedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isEdited',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messageId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'messageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'messageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'messageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'messageId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      messageIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'messageId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      pendingSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingSync',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToMessageIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'replyToMessageId',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToMessageIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'replyToMessageId',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToMessageIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replyToMessageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToMessageIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'replyToMessageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToMessageIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'replyToMessageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToMessageIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'replyToMessageId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToMessageIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'replyToMessageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToMessageIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'replyToMessageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToMessageIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'replyToMessageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToMessageIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'replyToMessageId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToMessageIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replyToMessageId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      replyToMessageIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'replyToMessageId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'senderId',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'senderId',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'senderId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'senderId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      senderIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'senderId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> typeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LocalMessageQueryObject
    on QueryBuilder<LocalMessage, LocalMessage, QFilterCondition> {}

extension LocalMessageQueryLinks
    on QueryBuilder<LocalMessage, LocalMessage, QFilterCondition> {}

extension LocalMessageQuerySortBy
    on QueryBuilder<LocalMessage, LocalMessage, QSortBy> {
  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByChatId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByChatIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByIsEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEdited', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByIsEditedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEdited', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByReplyToMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToMessageId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      sortByReplyToMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToMessageId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortBySenderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortBySenderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension LocalMessageQuerySortThenBy
    on QueryBuilder<LocalMessage, LocalMessage, QSortThenBy> {
  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByChatId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByChatIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByIsEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEdited', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByIsEditedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEdited', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByReplyToMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToMessageId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy>
      thenByReplyToMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToMessageId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenBySenderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderId', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenBySenderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderId', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension LocalMessageQueryWhereDistinct
    on QueryBuilder<LocalMessage, LocalMessage, QDistinct> {
  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByChatId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chatId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByIsEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEdited');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByMessageId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingSync');
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct>
      distinctByReplyToMessageId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replyToMessageId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctBySenderId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'senderId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMessage, LocalMessage, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension LocalMessageQueryProperty
    on QueryBuilder<LocalMessage, LocalMessage, QQueryProperty> {
  QueryBuilder<LocalMessage, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalMessage, String, QQueryOperations> chatIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chatId');
    });
  }

  QueryBuilder<LocalMessage, String?, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<LocalMessage, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LocalMessage, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<LocalMessage, bool, QQueryOperations> isEditedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEdited');
    });
  }

  QueryBuilder<LocalMessage, String, QQueryOperations> messageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageId');
    });
  }

  QueryBuilder<LocalMessage, bool, QQueryOperations> pendingSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingSync');
    });
  }

  QueryBuilder<LocalMessage, String?, QQueryOperations>
      replyToMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replyToMessageId');
    });
  }

  QueryBuilder<LocalMessage, String?, QQueryOperations> senderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'senderId');
    });
  }

  QueryBuilder<LocalMessage, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<LocalMessage, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalChatCollection on Isar {
  IsarCollection<LocalChat> get localChats => this.collection();
}

const LocalChatSchema = CollectionSchema(
  name: r'LocalChat',
  id: -2936702508279018238,
  properties: {
    r'chatId': PropertySchema(
      id: 0,
      name: r'chatId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'lastMessageId': PropertySchema(
      id: 2,
      name: r'lastMessageId',
      type: IsarType.string,
    ),
    r'userOneId': PropertySchema(
      id: 3,
      name: r'userOneId',
      type: IsarType.string,
    ),
    r'userTwoId': PropertySchema(
      id: 4,
      name: r'userTwoId',
      type: IsarType.string,
    )
  },
  estimateSize: _localChatEstimateSize,
  serialize: _localChatSerialize,
  deserialize: _localChatDeserialize,
  deserializeProp: _localChatDeserializeProp,
  idName: r'id',
  indexes: {
    r'chatId': IndexSchema(
      id: 1909629659142158609,
      name: r'chatId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'chatId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localChatGetId,
  getLinks: _localChatGetLinks,
  attach: _localChatAttach,
  version: '3.1.0+1',
);

int _localChatEstimateSize(
  LocalChat object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.chatId.length * 3;
  {
    final value = object.lastMessageId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userOneId.length * 3;
  bytesCount += 3 + object.userTwoId.length * 3;
  return bytesCount;
}

void _localChatSerialize(
  LocalChat object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.chatId);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.lastMessageId);
  writer.writeString(offsets[3], object.userOneId);
  writer.writeString(offsets[4], object.userTwoId);
}

LocalChat _localChatDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalChat(
    chatId: reader.readString(offsets[0]),
    createdAt: reader.readDateTimeOrNull(offsets[1]),
    lastMessageId: reader.readStringOrNull(offsets[2]),
    userOneId: reader.readString(offsets[3]),
    userTwoId: reader.readString(offsets[4]),
  );
  object.id = id;
  return object;
}

P _localChatDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localChatGetId(LocalChat object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localChatGetLinks(LocalChat object) {
  return [];
}

void _localChatAttach(IsarCollection<dynamic> col, Id id, LocalChat object) {
  object.id = id;
}

extension LocalChatByIndex on IsarCollection<LocalChat> {
  Future<LocalChat?> getByChatId(String chatId) {
    return getByIndex(r'chatId', [chatId]);
  }

  LocalChat? getByChatIdSync(String chatId) {
    return getByIndexSync(r'chatId', [chatId]);
  }

  Future<bool> deleteByChatId(String chatId) {
    return deleteByIndex(r'chatId', [chatId]);
  }

  bool deleteByChatIdSync(String chatId) {
    return deleteByIndexSync(r'chatId', [chatId]);
  }

  Future<List<LocalChat?>> getAllByChatId(List<String> chatIdValues) {
    final values = chatIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'chatId', values);
  }

  List<LocalChat?> getAllByChatIdSync(List<String> chatIdValues) {
    final values = chatIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'chatId', values);
  }

  Future<int> deleteAllByChatId(List<String> chatIdValues) {
    final values = chatIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'chatId', values);
  }

  int deleteAllByChatIdSync(List<String> chatIdValues) {
    final values = chatIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'chatId', values);
  }

  Future<Id> putByChatId(LocalChat object) {
    return putByIndex(r'chatId', object);
  }

  Id putByChatIdSync(LocalChat object, {bool saveLinks = true}) {
    return putByIndexSync(r'chatId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByChatId(List<LocalChat> objects) {
    return putAllByIndex(r'chatId', objects);
  }

  List<Id> putAllByChatIdSync(List<LocalChat> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'chatId', objects, saveLinks: saveLinks);
  }
}

extension LocalChatQueryWhereSort
    on QueryBuilder<LocalChat, LocalChat, QWhere> {
  QueryBuilder<LocalChat, LocalChat, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalChatQueryWhere
    on QueryBuilder<LocalChat, LocalChat, QWhereClause> {
  QueryBuilder<LocalChat, LocalChat, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterWhereClause> chatIdEqualTo(
      String chatId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'chatId',
        value: [chatId],
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterWhereClause> chatIdNotEqualTo(
      String chatId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatId',
              lower: [],
              upper: [chatId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatId',
              lower: [chatId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatId',
              lower: [chatId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatId',
              lower: [],
              upper: [chatId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalChatQueryFilter
    on QueryBuilder<LocalChat, LocalChat, QFilterCondition> {
  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> chatIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chatId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> chatIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chatId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> chatIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chatId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> chatIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chatId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> chatIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'chatId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> chatIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'chatId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> chatIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'chatId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> chatIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'chatId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> chatIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chatId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> chatIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'chatId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> createdAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      lastMessageIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastMessageId',
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      lastMessageIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastMessageId',
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      lastMessageIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      lastMessageIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      lastMessageIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      lastMessageIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessageId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      lastMessageIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastMessageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      lastMessageIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastMessageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      lastMessageIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastMessageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      lastMessageIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastMessageId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      lastMessageIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      lastMessageIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastMessageId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userOneIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userOneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      userOneIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userOneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userOneIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userOneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userOneIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userOneId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userOneIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userOneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userOneIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userOneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userOneIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userOneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userOneIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userOneId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userOneIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userOneId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      userOneIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userOneId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userTwoIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userTwoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      userTwoIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userTwoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userTwoIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userTwoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userTwoIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userTwoId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userTwoIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userTwoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userTwoIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userTwoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userTwoIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userTwoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userTwoIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userTwoId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition> userTwoIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userTwoId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterFilterCondition>
      userTwoIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userTwoId',
        value: '',
      ));
    });
  }
}

extension LocalChatQueryObject
    on QueryBuilder<LocalChat, LocalChat, QFilterCondition> {}

extension LocalChatQueryLinks
    on QueryBuilder<LocalChat, LocalChat, QFilterCondition> {}

extension LocalChatQuerySortBy on QueryBuilder<LocalChat, LocalChat, QSortBy> {
  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> sortByChatId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatId', Sort.asc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> sortByChatIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatId', Sort.desc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> sortByLastMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageId', Sort.asc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> sortByLastMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageId', Sort.desc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> sortByUserOneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userOneId', Sort.asc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> sortByUserOneIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userOneId', Sort.desc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> sortByUserTwoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userTwoId', Sort.asc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> sortByUserTwoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userTwoId', Sort.desc);
    });
  }
}

extension LocalChatQuerySortThenBy
    on QueryBuilder<LocalChat, LocalChat, QSortThenBy> {
  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> thenByChatId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatId', Sort.asc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> thenByChatIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatId', Sort.desc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> thenByLastMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageId', Sort.asc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> thenByLastMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageId', Sort.desc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> thenByUserOneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userOneId', Sort.asc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> thenByUserOneIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userOneId', Sort.desc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> thenByUserTwoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userTwoId', Sort.asc);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QAfterSortBy> thenByUserTwoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userTwoId', Sort.desc);
    });
  }
}

extension LocalChatQueryWhereDistinct
    on QueryBuilder<LocalChat, LocalChat, QDistinct> {
  QueryBuilder<LocalChat, LocalChat, QDistinct> distinctByChatId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chatId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LocalChat, LocalChat, QDistinct> distinctByLastMessageId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QDistinct> distinctByUserOneId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userOneId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalChat, LocalChat, QDistinct> distinctByUserTwoId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userTwoId', caseSensitive: caseSensitive);
    });
  }
}

extension LocalChatQueryProperty
    on QueryBuilder<LocalChat, LocalChat, QQueryProperty> {
  QueryBuilder<LocalChat, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalChat, String, QQueryOperations> chatIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chatId');
    });
  }

  QueryBuilder<LocalChat, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LocalChat, String?, QQueryOperations> lastMessageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageId');
    });
  }

  QueryBuilder<LocalChat, String, QQueryOperations> userOneIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userOneId');
    });
  }

  QueryBuilder<LocalChat, String, QQueryOperations> userTwoIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userTwoId');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalProfileCollection on Isar {
  IsarCollection<LocalProfile> get localProfiles => this.collection();
}

const LocalProfileSchema = CollectionSchema(
  name: r'LocalProfile',
  id: -3481655517967548928,
  properties: {
    r'avatarColor': PropertySchema(
      id: 0,
      name: r'avatarColor',
      type: IsarType.long,
    ),
    r'avatarUrl': PropertySchema(
      id: 1,
      name: r'avatarUrl',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'displayName': PropertySchema(
      id: 3,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'lastSeen': PropertySchema(
      id: 4,
      name: r'lastSeen',
      type: IsarType.dateTime,
    ),
    r'profileId': PropertySchema(
      id: 5,
      name: r'profileId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 6,
      name: r'status',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 7,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'username': PropertySchema(
      id: 8,
      name: r'username',
      type: IsarType.string,
    )
  },
  estimateSize: _localProfileEstimateSize,
  serialize: _localProfileSerialize,
  deserialize: _localProfileDeserialize,
  deserializeProp: _localProfileDeserializeProp,
  idName: r'id',
  indexes: {
    r'profileId': IndexSchema(
      id: 6052971939042612300,
      name: r'profileId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'profileId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localProfileGetId,
  getLinks: _localProfileGetLinks,
  attach: _localProfileAttach,
  version: '3.1.0+1',
);

int _localProfileEstimateSize(
  LocalProfile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.avatarUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.displayName.length * 3;
  bytesCount += 3 + object.profileId.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.username.length * 3;
  return bytesCount;
}

void _localProfileSerialize(
  LocalProfile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.avatarColor);
  writer.writeString(offsets[1], object.avatarUrl);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.displayName);
  writer.writeDateTime(offsets[4], object.lastSeen);
  writer.writeString(offsets[5], object.profileId);
  writer.writeString(offsets[6], object.status);
  writer.writeDateTime(offsets[7], object.updatedAt);
  writer.writeString(offsets[8], object.username);
}

LocalProfile _localProfileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalProfile(
    avatarColor: reader.readLongOrNull(offsets[0]),
    avatarUrl: reader.readStringOrNull(offsets[1]),
    createdAt: reader.readDateTimeOrNull(offsets[2]),
    displayName: reader.readString(offsets[3]),
    lastSeen: reader.readDateTimeOrNull(offsets[4]),
    profileId: reader.readString(offsets[5]),
    status: reader.readString(offsets[6]),
    updatedAt: reader.readDateTimeOrNull(offsets[7]),
    username: reader.readString(offsets[8]),
  );
  object.id = id;
  return object;
}

P _localProfileDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localProfileGetId(LocalProfile object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localProfileGetLinks(LocalProfile object) {
  return [];
}

void _localProfileAttach(
    IsarCollection<dynamic> col, Id id, LocalProfile object) {
  object.id = id;
}

extension LocalProfileByIndex on IsarCollection<LocalProfile> {
  Future<LocalProfile?> getByProfileId(String profileId) {
    return getByIndex(r'profileId', [profileId]);
  }

  LocalProfile? getByProfileIdSync(String profileId) {
    return getByIndexSync(r'profileId', [profileId]);
  }

  Future<bool> deleteByProfileId(String profileId) {
    return deleteByIndex(r'profileId', [profileId]);
  }

  bool deleteByProfileIdSync(String profileId) {
    return deleteByIndexSync(r'profileId', [profileId]);
  }

  Future<List<LocalProfile?>> getAllByProfileId(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'profileId', values);
  }

  List<LocalProfile?> getAllByProfileIdSync(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'profileId', values);
  }

  Future<int> deleteAllByProfileId(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'profileId', values);
  }

  int deleteAllByProfileIdSync(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'profileId', values);
  }

  Future<Id> putByProfileId(LocalProfile object) {
    return putByIndex(r'profileId', object);
  }

  Id putByProfileIdSync(LocalProfile object, {bool saveLinks = true}) {
    return putByIndexSync(r'profileId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByProfileId(List<LocalProfile> objects) {
    return putAllByIndex(r'profileId', objects);
  }

  List<Id> putAllByProfileIdSync(List<LocalProfile> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'profileId', objects, saveLinks: saveLinks);
  }
}

extension LocalProfileQueryWhereSort
    on QueryBuilder<LocalProfile, LocalProfile, QWhere> {
  QueryBuilder<LocalProfile, LocalProfile, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalProfileQueryWhere
    on QueryBuilder<LocalProfile, LocalProfile, QWhereClause> {
  QueryBuilder<LocalProfile, LocalProfile, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterWhereClause> profileIdEqualTo(
      String profileId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'profileId',
        value: [profileId],
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterWhereClause>
      profileIdNotEqualTo(String profileId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [],
              upper: [profileId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [profileId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [profileId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [],
              upper: [profileId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalProfileQueryFilter
    on QueryBuilder<LocalProfile, LocalProfile, QFilterCondition> {
  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarColorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avatarColor',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarColorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avatarColor',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarColorEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarColor',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarColorGreaterThan(
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

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarColorLessThan(
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

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarColorBetween(
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

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avatarUrl',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avatarUrl',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avatarUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'avatarUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      avatarUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'avatarUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      displayNameEqualTo(
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

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      displayNameGreaterThan(
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

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      displayNameLessThan(
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

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      displayNameBetween(
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

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      displayNameStartsWith(
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

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      displayNameEndsWith(
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

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      lastSeenIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSeen',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      lastSeenIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSeen',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      lastSeenEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      lastSeenGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      lastSeenLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      lastSeenBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSeen',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      profileIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      profileIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      profileIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      profileIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'profileId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      profileIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      profileIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      profileIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      profileIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'profileId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      profileIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      profileIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'profileId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition> statusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      usernameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      usernameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      usernameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      usernameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'username',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      usernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      usernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      usernameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      usernameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'username',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      usernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterFilterCondition>
      usernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'username',
        value: '',
      ));
    });
  }
}

extension LocalProfileQueryObject
    on QueryBuilder<LocalProfile, LocalProfile, QFilterCondition> {}

extension LocalProfileQueryLinks
    on QueryBuilder<LocalProfile, LocalProfile, QFilterCondition> {}

extension LocalProfileQuerySortBy
    on QueryBuilder<LocalProfile, LocalProfile, QSortBy> {
  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByAvatarColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarColor', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy>
      sortByAvatarColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarColor', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByAvatarUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByAvatarUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy>
      sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByLastSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> sortByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }
}

extension LocalProfileQuerySortThenBy
    on QueryBuilder<LocalProfile, LocalProfile, QSortThenBy> {
  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByAvatarColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarColor', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy>
      thenByAvatarColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarColor', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByAvatarUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByAvatarUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy>
      thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByLastSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSeen', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QAfterSortBy> thenByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }
}

extension LocalProfileQueryWhereDistinct
    on QueryBuilder<LocalProfile, LocalProfile, QDistinct> {
  QueryBuilder<LocalProfile, LocalProfile, QDistinct> distinctByAvatarColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatarColor');
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QDistinct> distinctByAvatarUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatarUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QDistinct> distinctByDisplayName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QDistinct> distinctByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSeen');
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QDistinct> distinctByProfileId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profileId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<LocalProfile, LocalProfile, QDistinct> distinctByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'username', caseSensitive: caseSensitive);
    });
  }
}

extension LocalProfileQueryProperty
    on QueryBuilder<LocalProfile, LocalProfile, QQueryProperty> {
  QueryBuilder<LocalProfile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalProfile, int?, QQueryOperations> avatarColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatarColor');
    });
  }

  QueryBuilder<LocalProfile, String?, QQueryOperations> avatarUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatarUrl');
    });
  }

  QueryBuilder<LocalProfile, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LocalProfile, String, QQueryOperations> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<LocalProfile, DateTime?, QQueryOperations> lastSeenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSeen');
    });
  }

  QueryBuilder<LocalProfile, String, QQueryOperations> profileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileId');
    });
  }

  QueryBuilder<LocalProfile, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<LocalProfile, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<LocalProfile, String, QQueryOperations> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'username');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalRelationshipCollection on Isar {
  IsarCollection<LocalRelationship> get localRelationships => this.collection();
}

const LocalRelationshipSchema = CollectionSchema(
  name: r'LocalRelationship',
  id: -3318494633011079413,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'pendingSync': PropertySchema(
      id: 1,
      name: r'pendingSync',
      type: IsarType.bool,
    ),
    r'receiverId': PropertySchema(
      id: 2,
      name: r'receiverId',
      type: IsarType.string,
    ),
    r'relationshipId': PropertySchema(
      id: 3,
      name: r'relationshipId',
      type: IsarType.string,
    ),
    r'requesterId': PropertySchema(
      id: 4,
      name: r'requesterId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 5,
      name: r'status',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 6,
      name: r'type',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 7,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _localRelationshipEstimateSize,
  serialize: _localRelationshipSerialize,
  deserialize: _localRelationshipDeserialize,
  deserializeProp: _localRelationshipDeserializeProp,
  idName: r'id',
  indexes: {
    r'relationshipId': IndexSchema(
      id: -8609994343672160716,
      name: r'relationshipId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'relationshipId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'requesterId': IndexSchema(
      id: 804429649568402206,
      name: r'requesterId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'requesterId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'receiverId': IndexSchema(
      id: 6011257104462202512,
      name: r'receiverId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'receiverId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localRelationshipGetId,
  getLinks: _localRelationshipGetLinks,
  attach: _localRelationshipAttach,
  version: '3.1.0+1',
);

int _localRelationshipEstimateSize(
  LocalRelationship object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.receiverId.length * 3;
  bytesCount += 3 + object.relationshipId.length * 3;
  bytesCount += 3 + object.requesterId.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _localRelationshipSerialize(
  LocalRelationship object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeBool(offsets[1], object.pendingSync);
  writer.writeString(offsets[2], object.receiverId);
  writer.writeString(offsets[3], object.relationshipId);
  writer.writeString(offsets[4], object.requesterId);
  writer.writeString(offsets[5], object.status);
  writer.writeString(offsets[6], object.type);
  writer.writeDateTime(offsets[7], object.updatedAt);
}

LocalRelationship _localRelationshipDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalRelationship(
    createdAt: reader.readDateTimeOrNull(offsets[0]),
    pendingSync: reader.readBoolOrNull(offsets[1]) ?? false,
    receiverId: reader.readString(offsets[2]),
    relationshipId: reader.readString(offsets[3]),
    requesterId: reader.readString(offsets[4]),
    status: reader.readString(offsets[5]),
    type: reader.readString(offsets[6]),
    updatedAt: reader.readDateTimeOrNull(offsets[7]),
  );
  object.id = id;
  return object;
}

P _localRelationshipDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localRelationshipGetId(LocalRelationship object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localRelationshipGetLinks(
    LocalRelationship object) {
  return [];
}

void _localRelationshipAttach(
    IsarCollection<dynamic> col, Id id, LocalRelationship object) {
  object.id = id;
}

extension LocalRelationshipByIndex on IsarCollection<LocalRelationship> {
  Future<LocalRelationship?> getByRelationshipId(String relationshipId) {
    return getByIndex(r'relationshipId', [relationshipId]);
  }

  LocalRelationship? getByRelationshipIdSync(String relationshipId) {
    return getByIndexSync(r'relationshipId', [relationshipId]);
  }

  Future<bool> deleteByRelationshipId(String relationshipId) {
    return deleteByIndex(r'relationshipId', [relationshipId]);
  }

  bool deleteByRelationshipIdSync(String relationshipId) {
    return deleteByIndexSync(r'relationshipId', [relationshipId]);
  }

  Future<List<LocalRelationship?>> getAllByRelationshipId(
      List<String> relationshipIdValues) {
    final values = relationshipIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'relationshipId', values);
  }

  List<LocalRelationship?> getAllByRelationshipIdSync(
      List<String> relationshipIdValues) {
    final values = relationshipIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'relationshipId', values);
  }

  Future<int> deleteAllByRelationshipId(List<String> relationshipIdValues) {
    final values = relationshipIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'relationshipId', values);
  }

  int deleteAllByRelationshipIdSync(List<String> relationshipIdValues) {
    final values = relationshipIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'relationshipId', values);
  }

  Future<Id> putByRelationshipId(LocalRelationship object) {
    return putByIndex(r'relationshipId', object);
  }

  Id putByRelationshipIdSync(LocalRelationship object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'relationshipId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRelationshipId(List<LocalRelationship> objects) {
    return putAllByIndex(r'relationshipId', objects);
  }

  List<Id> putAllByRelationshipIdSync(List<LocalRelationship> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'relationshipId', objects, saveLinks: saveLinks);
  }
}

extension LocalRelationshipQueryWhereSort
    on QueryBuilder<LocalRelationship, LocalRelationship, QWhere> {
  QueryBuilder<LocalRelationship, LocalRelationship, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalRelationshipQueryWhere
    on QueryBuilder<LocalRelationship, LocalRelationship, QWhereClause> {
  QueryBuilder<LocalRelationship, LocalRelationship, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterWhereClause>
      relationshipIdEqualTo(String relationshipId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'relationshipId',
        value: [relationshipId],
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterWhereClause>
      relationshipIdNotEqualTo(String relationshipId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'relationshipId',
              lower: [],
              upper: [relationshipId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'relationshipId',
              lower: [relationshipId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'relationshipId',
              lower: [relationshipId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'relationshipId',
              lower: [],
              upper: [relationshipId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterWhereClause>
      requesterIdEqualTo(String requesterId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'requesterId',
        value: [requesterId],
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterWhereClause>
      requesterIdNotEqualTo(String requesterId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'requesterId',
              lower: [],
              upper: [requesterId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'requesterId',
              lower: [requesterId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'requesterId',
              lower: [requesterId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'requesterId',
              lower: [],
              upper: [requesterId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterWhereClause>
      receiverIdEqualTo(String receiverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'receiverId',
        value: [receiverId],
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterWhereClause>
      receiverIdNotEqualTo(String receiverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'receiverId',
              lower: [],
              upper: [receiverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'receiverId',
              lower: [receiverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'receiverId',
              lower: [receiverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'receiverId',
              lower: [],
              upper: [receiverId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalRelationshipQueryFilter
    on QueryBuilder<LocalRelationship, LocalRelationship, QFilterCondition> {
  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      pendingSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingSync',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      receiverIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      receiverIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receiverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      receiverIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receiverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      receiverIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receiverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      receiverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'receiverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      receiverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'receiverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      receiverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'receiverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      receiverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'receiverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      receiverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiverId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      receiverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'receiverId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      relationshipIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relationshipId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      relationshipIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'relationshipId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      relationshipIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'relationshipId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      relationshipIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'relationshipId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      relationshipIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'relationshipId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      relationshipIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'relationshipId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      relationshipIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'relationshipId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      relationshipIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'relationshipId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      relationshipIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relationshipId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      relationshipIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'relationshipId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      requesterIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requesterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      requesterIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'requesterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      requesterIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'requesterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      requesterIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'requesterId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      requesterIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'requesterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      requesterIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'requesterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      requesterIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'requesterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      requesterIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'requesterId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      requesterIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requesterId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      requesterIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'requesterId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LocalRelationshipQueryObject
    on QueryBuilder<LocalRelationship, LocalRelationship, QFilterCondition> {}

extension LocalRelationshipQueryLinks
    on QueryBuilder<LocalRelationship, LocalRelationship, QFilterCondition> {}

extension LocalRelationshipQuerySortBy
    on QueryBuilder<LocalRelationship, LocalRelationship, QSortBy> {
  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByReceiverId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiverId', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByReceiverIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiverId', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByRelationshipId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationshipId', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByRelationshipIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationshipId', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByRequesterId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requesterId', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByRequesterIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requesterId', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension LocalRelationshipQuerySortThenBy
    on QueryBuilder<LocalRelationship, LocalRelationship, QSortThenBy> {
  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingSync', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByReceiverId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiverId', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByReceiverIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiverId', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByRelationshipId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationshipId', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByRelationshipIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationshipId', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByRequesterId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requesterId', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByRequesterIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requesterId', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension LocalRelationshipQueryWhereDistinct
    on QueryBuilder<LocalRelationship, LocalRelationship, QDistinct> {
  QueryBuilder<LocalRelationship, LocalRelationship, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QDistinct>
      distinctByPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingSync');
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QDistinct>
      distinctByReceiverId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QDistinct>
      distinctByRelationshipId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relationshipId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QDistinct>
      distinctByRequesterId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'requesterId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalRelationship, LocalRelationship, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension LocalRelationshipQueryProperty
    on QueryBuilder<LocalRelationship, LocalRelationship, QQueryProperty> {
  QueryBuilder<LocalRelationship, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalRelationship, DateTime?, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LocalRelationship, bool, QQueryOperations>
      pendingSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingSync');
    });
  }

  QueryBuilder<LocalRelationship, String, QQueryOperations>
      receiverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiverId');
    });
  }

  QueryBuilder<LocalRelationship, String, QQueryOperations>
      relationshipIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relationshipId');
    });
  }

  QueryBuilder<LocalRelationship, String, QQueryOperations>
      requesterIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requesterId');
    });
  }

  QueryBuilder<LocalRelationship, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<LocalRelationship, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<LocalRelationship, DateTime?, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPendingChangeCollection on Isar {
  IsarCollection<PendingChange> get pendingChanges => this.collection();
}

const PendingChangeSchema = CollectionSchema(
  name: r'PendingChange',
  id: 5459551212669032204,
  properties: {
    r'action': PropertySchema(
      id: 0,
      name: r'action',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'entityId': PropertySchema(
      id: 2,
      name: r'entityId',
      type: IsarType.string,
    ),
    r'entityType': PropertySchema(
      id: 3,
      name: r'entityType',
      type: IsarType.string,
    ),
    r'payload': PropertySchema(
      id: 4,
      name: r'payload',
      type: IsarType.string,
    )
  },
  estimateSize: _pendingChangeEstimateSize,
  serialize: _pendingChangeSerialize,
  deserialize: _pendingChangeDeserialize,
  deserializeProp: _pendingChangeDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _pendingChangeGetId,
  getLinks: _pendingChangeGetLinks,
  attach: _pendingChangeAttach,
  version: '3.1.0+1',
);

int _pendingChangeEstimateSize(
  PendingChange object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.action.length * 3;
  bytesCount += 3 + object.entityId.length * 3;
  bytesCount += 3 + object.entityType.length * 3;
  bytesCount += 3 + object.payload.length * 3;
  return bytesCount;
}

void _pendingChangeSerialize(
  PendingChange object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.action);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.entityId);
  writer.writeString(offsets[3], object.entityType);
  writer.writeString(offsets[4], object.payload);
}

PendingChange _pendingChangeDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PendingChange(
    action: reader.readString(offsets[0]),
    createdAt: reader.readDateTime(offsets[1]),
    entityId: reader.readString(offsets[2]),
    entityType: reader.readString(offsets[3]),
    payload: reader.readString(offsets[4]),
  );
  object.id = id;
  return object;
}

P _pendingChangeDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pendingChangeGetId(PendingChange object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pendingChangeGetLinks(PendingChange object) {
  return [];
}

void _pendingChangeAttach(
    IsarCollection<dynamic> col, Id id, PendingChange object) {
  object.id = id;
}

extension PendingChangeQueryWhereSort
    on QueryBuilder<PendingChange, PendingChange, QWhere> {
  QueryBuilder<PendingChange, PendingChange, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PendingChangeQueryWhere
    on QueryBuilder<PendingChange, PendingChange, QWhereClause> {
  QueryBuilder<PendingChange, PendingChange, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PendingChangeQueryFilter
    on QueryBuilder<PendingChange, PendingChange, QFilterCondition> {
  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      actionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      actionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      actionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      actionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'action',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      actionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      actionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      actionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      actionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'action',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      actionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'action',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      actionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'action',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entityId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'entityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'entityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'entityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'entityId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityId',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'entityId',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entityType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'entityType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityType',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      entityTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'entityType',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      payloadEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      payloadGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      payloadLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      payloadBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payload',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      payloadStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      payloadEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      payloadContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      payloadMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payload',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      payloadIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payload',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterFilterCondition>
      payloadIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payload',
        value: '',
      ));
    });
  }
}

extension PendingChangeQueryObject
    on QueryBuilder<PendingChange, PendingChange, QFilterCondition> {}

extension PendingChangeQueryLinks
    on QueryBuilder<PendingChange, PendingChange, QFilterCondition> {}

extension PendingChangeQuerySortBy
    on QueryBuilder<PendingChange, PendingChange, QSortBy> {
  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> sortByAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'action', Sort.asc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> sortByActionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'action', Sort.desc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> sortByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy>
      sortByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> sortByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy>
      sortByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> sortByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> sortByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }
}

extension PendingChangeQuerySortThenBy
    on QueryBuilder<PendingChange, PendingChange, QSortThenBy> {
  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> thenByAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'action', Sort.asc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> thenByActionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'action', Sort.desc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> thenByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy>
      thenByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> thenByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy>
      thenByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> thenByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QAfterSortBy> thenByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }
}

extension PendingChangeQueryWhereDistinct
    on QueryBuilder<PendingChange, PendingChange, QDistinct> {
  QueryBuilder<PendingChange, PendingChange, QDistinct> distinctByAction(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'action', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PendingChange, PendingChange, QDistinct> distinctByEntityId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QDistinct> distinctByEntityType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingChange, PendingChange, QDistinct> distinctByPayload(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payload', caseSensitive: caseSensitive);
    });
  }
}

extension PendingChangeQueryProperty
    on QueryBuilder<PendingChange, PendingChange, QQueryProperty> {
  QueryBuilder<PendingChange, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PendingChange, String, QQueryOperations> actionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'action');
    });
  }

  QueryBuilder<PendingChange, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PendingChange, String, QQueryOperations> entityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityId');
    });
  }

  QueryBuilder<PendingChange, String, QQueryOperations> entityTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityType');
    });
  }

  QueryBuilder<PendingChange, String, QQueryOperations> payloadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payload');
    });
  }
}
