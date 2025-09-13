// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_config_service.dart';

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
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
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
    provider,
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
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
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
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
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
  final String provider;
  final String? baseUrl;
  final String? modelName;
  final String? options;
  const ProviderConfig({
    required this.id,
    required this.provider,
    this.baseUrl,
    this.modelName,
    this.options,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider'] = Variable<String>(provider);
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
      provider: Value(provider),
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
      provider: serializer.fromJson<String>(json['provider']),
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
      'provider': serializer.toJson<String>(provider),
      'baseUrl': serializer.toJson<String?>(baseUrl),
      'modelName': serializer.toJson<String?>(modelName),
      'options': serializer.toJson<String?>(options),
    };
  }

  ProviderConfig copyWith({
    int? id,
    String? provider,
    Value<String?> baseUrl = const Value.absent(),
    Value<String?> modelName = const Value.absent(),
    Value<String?> options = const Value.absent(),
  }) => ProviderConfig(
    id: id ?? this.id,
    provider: provider ?? this.provider,
    baseUrl: baseUrl.present ? baseUrl.value : this.baseUrl,
    modelName: modelName.present ? modelName.value : this.modelName,
    options: options.present ? options.value : this.options,
  );
  ProviderConfig copyWithCompanion(ProviderConfigsCompanion data) {
    return ProviderConfig(
      id: data.id.present ? data.id.value : this.id,
      provider: data.provider.present ? data.provider.value : this.provider,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      options: data.options.present ? data.options.value : this.options,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConfig(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('modelName: $modelName, ')
          ..write('options: $options')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, provider, baseUrl, modelName, options);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderConfig &&
          other.id == this.id &&
          other.provider == this.provider &&
          other.baseUrl == this.baseUrl &&
          other.modelName == this.modelName &&
          other.options == this.options);
}

class ProviderConfigsCompanion extends UpdateCompanion<ProviderConfig> {
  final Value<int> id;
  final Value<String> provider;
  final Value<String?> baseUrl;
  final Value<String?> modelName;
  final Value<String?> options;
  const ProviderConfigsCompanion({
    this.id = const Value.absent(),
    this.provider = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.modelName = const Value.absent(),
    this.options = const Value.absent(),
  });
  ProviderConfigsCompanion.insert({
    this.id = const Value.absent(),
    required String provider,
    this.baseUrl = const Value.absent(),
    this.modelName = const Value.absent(),
    this.options = const Value.absent(),
  }) : provider = Value(provider);
  static Insertable<ProviderConfig> custom({
    Expression<int>? id,
    Expression<String>? provider,
    Expression<String>? baseUrl,
    Expression<String>? modelName,
    Expression<String>? options,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (provider != null) 'provider': provider,
      if (baseUrl != null) 'base_url': baseUrl,
      if (modelName != null) 'model_name': modelName,
      if (options != null) 'options': options,
    });
  }

  ProviderConfigsCompanion copyWith({
    Value<int>? id,
    Value<String>? provider,
    Value<String?>? baseUrl,
    Value<String?>? modelName,
    Value<String?>? options,
  }) {
    return ProviderConfigsCompanion(
      id: id ?? this.id,
      provider: provider ?? this.provider,
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
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
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
          ..write('provider: $provider, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('modelName: $modelName, ')
          ..write('options: $options')
          ..write(')'))
        .toString();
  }
}

