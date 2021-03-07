part of 'data_cache_manager.dart';

/// Private class for caching data in memory.
class _MemoryCache {
  final _cache = <String, Map<String, CachedData>>{};

  /// Add data to cache.
  void add(String key, String params, CachedData data) {
    _cache.putIfAbsent(key, () => <String, CachedData>{});
    _cache[key][params] = data;
  }

  /// Get data from cache.
  CachedData get(String key, String params) {
    CachedData data;
    final map = _cache[key];
    if (map != null) data = map[params];

    return data;
  }

  /// Remove data from cache.
  void remove(String key, String params) {
    if (_cache.containsKey(key) && _cache[key].containsKey(params)) {
      _cache[key].remove(params);
    }
  }

  /// Remove data from cache by [key].
  void removeByKey(String key) => _cache.remove(key);

  /// Clear everything in memory cache.
  void clear() => _cache.clear();
}
