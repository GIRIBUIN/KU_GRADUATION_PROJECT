// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FolderGroupsTable extends FolderGroups
    with TableInfo<$FolderGroupsTable, FolderGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FolderGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sortOrder,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folder_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<FolderGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FolderGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FolderGroupsTable createAlias(String alias) {
    return $FolderGroupsTable(attachedDatabase, alias);
  }
}

class FolderGroup extends DataClass implements Insertable<FolderGroup> {
  final String id;
  final String name;
  final int sortOrder;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FolderGroup({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FolderGroupsCompanion toCompanion(bool nullToAbsent) {
    return FolderGroupsCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FolderGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderGroup(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FolderGroup copyWith({
    String? id,
    String? name,
    int? sortOrder,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FolderGroup(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FolderGroup copyWithCompanion(FolderGroupsCompanion data) {
    return FolderGroup(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderGroup(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, sortOrder, deletedAt, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderGroup &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FolderGroupsCompanion extends UpdateCompanion<FolderGroup> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FolderGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FolderGroupsCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FolderGroup> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FolderGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FolderGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FolderGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES folder_groups (id)',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    icon,
    groupId,
    sortOrder,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['folder_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final String id;
  final String name;
  final String? color;
  final String? icon;
  final String? groupId;
  final int sortOrder;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Folder({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    this.groupId,
    required this.sortOrder,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || groupId != null) {
      map['folder_id'] = Variable<String>(groupId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      sortOrder: Value(sortOrder),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
      'groupId': serializer.toJson<String?>(groupId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Folder copyWith({
    String? id,
    String? name,
    Value<String?> color = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    int? sortOrder,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Folder(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    icon: icon.present ? icon.value : this.icon,
    groupId: groupId.present ? groupId.value : this.groupId,
    sortOrder: sortOrder ?? this.sortOrder,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('groupId: $groupId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    color,
    icon,
    groupId,
    sortOrder,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.groupId == this.groupId &&
          other.sortOrder == this.sortOrder &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<String?> groupId;
  final Value<int> sortOrder;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.groupId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.groupId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Folder> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<String>? groupId,
    Expression<int>? sortOrder,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (groupId != null) 'folder_id': groupId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? color,
    Value<String?>? icon,
    Value<String?>? groupId,
    Value<int>? sortOrder,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      groupId: groupId ?? this.groupId,
      sortOrder: sortOrder ?? this.sortOrder,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (groupId.present) {
      map['folder_id'] = Variable<String>(groupId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('groupId: $groupId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES task_lists (id)',
    ),
    defaultValue: const Constant(inboxListId),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    dueDate,
    priority,
    memo,
    folderId,
    sortOrder,
    completedAt,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['list_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final DateTime? dueDate;
  final String? priority;
  final String? memo;
  final String folderId;
  final int sortOrder;
  final DateTime? completedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Task({
    required this.id,
    required this.title,
    this.dueDate,
    this.priority,
    this.memo,
    required this.folderId,
    required this.sortOrder,
    this.completedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || priority != null) {
      map['priority'] = Variable<String>(priority);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['list_id'] = Variable<String>(folderId);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      priority: priority == null && nullToAbsent
          ? const Value.absent()
          : Value(priority),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      folderId: Value(folderId),
      sortOrder: Value(sortOrder),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      priority: serializer.fromJson<String?>(json['priority']),
      memo: serializer.fromJson<String?>(json['memo']),
      folderId: serializer.fromJson<String>(json['folderId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'priority': serializer.toJson<String?>(priority),
      'memo': serializer.toJson<String?>(memo),
      'folderId': serializer.toJson<String>(folderId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    Value<DateTime?> dueDate = const Value.absent(),
    Value<String?> priority = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    String? folderId,
    int? sortOrder,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    priority: priority.present ? priority.value : this.priority,
    memo: memo.present ? memo.value : this.memo,
    folderId: folderId ?? this.folderId,
    sortOrder: sortOrder ?? this.sortOrder,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      priority: data.priority.present ? data.priority.value : this.priority,
      memo: data.memo.present ? data.memo.value : this.memo,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('dueDate: $dueDate, ')
          ..write('priority: $priority, ')
          ..write('memo: $memo, ')
          ..write('folderId: $folderId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('completedAt: $completedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    dueDate,
    priority,
    memo,
    folderId,
    sortOrder,
    completedAt,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.dueDate == this.dueDate &&
          other.priority == this.priority &&
          other.memo == this.memo &&
          other.folderId == this.folderId &&
          other.sortOrder == this.sortOrder &&
          other.completedAt == this.completedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime?> dueDate;
  final Value<String?> priority;
  final Value<String?> memo;
  final Value<String> folderId;
  final Value<int> sortOrder;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.memo = const Value.absent(),
    this.folderId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.dueDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.memo = const Value.absent(),
    this.folderId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? dueDate,
    Expression<String>? priority,
    Expression<String>? memo,
    Expression<String>? folderId,
    Expression<int>? sortOrder,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (dueDate != null) 'due_date': dueDate,
      if (priority != null) 'priority': priority,
      if (memo != null) 'memo': memo,
      if (folderId != null) 'list_id': folderId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (completedAt != null) 'completed_at': completedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime?>? dueDate,
    Value<String?>? priority,
    Value<String?>? memo,
    Value<String>? folderId,
    Value<int>? sortOrder,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      memo: memo ?? this.memo,
      folderId: folderId ?? this.folderId,
      sortOrder: sortOrder ?? this.sortOrder,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (folderId.present) {
      map['list_id'] = Variable<String>(folderId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('dueDate: $dueDate, ')
          ..write('priority: $priority, ')
          ..write('memo: $memo, ')
          ..write('folderId: $folderId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('completedAt: $completedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubTasksTable extends SubTasks with TableInfo<$SubTasksTable, SubTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    title,
    position,
    completedAt,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sub_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SubTasksTable createAlias(String alias) {
    return $SubTasksTable(attachedDatabase, alias);
  }
}

class SubTask extends DataClass implements Insertable<SubTask> {
  final String id;
  final String taskId;
  final String title;
  final int position;
  final DateTime? completedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SubTask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.position,
    this.completedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['title'] = Variable<String>(title);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SubTasksCompanion toCompanion(bool nullToAbsent) {
    return SubTasksCompanion(
      id: Value(id),
      taskId: Value(taskId),
      title: Value(title),
      position: Value(position),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SubTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubTask(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      title: serializer.fromJson<String>(json['title']),
      position: serializer.fromJson<int>(json['position']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'title': serializer.toJson<String>(title),
      'position': serializer.toJson<int>(position),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SubTask copyWith({
    String? id,
    String? taskId,
    String? title,
    int? position,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SubTask(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    title: title ?? this.title,
    position: position ?? this.position,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SubTask copyWithCompanion(SubTasksCompanion data) {
    return SubTask(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      title: data.title.present ? data.title.value : this.title,
      position: data.position.present ? data.position.value : this.position,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubTask(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('position: $position, ')
          ..write('completedAt: $completedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    title,
    position,
    completedAt,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubTask &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.title == this.title &&
          other.position == this.position &&
          other.completedAt == this.completedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubTasksCompanion extends UpdateCompanion<SubTask> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> title;
  final Value<int> position;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SubTasksCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.title = const Value.absent(),
    this.position = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubTasksCompanion.insert({
    required String id,
    required String taskId,
    required String title,
    this.position = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SubTask> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? title,
    Expression<int>? position,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (title != null) 'title': title,
      if (position != null) 'position': position,
      if (completedAt != null) 'completed_at': completedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubTasksCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? title,
    Value<int>? position,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SubTasksCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      position: position ?? this.position,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubTasksCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('position: $position, ')
          ..write('completedAt: $completedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    sortOrder,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String name;
  final String color;
  final int sortOrder;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.sortOrder,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      sortOrder: Value(sortOrder),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    String? color,
    int? sortOrder,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, color, sortOrder, deletedAt, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> color;
  final Value<int> sortOrder;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    required String color,
    this.sortOrder = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       color = Value(color),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<int>? sortOrder,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? color,
    Value<int>? sortOrder,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTagsTable extends TaskTags with TableInfo<$TaskTagsTable, TaskTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [taskId, tagId, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, tagId};
  @override
  TaskTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTag(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TaskTagsTable createAlias(String alias) {
    return $TaskTagsTable(attachedDatabase, alias);
  }
}

class TaskTag extends DataClass implements Insertable<TaskTag> {
  final String taskId;
  final String tagId;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const TaskTag({
    required this.taskId,
    required this.tagId,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['tag_id'] = Variable<String>(tagId);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TaskTagsCompanion toCompanion(bool nullToAbsent) {
    return TaskTagsCompanion(
      taskId: Value(taskId),
      tagId: Value(tagId),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TaskTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTag(
      taskId: serializer.fromJson<String>(json['taskId']),
      tagId: serializer.fromJson<String>(json['tagId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'tagId': serializer.toJson<String>(tagId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  TaskTag copyWith({
    String? taskId,
    String? tagId,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => TaskTag(
    taskId: taskId ?? this.taskId,
    tagId: tagId ?? this.tagId,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TaskTag copyWithCompanion(TaskTagsCompanion data) {
    return TaskTag(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTag(')
          ..write('taskId: $taskId, ')
          ..write('tagId: $tagId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, tagId, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTag &&
          other.taskId == this.taskId &&
          other.tagId == this.tagId &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TaskTagsCompanion extends UpdateCompanion<TaskTag> {
  final Value<String> taskId;
  final Value<String> tagId;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TaskTagsCompanion({
    this.taskId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTagsCompanion.insert({
    required String taskId,
    required String tagId,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       tagId = Value(tagId),
       updatedAt = Value(updatedAt);
  static Insertable<TaskTag> custom({
    Expression<String>? taskId,
    Expression<String>? tagId,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (tagId != null) 'tag_id': tagId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTagsCompanion copyWith({
    Value<String>? taskId,
    Value<String>? tagId,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TaskTagsCompanion(
      taskId: taskId ?? this.taskId,
      tagId: tagId ?? this.tagId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTagsCompanion(')
          ..write('taskId: $taskId, ')
          ..write('tagId: $tagId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EcampusCoursesTable extends EcampusCourses
    with TableInfo<$EcampusCoursesTable, EcampusCourse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EcampusCoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceScopeIdMeta = const VerificationMeta(
    'sourceScopeId',
  );
  @override
  late final GeneratedColumn<String> sourceScopeId = GeneratedColumn<String>(
    'source_scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalCourseKeyMeta = const VerificationMeta(
    'externalCourseKey',
  );
  @override
  late final GeneratedColumn<String> externalCourseKey =
      GeneratedColumn<String>(
        'external_course_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES task_lists (id)',
    ),
  );
  static const VerificationMeta _lastObservedAtMeta = const VerificationMeta(
    'lastObservedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastObservedAt =
      GeneratedColumn<DateTime>(
        'last_observed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceScopeId,
    externalCourseKey,
    name,
    tagId,
    listId,
    lastObservedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ecampus_courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<EcampusCourse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_scope_id')) {
      context.handle(
        _sourceScopeIdMeta,
        sourceScopeId.isAcceptableOrUnknown(
          data['source_scope_id']!,
          _sourceScopeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceScopeIdMeta);
    }
    if (data.containsKey('external_course_key')) {
      context.handle(
        _externalCourseKeyMeta,
        externalCourseKey.isAcceptableOrUnknown(
          data['external_course_key']!,
          _externalCourseKeyMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    }
    if (data.containsKey('last_observed_at')) {
      context.handle(
        _lastObservedAtMeta,
        lastObservedAt.isAcceptableOrUnknown(
          data['last_observed_at']!,
          _lastObservedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastObservedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceScopeId, externalCourseKey},
  ];
  @override
  EcampusCourse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EcampusCourse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceScopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_scope_id'],
      )!,
      externalCourseKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_course_key'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      ),
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      ),
      lastObservedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_observed_at'],
      )!,
    );
  }

  @override
  $EcampusCoursesTable createAlias(String alias) {
    return $EcampusCoursesTable(attachedDatabase, alias);
  }
}

class EcampusCourse extends DataClass implements Insertable<EcampusCourse> {
  final String id;
  final String sourceScopeId;
  final String? externalCourseKey;
  final String name;
  final String? tagId;
  final String? listId;
  final DateTime lastObservedAt;
  const EcampusCourse({
    required this.id,
    required this.sourceScopeId,
    this.externalCourseKey,
    required this.name,
    this.tagId,
    this.listId,
    required this.lastObservedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_scope_id'] = Variable<String>(sourceScopeId);
    if (!nullToAbsent || externalCourseKey != null) {
      map['external_course_key'] = Variable<String>(externalCourseKey);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || tagId != null) {
      map['tag_id'] = Variable<String>(tagId);
    }
    if (!nullToAbsent || listId != null) {
      map['list_id'] = Variable<String>(listId);
    }
    map['last_observed_at'] = Variable<DateTime>(lastObservedAt);
    return map;
  }

  EcampusCoursesCompanion toCompanion(bool nullToAbsent) {
    return EcampusCoursesCompanion(
      id: Value(id),
      sourceScopeId: Value(sourceScopeId),
      externalCourseKey: externalCourseKey == null && nullToAbsent
          ? const Value.absent()
          : Value(externalCourseKey),
      name: Value(name),
      tagId: tagId == null && nullToAbsent
          ? const Value.absent()
          : Value(tagId),
      listId: listId == null && nullToAbsent
          ? const Value.absent()
          : Value(listId),
      lastObservedAt: Value(lastObservedAt),
    );
  }

  factory EcampusCourse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EcampusCourse(
      id: serializer.fromJson<String>(json['id']),
      sourceScopeId: serializer.fromJson<String>(json['sourceScopeId']),
      externalCourseKey: serializer.fromJson<String?>(
        json['externalCourseKey'],
      ),
      name: serializer.fromJson<String>(json['name']),
      tagId: serializer.fromJson<String?>(json['tagId']),
      listId: serializer.fromJson<String?>(json['listId']),
      lastObservedAt: serializer.fromJson<DateTime>(json['lastObservedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceScopeId': serializer.toJson<String>(sourceScopeId),
      'externalCourseKey': serializer.toJson<String?>(externalCourseKey),
      'name': serializer.toJson<String>(name),
      'tagId': serializer.toJson<String?>(tagId),
      'listId': serializer.toJson<String?>(listId),
      'lastObservedAt': serializer.toJson<DateTime>(lastObservedAt),
    };
  }

  EcampusCourse copyWith({
    String? id,
    String? sourceScopeId,
    Value<String?> externalCourseKey = const Value.absent(),
    String? name,
    Value<String?> tagId = const Value.absent(),
    Value<String?> listId = const Value.absent(),
    DateTime? lastObservedAt,
  }) => EcampusCourse(
    id: id ?? this.id,
    sourceScopeId: sourceScopeId ?? this.sourceScopeId,
    externalCourseKey: externalCourseKey.present
        ? externalCourseKey.value
        : this.externalCourseKey,
    name: name ?? this.name,
    tagId: tagId.present ? tagId.value : this.tagId,
    listId: listId.present ? listId.value : this.listId,
    lastObservedAt: lastObservedAt ?? this.lastObservedAt,
  );
  EcampusCourse copyWithCompanion(EcampusCoursesCompanion data) {
    return EcampusCourse(
      id: data.id.present ? data.id.value : this.id,
      sourceScopeId: data.sourceScopeId.present
          ? data.sourceScopeId.value
          : this.sourceScopeId,
      externalCourseKey: data.externalCourseKey.present
          ? data.externalCourseKey.value
          : this.externalCourseKey,
      name: data.name.present ? data.name.value : this.name,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      listId: data.listId.present ? data.listId.value : this.listId,
      lastObservedAt: data.lastObservedAt.present
          ? data.lastObservedAt.value
          : this.lastObservedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EcampusCourse(')
          ..write('id: $id, ')
          ..write('sourceScopeId: $sourceScopeId, ')
          ..write('externalCourseKey: $externalCourseKey, ')
          ..write('name: $name, ')
          ..write('tagId: $tagId, ')
          ..write('listId: $listId, ')
          ..write('lastObservedAt: $lastObservedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceScopeId,
    externalCourseKey,
    name,
    tagId,
    listId,
    lastObservedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EcampusCourse &&
          other.id == this.id &&
          other.sourceScopeId == this.sourceScopeId &&
          other.externalCourseKey == this.externalCourseKey &&
          other.name == this.name &&
          other.tagId == this.tagId &&
          other.listId == this.listId &&
          other.lastObservedAt == this.lastObservedAt);
}

class EcampusCoursesCompanion extends UpdateCompanion<EcampusCourse> {
  final Value<String> id;
  final Value<String> sourceScopeId;
  final Value<String?> externalCourseKey;
  final Value<String> name;
  final Value<String?> tagId;
  final Value<String?> listId;
  final Value<DateTime> lastObservedAt;
  final Value<int> rowid;
  const EcampusCoursesCompanion({
    this.id = const Value.absent(),
    this.sourceScopeId = const Value.absent(),
    this.externalCourseKey = const Value.absent(),
    this.name = const Value.absent(),
    this.tagId = const Value.absent(),
    this.listId = const Value.absent(),
    this.lastObservedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EcampusCoursesCompanion.insert({
    required String id,
    required String sourceScopeId,
    this.externalCourseKey = const Value.absent(),
    required String name,
    this.tagId = const Value.absent(),
    this.listId = const Value.absent(),
    required DateTime lastObservedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceScopeId = Value(sourceScopeId),
       name = Value(name),
       lastObservedAt = Value(lastObservedAt);
  static Insertable<EcampusCourse> custom({
    Expression<String>? id,
    Expression<String>? sourceScopeId,
    Expression<String>? externalCourseKey,
    Expression<String>? name,
    Expression<String>? tagId,
    Expression<String>? listId,
    Expression<DateTime>? lastObservedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceScopeId != null) 'source_scope_id': sourceScopeId,
      if (externalCourseKey != null) 'external_course_key': externalCourseKey,
      if (name != null) 'name': name,
      if (tagId != null) 'tag_id': tagId,
      if (listId != null) 'list_id': listId,
      if (lastObservedAt != null) 'last_observed_at': lastObservedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EcampusCoursesCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceScopeId,
    Value<String?>? externalCourseKey,
    Value<String>? name,
    Value<String?>? tagId,
    Value<String?>? listId,
    Value<DateTime>? lastObservedAt,
    Value<int>? rowid,
  }) {
    return EcampusCoursesCompanion(
      id: id ?? this.id,
      sourceScopeId: sourceScopeId ?? this.sourceScopeId,
      externalCourseKey: externalCourseKey ?? this.externalCourseKey,
      name: name ?? this.name,
      tagId: tagId ?? this.tagId,
      listId: listId ?? this.listId,
      lastObservedAt: lastObservedAt ?? this.lastObservedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceScopeId.present) {
      map['source_scope_id'] = Variable<String>(sourceScopeId.value);
    }
    if (externalCourseKey.present) {
      map['external_course_key'] = Variable<String>(externalCourseKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (lastObservedAt.present) {
      map['last_observed_at'] = Variable<DateTime>(lastObservedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EcampusCoursesCompanion(')
          ..write('id: $id, ')
          ..write('sourceScopeId: $sourceScopeId, ')
          ..write('externalCourseKey: $externalCourseKey, ')
          ..write('name: $name, ')
          ..write('tagId: $tagId, ')
          ..write('listId: $listId, ')
          ..write('lastObservedAt: $lastObservedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EcampusItemsTable extends EcampusItems
    with TableInfo<$EcampusItemsTable, EcampusItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EcampusItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceScopeIdMeta = const VerificationMeta(
    'sourceScopeId',
  );
  @override
  late final GeneratedColumn<String> sourceScopeId = GeneratedColumn<String>(
    'source_scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ecampus_courses (id)',
    ),
  );
  static const VerificationMeta _externalKeyMeta = const VerificationMeta(
    'externalKey',
  );
  @override
  late final GeneratedColumn<String> externalKey = GeneratedColumn<String>(
    'external_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTitleMeta = const VerificationMeta(
    'sourceTitle',
  );
  @override
  late final GeneratedColumn<String> sourceTitle = GeneratedColumn<String>(
    'source_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceCourseMeta = const VerificationMeta(
    'sourceCourse',
  );
  @override
  late final GeneratedColumn<String> sourceCourse = GeneratedColumn<String>(
    'source_course',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceStartAtMeta = const VerificationMeta(
    'sourceStartAt',
  );
  @override
  late final GeneratedColumn<DateTime> sourceStartAt =
      GeneratedColumn<DateTime>(
        'source_start_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sourceEndAtMeta = const VerificationMeta(
    'sourceEndAt',
  );
  @override
  late final GeneratedColumn<DateTime> sourceEndAt = GeneratedColumn<DateTime>(
    'source_end_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES tasks (id)',
    ),
  );
  static const VerificationMeta _importStateMeta = const VerificationMeta(
    'importState',
  );
  @override
  late final GeneratedColumn<String> importState = GeneratedColumn<String>(
    'import_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstObservedAtMeta = const VerificationMeta(
    'firstObservedAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstObservedAt =
      GeneratedColumn<DateTime>(
        'first_observed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastObservedAtMeta = const VerificationMeta(
    'lastObservedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastObservedAt =
      GeneratedColumn<DateTime>(
        'last_observed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceScopeId,
    courseId,
    externalKey,
    sourceTitle,
    sourceCourse,
    sourceType,
    sourceStartAt,
    sourceEndAt,
    taskId,
    importState,
    firstObservedAt,
    lastObservedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ecampus_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<EcampusItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_scope_id')) {
      context.handle(
        _sourceScopeIdMeta,
        sourceScopeId.isAcceptableOrUnknown(
          data['source_scope_id']!,
          _sourceScopeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceScopeIdMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    }
    if (data.containsKey('external_key')) {
      context.handle(
        _externalKeyMeta,
        externalKey.isAcceptableOrUnknown(
          data['external_key']!,
          _externalKeyMeta,
        ),
      );
    }
    if (data.containsKey('source_title')) {
      context.handle(
        _sourceTitleMeta,
        sourceTitle.isAcceptableOrUnknown(
          data['source_title']!,
          _sourceTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceTitleMeta);
    }
    if (data.containsKey('source_course')) {
      context.handle(
        _sourceCourseMeta,
        sourceCourse.isAcceptableOrUnknown(
          data['source_course']!,
          _sourceCourseMeta,
        ),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('source_start_at')) {
      context.handle(
        _sourceStartAtMeta,
        sourceStartAt.isAcceptableOrUnknown(
          data['source_start_at']!,
          _sourceStartAtMeta,
        ),
      );
    }
    if (data.containsKey('source_end_at')) {
      context.handle(
        _sourceEndAtMeta,
        sourceEndAt.isAcceptableOrUnknown(
          data['source_end_at']!,
          _sourceEndAtMeta,
        ),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('import_state')) {
      context.handle(
        _importStateMeta,
        importState.isAcceptableOrUnknown(
          data['import_state']!,
          _importStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importStateMeta);
    }
    if (data.containsKey('first_observed_at')) {
      context.handle(
        _firstObservedAtMeta,
        firstObservedAt.isAcceptableOrUnknown(
          data['first_observed_at']!,
          _firstObservedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstObservedAtMeta);
    }
    if (data.containsKey('last_observed_at')) {
      context.handle(
        _lastObservedAtMeta,
        lastObservedAt.isAcceptableOrUnknown(
          data['last_observed_at']!,
          _lastObservedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastObservedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceScopeId, externalKey},
  ];
  @override
  EcampusItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EcampusItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceScopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_scope_id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      ),
      externalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_key'],
      ),
      sourceTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_title'],
      )!,
      sourceCourse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_course'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      ),
      sourceStartAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}source_start_at'],
      ),
      sourceEndAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}source_end_at'],
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      importState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_state'],
      )!,
      firstObservedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_observed_at'],
      )!,
      lastObservedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_observed_at'],
      )!,
    );
  }

  @override
  $EcampusItemsTable createAlias(String alias) {
    return $EcampusItemsTable(attachedDatabase, alias);
  }
}

class EcampusItem extends DataClass implements Insertable<EcampusItem> {
  final String id;
  final String sourceScopeId;
  final String? courseId;
  final String? externalKey;
  final String sourceTitle;
  final String? sourceCourse;
  final String? sourceType;
  final DateTime? sourceStartAt;
  final DateTime? sourceEndAt;
  final String? taskId;
  final String importState;
  final DateTime firstObservedAt;
  final DateTime lastObservedAt;
  const EcampusItem({
    required this.id,
    required this.sourceScopeId,
    this.courseId,
    this.externalKey,
    required this.sourceTitle,
    this.sourceCourse,
    this.sourceType,
    this.sourceStartAt,
    this.sourceEndAt,
    this.taskId,
    required this.importState,
    required this.firstObservedAt,
    required this.lastObservedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_scope_id'] = Variable<String>(sourceScopeId);
    if (!nullToAbsent || courseId != null) {
      map['course_id'] = Variable<String>(courseId);
    }
    if (!nullToAbsent || externalKey != null) {
      map['external_key'] = Variable<String>(externalKey);
    }
    map['source_title'] = Variable<String>(sourceTitle);
    if (!nullToAbsent || sourceCourse != null) {
      map['source_course'] = Variable<String>(sourceCourse);
    }
    if (!nullToAbsent || sourceType != null) {
      map['source_type'] = Variable<String>(sourceType);
    }
    if (!nullToAbsent || sourceStartAt != null) {
      map['source_start_at'] = Variable<DateTime>(sourceStartAt);
    }
    if (!nullToAbsent || sourceEndAt != null) {
      map['source_end_at'] = Variable<DateTime>(sourceEndAt);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['import_state'] = Variable<String>(importState);
    map['first_observed_at'] = Variable<DateTime>(firstObservedAt);
    map['last_observed_at'] = Variable<DateTime>(lastObservedAt);
    return map;
  }

  EcampusItemsCompanion toCompanion(bool nullToAbsent) {
    return EcampusItemsCompanion(
      id: Value(id),
      sourceScopeId: Value(sourceScopeId),
      courseId: courseId == null && nullToAbsent
          ? const Value.absent()
          : Value(courseId),
      externalKey: externalKey == null && nullToAbsent
          ? const Value.absent()
          : Value(externalKey),
      sourceTitle: Value(sourceTitle),
      sourceCourse: sourceCourse == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceCourse),
      sourceType: sourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceType),
      sourceStartAt: sourceStartAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceStartAt),
      sourceEndAt: sourceEndAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceEndAt),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      importState: Value(importState),
      firstObservedAt: Value(firstObservedAt),
      lastObservedAt: Value(lastObservedAt),
    );
  }

  factory EcampusItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EcampusItem(
      id: serializer.fromJson<String>(json['id']),
      sourceScopeId: serializer.fromJson<String>(json['sourceScopeId']),
      courseId: serializer.fromJson<String?>(json['courseId']),
      externalKey: serializer.fromJson<String?>(json['externalKey']),
      sourceTitle: serializer.fromJson<String>(json['sourceTitle']),
      sourceCourse: serializer.fromJson<String?>(json['sourceCourse']),
      sourceType: serializer.fromJson<String?>(json['sourceType']),
      sourceStartAt: serializer.fromJson<DateTime?>(json['sourceStartAt']),
      sourceEndAt: serializer.fromJson<DateTime?>(json['sourceEndAt']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      importState: serializer.fromJson<String>(json['importState']),
      firstObservedAt: serializer.fromJson<DateTime>(json['firstObservedAt']),
      lastObservedAt: serializer.fromJson<DateTime>(json['lastObservedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceScopeId': serializer.toJson<String>(sourceScopeId),
      'courseId': serializer.toJson<String?>(courseId),
      'externalKey': serializer.toJson<String?>(externalKey),
      'sourceTitle': serializer.toJson<String>(sourceTitle),
      'sourceCourse': serializer.toJson<String?>(sourceCourse),
      'sourceType': serializer.toJson<String?>(sourceType),
      'sourceStartAt': serializer.toJson<DateTime?>(sourceStartAt),
      'sourceEndAt': serializer.toJson<DateTime?>(sourceEndAt),
      'taskId': serializer.toJson<String?>(taskId),
      'importState': serializer.toJson<String>(importState),
      'firstObservedAt': serializer.toJson<DateTime>(firstObservedAt),
      'lastObservedAt': serializer.toJson<DateTime>(lastObservedAt),
    };
  }

  EcampusItem copyWith({
    String? id,
    String? sourceScopeId,
    Value<String?> courseId = const Value.absent(),
    Value<String?> externalKey = const Value.absent(),
    String? sourceTitle,
    Value<String?> sourceCourse = const Value.absent(),
    Value<String?> sourceType = const Value.absent(),
    Value<DateTime?> sourceStartAt = const Value.absent(),
    Value<DateTime?> sourceEndAt = const Value.absent(),
    Value<String?> taskId = const Value.absent(),
    String? importState,
    DateTime? firstObservedAt,
    DateTime? lastObservedAt,
  }) => EcampusItem(
    id: id ?? this.id,
    sourceScopeId: sourceScopeId ?? this.sourceScopeId,
    courseId: courseId.present ? courseId.value : this.courseId,
    externalKey: externalKey.present ? externalKey.value : this.externalKey,
    sourceTitle: sourceTitle ?? this.sourceTitle,
    sourceCourse: sourceCourse.present ? sourceCourse.value : this.sourceCourse,
    sourceType: sourceType.present ? sourceType.value : this.sourceType,
    sourceStartAt: sourceStartAt.present
        ? sourceStartAt.value
        : this.sourceStartAt,
    sourceEndAt: sourceEndAt.present ? sourceEndAt.value : this.sourceEndAt,
    taskId: taskId.present ? taskId.value : this.taskId,
    importState: importState ?? this.importState,
    firstObservedAt: firstObservedAt ?? this.firstObservedAt,
    lastObservedAt: lastObservedAt ?? this.lastObservedAt,
  );
  EcampusItem copyWithCompanion(EcampusItemsCompanion data) {
    return EcampusItem(
      id: data.id.present ? data.id.value : this.id,
      sourceScopeId: data.sourceScopeId.present
          ? data.sourceScopeId.value
          : this.sourceScopeId,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      externalKey: data.externalKey.present
          ? data.externalKey.value
          : this.externalKey,
      sourceTitle: data.sourceTitle.present
          ? data.sourceTitle.value
          : this.sourceTitle,
      sourceCourse: data.sourceCourse.present
          ? data.sourceCourse.value
          : this.sourceCourse,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceStartAt: data.sourceStartAt.present
          ? data.sourceStartAt.value
          : this.sourceStartAt,
      sourceEndAt: data.sourceEndAt.present
          ? data.sourceEndAt.value
          : this.sourceEndAt,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      importState: data.importState.present
          ? data.importState.value
          : this.importState,
      firstObservedAt: data.firstObservedAt.present
          ? data.firstObservedAt.value
          : this.firstObservedAt,
      lastObservedAt: data.lastObservedAt.present
          ? data.lastObservedAt.value
          : this.lastObservedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EcampusItem(')
          ..write('id: $id, ')
          ..write('sourceScopeId: $sourceScopeId, ')
          ..write('courseId: $courseId, ')
          ..write('externalKey: $externalKey, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('sourceCourse: $sourceCourse, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceStartAt: $sourceStartAt, ')
          ..write('sourceEndAt: $sourceEndAt, ')
          ..write('taskId: $taskId, ')
          ..write('importState: $importState, ')
          ..write('firstObservedAt: $firstObservedAt, ')
          ..write('lastObservedAt: $lastObservedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceScopeId,
    courseId,
    externalKey,
    sourceTitle,
    sourceCourse,
    sourceType,
    sourceStartAt,
    sourceEndAt,
    taskId,
    importState,
    firstObservedAt,
    lastObservedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EcampusItem &&
          other.id == this.id &&
          other.sourceScopeId == this.sourceScopeId &&
          other.courseId == this.courseId &&
          other.externalKey == this.externalKey &&
          other.sourceTitle == this.sourceTitle &&
          other.sourceCourse == this.sourceCourse &&
          other.sourceType == this.sourceType &&
          other.sourceStartAt == this.sourceStartAt &&
          other.sourceEndAt == this.sourceEndAt &&
          other.taskId == this.taskId &&
          other.importState == this.importState &&
          other.firstObservedAt == this.firstObservedAt &&
          other.lastObservedAt == this.lastObservedAt);
}

class EcampusItemsCompanion extends UpdateCompanion<EcampusItem> {
  final Value<String> id;
  final Value<String> sourceScopeId;
  final Value<String?> courseId;
  final Value<String?> externalKey;
  final Value<String> sourceTitle;
  final Value<String?> sourceCourse;
  final Value<String?> sourceType;
  final Value<DateTime?> sourceStartAt;
  final Value<DateTime?> sourceEndAt;
  final Value<String?> taskId;
  final Value<String> importState;
  final Value<DateTime> firstObservedAt;
  final Value<DateTime> lastObservedAt;
  final Value<int> rowid;
  const EcampusItemsCompanion({
    this.id = const Value.absent(),
    this.sourceScopeId = const Value.absent(),
    this.courseId = const Value.absent(),
    this.externalKey = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.sourceCourse = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceStartAt = const Value.absent(),
    this.sourceEndAt = const Value.absent(),
    this.taskId = const Value.absent(),
    this.importState = const Value.absent(),
    this.firstObservedAt = const Value.absent(),
    this.lastObservedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EcampusItemsCompanion.insert({
    required String id,
    required String sourceScopeId,
    this.courseId = const Value.absent(),
    this.externalKey = const Value.absent(),
    required String sourceTitle,
    this.sourceCourse = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceStartAt = const Value.absent(),
    this.sourceEndAt = const Value.absent(),
    this.taskId = const Value.absent(),
    required String importState,
    required DateTime firstObservedAt,
    required DateTime lastObservedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceScopeId = Value(sourceScopeId),
       sourceTitle = Value(sourceTitle),
       importState = Value(importState),
       firstObservedAt = Value(firstObservedAt),
       lastObservedAt = Value(lastObservedAt);
  static Insertable<EcampusItem> custom({
    Expression<String>? id,
    Expression<String>? sourceScopeId,
    Expression<String>? courseId,
    Expression<String>? externalKey,
    Expression<String>? sourceTitle,
    Expression<String>? sourceCourse,
    Expression<String>? sourceType,
    Expression<DateTime>? sourceStartAt,
    Expression<DateTime>? sourceEndAt,
    Expression<String>? taskId,
    Expression<String>? importState,
    Expression<DateTime>? firstObservedAt,
    Expression<DateTime>? lastObservedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceScopeId != null) 'source_scope_id': sourceScopeId,
      if (courseId != null) 'course_id': courseId,
      if (externalKey != null) 'external_key': externalKey,
      if (sourceTitle != null) 'source_title': sourceTitle,
      if (sourceCourse != null) 'source_course': sourceCourse,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceStartAt != null) 'source_start_at': sourceStartAt,
      if (sourceEndAt != null) 'source_end_at': sourceEndAt,
      if (taskId != null) 'task_id': taskId,
      if (importState != null) 'import_state': importState,
      if (firstObservedAt != null) 'first_observed_at': firstObservedAt,
      if (lastObservedAt != null) 'last_observed_at': lastObservedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EcampusItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceScopeId,
    Value<String?>? courseId,
    Value<String?>? externalKey,
    Value<String>? sourceTitle,
    Value<String?>? sourceCourse,
    Value<String?>? sourceType,
    Value<DateTime?>? sourceStartAt,
    Value<DateTime?>? sourceEndAt,
    Value<String?>? taskId,
    Value<String>? importState,
    Value<DateTime>? firstObservedAt,
    Value<DateTime>? lastObservedAt,
    Value<int>? rowid,
  }) {
    return EcampusItemsCompanion(
      id: id ?? this.id,
      sourceScopeId: sourceScopeId ?? this.sourceScopeId,
      courseId: courseId ?? this.courseId,
      externalKey: externalKey ?? this.externalKey,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceCourse: sourceCourse ?? this.sourceCourse,
      sourceType: sourceType ?? this.sourceType,
      sourceStartAt: sourceStartAt ?? this.sourceStartAt,
      sourceEndAt: sourceEndAt ?? this.sourceEndAt,
      taskId: taskId ?? this.taskId,
      importState: importState ?? this.importState,
      firstObservedAt: firstObservedAt ?? this.firstObservedAt,
      lastObservedAt: lastObservedAt ?? this.lastObservedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceScopeId.present) {
      map['source_scope_id'] = Variable<String>(sourceScopeId.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (externalKey.present) {
      map['external_key'] = Variable<String>(externalKey.value);
    }
    if (sourceTitle.present) {
      map['source_title'] = Variable<String>(sourceTitle.value);
    }
    if (sourceCourse.present) {
      map['source_course'] = Variable<String>(sourceCourse.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceStartAt.present) {
      map['source_start_at'] = Variable<DateTime>(sourceStartAt.value);
    }
    if (sourceEndAt.present) {
      map['source_end_at'] = Variable<DateTime>(sourceEndAt.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (importState.present) {
      map['import_state'] = Variable<String>(importState.value);
    }
    if (firstObservedAt.present) {
      map['first_observed_at'] = Variable<DateTime>(firstObservedAt.value);
    }
    if (lastObservedAt.present) {
      map['last_observed_at'] = Variable<DateTime>(lastObservedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EcampusItemsCompanion(')
          ..write('id: $id, ')
          ..write('sourceScopeId: $sourceScopeId, ')
          ..write('courseId: $courseId, ')
          ..write('externalKey: $externalKey, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('sourceCourse: $sourceCourse, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceStartAt: $sourceStartAt, ')
          ..write('sourceEndAt: $sourceEndAt, ')
          ..write('taskId: $taskId, ')
          ..write('importState: $importState, ')
          ..write('firstObservedAt: $firstObservedAt, ')
          ..write('lastObservedAt: $lastObservedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportSessionsTable extends ImportSessions
    with TableInfo<$ImportSessionsTable, ImportSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ecampus'),
  );
  static const VerificationMeta _inputMethodMeta = const VerificationMeta(
    'inputMethod',
  );
  @override
  late final GeneratedColumn<String> inputMethod = GeneratedColumn<String>(
    'input_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('webview_html'),
  );
  static const VerificationMeta _sourceScopeIdMeta = const VerificationMeta(
    'sourceScopeId',
  );
  @override
  late final GeneratedColumn<String> sourceScopeId = GeneratedColumn<String>(
    'source_scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedCountMeta = const VerificationMeta(
    'appliedCount',
  );
  @override
  late final GeneratedColumn<int> appliedCount = GeneratedColumn<int>(
    'applied_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    provider,
    inputMethod,
    sourceScopeId,
    startedAt,
    endedAt,
    state,
    appliedCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    }
    if (data.containsKey('input_method')) {
      context.handle(
        _inputMethodMeta,
        inputMethod.isAcceptableOrUnknown(
          data['input_method']!,
          _inputMethodMeta,
        ),
      );
    }
    if (data.containsKey('source_scope_id')) {
      context.handle(
        _sourceScopeIdMeta,
        sourceScopeId.isAcceptableOrUnknown(
          data['source_scope_id']!,
          _sourceScopeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceScopeIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('applied_count')) {
      context.handle(
        _appliedCountMeta,
        appliedCount.isAcceptableOrUnknown(
          data['applied_count']!,
          _appliedCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      inputMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_method'],
      )!,
      sourceScopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_scope_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      appliedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_count'],
      )!,
    );
  }

  @override
  $ImportSessionsTable createAlias(String alias) {
    return $ImportSessionsTable(attachedDatabase, alias);
  }
}

class ImportSession extends DataClass implements Insertable<ImportSession> {
  final String id;
  final String provider;
  final String inputMethod;
  final String sourceScopeId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String state;
  final int appliedCount;
  const ImportSession({
    required this.id,
    required this.provider,
    required this.inputMethod,
    required this.sourceScopeId,
    required this.startedAt,
    this.endedAt,
    required this.state,
    required this.appliedCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider'] = Variable<String>(provider);
    map['input_method'] = Variable<String>(inputMethod);
    map['source_scope_id'] = Variable<String>(sourceScopeId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['state'] = Variable<String>(state);
    map['applied_count'] = Variable<int>(appliedCount);
    return map;
  }

  ImportSessionsCompanion toCompanion(bool nullToAbsent) {
    return ImportSessionsCompanion(
      id: Value(id),
      provider: Value(provider),
      inputMethod: Value(inputMethod),
      sourceScopeId: Value(sourceScopeId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      state: Value(state),
      appliedCount: Value(appliedCount),
    );
  }

  factory ImportSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportSession(
      id: serializer.fromJson<String>(json['id']),
      provider: serializer.fromJson<String>(json['provider']),
      inputMethod: serializer.fromJson<String>(json['inputMethod']),
      sourceScopeId: serializer.fromJson<String>(json['sourceScopeId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      state: serializer.fromJson<String>(json['state']),
      appliedCount: serializer.fromJson<int>(json['appliedCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'provider': serializer.toJson<String>(provider),
      'inputMethod': serializer.toJson<String>(inputMethod),
      'sourceScopeId': serializer.toJson<String>(sourceScopeId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'state': serializer.toJson<String>(state),
      'appliedCount': serializer.toJson<int>(appliedCount),
    };
  }

  ImportSession copyWith({
    String? id,
    String? provider,
    String? inputMethod,
    String? sourceScopeId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    String? state,
    int? appliedCount,
  }) => ImportSession(
    id: id ?? this.id,
    provider: provider ?? this.provider,
    inputMethod: inputMethod ?? this.inputMethod,
    sourceScopeId: sourceScopeId ?? this.sourceScopeId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    state: state ?? this.state,
    appliedCount: appliedCount ?? this.appliedCount,
  );
  ImportSession copyWithCompanion(ImportSessionsCompanion data) {
    return ImportSession(
      id: data.id.present ? data.id.value : this.id,
      provider: data.provider.present ? data.provider.value : this.provider,
      inputMethod: data.inputMethod.present
          ? data.inputMethod.value
          : this.inputMethod,
      sourceScopeId: data.sourceScopeId.present
          ? data.sourceScopeId.value
          : this.sourceScopeId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      state: data.state.present ? data.state.value : this.state,
      appliedCount: data.appliedCount.present
          ? data.appliedCount.value
          : this.appliedCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportSession(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('inputMethod: $inputMethod, ')
          ..write('sourceScopeId: $sourceScopeId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('state: $state, ')
          ..write('appliedCount: $appliedCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    provider,
    inputMethod,
    sourceScopeId,
    startedAt,
    endedAt,
    state,
    appliedCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportSession &&
          other.id == this.id &&
          other.provider == this.provider &&
          other.inputMethod == this.inputMethod &&
          other.sourceScopeId == this.sourceScopeId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.state == this.state &&
          other.appliedCount == this.appliedCount);
}

class ImportSessionsCompanion extends UpdateCompanion<ImportSession> {
  final Value<String> id;
  final Value<String> provider;
  final Value<String> inputMethod;
  final Value<String> sourceScopeId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String> state;
  final Value<int> appliedCount;
  final Value<int> rowid;
  const ImportSessionsCompanion({
    this.id = const Value.absent(),
    this.provider = const Value.absent(),
    this.inputMethod = const Value.absent(),
    this.sourceScopeId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.state = const Value.absent(),
    this.appliedCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportSessionsCompanion.insert({
    required String id,
    this.provider = const Value.absent(),
    this.inputMethod = const Value.absent(),
    required String sourceScopeId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required String state,
    this.appliedCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceScopeId = Value(sourceScopeId),
       startedAt = Value(startedAt),
       state = Value(state);
  static Insertable<ImportSession> custom({
    Expression<String>? id,
    Expression<String>? provider,
    Expression<String>? inputMethod,
    Expression<String>? sourceScopeId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? state,
    Expression<int>? appliedCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (provider != null) 'provider': provider,
      if (inputMethod != null) 'input_method': inputMethod,
      if (sourceScopeId != null) 'source_scope_id': sourceScopeId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (state != null) 'state': state,
      if (appliedCount != null) 'applied_count': appliedCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? provider,
    Value<String>? inputMethod,
    Value<String>? sourceScopeId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String>? state,
    Value<int>? appliedCount,
    Value<int>? rowid,
  }) {
    return ImportSessionsCompanion(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      inputMethod: inputMethod ?? this.inputMethod,
      sourceScopeId: sourceScopeId ?? this.sourceScopeId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      state: state ?? this.state,
      appliedCount: appliedCount ?? this.appliedCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (inputMethod.present) {
      map['input_method'] = Variable<String>(inputMethod.value);
    }
    if (sourceScopeId.present) {
      map['source_scope_id'] = Variable<String>(sourceScopeId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (appliedCount.present) {
      map['applied_count'] = Variable<int>(appliedCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportSessionsCompanion(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('inputMethod: $inputMethod, ')
          ..write('sourceScopeId: $sourceScopeId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('state: $state, ')
          ..write('appliedCount: $appliedCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskRemindersTable extends TaskReminders
    with TableInfo<$TaskRemindersTable, TaskReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _offsetMinutesMeta = const VerificationMeta(
    'offsetMinutes',
  );
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
    'offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    enabled,
    offsetMinutes,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskReminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('offset_minutes')) {
      context.handle(
        _offsetMinutesMeta,
        offsetMinutes.isAcceptableOrUnknown(
          data['offset_minutes']!,
          _offsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offsetMinutesMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId};
  @override
  TaskReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskReminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      offsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_minutes'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TaskRemindersTable createAlias(String alias) {
    return $TaskRemindersTable(attachedDatabase, alias);
  }
}

class TaskReminder extends DataClass implements Insertable<TaskReminder> {
  final String id;
  final String taskId;
  final bool enabled;
  final int offsetMinutes;
  final DateTime updatedAt;
  const TaskReminder({
    required this.id,
    required this.taskId,
    required this.enabled,
    required this.offsetMinutes,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['enabled'] = Variable<bool>(enabled);
    map['offset_minutes'] = Variable<int>(offsetMinutes);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TaskRemindersCompanion toCompanion(bool nullToAbsent) {
    return TaskRemindersCompanion(
      id: Value(id),
      taskId: Value(taskId),
      enabled: Value(enabled),
      offsetMinutes: Value(offsetMinutes),
      updatedAt: Value(updatedAt),
    );
  }

  factory TaskReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskReminder(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      offsetMinutes: serializer.fromJson<int>(json['offsetMinutes']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'enabled': serializer.toJson<bool>(enabled),
      'offsetMinutes': serializer.toJson<int>(offsetMinutes),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TaskReminder copyWith({
    String? id,
    String? taskId,
    bool? enabled,
    int? offsetMinutes,
    DateTime? updatedAt,
  }) => TaskReminder(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    enabled: enabled ?? this.enabled,
    offsetMinutes: offsetMinutes ?? this.offsetMinutes,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TaskReminder copyWithCompanion(TaskRemindersCompanion data) {
    return TaskReminder(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      offsetMinutes: data.offsetMinutes.present
          ? data.offsetMinutes.value
          : this.offsetMinutes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskReminder(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('enabled: $enabled, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, enabled, offsetMinutes, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskReminder &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.enabled == this.enabled &&
          other.offsetMinutes == this.offsetMinutes &&
          other.updatedAt == this.updatedAt);
}

class TaskRemindersCompanion extends UpdateCompanion<TaskReminder> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<bool> enabled;
  final Value<int> offsetMinutes;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TaskRemindersCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskRemindersCompanion.insert({
    required String id,
    required String taskId,
    required bool enabled,
    required int offsetMinutes,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       enabled = Value(enabled),
       offsetMinutes = Value(offsetMinutes),
       updatedAt = Value(updatedAt);
  static Insertable<TaskReminder> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<bool>? enabled,
    Expression<int>? offsetMinutes,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (enabled != null) 'enabled': enabled,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskRemindersCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<bool>? enabled,
    Value<int>? offsetMinutes,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TaskRemindersCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      enabled: enabled ?? this.enabled,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRemindersCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('enabled: $enabled, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalNotificationSchedulesTable extends LocalNotificationSchedules
    with
        TableInfo<$LocalNotificationSchedulesTable, LocalNotificationSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNotificationSchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  static const VerificationMeta _platformNotificationIdMeta =
      const VerificationMeta('platformNotificationId');
  @override
  late final GeneratedColumn<int> platformNotificationId = GeneratedColumn<int>(
    'platform_notification_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    taskId,
    platformNotificationId,
    scheduledAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_notification_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalNotificationSchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('platform_notification_id')) {
      context.handle(
        _platformNotificationIdMeta,
        platformNotificationId.isAcceptableOrUnknown(
          data['platform_notification_id']!,
          _platformNotificationIdMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId};
  @override
  LocalNotificationSchedule map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalNotificationSchedule(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      platformNotificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}platform_notification_id'],
      ),
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $LocalNotificationSchedulesTable createAlias(String alias) {
    return $LocalNotificationSchedulesTable(attachedDatabase, alias);
  }
}

class LocalNotificationSchedule extends DataClass
    implements Insertable<LocalNotificationSchedule> {
  final String taskId;
  final int? platformNotificationId;
  final DateTime? scheduledAt;
  final String? lastError;
  const LocalNotificationSchedule({
    required this.taskId,
    this.platformNotificationId,
    this.scheduledAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    if (!nullToAbsent || platformNotificationId != null) {
      map['platform_notification_id'] = Variable<int>(platformNotificationId);
    }
    if (!nullToAbsent || scheduledAt != null) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  LocalNotificationSchedulesCompanion toCompanion(bool nullToAbsent) {
    return LocalNotificationSchedulesCompanion(
      taskId: Value(taskId),
      platformNotificationId: platformNotificationId == null && nullToAbsent
          ? const Value.absent()
          : Value(platformNotificationId),
      scheduledAt: scheduledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory LocalNotificationSchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalNotificationSchedule(
      taskId: serializer.fromJson<String>(json['taskId']),
      platformNotificationId: serializer.fromJson<int?>(
        json['platformNotificationId'],
      ),
      scheduledAt: serializer.fromJson<DateTime?>(json['scheduledAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'platformNotificationId': serializer.toJson<int?>(platformNotificationId),
      'scheduledAt': serializer.toJson<DateTime?>(scheduledAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  LocalNotificationSchedule copyWith({
    String? taskId,
    Value<int?> platformNotificationId = const Value.absent(),
    Value<DateTime?> scheduledAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => LocalNotificationSchedule(
    taskId: taskId ?? this.taskId,
    platformNotificationId: platformNotificationId.present
        ? platformNotificationId.value
        : this.platformNotificationId,
    scheduledAt: scheduledAt.present ? scheduledAt.value : this.scheduledAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  LocalNotificationSchedule copyWithCompanion(
    LocalNotificationSchedulesCompanion data,
  ) {
    return LocalNotificationSchedule(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      platformNotificationId: data.platformNotificationId.present
          ? data.platformNotificationId.value
          : this.platformNotificationId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotificationSchedule(')
          ..write('taskId: $taskId, ')
          ..write('platformNotificationId: $platformNotificationId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(taskId, platformNotificationId, scheduledAt, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalNotificationSchedule &&
          other.taskId == this.taskId &&
          other.platformNotificationId == this.platformNotificationId &&
          other.scheduledAt == this.scheduledAt &&
          other.lastError == this.lastError);
}

class LocalNotificationSchedulesCompanion
    extends UpdateCompanion<LocalNotificationSchedule> {
  final Value<String> taskId;
  final Value<int?> platformNotificationId;
  final Value<DateTime?> scheduledAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const LocalNotificationSchedulesCompanion({
    this.taskId = const Value.absent(),
    this.platformNotificationId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalNotificationSchedulesCompanion.insert({
    required String taskId,
    this.platformNotificationId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId);
  static Insertable<LocalNotificationSchedule> custom({
    Expression<String>? taskId,
    Expression<int>? platformNotificationId,
    Expression<DateTime>? scheduledAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (platformNotificationId != null)
        'platform_notification_id': platformNotificationId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalNotificationSchedulesCompanion copyWith({
    Value<String>? taskId,
    Value<int?>? platformNotificationId,
    Value<DateTime?>? scheduledAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return LocalNotificationSchedulesCompanion(
      taskId: taskId ?? this.taskId,
      platformNotificationId:
          platformNotificationId ?? this.platformNotificationId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (platformNotificationId.present) {
      map['platform_notification_id'] = Variable<int>(
        platformNotificationId.value,
      );
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotificationSchedulesCompanion(')
          ..write('taskId: $taskId, ')
          ..write('platformNotificationId: $platformNotificationId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MigrationIssuesTable extends MigrationIssues
    with TableInfo<$MigrationIssuesTable, MigrationIssue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MigrationIssuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legacyDataMeta = const VerificationMeta(
    'legacyData',
  );
  @override
  late final GeneratedColumn<String> legacyData = GeneratedColumn<String>(
    'legacy_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, entityId, reason, legacyData];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_issues';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationIssue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('legacy_data')) {
      context.handle(
        _legacyDataMeta,
        legacyData.isAcceptableOrUnknown(data['legacy_data']!, _legacyDataMeta),
      );
    } else if (isInserting) {
      context.missing(_legacyDataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MigrationIssue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationIssue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      legacyData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_data'],
      )!,
    );
  }

  @override
  $MigrationIssuesTable createAlias(String alias) {
    return $MigrationIssuesTable(attachedDatabase, alias);
  }
}

class MigrationIssue extends DataClass implements Insertable<MigrationIssue> {
  final int id;
  final String entityId;
  final String reason;
  final String legacyData;
  const MigrationIssue({
    required this.id,
    required this.entityId,
    required this.reason,
    required this.legacyData,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_id'] = Variable<String>(entityId);
    map['reason'] = Variable<String>(reason);
    map['legacy_data'] = Variable<String>(legacyData);
    return map;
  }

  MigrationIssuesCompanion toCompanion(bool nullToAbsent) {
    return MigrationIssuesCompanion(
      id: Value(id),
      entityId: Value(entityId),
      reason: Value(reason),
      legacyData: Value(legacyData),
    );
  }

  factory MigrationIssue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationIssue(
      id: serializer.fromJson<int>(json['id']),
      entityId: serializer.fromJson<String>(json['entityId']),
      reason: serializer.fromJson<String>(json['reason']),
      legacyData: serializer.fromJson<String>(json['legacyData']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityId': serializer.toJson<String>(entityId),
      'reason': serializer.toJson<String>(reason),
      'legacyData': serializer.toJson<String>(legacyData),
    };
  }

  MigrationIssue copyWith({
    int? id,
    String? entityId,
    String? reason,
    String? legacyData,
  }) => MigrationIssue(
    id: id ?? this.id,
    entityId: entityId ?? this.entityId,
    reason: reason ?? this.reason,
    legacyData: legacyData ?? this.legacyData,
  );
  MigrationIssue copyWithCompanion(MigrationIssuesCompanion data) {
    return MigrationIssue(
      id: data.id.present ? data.id.value : this.id,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      reason: data.reason.present ? data.reason.value : this.reason,
      legacyData: data.legacyData.present
          ? data.legacyData.value
          : this.legacyData,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationIssue(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('reason: $reason, ')
          ..write('legacyData: $legacyData')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityId, reason, legacyData);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationIssue &&
          other.id == this.id &&
          other.entityId == this.entityId &&
          other.reason == this.reason &&
          other.legacyData == this.legacyData);
}

class MigrationIssuesCompanion extends UpdateCompanion<MigrationIssue> {
  final Value<int> id;
  final Value<String> entityId;
  final Value<String> reason;
  final Value<String> legacyData;
  const MigrationIssuesCompanion({
    this.id = const Value.absent(),
    this.entityId = const Value.absent(),
    this.reason = const Value.absent(),
    this.legacyData = const Value.absent(),
  });
  MigrationIssuesCompanion.insert({
    this.id = const Value.absent(),
    required String entityId,
    required String reason,
    required String legacyData,
  }) : entityId = Value(entityId),
       reason = Value(reason),
       legacyData = Value(legacyData);
  static Insertable<MigrationIssue> custom({
    Expression<int>? id,
    Expression<String>? entityId,
    Expression<String>? reason,
    Expression<String>? legacyData,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityId != null) 'entity_id': entityId,
      if (reason != null) 'reason': reason,
      if (legacyData != null) 'legacy_data': legacyData,
    });
  }

  MigrationIssuesCompanion copyWith({
    Value<int>? id,
    Value<String>? entityId,
    Value<String>? reason,
    Value<String>? legacyData,
  }) {
    return MigrationIssuesCompanion(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      reason: reason ?? this.reason,
      legacyData: legacyData ?? this.legacyData,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (legacyData.present) {
      map['legacy_data'] = Variable<String>(legacyData.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationIssuesCompanion(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('reason: $reason, ')
          ..write('legacyData: $legacyData')
          ..write(')'))
        .toString();
  }
}

class $DeletedEntitiesTable extends DeletedEntities
    with TableInfo<$DeletedEntitiesTable, DeletedEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletedEntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entityType, entityId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deleted_entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletedEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, entityId};
  @override
  DeletedEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletedEntity(
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $DeletedEntitiesTable createAlias(String alias) {
    return $DeletedEntitiesTable(attachedDatabase, alias);
  }
}

class DeletedEntity extends DataClass implements Insertable<DeletedEntity> {
  final String entityType;
  final String entityId;
  final DateTime deletedAt;
  const DeletedEntity({
    required this.entityType,
    required this.entityId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  DeletedEntitiesCompanion toCompanion(bool nullToAbsent) {
    return DeletedEntitiesCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      deletedAt: Value(deletedAt),
    );
  }

  factory DeletedEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletedEntity(
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  DeletedEntity copyWith({
    String? entityType,
    String? entityId,
    DateTime? deletedAt,
  }) => DeletedEntity(
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  DeletedEntity copyWithCompanion(DeletedEntitiesCompanion data) {
    return DeletedEntity(
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletedEntity(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityType, entityId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletedEntity &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.deletedAt == this.deletedAt);
}

class DeletedEntitiesCompanion extends UpdateCompanion<DeletedEntity> {
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const DeletedEntitiesCompanion({
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeletedEntitiesCompanion.insert({
    required String entityType,
    required String entityId,
    required DateTime deletedAt,
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       deletedAt = Value(deletedAt);
  static Insertable<DeletedEntity> custom({
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeletedEntitiesCompanion copyWith({
    Value<String>? entityType,
    Value<String>? entityId,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return DeletedEntitiesCompanion(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeletedEntitiesCompanion(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FolderGroupsTable folderGroups = $FolderGroupsTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $SubTasksTable subTasks = $SubTasksTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $TaskTagsTable taskTags = $TaskTagsTable(this);
  late final $EcampusCoursesTable ecampusCourses = $EcampusCoursesTable(this);
  late final $EcampusItemsTable ecampusItems = $EcampusItemsTable(this);
  late final $ImportSessionsTable importSessions = $ImportSessionsTable(this);
  late final $TaskRemindersTable taskReminders = $TaskRemindersTable(this);
  late final $LocalNotificationSchedulesTable localNotificationSchedules =
      $LocalNotificationSchedulesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $MigrationIssuesTable migrationIssues = $MigrationIssuesTable(
    this,
  );
  late final $DeletedEntitiesTable deletedEntities = $DeletedEntitiesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    folderGroups,
    folders,
    tasks,
    subTasks,
    tags,
    taskTags,
    ecampusCourses,
    ecampusItems,
    importSessions,
    taskReminders,
    localNotificationSchedules,
    appSettings,
    migrationIssues,
    deletedEntities,
  ];
}

typedef $$FolderGroupsTableCreateCompanionBuilder =
    FolderGroupsCompanion Function({
      required String id,
      required String name,
      Value<int> sortOrder,
      Value<DateTime?> deletedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FolderGroupsTableUpdateCompanionBuilder =
    FolderGroupsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FolderGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $FolderGroupsTable, FolderGroup> {
  $$FolderGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FoldersTable, List<Folder>> _foldersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.folders,
    aliasName: $_aliasNameGenerator(db.folderGroups.id, db.folders.groupId),
  );

  $$FoldersTableProcessedTableManager get foldersRefs {
    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_foldersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FolderGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $FolderGroupsTable> {
  $$FolderGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> foldersRefs(
    Expression<bool> Function($$FoldersTableFilterComposer f) f,
  ) {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FolderGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $FolderGroupsTable> {
  $$FolderGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FolderGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FolderGroupsTable> {
  $$FolderGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> foldersRefs<T extends Object>(
    Expression<T> Function($$FoldersTableAnnotationComposer a) f,
  ) {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FolderGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FolderGroupsTable,
          FolderGroup,
          $$FolderGroupsTableFilterComposer,
          $$FolderGroupsTableOrderingComposer,
          $$FolderGroupsTableAnnotationComposer,
          $$FolderGroupsTableCreateCompanionBuilder,
          $$FolderGroupsTableUpdateCompanionBuilder,
          (FolderGroup, $$FolderGroupsTableReferences),
          FolderGroup,
          PrefetchHooks Function({bool foldersRefs})
        > {
  $$FolderGroupsTableTableManager(_$AppDatabase db, $FolderGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FolderGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FolderGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FolderGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FolderGroupsCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FolderGroupsCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FolderGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({foldersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (foldersRefs) db.folders],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (foldersRefs)
                    await $_getPrefetchedData<
                      FolderGroup,
                      $FolderGroupsTable,
                      Folder
                    >(
                      currentTable: table,
                      referencedTable: $$FolderGroupsTableReferences
                          ._foldersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FolderGroupsTableReferences(
                            db,
                            table,
                            p0,
                          ).foldersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.groupId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FolderGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FolderGroupsTable,
      FolderGroup,
      $$FolderGroupsTableFilterComposer,
      $$FolderGroupsTableOrderingComposer,
      $$FolderGroupsTableAnnotationComposer,
      $$FolderGroupsTableCreateCompanionBuilder,
      $$FolderGroupsTableUpdateCompanionBuilder,
      (FolderGroup, $$FolderGroupsTableReferences),
      FolderGroup,
      PrefetchHooks Function({bool foldersRefs})
    >;
typedef $$FoldersTableCreateCompanionBuilder =
    FoldersCompanion Function({
      required String id,
      required String name,
      Value<String?> color,
      Value<String?> icon,
      Value<String?> groupId,
      Value<int> sortOrder,
      Value<DateTime?> deletedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FoldersTableUpdateCompanionBuilder =
    FoldersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> color,
      Value<String?> icon,
      Value<String?> groupId,
      Value<int> sortOrder,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FoldersTableReferences
    extends BaseReferences<_$AppDatabase, $FoldersTable, Folder> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FolderGroupsTable _groupIdTable(_$AppDatabase db) =>
      db.folderGroups.createAlias(
        $_aliasNameGenerator(db.folders.groupId, db.folderGroups.id),
      );

  $$FolderGroupsTableProcessedTableManager? get groupId {
    final $_column = $_itemColumn<String>('folder_id');
    if ($_column == null) return null;
    final manager = $$FolderGroupsTableTableManager(
      $_db,
      $_db.folderGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: $_aliasNameGenerator(db.folders.id, db.tasks.folderId),
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EcampusCoursesTable, List<EcampusCourse>>
  _ecampusCoursesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ecampusCourses,
    aliasName: $_aliasNameGenerator(db.folders.id, db.ecampusCourses.listId),
  );

  $$EcampusCoursesTableProcessedTableManager get ecampusCoursesRefs {
    final manager = $$EcampusCoursesTableTableManager(
      $_db,
      $_db.ecampusCourses,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ecampusCoursesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FolderGroupsTableFilterComposer get groupId {
    final $$FolderGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.folderGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FolderGroupsTableFilterComposer(
            $db: $db,
            $table: $db.folderGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ecampusCoursesRefs(
    Expression<bool> Function($$EcampusCoursesTableFilterComposer f) f,
  ) {
    final $$EcampusCoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ecampusCourses,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcampusCoursesTableFilterComposer(
            $db: $db,
            $table: $db.ecampusCourses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FolderGroupsTableOrderingComposer get groupId {
    final $$FolderGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.folderGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FolderGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.folderGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FolderGroupsTableAnnotationComposer get groupId {
    final $$FolderGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.folderGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FolderGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.folderGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ecampusCoursesRefs<T extends Object>(
    Expression<T> Function($$EcampusCoursesTableAnnotationComposer a) f,
  ) {
    final $$EcampusCoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ecampusCourses,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcampusCoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.ecampusCourses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, $$FoldersTableReferences),
          Folder,
          PrefetchHooks Function({
            bool groupId,
            bool tasksRefs,
            bool ecampusCoursesRefs,
          })
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion(
                id: id,
                name: name,
                color: color,
                icon: icon,
                groupId: groupId,
                sortOrder: sortOrder,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion.insert(
                id: id,
                name: name,
                color: color,
                icon: icon,
                groupId: groupId,
                sortOrder: sortOrder,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                tasksRefs = false,
                ecampusCoursesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tasksRefs) db.tasks,
                    if (ecampusCoursesRefs) db.ecampusCourses,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable: $$FoldersTableReferences
                                        ._groupIdTable(db),
                                    referencedColumn: $$FoldersTableReferences
                                        ._groupIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tasksRefs)
                        await $_getPrefetchedData<Folder, $FoldersTable, Task>(
                          currentTable: table,
                          referencedTable: $$FoldersTableReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FoldersTableReferences(db, table, p0).tasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.folderId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ecampusCoursesRefs)
                        await $_getPrefetchedData<
                          Folder,
                          $FoldersTable,
                          EcampusCourse
                        >(
                          currentTable: table,
                          referencedTable: $$FoldersTableReferences
                              ._ecampusCoursesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FoldersTableReferences(
                                db,
                                table,
                                p0,
                              ).ecampusCoursesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.listId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, $$FoldersTableReferences),
      Folder,
      PrefetchHooks Function({
        bool groupId,
        bool tasksRefs,
        bool ecampusCoursesRefs,
      })
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String title,
      Value<DateTime?> dueDate,
      Value<String?> priority,
      Value<String?> memo,
      Value<String> folderId,
      Value<int> sortOrder,
      Value<DateTime?> completedAt,
      Value<DateTime?> deletedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<DateTime?> dueDate,
      Value<String?> priority,
      Value<String?> memo,
      Value<String> folderId,
      Value<int> sortOrder,
      Value<DateTime?> completedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoldersTable _folderIdTable(_$AppDatabase db) => db.folders
      .createAlias($_aliasNameGenerator(db.tasks.folderId, db.folders.id));

  $$FoldersTableProcessedTableManager get folderId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SubTasksTable, List<SubTask>> _subTasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.subTasks,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.subTasks.taskId),
  );

  $$SubTasksTableProcessedTableManager get subTasksRefs {
    final manager = $$SubTasksTableTableManager(
      $_db,
      $_db.subTasks,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_subTasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskTagsTable, List<TaskTag>> _taskTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.taskTags,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.taskTags.taskId),
  );

  $$TaskTagsTableProcessedTableManager get taskTagsRefs {
    final manager = $$TaskTagsTableTableManager(
      $_db,
      $_db.taskTags,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EcampusItemsTable, List<EcampusItem>>
  _ecampusItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ecampusItems,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.ecampusItems.taskId),
  );

  $$EcampusItemsTableProcessedTableManager get ecampusItemsRefs {
    final manager = $$EcampusItemsTableTableManager(
      $_db,
      $_db.ecampusItems,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ecampusItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskRemindersTable, List<TaskReminder>>
  _taskRemindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskReminders,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.taskReminders.taskId),
  );

  $$TaskRemindersTableProcessedTableManager get taskRemindersRefs {
    final manager = $$TaskRemindersTableTableManager(
      $_db,
      $_db.taskReminders,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskRemindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $LocalNotificationSchedulesTable,
    List<LocalNotificationSchedule>
  >
  _localNotificationSchedulesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localNotificationSchedules,
        aliasName: $_aliasNameGenerator(
          db.tasks.id,
          db.localNotificationSchedules.taskId,
        ),
      );

  $$LocalNotificationSchedulesTableProcessedTableManager
  get localNotificationSchedulesRefs {
    final manager = $$LocalNotificationSchedulesTableTableManager(
      $_db,
      $_db.localNotificationSchedules,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localNotificationSchedulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> subTasksRefs(
    Expression<bool> Function($$SubTasksTableFilterComposer f) f,
  ) {
    final $$SubTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subTasks,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubTasksTableFilterComposer(
            $db: $db,
            $table: $db.subTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskTagsRefs(
    Expression<bool> Function($$TaskTagsTableFilterComposer f) f,
  ) {
    final $$TaskTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTagsTableFilterComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ecampusItemsRefs(
    Expression<bool> Function($$EcampusItemsTableFilterComposer f) f,
  ) {
    final $$EcampusItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ecampusItems,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcampusItemsTableFilterComposer(
            $db: $db,
            $table: $db.ecampusItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskRemindersRefs(
    Expression<bool> Function($$TaskRemindersTableFilterComposer f) f,
  ) {
    final $$TaskRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskReminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRemindersTableFilterComposer(
            $db: $db,
            $table: $db.taskReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localNotificationSchedulesRefs(
    Expression<bool> Function($$LocalNotificationSchedulesTableFilterComposer f)
    f,
  ) {
    final $$LocalNotificationSchedulesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.localNotificationSchedules,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalNotificationSchedulesTableFilterComposer(
                $db: $db,
                $table: $db.localNotificationSchedules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableOrderingComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FoldersTableAnnotationComposer get folderId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> subTasksRefs<T extends Object>(
    Expression<T> Function($$SubTasksTableAnnotationComposer a) f,
  ) {
    final $$SubTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subTasks,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.subTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskTagsRefs<T extends Object>(
    Expression<T> Function($$TaskTagsTableAnnotationComposer a) f,
  ) {
    final $$TaskTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ecampusItemsRefs<T extends Object>(
    Expression<T> Function($$EcampusItemsTableAnnotationComposer a) f,
  ) {
    final $$EcampusItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ecampusItems,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcampusItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.ecampusItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskRemindersRefs<T extends Object>(
    Expression<T> Function($$TaskRemindersTableAnnotationComposer a) f,
  ) {
    final $$TaskRemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskReminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.taskReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> localNotificationSchedulesRefs<T extends Object>(
    Expression<T> Function(
      $$LocalNotificationSchedulesTableAnnotationComposer a,
    )
    f,
  ) {
    final $$LocalNotificationSchedulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.localNotificationSchedules,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalNotificationSchedulesTableAnnotationComposer(
                $db: $db,
                $table: $db.localNotificationSchedules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({
            bool folderId,
            bool subTasksRefs,
            bool taskTagsRefs,
            bool ecampusItemsRefs,
            bool taskRemindersRefs,
            bool localNotificationSchedulesRefs,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String?> priority = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String> folderId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                dueDate: dueDate,
                priority: priority,
                memo: memo,
                folderId: folderId,
                sortOrder: sortOrder,
                completedAt: completedAt,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String?> priority = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String> folderId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                dueDate: dueDate,
                priority: priority,
                memo: memo,
                folderId: folderId,
                sortOrder: sortOrder,
                completedAt: completedAt,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TasksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                folderId = false,
                subTasksRefs = false,
                taskTagsRefs = false,
                ecampusItemsRefs = false,
                taskRemindersRefs = false,
                localNotificationSchedulesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (subTasksRefs) db.subTasks,
                    if (taskTagsRefs) db.taskTags,
                    if (ecampusItemsRefs) db.ecampusItems,
                    if (taskRemindersRefs) db.taskReminders,
                    if (localNotificationSchedulesRefs)
                      db.localNotificationSchedules,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (folderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.folderId,
                                    referencedTable: $$TasksTableReferences
                                        ._folderIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._folderIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (subTasksRefs)
                        await $_getPrefetchedData<Task, $TasksTable, SubTask>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._subTasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).subTasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskTagsRefs)
                        await $_getPrefetchedData<Task, $TasksTable, TaskTag>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ecampusItemsRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          EcampusItem
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._ecampusItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).ecampusItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskRemindersRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          TaskReminder
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskRemindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskRemindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (localNotificationSchedulesRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          LocalNotificationSchedule
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._localNotificationSchedulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).localNotificationSchedulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({
        bool folderId,
        bool subTasksRefs,
        bool taskTagsRefs,
        bool ecampusItemsRefs,
        bool taskRemindersRefs,
        bool localNotificationSchedulesRefs,
      })
    >;
typedef $$SubTasksTableCreateCompanionBuilder =
    SubTasksCompanion Function({
      required String id,
      required String taskId,
      required String title,
      Value<int> position,
      Value<DateTime?> completedAt,
      Value<DateTime?> deletedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SubTasksTableUpdateCompanionBuilder =
    SubTasksCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> title,
      Value<int> position,
      Value<DateTime?> completedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SubTasksTableReferences
    extends BaseReferences<_$AppDatabase, $SubTasksTable, SubTask> {
  $$SubTasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.subTasks.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SubTasksTableFilterComposer
    extends Composer<_$AppDatabase, $SubTasksTable> {
  $$SubTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $SubTasksTable> {
  $$SubTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubTasksTable> {
  $$SubTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubTasksTable,
          SubTask,
          $$SubTasksTableFilterComposer,
          $$SubTasksTableOrderingComposer,
          $$SubTasksTableAnnotationComposer,
          $$SubTasksTableCreateCompanionBuilder,
          $$SubTasksTableUpdateCompanionBuilder,
          (SubTask, $$SubTasksTableReferences),
          SubTask,
          PrefetchHooks Function({bool taskId})
        > {
  $$SubTasksTableTableManager(_$AppDatabase db, $SubTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubTasksCompanion(
                id: id,
                taskId: taskId,
                title: title,
                position: position,
                completedAt: completedAt,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String title,
                Value<int> position = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SubTasksCompanion.insert(
                id: id,
                taskId: taskId,
                title: title,
                position: position,
                completedAt: completedAt,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SubTasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$SubTasksTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$SubTasksTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SubTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubTasksTable,
      SubTask,
      $$SubTasksTableFilterComposer,
      $$SubTasksTableOrderingComposer,
      $$SubTasksTableAnnotationComposer,
      $$SubTasksTableCreateCompanionBuilder,
      $$SubTasksTableUpdateCompanionBuilder,
      (SubTask, $$SubTasksTableReferences),
      SubTask,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String name,
      required String color,
      Value<int> sortOrder,
      Value<DateTime?> deletedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> color,
      Value<int> sortOrder,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TaskTagsTable, List<TaskTag>> _taskTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.taskTags,
    aliasName: $_aliasNameGenerator(db.tags.id, db.taskTags.tagId),
  );

  $$TaskTagsTableProcessedTableManager get taskTagsRefs {
    final manager = $$TaskTagsTableTableManager(
      $_db,
      $_db.taskTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EcampusCoursesTable, List<EcampusCourse>>
  _ecampusCoursesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ecampusCourses,
    aliasName: $_aliasNameGenerator(db.tags.id, db.ecampusCourses.tagId),
  );

  $$EcampusCoursesTableProcessedTableManager get ecampusCoursesRefs {
    final manager = $$EcampusCoursesTableTableManager(
      $_db,
      $_db.ecampusCourses,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ecampusCoursesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> taskTagsRefs(
    Expression<bool> Function($$TaskTagsTableFilterComposer f) f,
  ) {
    final $$TaskTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTagsTableFilterComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ecampusCoursesRefs(
    Expression<bool> Function($$EcampusCoursesTableFilterComposer f) f,
  ) {
    final $$EcampusCoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ecampusCourses,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcampusCoursesTableFilterComposer(
            $db: $db,
            $table: $db.ecampusCourses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> taskTagsRefs<T extends Object>(
    Expression<T> Function($$TaskTagsTableAnnotationComposer a) f,
  ) {
    final $$TaskTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ecampusCoursesRefs<T extends Object>(
    Expression<T> Function($$EcampusCoursesTableAnnotationComposer a) f,
  ) {
    final $$EcampusCoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ecampusCourses,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcampusCoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.ecampusCourses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool taskTagsRefs, bool ecampusCoursesRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                color: color,
                sortOrder: sortOrder,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String color,
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                color: color,
                sortOrder: sortOrder,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({taskTagsRefs = false, ecampusCoursesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskTagsRefs) db.taskTags,
                    if (ecampusCoursesRefs) db.ecampusCourses,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskTagsRefs)
                        await $_getPrefetchedData<Tag, $TagsTable, TaskTag>(
                          currentTable: table,
                          referencedTable: $$TagsTableReferences
                              ._taskTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TagsTableReferences(db, table, p0).taskTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tagId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ecampusCoursesRefs)
                        await $_getPrefetchedData<
                          Tag,
                          $TagsTable,
                          EcampusCourse
                        >(
                          currentTable: table,
                          referencedTable: $$TagsTableReferences
                              ._ecampusCoursesRefsTable(db),
                          managerFromTypedResult: (p0) => $$TagsTableReferences(
                            db,
                            table,
                            p0,
                          ).ecampusCoursesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tagId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool taskTagsRefs, bool ecampusCoursesRefs})
    >;
typedef $$TaskTagsTableCreateCompanionBuilder =
    TaskTagsCompanion Function({
      required String taskId,
      required String tagId,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TaskTagsTableUpdateCompanionBuilder =
    TaskTagsCompanion Function({
      Value<String> taskId,
      Value<String> tagId,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$TaskTagsTableReferences
    extends BaseReferences<_$AppDatabase, $TaskTagsTable, TaskTag> {
  $$TaskTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.taskTags.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias($_aliasNameGenerator(db.taskTags.tagId, db.tags.id));

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskTagsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskTagsTable> {
  $$TaskTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskTagsTable> {
  $$TaskTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskTagsTable> {
  $$TaskTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskTagsTable,
          TaskTag,
          $$TaskTagsTableFilterComposer,
          $$TaskTagsTableOrderingComposer,
          $$TaskTagsTableAnnotationComposer,
          $$TaskTagsTableCreateCompanionBuilder,
          $$TaskTagsTableUpdateCompanionBuilder,
          (TaskTag, $$TaskTagsTableReferences),
          TaskTag,
          PrefetchHooks Function({bool taskId, bool tagId})
        > {
  $$TaskTagsTableTableManager(_$AppDatabase db, $TaskTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTagsCompanion(
                taskId: taskId,
                tagId: tagId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required String tagId,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTagsCompanion.insert(
                taskId: taskId,
                tagId: tagId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$TaskTagsTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$TaskTagsTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$TaskTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$TaskTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskTagsTable,
      TaskTag,
      $$TaskTagsTableFilterComposer,
      $$TaskTagsTableOrderingComposer,
      $$TaskTagsTableAnnotationComposer,
      $$TaskTagsTableCreateCompanionBuilder,
      $$TaskTagsTableUpdateCompanionBuilder,
      (TaskTag, $$TaskTagsTableReferences),
      TaskTag,
      PrefetchHooks Function({bool taskId, bool tagId})
    >;
typedef $$EcampusCoursesTableCreateCompanionBuilder =
    EcampusCoursesCompanion Function({
      required String id,
      required String sourceScopeId,
      Value<String?> externalCourseKey,
      required String name,
      Value<String?> tagId,
      Value<String?> listId,
      required DateTime lastObservedAt,
      Value<int> rowid,
    });
typedef $$EcampusCoursesTableUpdateCompanionBuilder =
    EcampusCoursesCompanion Function({
      Value<String> id,
      Value<String> sourceScopeId,
      Value<String?> externalCourseKey,
      Value<String> name,
      Value<String?> tagId,
      Value<String?> listId,
      Value<DateTime> lastObservedAt,
      Value<int> rowid,
    });

final class $$EcampusCoursesTableReferences
    extends BaseReferences<_$AppDatabase, $EcampusCoursesTable, EcampusCourse> {
  $$EcampusCoursesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TagsTable _tagIdTable(_$AppDatabase db) => db.tags.createAlias(
    $_aliasNameGenerator(db.ecampusCourses.tagId, db.tags.id),
  );

  $$TagsTableProcessedTableManager? get tagId {
    final $_column = $_itemColumn<String>('tag_id');
    if ($_column == null) return null;
    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FoldersTable _listIdTable(_$AppDatabase db) => db.folders.createAlias(
    $_aliasNameGenerator(db.ecampusCourses.listId, db.folders.id),
  );

  $$FoldersTableProcessedTableManager? get listId {
    final $_column = $_itemColumn<String>('list_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EcampusItemsTable, List<EcampusItem>>
  _ecampusItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ecampusItems,
    aliasName: $_aliasNameGenerator(
      db.ecampusCourses.id,
      db.ecampusItems.courseId,
    ),
  );

  $$EcampusItemsTableProcessedTableManager get ecampusItemsRefs {
    final manager = $$EcampusItemsTableTableManager(
      $_db,
      $_db.ecampusItems,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ecampusItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EcampusCoursesTableFilterComposer
    extends Composer<_$AppDatabase, $EcampusCoursesTable> {
  $$EcampusCoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceScopeId => $composableBuilder(
    column: $table.sourceScopeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalCourseKey => $composableBuilder(
    column: $table.externalCourseKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastObservedAt => $composableBuilder(
    column: $table.lastObservedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoldersTableFilterComposer get listId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ecampusItemsRefs(
    Expression<bool> Function($$EcampusItemsTableFilterComposer f) f,
  ) {
    final $$EcampusItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ecampusItems,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcampusItemsTableFilterComposer(
            $db: $db,
            $table: $db.ecampusItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EcampusCoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $EcampusCoursesTable> {
  $$EcampusCoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceScopeId => $composableBuilder(
    column: $table.sourceScopeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalCourseKey => $composableBuilder(
    column: $table.externalCourseKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastObservedAt => $composableBuilder(
    column: $table.lastObservedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoldersTableOrderingComposer get listId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableOrderingComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EcampusCoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EcampusCoursesTable> {
  $$EcampusCoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceScopeId => $composableBuilder(
    column: $table.sourceScopeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalCourseKey => $composableBuilder(
    column: $table.externalCourseKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get lastObservedAt => $composableBuilder(
    column: $table.lastObservedAt,
    builder: (column) => column,
  );

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoldersTableAnnotationComposer get listId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ecampusItemsRefs<T extends Object>(
    Expression<T> Function($$EcampusItemsTableAnnotationComposer a) f,
  ) {
    final $$EcampusItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ecampusItems,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcampusItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.ecampusItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EcampusCoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EcampusCoursesTable,
          EcampusCourse,
          $$EcampusCoursesTableFilterComposer,
          $$EcampusCoursesTableOrderingComposer,
          $$EcampusCoursesTableAnnotationComposer,
          $$EcampusCoursesTableCreateCompanionBuilder,
          $$EcampusCoursesTableUpdateCompanionBuilder,
          (EcampusCourse, $$EcampusCoursesTableReferences),
          EcampusCourse,
          PrefetchHooks Function({
            bool tagId,
            bool listId,
            bool ecampusItemsRefs,
          })
        > {
  $$EcampusCoursesTableTableManager(
    _$AppDatabase db,
    $EcampusCoursesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EcampusCoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EcampusCoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EcampusCoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceScopeId = const Value.absent(),
                Value<String?> externalCourseKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> tagId = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                Value<DateTime> lastObservedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EcampusCoursesCompanion(
                id: id,
                sourceScopeId: sourceScopeId,
                externalCourseKey: externalCourseKey,
                name: name,
                tagId: tagId,
                listId: listId,
                lastObservedAt: lastObservedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceScopeId,
                Value<String?> externalCourseKey = const Value.absent(),
                required String name,
                Value<String?> tagId = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                required DateTime lastObservedAt,
                Value<int> rowid = const Value.absent(),
              }) => EcampusCoursesCompanion.insert(
                id: id,
                sourceScopeId: sourceScopeId,
                externalCourseKey: externalCourseKey,
                name: name,
                tagId: tagId,
                listId: listId,
                lastObservedAt: lastObservedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EcampusCoursesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({tagId = false, listId = false, ecampusItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ecampusItemsRefs) db.ecampusItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (tagId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.tagId,
                                    referencedTable:
                                        $$EcampusCoursesTableReferences
                                            ._tagIdTable(db),
                                    referencedColumn:
                                        $$EcampusCoursesTableReferences
                                            ._tagIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (listId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.listId,
                                    referencedTable:
                                        $$EcampusCoursesTableReferences
                                            ._listIdTable(db),
                                    referencedColumn:
                                        $$EcampusCoursesTableReferences
                                            ._listIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ecampusItemsRefs)
                        await $_getPrefetchedData<
                          EcampusCourse,
                          $EcampusCoursesTable,
                          EcampusItem
                        >(
                          currentTable: table,
                          referencedTable: $$EcampusCoursesTableReferences
                              ._ecampusItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EcampusCoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).ecampusItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EcampusCoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EcampusCoursesTable,
      EcampusCourse,
      $$EcampusCoursesTableFilterComposer,
      $$EcampusCoursesTableOrderingComposer,
      $$EcampusCoursesTableAnnotationComposer,
      $$EcampusCoursesTableCreateCompanionBuilder,
      $$EcampusCoursesTableUpdateCompanionBuilder,
      (EcampusCourse, $$EcampusCoursesTableReferences),
      EcampusCourse,
      PrefetchHooks Function({bool tagId, bool listId, bool ecampusItemsRefs})
    >;
typedef $$EcampusItemsTableCreateCompanionBuilder =
    EcampusItemsCompanion Function({
      required String id,
      required String sourceScopeId,
      Value<String?> courseId,
      Value<String?> externalKey,
      required String sourceTitle,
      Value<String?> sourceCourse,
      Value<String?> sourceType,
      Value<DateTime?> sourceStartAt,
      Value<DateTime?> sourceEndAt,
      Value<String?> taskId,
      required String importState,
      required DateTime firstObservedAt,
      required DateTime lastObservedAt,
      Value<int> rowid,
    });
typedef $$EcampusItemsTableUpdateCompanionBuilder =
    EcampusItemsCompanion Function({
      Value<String> id,
      Value<String> sourceScopeId,
      Value<String?> courseId,
      Value<String?> externalKey,
      Value<String> sourceTitle,
      Value<String?> sourceCourse,
      Value<String?> sourceType,
      Value<DateTime?> sourceStartAt,
      Value<DateTime?> sourceEndAt,
      Value<String?> taskId,
      Value<String> importState,
      Value<DateTime> firstObservedAt,
      Value<DateTime> lastObservedAt,
      Value<int> rowid,
    });

final class $$EcampusItemsTableReferences
    extends BaseReferences<_$AppDatabase, $EcampusItemsTable, EcampusItem> {
  $$EcampusItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EcampusCoursesTable _courseIdTable(_$AppDatabase db) =>
      db.ecampusCourses.createAlias(
        $_aliasNameGenerator(db.ecampusItems.courseId, db.ecampusCourses.id),
      );

  $$EcampusCoursesTableProcessedTableManager? get courseId {
    final $_column = $_itemColumn<String>('course_id');
    if ($_column == null) return null;
    final manager = $$EcampusCoursesTableTableManager(
      $_db,
      $_db.ecampusCourses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.ecampusItems.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager? get taskId {
    final $_column = $_itemColumn<String>('task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EcampusItemsTableFilterComposer
    extends Composer<_$AppDatabase, $EcampusItemsTable> {
  $$EcampusItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceScopeId => $composableBuilder(
    column: $table.sourceScopeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalKey => $composableBuilder(
    column: $table.externalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceCourse => $composableBuilder(
    column: $table.sourceCourse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sourceStartAt => $composableBuilder(
    column: $table.sourceStartAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sourceEndAt => $composableBuilder(
    column: $table.sourceEndAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importState => $composableBuilder(
    column: $table.importState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstObservedAt => $composableBuilder(
    column: $table.firstObservedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastObservedAt => $composableBuilder(
    column: $table.lastObservedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EcampusCoursesTableFilterComposer get courseId {
    final $$EcampusCoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.ecampusCourses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcampusCoursesTableFilterComposer(
            $db: $db,
            $table: $db.ecampusCourses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EcampusItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $EcampusItemsTable> {
  $$EcampusItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceScopeId => $composableBuilder(
    column: $table.sourceScopeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalKey => $composableBuilder(
    column: $table.externalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceCourse => $composableBuilder(
    column: $table.sourceCourse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sourceStartAt => $composableBuilder(
    column: $table.sourceStartAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sourceEndAt => $composableBuilder(
    column: $table.sourceEndAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importState => $composableBuilder(
    column: $table.importState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstObservedAt => $composableBuilder(
    column: $table.firstObservedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastObservedAt => $composableBuilder(
    column: $table.lastObservedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EcampusCoursesTableOrderingComposer get courseId {
    final $$EcampusCoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.ecampusCourses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcampusCoursesTableOrderingComposer(
            $db: $db,
            $table: $db.ecampusCourses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EcampusItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EcampusItemsTable> {
  $$EcampusItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceScopeId => $composableBuilder(
    column: $table.sourceScopeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalKey => $composableBuilder(
    column: $table.externalKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceCourse => $composableBuilder(
    column: $table.sourceCourse,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sourceStartAt => $composableBuilder(
    column: $table.sourceStartAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sourceEndAt => $composableBuilder(
    column: $table.sourceEndAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get importState => $composableBuilder(
    column: $table.importState,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstObservedAt => $composableBuilder(
    column: $table.firstObservedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastObservedAt => $composableBuilder(
    column: $table.lastObservedAt,
    builder: (column) => column,
  );

  $$EcampusCoursesTableAnnotationComposer get courseId {
    final $$EcampusCoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.ecampusCourses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcampusCoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.ecampusCourses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EcampusItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EcampusItemsTable,
          EcampusItem,
          $$EcampusItemsTableFilterComposer,
          $$EcampusItemsTableOrderingComposer,
          $$EcampusItemsTableAnnotationComposer,
          $$EcampusItemsTableCreateCompanionBuilder,
          $$EcampusItemsTableUpdateCompanionBuilder,
          (EcampusItem, $$EcampusItemsTableReferences),
          EcampusItem,
          PrefetchHooks Function({bool courseId, bool taskId})
        > {
  $$EcampusItemsTableTableManager(_$AppDatabase db, $EcampusItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EcampusItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EcampusItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EcampusItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceScopeId = const Value.absent(),
                Value<String?> courseId = const Value.absent(),
                Value<String?> externalKey = const Value.absent(),
                Value<String> sourceTitle = const Value.absent(),
                Value<String?> sourceCourse = const Value.absent(),
                Value<String?> sourceType = const Value.absent(),
                Value<DateTime?> sourceStartAt = const Value.absent(),
                Value<DateTime?> sourceEndAt = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String> importState = const Value.absent(),
                Value<DateTime> firstObservedAt = const Value.absent(),
                Value<DateTime> lastObservedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EcampusItemsCompanion(
                id: id,
                sourceScopeId: sourceScopeId,
                courseId: courseId,
                externalKey: externalKey,
                sourceTitle: sourceTitle,
                sourceCourse: sourceCourse,
                sourceType: sourceType,
                sourceStartAt: sourceStartAt,
                sourceEndAt: sourceEndAt,
                taskId: taskId,
                importState: importState,
                firstObservedAt: firstObservedAt,
                lastObservedAt: lastObservedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceScopeId,
                Value<String?> courseId = const Value.absent(),
                Value<String?> externalKey = const Value.absent(),
                required String sourceTitle,
                Value<String?> sourceCourse = const Value.absent(),
                Value<String?> sourceType = const Value.absent(),
                Value<DateTime?> sourceStartAt = const Value.absent(),
                Value<DateTime?> sourceEndAt = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                required String importState,
                required DateTime firstObservedAt,
                required DateTime lastObservedAt,
                Value<int> rowid = const Value.absent(),
              }) => EcampusItemsCompanion.insert(
                id: id,
                sourceScopeId: sourceScopeId,
                courseId: courseId,
                externalKey: externalKey,
                sourceTitle: sourceTitle,
                sourceCourse: sourceCourse,
                sourceType: sourceType,
                sourceStartAt: sourceStartAt,
                sourceEndAt: sourceEndAt,
                taskId: taskId,
                importState: importState,
                firstObservedAt: firstObservedAt,
                lastObservedAt: lastObservedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EcampusItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseId = false, taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseId,
                                referencedTable: $$EcampusItemsTableReferences
                                    ._courseIdTable(db),
                                referencedColumn: $$EcampusItemsTableReferences
                                    ._courseIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$EcampusItemsTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$EcampusItemsTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EcampusItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EcampusItemsTable,
      EcampusItem,
      $$EcampusItemsTableFilterComposer,
      $$EcampusItemsTableOrderingComposer,
      $$EcampusItemsTableAnnotationComposer,
      $$EcampusItemsTableCreateCompanionBuilder,
      $$EcampusItemsTableUpdateCompanionBuilder,
      (EcampusItem, $$EcampusItemsTableReferences),
      EcampusItem,
      PrefetchHooks Function({bool courseId, bool taskId})
    >;
typedef $$ImportSessionsTableCreateCompanionBuilder =
    ImportSessionsCompanion Function({
      required String id,
      Value<String> provider,
      Value<String> inputMethod,
      required String sourceScopeId,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required String state,
      Value<int> appliedCount,
      Value<int> rowid,
    });
typedef $$ImportSessionsTableUpdateCompanionBuilder =
    ImportSessionsCompanion Function({
      Value<String> id,
      Value<String> provider,
      Value<String> inputMethod,
      Value<String> sourceScopeId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String> state,
      Value<int> appliedCount,
      Value<int> rowid,
    });

class $$ImportSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportSessionsTable> {
  $$ImportSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputMethod => $composableBuilder(
    column: $table.inputMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceScopeId => $composableBuilder(
    column: $table.sourceScopeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appliedCount => $composableBuilder(
    column: $table.appliedCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportSessionsTable> {
  $$ImportSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputMethod => $composableBuilder(
    column: $table.inputMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceScopeId => $composableBuilder(
    column: $table.sourceScopeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedCount => $composableBuilder(
    column: $table.appliedCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportSessionsTable> {
  $$ImportSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get inputMethod => $composableBuilder(
    column: $table.inputMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceScopeId => $composableBuilder(
    column: $table.sourceScopeId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get appliedCount => $composableBuilder(
    column: $table.appliedCount,
    builder: (column) => column,
  );
}

class $$ImportSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportSessionsTable,
          ImportSession,
          $$ImportSessionsTableFilterComposer,
          $$ImportSessionsTableOrderingComposer,
          $$ImportSessionsTableAnnotationComposer,
          $$ImportSessionsTableCreateCompanionBuilder,
          $$ImportSessionsTableUpdateCompanionBuilder,
          (
            ImportSession,
            BaseReferences<_$AppDatabase, $ImportSessionsTable, ImportSession>,
          ),
          ImportSession,
          PrefetchHooks Function()
        > {
  $$ImportSessionsTableTableManager(
    _$AppDatabase db,
    $ImportSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> inputMethod = const Value.absent(),
                Value<String> sourceScopeId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> appliedCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportSessionsCompanion(
                id: id,
                provider: provider,
                inputMethod: inputMethod,
                sourceScopeId: sourceScopeId,
                startedAt: startedAt,
                endedAt: endedAt,
                state: state,
                appliedCount: appliedCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> provider = const Value.absent(),
                Value<String> inputMethod = const Value.absent(),
                required String sourceScopeId,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required String state,
                Value<int> appliedCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportSessionsCompanion.insert(
                id: id,
                provider: provider,
                inputMethod: inputMethod,
                sourceScopeId: sourceScopeId,
                startedAt: startedAt,
                endedAt: endedAt,
                state: state,
                appliedCount: appliedCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportSessionsTable,
      ImportSession,
      $$ImportSessionsTableFilterComposer,
      $$ImportSessionsTableOrderingComposer,
      $$ImportSessionsTableAnnotationComposer,
      $$ImportSessionsTableCreateCompanionBuilder,
      $$ImportSessionsTableUpdateCompanionBuilder,
      (
        ImportSession,
        BaseReferences<_$AppDatabase, $ImportSessionsTable, ImportSession>,
      ),
      ImportSession,
      PrefetchHooks Function()
    >;
typedef $$TaskRemindersTableCreateCompanionBuilder =
    TaskRemindersCompanion Function({
      required String id,
      required String taskId,
      required bool enabled,
      required int offsetMinutes,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TaskRemindersTableUpdateCompanionBuilder =
    TaskRemindersCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<bool> enabled,
      Value<int> offsetMinutes,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TaskRemindersTableReferences
    extends BaseReferences<_$AppDatabase, $TaskRemindersTable, TaskReminder> {
  $$TaskRemindersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.taskReminders.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRemindersTable,
          TaskReminder,
          $$TaskRemindersTableFilterComposer,
          $$TaskRemindersTableOrderingComposer,
          $$TaskRemindersTableAnnotationComposer,
          $$TaskRemindersTableCreateCompanionBuilder,
          $$TaskRemindersTableUpdateCompanionBuilder,
          (TaskReminder, $$TaskRemindersTableReferences),
          TaskReminder,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskRemindersTableTableManager(_$AppDatabase db, $TaskRemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> offsetMinutes = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRemindersCompanion(
                id: id,
                taskId: taskId,
                enabled: enabled,
                offsetMinutes: offsetMinutes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required bool enabled,
                required int offsetMinutes,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TaskRemindersCompanion.insert(
                id: id,
                taskId: taskId,
                enabled: enabled,
                offsetMinutes: offsetMinutes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskRemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$TaskRemindersTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$TaskRemindersTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRemindersTable,
      TaskReminder,
      $$TaskRemindersTableFilterComposer,
      $$TaskRemindersTableOrderingComposer,
      $$TaskRemindersTableAnnotationComposer,
      $$TaskRemindersTableCreateCompanionBuilder,
      $$TaskRemindersTableUpdateCompanionBuilder,
      (TaskReminder, $$TaskRemindersTableReferences),
      TaskReminder,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$LocalNotificationSchedulesTableCreateCompanionBuilder =
    LocalNotificationSchedulesCompanion Function({
      required String taskId,
      Value<int?> platformNotificationId,
      Value<DateTime?> scheduledAt,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$LocalNotificationSchedulesTableUpdateCompanionBuilder =
    LocalNotificationSchedulesCompanion Function({
      Value<String> taskId,
      Value<int?> platformNotificationId,
      Value<DateTime?> scheduledAt,
      Value<String?> lastError,
      Value<int> rowid,
    });

final class $$LocalNotificationSchedulesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalNotificationSchedulesTable,
          LocalNotificationSchedule
        > {
  $$LocalNotificationSchedulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.localNotificationSchedules.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalNotificationSchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalNotificationSchedulesTable> {
  $$LocalNotificationSchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get platformNotificationId => $composableBuilder(
    column: $table.platformNotificationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalNotificationSchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalNotificationSchedulesTable> {
  $$LocalNotificationSchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get platformNotificationId => $composableBuilder(
    column: $table.platformNotificationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalNotificationSchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalNotificationSchedulesTable> {
  $$LocalNotificationSchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get platformNotificationId => $composableBuilder(
    column: $table.platformNotificationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalNotificationSchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalNotificationSchedulesTable,
          LocalNotificationSchedule,
          $$LocalNotificationSchedulesTableFilterComposer,
          $$LocalNotificationSchedulesTableOrderingComposer,
          $$LocalNotificationSchedulesTableAnnotationComposer,
          $$LocalNotificationSchedulesTableCreateCompanionBuilder,
          $$LocalNotificationSchedulesTableUpdateCompanionBuilder,
          (
            LocalNotificationSchedule,
            $$LocalNotificationSchedulesTableReferences,
          ),
          LocalNotificationSchedule,
          PrefetchHooks Function({bool taskId})
        > {
  $$LocalNotificationSchedulesTableTableManager(
    _$AppDatabase db,
    $LocalNotificationSchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalNotificationSchedulesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalNotificationSchedulesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalNotificationSchedulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<int?> platformNotificationId = const Value.absent(),
                Value<DateTime?> scheduledAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalNotificationSchedulesCompanion(
                taskId: taskId,
                platformNotificationId: platformNotificationId,
                scheduledAt: scheduledAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                Value<int?> platformNotificationId = const Value.absent(),
                Value<DateTime?> scheduledAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalNotificationSchedulesCompanion.insert(
                taskId: taskId,
                platformNotificationId: platformNotificationId,
                scheduledAt: scheduledAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalNotificationSchedulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$LocalNotificationSchedulesTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$LocalNotificationSchedulesTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalNotificationSchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalNotificationSchedulesTable,
      LocalNotificationSchedule,
      $$LocalNotificationSchedulesTableFilterComposer,
      $$LocalNotificationSchedulesTableOrderingComposer,
      $$LocalNotificationSchedulesTableAnnotationComposer,
      $$LocalNotificationSchedulesTableCreateCompanionBuilder,
      $$LocalNotificationSchedulesTableUpdateCompanionBuilder,
      (LocalNotificationSchedule, $$LocalNotificationSchedulesTableReferences),
      LocalNotificationSchedule,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$MigrationIssuesTableCreateCompanionBuilder =
    MigrationIssuesCompanion Function({
      Value<int> id,
      required String entityId,
      required String reason,
      required String legacyData,
    });
typedef $$MigrationIssuesTableUpdateCompanionBuilder =
    MigrationIssuesCompanion Function({
      Value<int> id,
      Value<String> entityId,
      Value<String> reason,
      Value<String> legacyData,
    });

class $$MigrationIssuesTableFilterComposer
    extends Composer<_$AppDatabase, $MigrationIssuesTable> {
  $$MigrationIssuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legacyData => $composableBuilder(
    column: $table.legacyData,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MigrationIssuesTableOrderingComposer
    extends Composer<_$AppDatabase, $MigrationIssuesTable> {
  $$MigrationIssuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legacyData => $composableBuilder(
    column: $table.legacyData,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MigrationIssuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MigrationIssuesTable> {
  $$MigrationIssuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get legacyData => $composableBuilder(
    column: $table.legacyData,
    builder: (column) => column,
  );
}

class $$MigrationIssuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MigrationIssuesTable,
          MigrationIssue,
          $$MigrationIssuesTableFilterComposer,
          $$MigrationIssuesTableOrderingComposer,
          $$MigrationIssuesTableAnnotationComposer,
          $$MigrationIssuesTableCreateCompanionBuilder,
          $$MigrationIssuesTableUpdateCompanionBuilder,
          (
            MigrationIssue,
            BaseReferences<
              _$AppDatabase,
              $MigrationIssuesTable,
              MigrationIssue
            >,
          ),
          MigrationIssue,
          PrefetchHooks Function()
        > {
  $$MigrationIssuesTableTableManager(
    _$AppDatabase db,
    $MigrationIssuesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MigrationIssuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MigrationIssuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MigrationIssuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> legacyData = const Value.absent(),
              }) => MigrationIssuesCompanion(
                id: id,
                entityId: entityId,
                reason: reason,
                legacyData: legacyData,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityId,
                required String reason,
                required String legacyData,
              }) => MigrationIssuesCompanion.insert(
                id: id,
                entityId: entityId,
                reason: reason,
                legacyData: legacyData,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MigrationIssuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MigrationIssuesTable,
      MigrationIssue,
      $$MigrationIssuesTableFilterComposer,
      $$MigrationIssuesTableOrderingComposer,
      $$MigrationIssuesTableAnnotationComposer,
      $$MigrationIssuesTableCreateCompanionBuilder,
      $$MigrationIssuesTableUpdateCompanionBuilder,
      (
        MigrationIssue,
        BaseReferences<_$AppDatabase, $MigrationIssuesTable, MigrationIssue>,
      ),
      MigrationIssue,
      PrefetchHooks Function()
    >;
typedef $$DeletedEntitiesTableCreateCompanionBuilder =
    DeletedEntitiesCompanion Function({
      required String entityType,
      required String entityId,
      required DateTime deletedAt,
      Value<int> rowid,
    });
typedef $$DeletedEntitiesTableUpdateCompanionBuilder =
    DeletedEntitiesCompanion Function({
      Value<String> entityType,
      Value<String> entityId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$DeletedEntitiesTableFilterComposer
    extends Composer<_$AppDatabase, $DeletedEntitiesTable> {
  $$DeletedEntitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeletedEntitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $DeletedEntitiesTable> {
  $$DeletedEntitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeletedEntitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeletedEntitiesTable> {
  $$DeletedEntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DeletedEntitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeletedEntitiesTable,
          DeletedEntity,
          $$DeletedEntitiesTableFilterComposer,
          $$DeletedEntitiesTableOrderingComposer,
          $$DeletedEntitiesTableAnnotationComposer,
          $$DeletedEntitiesTableCreateCompanionBuilder,
          $$DeletedEntitiesTableUpdateCompanionBuilder,
          (
            DeletedEntity,
            BaseReferences<_$AppDatabase, $DeletedEntitiesTable, DeletedEntity>,
          ),
          DeletedEntity,
          PrefetchHooks Function()
        > {
  $$DeletedEntitiesTableTableManager(
    _$AppDatabase db,
    $DeletedEntitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletedEntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeletedEntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeletedEntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedEntitiesCompanion(
                entityType: entityType,
                entityId: entityId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityType,
                required String entityId,
                required DateTime deletedAt,
                Value<int> rowid = const Value.absent(),
              }) => DeletedEntitiesCompanion.insert(
                entityType: entityType,
                entityId: entityId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeletedEntitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeletedEntitiesTable,
      DeletedEntity,
      $$DeletedEntitiesTableFilterComposer,
      $$DeletedEntitiesTableOrderingComposer,
      $$DeletedEntitiesTableAnnotationComposer,
      $$DeletedEntitiesTableCreateCompanionBuilder,
      $$DeletedEntitiesTableUpdateCompanionBuilder,
      (
        DeletedEntity,
        BaseReferences<_$AppDatabase, $DeletedEntitiesTable, DeletedEntity>,
      ),
      DeletedEntity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FolderGroupsTableTableManager get folderGroups =>
      $$FolderGroupsTableTableManager(_db, _db.folderGroups);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$SubTasksTableTableManager get subTasks =>
      $$SubTasksTableTableManager(_db, _db.subTasks);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$TaskTagsTableTableManager get taskTags =>
      $$TaskTagsTableTableManager(_db, _db.taskTags);
  $$EcampusCoursesTableTableManager get ecampusCourses =>
      $$EcampusCoursesTableTableManager(_db, _db.ecampusCourses);
  $$EcampusItemsTableTableManager get ecampusItems =>
      $$EcampusItemsTableTableManager(_db, _db.ecampusItems);
  $$ImportSessionsTableTableManager get importSessions =>
      $$ImportSessionsTableTableManager(_db, _db.importSessions);
  $$TaskRemindersTableTableManager get taskReminders =>
      $$TaskRemindersTableTableManager(_db, _db.taskReminders);
  $$LocalNotificationSchedulesTableTableManager
  get localNotificationSchedules =>
      $$LocalNotificationSchedulesTableTableManager(
        _db,
        _db.localNotificationSchedules,
      );
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$MigrationIssuesTableTableManager get migrationIssues =>
      $$MigrationIssuesTableTableManager(_db, _db.migrationIssues);
  $$DeletedEntitiesTableTableManager get deletedEntities =>
      $$DeletedEntitiesTableTableManager(_db, _db.deletedEntities);
}