class $JobQueueTable extends JobQueue
    with TableInfo<$JobQueueTable, JobQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobQueueTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _jobTypeMeta = const VerificationMeta(
    'jobType',
  );
  @override
  late final GeneratedColumn<String> jobType = GeneratedColumn<String>(
    'job_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jobType,
    payload,
    attempts,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'job_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<JobQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('job_type')) {
      context.handle(
        _jobTypeMeta,
        jobType.isAcceptableOrUnknown(data['job_type']!, _jobTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_jobTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JobQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jobType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $JobQueueTable createAlias(String alias) {
    return $JobQueueTable(attachedDatabase, alias);
  }
}

class JobQueueData extends DataClass implements Insertable<JobQueueData> {
  final int id;
  final String jobType;
  final String payload;
  final int attempts;
  final DateTime createdAt;
  const JobQueueData({
    required this.id,
    required this.jobType,
    required this.payload,
    required this.attempts,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['job_type'] = Variable<String>(jobType);
    map['payload'] = Variable<String>(payload);
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  JobQueueCompanion toCompanion(bool nullToAbsent) {
    return JobQueueCompanion(
      id: Value(id),
      jobType: Value(jobType),
      payload: Value(payload),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
    );
  }

  factory JobQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobQueueData(
      id: serializer.fromJson<int>(json['id']),
      jobType: serializer.fromJson<String>(json['jobType']),
      payload: serializer.fromJson<String>(json['payload']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jobType': serializer.toJson<String>(jobType),
      'payload': serializer.toJson<String>(payload),
      'attempts': serializer.toJson<int>(attempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  JobQueueData copyWith({
    int? id,
    String? jobType,
    String? payload,
    int? attempts,
    DateTime? createdAt,
  }) => JobQueueData(
    id: id ?? this.id,
    jobType: jobType ?? this.jobType,
    payload: payload ?? this.payload,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
  );
  JobQueueData copyWithCompanion(JobQueueCompanion data) {
    return JobQueueData(
      id: data.id.present ? data.id.value : this.id,
      jobType: data.jobType.present ? data.jobType.value : this.jobType,
      payload: data.payload.present ? data.payload.value : this.payload,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobQueueData(')
          ..write('id: $id, ')
          ..write('jobType: $jobType, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jobType, payload, attempts, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobQueueData &&
          other.id == this.id &&
          other.jobType == this.jobType &&
          other.payload == this.payload &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt);
}

class JobQueueCompanion extends UpdateCompanion<JobQueueData> {
  final Value<int> id;
  final Value<String> jobType;
  final Value<String> payload;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  const JobQueueCompanion({
    this.id = const Value.absent(),
    this.jobType = const Value.absent(),
    this.payload = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  JobQueueCompanion.insert({
    this.id = const Value.absent(),
    required String jobType,
    required String payload,
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : jobType = Value(jobType),
       payload = Value(payload);
  static Insertable<JobQueueData> custom({
    Expression<int>? id,
    Expression<String>? jobType,
    Expression<String>? payload,
    Expression<int>? attempts,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobType != null) 'job_type': jobType,
      if (payload != null) 'payload': payload,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  JobQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? jobType,
    Value<String>? payload,
    Value<int>? attempts,
    Value<DateTime>? createdAt,
  }) {
    return JobQueueCompanion(
      id: id ?? this.id,
      jobType: jobType ?? this.jobType,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jobType.present) {
      map['job_type'] = Variable<String>(jobType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobQueueCompanion(')
          ..write('id: $id, ')
          ..write('jobType: $jobType, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt')
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
  late final $JobQueueTable jobQueue = $JobQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    providerConfigs,
    jobQueue,
  ];
}

typedef $$ProviderConfigsTableCreateCompanionBuilder =
    ProviderConfigsCompanion Function({
      Value<int> id,
      required String provider,
      Value<String?> baseUrl,
      Value<String?> modelName,
      Value<String?> options,
    });
typedef $$ProviderConfigsTableUpdateCompanionBuilder =
    ProviderConfigsCompanion Function({
      Value<int> id,
      Value<String> provider,
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

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
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

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
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

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

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
                Value<String> provider = const Value.absent(),
                Value<String?> baseUrl = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> options = const Value.absent(),
              }) => ProviderConfigsCompanion(
                id: id,
                provider: provider,
                baseUrl: baseUrl,
                modelName: modelName,
                options: options,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String provider,
                Value<String?> baseUrl = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> options = const Value.absent(),
              }) => ProviderConfigsCompanion.insert(
                id: id,
                provider: provider,
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
typedef $$JobQueueTableCreateCompanionBuilder =
    JobQueueCompanion Function({
      Value<int> id,
      required String jobType,
      required String payload,
      Value<int> attempts,
      Value<DateTime> createdAt,
    });
typedef $$JobQueueTableUpdateCompanionBuilder =
    JobQueueCompanion Function({
      Value<int> id,
      Value<String> jobType,
      Value<String> payload,
      Value<int> attempts,
      Value<DateTime> createdAt,
    });

class $$JobQueueTableFilterComposer
    extends Composer<_$AppDatabase, $JobQueueTable> {
  $$JobQueueTableFilterComposer({
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

  ColumnFilters<String> get jobType => $composableBuilder(
    column: $table.jobType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JobQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $JobQueueTable> {
  $$JobQueueTableOrderingComposer({
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

  ColumnOrderings<String> get jobType => $composableBuilder(
    column: $table.jobType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JobQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobQueueTable> {
  $$JobQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobType =>
      $composableBuilder(column: $table.jobType, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$JobQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobQueueTable,
          JobQueueData,
          $$JobQueueTableFilterComposer,
          $$JobQueueTableOrderingComposer,
          $$JobQueueTableAnnotationComposer,
          $$JobQueueTableCreateCompanionBuilder,
          $$JobQueueTableUpdateCompanionBuilder,
          (
            JobQueueData,
            BaseReferences<_$AppDatabase, $JobQueueTable, JobQueueData>,
          ),
          JobQueueData,
          PrefetchHooks Function()
        > {
  $$JobQueueTableTableManager(_$AppDatabase db, $JobQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jobType = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => JobQueueCompanion(
                id: id,
                jobType: jobType,
                payload: payload,
                attempts: attempts,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jobType,
                required String payload,
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => JobQueueCompanion.insert(
                id: id,
                jobType: jobType,
                payload: payload,
                attempts: attempts,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JobQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobQueueTable,
      JobQueueData,
      $$JobQueueTableFilterComposer,
      $$JobQueueTableOrderingComposer,
      $$JobQueueTableAnnotationComposer,
      $$JobQueueTableCreateCompanionBuilder,
      $$JobQueueTableUpdateCompanionBuilder,
      (
        JobQueueData,
        BaseReferences<_$AppDatabase, $JobQueueTable, JobQueueData>,
      ),
      JobQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProviderConfigsTableTableManager get providerConfigs =>
      $$ProviderConfigsTableTableManager(_db, _db.providerConfigs);
  $$JobQueueTableTableManager get jobQueue =>
      $$JobQueueTableTableManager(_db, _db.jobQueue);
}
