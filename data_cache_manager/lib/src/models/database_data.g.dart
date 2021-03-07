// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_data.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

extension DatabaseDataCopyWith on DatabaseData {
  DatabaseData copyWith({
    int id,
    String key,
    DateTime lastUsedAt,
    QueryParams queryParams,
    _DataType type,
    DateTime updatedAt,
    int useCount,
    String value,
  }) {
    return DatabaseData(
      id: id ?? this.id,
      key: key ?? this.key,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      queryParams: queryParams ?? this.queryParams,
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
      useCount: useCount ?? this.useCount,
      value: value ?? this.value,
    );
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DatabaseData _$DatabaseDataFromJson(Map<String, dynamic> json) {
  return DatabaseData(
    id: json['_id'] as int,
    key: json['cacheKey'] as String,
    type: _Utils.dataTypeFromJson(json['dataType'] as int),
    queryParams: _Utils.queryParamsFromJson(json['queryParams'] as String),
    value: json['cacheData'] as String,
    updatedAt: _Utils.dateTimeFromJson(json['updatedAt'] as int),
    lastUsedAt: _Utils.dateTimeFromJson(json['lastUsedAt'] as int),
    useCount: json['useCount'] as int,
  );
}

Map<String, dynamic> _$DatabaseDataToJson(DatabaseData instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'cacheKey': instance.key,
      'cacheData': instance.value,
      'useCount': instance.useCount,
      'dataType': _Utils.dataTypeToJson(instance.type),
      'queryParams': _Utils.queryParamsToJson(instance.queryParams),
      'updatedAt': _Utils.dateTimeToJson(instance.updatedAt),
      'lastUsedAt': _Utils.dateTimeToJson(instance.lastUsedAt),
    };
