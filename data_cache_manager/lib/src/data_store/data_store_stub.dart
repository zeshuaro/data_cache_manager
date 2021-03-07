import 'package:data_cache_manager/src/models/database_data.dart';
import 'package:data_cache_manager/src/models/query_params.dart';

/// Abstract class for the storage system.
abstract class DataStore {
  /// Insert data to storage.
  Future<void> insert(DatabaseData data);

  /// Update data to storage.
  Future<void> update(DatabaseData data);

  /// Insert or update data in storage.
  ///
  /// Insert data if it does not exist in the storage, otherwise update the
  /// existing data.
  Future<void> upsert(DatabaseData data);

  /// Get data from storage.
  ///
  /// The retrieved data is associated to both the [key] and [queryParams].
  Future<DatabaseData> get(String key, QueryParams queryParams);

  /// Get and udpate data in storage
  ///
  /// The retrieved data is associated to both the [key] and [queryParams]. The
  /// data should also be updated with the provided [lastUsedAt] datetime.
  Future<DatabaseData> getAndUpdate(
    String key,
    QueryParams queryParams,
    DateTime lastUsedAt,
  );

  /// Remove data from storage.
  ///
  /// Remove data by both the [key] and [queryParams]. And setting [rebuildDb]
  /// to `true` will clean up the SQL database and free up the space.
  Future<void> remove(
    String key,
    QueryParams queryParams, {
    bool rebuildDb = false,
  });

  /// Remove data from storage by [key].
  ///
  /// Setting [rebuildDb] to `true` will clean up the SQL database and free up
  /// the space.
  Future<void> removeByKey(String key, {bool rebuildDb = false});

  /// Remove data from storage where its last used datetime is before
  /// [staleDateTime].
  Future<List<DatabaseData>> removeStale(DateTime staleDateTime);

  /// Remove data from storage until the storage file size is less than
  /// [maxCacheSize].
  Future<List<DatabaseData>> removeOversized(int maxCacheSize);

  /// Remove everything from storage.
  ///
  /// Setting [rebuildDb] to `true` will clean up the SQL database and free up
  /// the space.
  Future<void> clear({bool rebuildDb = false});

  /// Open the storage system.
  Future<void> open();

  /// Close the storage system.
  Future<void> close();
}
