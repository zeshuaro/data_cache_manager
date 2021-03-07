import 'package:data_cache_manager/data_cache_manager.dart';
import 'package:firebase_database/firebase_database.dart';

/// FirebaseDbCache is a Flutter plugin for fetching Firebase database data
/// with read from cache first then server.
class FirebaseDbCache {
  /// The cache manager.
  final DataCacheManager manager;

  /// Create a new instance of FirebaseDbCache.
  ///
  /// You can pass in a [DataCacheManager] with you own configurations.
  FirebaseDbCache([DataCacheManager manager])
      : manager = manager ?? DefaultDataCacheManager.instance;

  /// Get the [query] data.
  ///
  /// The first fetch on the query will automatically fetch the data from
  /// Firebase and cache it locally. Subsequential calls will then always
  /// return the data from cache if it is still available. If not, it will
  /// fallback to fetch the data from Firebase.
  ///
  /// [updatedAt] can be used to indicate if the cache has outdated. If it is
  /// provided, then it will be used to compare with the datetime of the cached
  /// data to check if it has outdated. If the cache is outdated, it will be
  /// removed and `null` will be returned. If [updatedAt] is not provided, the
  /// data will always be retrieved from cache if it is still available.
  ///
  /// When removing outdated cache, setting [removeSameKeyData] to `true` will
  /// remove all the data from cache with the same key/path.
  Future<CachedData> get(
    Query query, {
    DateTime updatedAt,
    bool removeSameKeyData = false,
  }) async {
    final key = query.path;
    final queryParams = query.buildArguments();

    var result = await manager.get(
      key,
      queryParams: queryParams,
      updatedAt: updatedAt,
      removeSameKeyData: removeSameKeyData,
    );

    if (result == null) {
      final serverData = (await query.once()).value;
      if (serverData != null) {
        result = await manager.add(
          key,
          serverData,
          queryParams: queryParams,
        );
      }
    }

    return result;
  }
}
