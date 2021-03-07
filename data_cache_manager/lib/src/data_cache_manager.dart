import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart';

import 'data_store/data_store.dart';
import 'models/models.dart';

part 'memory_cache.dart';

/// DataCacheManager is a Flutter cache manager package for storing and
/// managing Dart data types, and should be used as a single instance.
class DataCacheManager {
  /// The config to customize DataCacheManager.
  final Config config;

  /// The underlying storage system to store the data.
  final DataStore dataStore;

  /// Create a new instance of DataCacheManager.
  ///
  /// You can pass in your [config] to customize the DataCacheManager. You
  /// can also pass in your own [dataStore] implementation for storing the data.
  DataCacheManager({this.config = const Config(), DataStore dataStore})
      : dataStore = dataStore ?? DataStoreSqflite(dbName: config.dbKey) {
    if (config.cleanupOnInit) {
      if (config.stalePeriod != null) removeStale();
      if (config.maxCacheSize != null) _removeOversized();
    } else if (config.cleanupInterval != null) {
      _scheduleCleanup();
    }
  }

  final _memCache = _MemoryCache();
  Timer _cleanupTask;
  DateTime _currDateTime;
  DateTime _dateTimeRef = DateTime.now();

  @visibleForTesting
  bool isCleanupTaskSet = false;

  /// Add data to cache.
  ///
  /// The data should be provided as [key], [value] pair where [key] is the
  /// unique identifier and [value] is the data to cache. You can also use
  /// [queryParams] to specify the query parameters you used to fetch the data.
  Future<CachedData> add(
    String key,
    dynamic value, {
    Map<String, dynamic> queryParams = const <String, dynamic>{},
  }) async {
    final params = QueryParams(queryParams);
    final dateTime = await _getCurrDateTime();
    final dbData = DatabaseData.fromUserValue(
      value: value,
      key: key,
      queryParams: params,
      dateTime: dateTime,
    );
    final result = CachedData(
      value: value,
      location: CacheLoc.server,
      updatedAt: dateTime,
      lastUsedAt: dateTime,
      useCount: 0,
    );

    await dataStore.upsert(dbData);
    if (config.useMemCache) {
      _memCache.add(
        key,
        params.asStr,
        result.copyWith(location: CacheLoc.memory),
      );
    }

    return result;
  }

  /// Get data from cache.
  ///
  /// Provide the same [key] that you used when adding the data to retrieve
  /// data from cache. You can also use [queryParams] to specify the query
  /// parameters you used to fetch and cache the data. If you cached a data with
  /// both [key] and [queryParams], you will need to provide both key and
  /// parameters to retrieve the data.
  ///
  /// [updatedAt] can be used to indicate if the cache has outdated. If it is
  /// provided, then it will be used to compare with the datetime of the cached
  /// data to check if it has outdated. If the cache is outdated, it will be
  /// removed and `null` will be returned. If [updatedAt] is not provided, the
  /// data will always be retrieved from cache if it is still available.
  ///
  /// When removing outdated cache, setting [removeSameKeyData] to `true` will
  /// remove all the data from cache with the same [key], even they have
  /// different [queryParams]. And setting [rebuildDb] to `true` will clean up
  /// the SQL database and free up the space.
  Future<CachedData> get(
    String key, {
    Map<String, dynamic> queryParams = const <String, dynamic>{},
    DateTime updatedAt,
    bool removeSameKeyData = false,
    bool rebuildDb = false,
  }) async {
    final params = QueryParams(queryParams);
    var data = await _getFromCache(key, params);

    if (updatedAt != null) {
      final cacheUpdatedAt = data?.updatedAt;
      if (cacheUpdatedAt != null && cacheUpdatedAt.isBefore(updatedAt)) {
        data = null;
        if (removeSameKeyData) {
          await removeByKey(key, rebuildDb: rebuildDb);
        } else {
          await remove(
            key,
            queryParams: queryParams,
            rebuildDb: rebuildDb,
          );
        }
      }
    }

    return data;
  }

