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

class $JobQueuesTable extends JobQueues
    with TableInfo<$JobQueuesTable, JobQueue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobQueuesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
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
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jobType,
    status,
    payload,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'job_queues';
  @override
  VerificationContext validateIntegrity(
    Insertable<JobQueue> instance, {
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JobQueue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobQueue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jobType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
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
  $JobQueuesTable createAlias(String alias) {
    return $JobQueuesTable(attachedDatabase, alias);
  }
}

class JobQueue extends DataClass implements Insertable<JobQueue> {
  final int id;
  final String jobType;
  final String status;
  final String payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  const JobQueue({
    required this.id,
    required this.jobType,
    required this.status,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['job_type'] = Variable<String>(jobType);
    map['status'] = Variable<String>(status);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  JobQueuesCompanion toCompanion(bool nullToAbsent) {
    return JobQueuesCompanion(
      id: Value(id),
      jobType: Value(jobType),
      status: Value(status),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory JobQueue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobQueue(
      id: serializer.fromJson<int>(json['id']),
      jobType: serializer.fromJson<String>(json['jobType']),
      status: serializer.fromJson<String>(json['status']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jobType': serializer.toJson<String>(jobType),
      'status': serializer.toJson<String>(status),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  JobQueue copyWith({
    int? id,
    String? jobType,
    String? status,
    String? payload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => JobQueue(
    id: id ?? this.id,
    jobType: jobType ?? this.jobType,
    status: status ?? this.status,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  JobQueue copyWithCompanion(JobQueuesCompanion data) {
    return JobQueue(
      id: data.id.present ? data.id.value : this.id,
      jobType: data.jobType.present ? data.jobType.value : this.jobType,
      status: data.status.present ? data.status.value : this.status,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobQueue(')
          ..write('id: $id, ')
          ..write('jobType: $jobType, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, jobType, status, payload, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobQueue &&
          other.id == this.id &&
          other.jobType == this.jobType &&
          other.status == this.status &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class JobQueuesCompanion extends UpdateCompanion<JobQueue> {
  final Value<int> id;
  final Value<String> jobType;
  final Value<String> status;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const JobQueuesCompanion({
    this.id = const Value.absent(),
    this.jobType = const Value.absent(),
    this.status = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  JobQueuesCompanion.insert({
    this.id = const Value.absent(),
    required String jobType,
    required String status,
    required String payload,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : jobType = Value(jobType),
       status = Value(status),
       payload = Value(payload);
  static Insertable<JobQueue> custom({
    Expression<int>? id,
    Expression<String>? jobType,
    Expression<String>? status,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobType != null) 'job_type': jobType,
      if (status != null) 'status': status,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  JobQueuesCompanion copyWith({
    Value<int>? id,
    Value<String>? jobType,
    Value<String>? status,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return JobQueuesCompanion(
      id: id ?? this.id,
      jobType: jobType ?? this.jobType,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobQueuesCompanion(')
          ..write('id: $id, ')
          ..write('jobType: $jobType, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DocProvenanceTable extends DocProvenance
    with TableInfo<$DocProvenanceTable, DocProvenanceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocProvenanceTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _newDocumentIdMeta = const VerificationMeta(
    'newDocumentId',
  );
  @override
  late final GeneratedColumn<String> newDocumentId = GeneratedColumn<String>(
    'new_document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceDocumentIdsMeta = const VerificationMeta(
    'sourceDocumentIds',
  );
  @override
  late final GeneratedColumn<String> sourceDocumentIds =
      GeneratedColumn<String>(
        'source_document_ids',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
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
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    newDocumentId,
    type,
    sourceDocumentIds,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'doc_provenance';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocProvenanceData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('new_document_id')) {
      context.handle(
        _newDocumentIdMeta,
        newDocumentId.isAcceptableOrUnknown(
          data['new_document_id']!,
          _newDocumentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_newDocumentIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('source_document_ids')) {
      context.handle(
        _sourceDocumentIdsMeta,
        sourceDocumentIds.isAcceptableOrUnknown(
          data['source_document_ids']!,
          _sourceDocumentIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceDocumentIdsMeta);
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
  DocProvenanceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocProvenanceData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      newDocumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_document_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      sourceDocumentIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_document_ids'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DocProvenanceTable createAlias(String alias) {
    return $DocProvenanceTable(attachedDatabase, alias);
  }
}

class DocProvenanceData extends DataClass
    implements Insertable<DocProvenanceData> {
  final int id;
  final String newDocumentId;
  final String type;
  final String sourceDocumentIds;
  final DateTime createdAt;
  const DocProvenanceData({
    required this.id,
    required this.newDocumentId,
    required this.type,
    required this.sourceDocumentIds,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['new_document_id'] = Variable<String>(newDocumentId);
    map['type'] = Variable<String>(type);
    map['source_document_ids'] = Variable<String>(sourceDocumentIds);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DocProvenanceCompanion toCompanion(bool nullToAbsent) {
    return DocProvenanceCompanion(
      id: Value(id),
      newDocumentId: Value(newDocumentId),
      type: Value(type),
      sourceDocumentIds: Value(sourceDocumentIds),
      createdAt: Value(createdAt),
    );
  }

  factory DocProvenanceData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocProvenanceData(
      id: serializer.fromJson<int>(json['id']),
      newDocumentId: serializer.fromJson<String>(json['newDocumentId']),
      type: serializer.fromJson<String>(json['type']),
      sourceDocumentIds: serializer.fromJson<String>(json['sourceDocumentIds']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'newDocumentId': serializer.toJson<String>(newDocumentId),
      'type': serializer.toJson<String>(type),
      'sourceDocumentIds': serializer.toJson<String>(sourceDocumentIds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DocProvenanceData copyWith({
    int? id,
    String? newDocumentId,
    String? type,
    String? sourceDocumentIds,
    DateTime? createdAt,
  }) => DocProvenanceData(
    id: id ?? this.id,
    newDocumentId: newDocumentId ?? this.newDocumentId,
    type: type ?? this.type,
    sourceDocumentIds: sourceDocumentIds ?? this.sourceDocumentIds,
    createdAt: createdAt ?? this.createdAt,
  );
  DocProvenanceData copyWithCompanion(DocProvenanceCompanion data) {
    return DocProvenanceData(
      id: data.id.present ? data.id.value : this.id,
      newDocumentId: data.newDocumentId.present
          ? data.newDocumentId.value
          : this.newDocumentId,
      type: data.type.present ? data.type.value : this.type,
      sourceDocumentIds: data.sourceDocumentIds.present
          ? data.sourceDocumentIds.value
          : this.sourceDocumentIds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocProvenanceData(')
          ..write('id: $id, ')
          ..write('newDocumentId: $newDocumentId, ')
          ..write('type: $type, ')
          ..write('sourceDocumentIds: $sourceDocumentIds, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, newDocumentId, type, sourceDocumentIds, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocProvenanceData &&
          other.id == this.id &&
          other.newDocumentId == this.newDocumentId &&
          other.type == this.type &&
          other.sourceDocumentIds == this.sourceDocumentIds &&
          other.createdAt == this.createdAt);
}

class DocProvenanceCompanion extends UpdateCompanion<DocProvenanceData> {
  final Value<int> id;
  final Value<String> newDocumentId;
  final Value<String> type;
  final Value<String> sourceDocumentIds;
  final Value<DateTime> createdAt;
  const DocProvenanceCompanion({
    this.id = const Value.absent(),
    this.newDocumentId = const Value.absent(),
    this.type = const Value.absent(),
    this.sourceDocumentIds = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DocProvenanceCompanion.insert({
    this.id = const Value.absent(),
    required String newDocumentId,
    required String type,
    required String sourceDocumentIds,
    this.createdAt = const Value.absent(),
  }) : newDocumentId = Value(newDocumentId),
       type = Value(type),
       sourceDocumentIds = Value(sourceDocumentIds);
  static Insertable<DocProvenanceData> custom({
    Expression<int>? id,
    Expression<String>? newDocumentId,
    Expression<String>? type,
    Expression<String>? sourceDocumentIds,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (newDocumentId != null) 'new_document_id': newDocumentId,
      if (type != null) 'type': type,
      if (sourceDocumentIds != null) 'source_document_ids': sourceDocumentIds,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DocProvenanceCompanion copyWith({
    Value<int>? id,
    Value<String>? newDocumentId,
    Value<String>? type,
    Value<String>? sourceDocumentIds,
    Value<DateTime>? createdAt,
  }) {
    return DocProvenanceCompanion(
      id: id ?? this.id,
      newDocumentId: newDocumentId ?? this.newDocumentId,
      type: type ?? this.type,
      sourceDocumentIds: sourceDocumentIds ?? this.sourceDocumentIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (newDocumentId.present) {
      map['new_document_id'] = Variable<String>(newDocumentId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (sourceDocumentIds.present) {
      map['source_document_ids'] = Variable<String>(sourceDocumentIds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocProvenanceCompanion(')
          ..write('id: $id, ')
          ..write('newDocumentId: $newDocumentId, ')
          ..write('type: $type, ')
          ..write('sourceDocumentIds: $sourceDocumentIds, ')
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
  late final $JobQueuesTable jobQueues = $JobQueuesTable(this);
  late final $DocProvenanceTable docProvenance = $DocProvenanceTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    providerConfigs,
    jobQueues,
    docProvenance,
  ];
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
typedef $$JobQueuesTableCreateCompanionBuilder =
    JobQueuesCompanion Function({
      Value<int> id,
      required String jobType,
      required String status,
      required String payload,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$JobQueuesTableUpdateCompanionBuilder =
    JobQueuesCompanion Function({
      Value<int> id,
      Value<String> jobType,
      Value<String> status,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$JobQueuesTableFilterComposer
    extends Composer<_$AppDatabase, $JobQueuesTable> {
  $$JobQueuesTableFilterComposer({
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
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
}

class $$JobQueuesTableOrderingComposer
    extends Composer<_$AppDatabase, $JobQueuesTable> {
  $$JobQueuesTableOrderingComposer({
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
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

class $$JobQueuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobQueuesTable> {
  $$JobQueuesTableAnnotationComposer({
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

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$JobQueuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobQueuesTable,
          JobQueue,
          $$JobQueuesTableFilterComposer,
          $$JobQueuesTableOrderingComposer,
          $$JobQueuesTableAnnotationComposer,
          $$JobQueuesTableCreateCompanionBuilder,
          $$JobQueuesTableUpdateCompanionBuilder,
          (JobQueue, BaseReferences<_$AppDatabase, $JobQueuesTable, JobQueue>),
          JobQueue,
          PrefetchHooks Function()
        > {
  $$JobQueuesTableTableManager(_$AppDatabase db, $JobQueuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobQueuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobQueuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobQueuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jobType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => JobQueuesCompanion(
                id: id,
                jobType: jobType,
                status: status,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jobType,
                required String status,
                required String payload,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => JobQueuesCompanion.insert(
                id: id,
                jobType: jobType,
                status: status,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JobQueuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobQueuesTable,
      JobQueue,
      $$JobQueuesTableFilterComposer,
      $$JobQueuesTableOrderingComposer,
      $$JobQueuesTableAnnotationComposer,
      $$JobQueuesTableCreateCompanionBuilder,
      $$JobQueuesTableUpdateCompanionBuilder,
      (JobQueue, BaseReferences<_$AppDatabase, $JobQueuesTable, JobQueue>),
      JobQueue,
      PrefetchHooks Function()
    >;
typedef $$DocProvenanceTableCreateCompanionBuilder =
    DocProvenanceCompanion Function({
      Value<int> id,
      required String newDocumentId,
      required String type,
      required String sourceDocumentIds,
      Value<DateTime> createdAt,
    });
typedef $$DocProvenanceTableUpdateCompanionBuilder =
    DocProvenanceCompanion Function({
      Value<int> id,
      Value<String> newDocumentId,
      Value<String> type,
      Value<String> sourceDocumentIds,
      Value<DateTime> createdAt,
    });

class $$DocProvenanceTableFilterComposer
    extends Composer<_$AppDatabase, $DocProvenanceTable> {
  $$DocProvenanceTableFilterComposer({
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

  ColumnFilters<String> get newDocumentId => $composableBuilder(
    column: $table.newDocumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceDocumentIds => $composableBuilder(
    column: $table.sourceDocumentIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocProvenanceTableOrderingComposer
    extends Composer<_$AppDatabase, $DocProvenanceTable> {
  $$DocProvenanceTableOrderingComposer({
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

  ColumnOrderings<String> get newDocumentId => $composableBuilder(
    column: $table.newDocumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceDocumentIds => $composableBuilder(
    column: $table.sourceDocumentIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocProvenanceTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocProvenanceTable> {
  $$DocProvenanceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get newDocumentId => $composableBuilder(
    column: $table.newDocumentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get sourceDocumentIds => $composableBuilder(
    column: $table.sourceDocumentIds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DocProvenanceTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocProvenanceTable,
          DocProvenanceData,
          $$DocProvenanceTableFilterComposer,
          $$DocProvenanceTableOrderingComposer,
          $$DocProvenanceTableAnnotationComposer,
          $$DocProvenanceTableCreateCompanionBuilder,
          $$DocProvenanceTableUpdateCompanionBuilder,
          (
            DocProvenanceData,
            BaseReferences<
              _$AppDatabase,
              $DocProvenanceTable,
              DocProvenanceData
            >,
          ),
          DocProvenanceData,
          PrefetchHooks Function()
        > {
  $$DocProvenanceTableTableManager(_$AppDatabase db, $DocProvenanceTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocProvenanceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocProvenanceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocProvenanceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> newDocumentId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> sourceDocumentIds = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DocProvenanceCompanion(
                id: id,
                newDocumentId: newDocumentId,
                type: type,
                sourceDocumentIds: sourceDocumentIds,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String newDocumentId,
                required String type,
                required String sourceDocumentIds,
                Value<DateTime> createdAt = const Value.absent(),
              }) => DocProvenanceCompanion.insert(
                id: id,
                newDocumentId: newDocumentId,
                type: type,
                sourceDocumentIds: sourceDocumentIds,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocProvenanceTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocProvenanceTable,
      DocProvenanceData,
      $$DocProvenanceTableFilterComposer,
      $$DocProvenanceTableOrderingComposer,
      $$DocProvenanceTableAnnotationComposer,
      $$DocProvenanceTableCreateCompanionBuilder,
      $$DocProvenanceTableUpdateCompanionBuilder,
      (
        DocProvenanceData,
        BaseReferences<_$AppDatabase, $DocProvenanceTable, DocProvenanceData>,
      ),
      DocProvenanceData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProviderConfigsTableTableManager get providerConfigs =>
      $$ProviderConfigsTableTableManager(_db, _db.providerConfigs);
  $$JobQueuesTableTableManager get jobQueues =>
      $$JobQueuesTableTableManager(_db, _db.jobQueues);
  $$DocProvenanceTableTableManager get docProvenance =>
      $$DocProvenanceTableTableManager(_db, _db.docProvenance);
}
