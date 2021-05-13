import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

part 'cached_data.g.dart';

/// Cache location types.
enum CacheLoc { server, local, memory }

/// Represents the data returned from cache.
@CopyWith()
class CachedData extends Equatable {
  /// The cached data value.
  final Object? value;

  /// The location of the cache is retrieved.
  final CacheLoc location;

  /// The datetime of the cache is updated.
  final DateTime updatedAt;

  /// The datatime of the cache is last used.
  final DateTime lastUsedAt;

  /// The cache use count.
  final int useCount;

  /// Create a new instance of CachedData.
  CachedData({
    this.value,
    required this.location,
    required this.updatedAt,
    required this.lastUsedAt,
    required this.useCount,
  });

  // coverage:ignore-start
  @override
  List<Object?> get props {
    return [
      value,
      location,
      updatedAt.millisecondsSinceEpoch,
      lastUsedAt.millisecondsSinceEpoch,
      useCount,
    ];
  }

  @override
  bool get stringify => true;
  // coverage:ignore-end
}
