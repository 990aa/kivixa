// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProviderConfigsTable extends ProviderConfigs
    with TableInfo<$ProviderConfigsTable, ProviderConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderConfigsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'options',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    baseUrl,
    modelName,
    options,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderConfig> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    }
    if (data.containsKey('options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['options']!, _optionsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderConfig(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      ),
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      ),
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options'],
      ),
    );
  }

  @override
  $ProviderConfigsTable createAlias(String alias) {
    return $ProviderConfigsTable(attachedDatabase, alias);
  }
}

class ProviderConfig extends DataClass implements Insertable<ProviderConfig> {
  final int id;
  final String providerId;
  final String? baseUrl;
  final String? modelName;
  final String? options;
  const ProviderConfig({
    required this.id,
    required this.providerId,
    this.baseUrl,
    this.modelName,
    this.options,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<String>(providerId);
    if (!nullToAbsent || baseUrl != null) {
      map['base_url'] = Variable<String>(baseUrl);
    }
    if (!nullToAbsent || modelName != null) {
      map['model_name'] = Variable<String>(modelName);
    }
    if (!nullToAbsent || options != null) {
      map['options'] = Variable<String>(options);
    }
    return map;
  }

  ProviderConfigsCompanion toCompanion(bool nullToAbsent) {
    return ProviderConfigsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      baseUrl: baseUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(baseUrl),
      modelName: modelName == null && nullToAbsent
          ? const Value.absent()
          : Value(modelName),
      options: options == null && nullToAbsent
          ? const Value.absent()
          : Value(options),
    );
  }

  factory ProviderConfig.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderConfig(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      baseUrl: serializer.fromJson<String?>(json['baseUrl']),
      modelName: serializer.fromJson<String?>(json['modelName']),
      options: serializer.fromJson<String?>(json['options']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<String>(providerId),
      'baseUrl': serializer.toJson<String?>(baseUrl),
      'modelName': serializer.toJson<String?>(modelName),
      'options': serializer.toJson<String?>(options),
    };
  }

  ProviderConfig copyWith({
    int? id,
    String? providerId,
    Value<String?> baseUrl = const Value.absent(),
    Value<String?> modelName = const Value.absent(),
    Value<String?> options = const Value.absent(),
  }) => ProviderConfig(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    baseUrl: baseUrl.present ? baseUrl.value : this.baseUrl,
    modelName: modelName.present ? modelName.value : this.modelName,
    options: options.present ? options.value : this.options,
  );
  ProviderConfig copyWithCompanion(ProviderConfigsCompanion data) {
    return ProviderConfig(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      options: data.options.present ? data.options.value : this.options,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConfig(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('modelName: $modelName, ')
          ..write('options: $options')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, providerId, baseUrl, modelName, options);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderConfig &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.baseUrl == this.baseUrl &&
          other.modelName == this.modelName &&
          other.options == this.options);
}

class ProviderConfigsCompanion extends UpdateCompanion<ProviderConfig> {
  final Value<int> id;
  final Value<String> providerId;
  final Value<String?> baseUrl;
  final Value<String?> modelName;
  final Value<String?> options;
  const ProviderConfigsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.modelName = const Value.absent(),
    this.options = const Value.absent(),
  });
  ProviderConfigsCompanion.insert({
    this.id = const Value.absent(),
    required String providerId,
    this.baseUrl = const Value.absent(),
    this.modelName = const Value.absent(),
    this.options = const Value.absent(),
  }) : providerId = Value(providerId);
  static Insertable<ProviderConfig> custom({
    Expression<int>? id,
    Expression<String>? providerId,
    Expression<String>? baseUrl,
    Expression<String>? modelName,
    Expression<String>? options,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (baseUrl != null) 'base_url': baseUrl,
      if (modelName != null) 'model_name': modelName,
      if (options != null) 'options': options,
    });
  }

  ProviderConfigsCompanion copyWith({
    Value<int>? id,
    Value<String>? providerId,
    Value<String?>? baseUrl,
    Value<String?>? modelName,
    Value<String?>? options,
  }) {
    return ProviderConfigsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      baseUrl: baseUrl ?? this.baseUrl,
      modelName: modelName ?? this.modelName,
      options: options ?? this.options,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConfigsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('modelName: $modelName, ')
          ..write('options: $options')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProviderConfigsTable providerConfigs = $ProviderConfigsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [providerConfigs];
}

typedef $$ProviderConfigsTableCreateCompanionBuilder =
    ProviderConfigsCompanion Function({
      Value<int> id,
      required String providerId,
      Value<String?> baseUrl,
      Value<String?> modelName,
      Value<String?> options,
    });
typedef $$ProviderConfigsTableUpdateCompanionBuilder =
    ProviderConfigsCompanion Function({
      Value<int> id,
      Value<String> providerId,
      Value<String?> baseUrl,
      Value<String?> modelName,
      Value<String?> options,
    });

class $$ProviderConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableFilterComposer({
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

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableOrderingComposer({
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

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);
}

class $$ProviderConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProviderConfigsTable,
          ProviderConfig,
          $$ProviderConfigsTableFilterComposer,
          $$ProviderConfigsTableOrderingComposer,
          $$ProviderConfigsTableAnnotationComposer,
          $$ProviderConfigsTableCreateCompanionBuilder,
          $$ProviderConfigsTableUpdateCompanionBuilder,
          (
            ProviderConfig,
            BaseReferences<
              _$AppDatabase,
              $ProviderConfigsTable,
              ProviderConfig
            >,
          ),
          ProviderConfig,
          PrefetchHooks Function()
        > {
  $$ProviderConfigsTableTableManager(
    _$AppDatabase db,
    $ProviderConfigsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String?> baseUrl = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> options = const Value.absent(),
              }) => ProviderConfigsCompanion(
                id: id,
                providerId: providerId,
                baseUrl: baseUrl,
                modelName: modelName,
                options: options,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String providerId,
                Value<String?> baseUrl = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> options = const Value.absent(),
              }) => ProviderConfigsCompanion.insert(
                id: id,
                providerId: providerId,
                baseUrl: baseUrl,
                modelName: modelName,
                options: options,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProviderConfigsTable,
      ProviderConfig,
      $$ProviderConfigsTableFilterComposer,
      $$ProviderConfigsTableOrderingComposer,
      $$ProviderConfigsTableAnnotationComposer,
      $$ProviderConfigsTableCreateCompanionBuilder,
      $$ProviderConfigsTableUpdateCompanionBuilder,
      (
        ProviderConfig,
        BaseReferences<_$AppDatabase, $ProviderConfigsTable, ProviderConfig>,
      ),
      ProviderConfig,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProviderConfigsTableTableManager get providerConfigs =>
      $$ProviderConfigsTableTableManager(_db, _db.providerConfigs);
}