  /// Remove data from cache.
  ///
  /// Provide the same [key] that you used when adding the data to remove
  /// data from cache. You can also use [queryParams] to specify the query
  /// parameters you used to fetch and cache the data. If you cached a data with
  /// both [key] and [queryParams], then you will need to provide both
  /// parameters to remove the data.
  ///
  /// Setting [rebuildDb] to `true` will clean up the SQL database and free up
  /// the space.
  Future<void> remove(
    String key, {
    Map<String, dynamic> queryParams = const <String, dynamic>{},
    bool rebuildDb = false,
  }) async {
    final params = QueryParams(queryParams);
    if (config.useMemCache) _memCache.remove(key, params.asStr);
    await dataStore.remove(key, params, rebuildDb: rebuildDb);
  }

  /// Remove data from cache by [key].
  ///
  /// Provide the same [key] that you used when adding the data to remove
  /// data from cache. This will remove all data withe the provided [key].
  ///
  /// Setting [rebuildDb] to `true` will clean up the SQL database and free up
  /// the space.
  Future<void> removeByKey(String key, {bool rebuildDb = false}) async {
    if (config.useMemCache) _memCache.removeByKey(key);
    await dataStore.removeByKey(key, rebuildDb: rebuildDb);
  }

  /// Remove everything from cache.
  ///
  /// Setting [rebuildDb] to `true` will clean up the SQL database and free up
  /// the space.
  Future<void> clear({bool rebuildDb = false}) async {
    if (config.useMemCache) _memCache.clear();
    await dataStore.clear(rebuildDb: rebuildDb);
  }

  /// Open the cache storage system.
  Future<void> open() async => await dataStore.open();

  /// Close the cache storage system.
  Future<void> close() async => await dataStore.close();

  /// Get current datetime.
  Future<DateTime> _getCurrDateTime() async {
    final now = DateTime.now();
    if (config.useNtpDateTime) {
      final diff = _dateTimeRef.difference(now).inSeconds;
      if (_currDateTime == null || diff > 2) {
        _dateTimeRef = now;
        _currDateTime = await NTP.now();
      }
    } else {
      _currDateTime = now;
    }

    return _currDateTime;
  }

  /// Get data from cache.
  Future<CachedData> _getFromCache(
    String key,
    QueryParams params,
  ) async {
    CachedData data;
    final currDateTime = await _getCurrDateTime();

    if (config.useMemCache) {
      final memData = _memCache.get(key, params.asStr);
      if (memData != null) {
        data = memData.copyWith(
          lastUsedAt: currDateTime,
          useCount: memData.useCount + 1,
        );
        _memCache.add(key, params.asStr, data);
      }
    }

    if (data == null) {
      final dbData = await dataStore.getAndUpdate(key, params, currDateTime);
      if (dbData != null) {
        data = CachedData(
          value: dbData.userValue,
          location: CacheLoc.local,
          updatedAt: dbData.updatedAt,
          lastUsedAt: currDateTime,
          useCount: dbData.useCount + 1,
        );
      }
    }

    return data;
  }

  /// Schedule cache cleanup.
  void _scheduleCleanup() {
    if (_cleanupTask == null) {
      isCleanupTaskSet = true;
      _cleanupTask = Timer(config.cleanupInterval, () async {
        if (config.stalePeriod != null) await removeStale();
        if (config.maxCacheSize != null) await _removeOversized();
        _cleanupTask = null;
        _scheduleCleanup();
      });
    }
  }

  /// Remove stale cache.
  @visibleForTesting
  Future<void> removeStale() async {
    final staleDateTime =
        (await _getCurrDateTime()).subtract(config.stalePeriod);
    final removedData = await dataStore.removeStale(staleDateTime);
    if (config.useMemCache) _removeMemCache(removedData);
  }

  /// Remove cache from memory with the given list of data.
  void _removeMemCache(List<DatabaseData> dataList) {
    for (final data in dataList) {
      _memCache.remove(data.key, data.queryParams.asStr);
    }
  }

  /// Clean up the cache to maintain the cache file size.
  Future<void> _removeOversized() async {
    final removedData = await dataStore.removeOversized(
      config.maxCacheSize,
    );
    if (config.useMemCache) _removeMemCache(removedData);
  }
}
