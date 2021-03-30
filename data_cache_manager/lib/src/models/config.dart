import 'package:equatable/equatable.dart';

/// The config to customize [DataCacheManager].
class Config extends Equatable {
  /// The unique identifier for [DataCacheManager], also use as the database
  /// file name. Default to `data_cache`.
  final String dbKey;

  /// Whether to cache data in memory or not. Default to `true`.
  final bool useMemCache;

  /// Whether to use Network Time Protocol (NTP) datetime. Default to `false`.
  ///
  /// Setting this to `true` will use NTP datetime instead of the device's
  /// datetime. Note that NTP has rate limiting and so using NTP datetime may
  /// cause up to 2 seconds difference to the actual datetime.
  final bool useNtpDateTime;

  /// The minimum [Duration] for a cache to become stale.
  final Duration? stalePeriod;

  /// Whether to cleanup once on initialization only. Default to `false`.
  ///
  /// This will override [cleanupInterval] to ensure that cleanup is only run
  /// once when the [DataCacheManager] is initialized.
  final bool cleanupOnInit;

  /// The interval between cache cleanups.
  ///
  /// This option is ignored if [cleanupOnInit] is set to `true`.
  final Duration? cleanupInterval;

  /// The maximum cache size in bytes.
  final int? maxCacheSize;

  /// Create a new instance of Config.
  const Config({
    this.dbKey = 'data_cache',
    this.useMemCache = true,
    this.useNtpDateTime = false,
    this.cleanupOnInit = false,
    this.cleanupInterval,
    this.stalePeriod,
    this.maxCacheSize,
  });

  @override
  List<Object?> get props {
    return [
      dbKey,
      useMemCache,
      useNtpDateTime,
      cleanupOnInit,
      cleanupInterval,
      stalePeriod,
      maxCacheSize,
    ];
  }

  @override
  bool get stringify => true;
}
