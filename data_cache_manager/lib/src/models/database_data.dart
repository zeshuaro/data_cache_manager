import 'dart:convert';

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'models.dart';

part 'database_data.g.dart';

/// The data types for identifying the type of the cached data.
enum DataType {
  nullType,
  intType,
  doubleType,
  stringType,
  boolType,
  listType,
  mapType,
}

/// Represents the data to interact with the storage system.
@CopyWith()
@JsonSerializable()
class DatabaseData extends Equatable {
  /// The unique ID, usually generated automatically.
  @JsonKey(name: '_id')
  final int? id;

  /// The key for the data.
  @JsonKey(name: 'cacheKey')
  final String key;

  /// The data value.
  @JsonKey(name: 'cacheData')
  final String? value;

  /// The data use count.
  final int useCount;

  /// The type of the data.
  @JsonKey(
    name: 'dataType',
    fromJson: _Utils.dataTypeFromJson,
    toJson: _Utils.dataTypeToJson,
  )
  final DataType type;

  /// The query parameters associated with the data.
  @JsonKey(
    fromJson: _Utils.queryParamsFromJson,
    toJson: _Utils.queryParamsToJson,
  )
  final QueryParams queryParams;

  /// The datetime of the data is updated.
  @JsonKey(fromJson: _Utils.dateTimeFromJson, toJson: _Utils.dateTimeToJson)
  final DateTime updatedAt;

  /// The datetime of the data is last used.
  @JsonKey(fromJson: _Utils.dateTimeFromJson, toJson: _Utils.dateTimeToJson)
  final DateTime lastUsedAt;

  /// Create a new instance of DatabaseData.
  DatabaseData({
    this.id,
    this.value,
    required this.key,
    required this.type,
    required this.queryParams,
    required this.updatedAt,
    required this.lastUsedAt,
    required this.useCount,
  });

  /// Create a new instance of DatabaseData from json.
  factory DatabaseData.fromJson(Map<String, dynamic> json) {
    return _$DatabaseDataFromJson(json);
  }

  /// Create a new instnace of DatabaseData from user provided values.
  ///
  /// Throw [UnsupportedDataType] if the type of the [value] is not supported.
  factory DatabaseData.fromUserValue({
    required dynamic value,
    required String key,
    required QueryParams queryParams,
    required DateTime dateTime,
  }) {
    DataType dataType;
    String? cacheData;

    if (value == null) {
      dataType = DataType.nullType;
    } else if (value is int) {
      dataType = DataType.intType;
      cacheData = value.toString();
    } else if (value is double) {
      dataType = DataType.doubleType;
      cacheData = value.toString();
    } else if (value is String) {
      dataType = DataType.stringType;
      cacheData = value;
    } else if (value is bool) {
      dataType = DataType.boolType;
      cacheData = value.toString();
    } else if (value is List) {
      dataType = DataType.listType;
      try {
        cacheData = jsonEncode(value);
      } on JsonUnsupportedObjectError {
        throw UnsupportedDataType();
      }
    } else if (value is Map) {
      dataType = DataType.mapType;
      try {
        cacheData = jsonEncode(value);
      } on JsonUnsupportedObjectError {
        throw UnsupportedDataType();
      }
    } else {
      throw UnsupportedDataType();
    }

    return DatabaseData(
      key: key,
      queryParams: queryParams,
      type: dataType,
      value: cacheData,
      updatedAt: dateTime,
      lastUsedAt: dateTime,
      useCount: 0,
    );
  }

  /// Return a json representation of the object.
  Map<String, dynamic> toJson() => _$DatabaseDataToJson(this);

  // coverage:ignore-start
  @override
  List<Object?> get props {
    return [
      id,
      key,
      type,
      queryParams,
      value,
      updatedAt.millisecondsSinceEpoch,
      lastUsedAt.millisecondsSinceEpoch,
      useCount,
    ];
  }

  @override
  bool get stringify => true;
  // coverage:ignore-end

  /// Return the original data value with its type.
  ///
  /// If the data value is `null`, it will have `dynamic` type. Throw
  /// [UnsupportedDataType] if the data type is unsupported.
  dynamic get userValue {
    dynamic result;
    if (type == DataType.nullType) {
      result = null;
    } else if (type == DataType.intType) {
      result = int.parse(value!);
    } else if (type == DataType.doubleType) {
      result = double.parse(value!);
    } else if (type == DataType.stringType) {
      result = value;
    } else if (type == DataType.boolType) {
      result = value == 'true' ? true : false;
    } else if (type == DataType.listType || type == DataType.mapType) {
      result = jsonDecode(value!);
    } else {
      throw UnsupportedDataType();
    }

    return result;
  }
}

/// Private class with utility methods for converting data types.
class _Utils {
  static DataType dataTypeFromJson(int value) => DataType.values[value];

  static int dataTypeToJson(DataType value) => value.index;

  static QueryParams queryParamsFromJson(String value) {
    return QueryParams(jsonDecode(value));
  }

  static String queryParamsToJson(QueryParams value) => value.asStr;

  static DateTime dateTimeFromJson(int value) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  static int dateTimeToJson(DateTime value) {
    return value.millisecondsSinceEpoch;
  }
}
