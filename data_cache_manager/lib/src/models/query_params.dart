import 'dart:collection';
import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Represents the query parameters.
class QueryParams extends Equatable {
  final Map<String, dynamic> _paramsMap;

  /// Create a new instance of QueryParams.
  QueryParams([Map<String, dynamic> params = const <String, dynamic>{}])
      : _paramsMap = SplayTreeMap.from(params);

  // coverage:ignore-start
  @override
  List<Object> get props => [_paramsMap];

  @override
  bool get stringify => true;
  // coverage:ignore-end

  /// Return the query parameters as a [Map].
  Map<String, dynamic> get asMap => _paramsMap;

  /// Return the query parameters as a [String].
  String get asStr => jsonEncode(_paramsMap);
}
