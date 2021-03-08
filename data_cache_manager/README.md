# Data Cache Manager

A Flutter cache manager package for storing and managing Dart data types.

[![pub package](https://img.shields.io/pub/v/data_cache_manager.svg)](https://pub.dartlang.org/packages/data_cache_manager)
[![docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://pub.dev/documentation/data_cache_manager/latest/)
[![MIT License](https://img.shields.io/github/license/zeshuaro/data_cache_manager.svg)](https://github.com/zeshuaro/data_cache_manager/blob/main/data_cache_manager/LICENSE)
[![data_cache_manager](https://github.com/zeshuaro/data_cache_manager/actions/workflows/data_cache_manager.yml/badge.svg)](https://github.com/zeshuaro/data_cache_manager/actions/workflows/data_cache_manager.yml)
[![codecov](https://codecov.io/gh/zeshuaro/data_cache_manager/branch/main/graph/badge.svg?token=BA2LTD1XI1&flag=data_cache_manager)](https://codecov.io/gh/zeshuaro/data_cache_manager)
[![Effective Dart](https://img.shields.io/badge/style-pedantic-40c4ff.svg)](https://github.com/google/pedantic)

## Getting Started

Add this to your project's `pubspec.yaml` file:

```yml
dependencies:
  data_cache_manager: ^0.0.1+1
```

## Usage

### Initialization

The easiest way is to use the provided `DefaultDataCacheManager.instance` to get a default instance of the cache manager:

```dart
import 'package:data_cache_manager/data_cache_manager.dart';

final DataCacheManager manager = DefaultDataCacheManager.instance;
```

### Adding data to cache

`DataCacheManager` can store most of the data types in Dart, see [this](#what-data-types-are-supported) section for a list of supported data types.

To add data, simply use the following method:

```dart
final String key = 'key';       // The unique key for your data
final String value = 'value';   // The data to cache

await manager.add(key, value);  // Add the data to local cache
```

**Storing different data with the same key**

In some cases, you might want to store different data with the same key. For example, when you are querying data from a database and paginating your data results. You can pass in the parameters you used to query the data as a `Map` when caching the data:

```dart
// The parameters you used to query the data in the first page
final Map<String, dynamic> firstParams = {'page': 1};

// The data on the first page
final List<int> firstValue = [0, 1, 2, 3, 4];

// The parameters you used to query the data in the second page
final Map<String, dynamic> secondParams = {'page': 2};

// The data on the second page
final List<int> secondValue = [5, 6, 7, 8, 9];

// Add the data to local cache
await manager.add(key, firstValue, queryParams: firstParams);
await manager.add(key, secondValue, queryParams: secondParams);
```

### Getting data from cache

To get data from the cache, simply use the same key that you used to store the data:

```dart
final cachedData = await manager.get(key);
```

If you passed in `queryParams` when storing the data, you can also use the same `queryParams` to get the respective data from the cache:

```dart
// firstCache will be [0, 1, 2, 3, 4]
final firstCache = await manager.get(key, queryParams: firstParams);

// secondCache will be [5, 6, 7, 8, 9]
final secondCache = await manager.get(key, queryParams: secondParams);
```

To avoid getting outdated cached data, you can pass in a `DateTime` to tell the cache manager when the data has been updated. If the cached data is stored earlier than the given `DateTime`, it will return `null` and remove the outdated cache.

```dart
final DateTime updatedAt = DateTime.now();

// cachedData will be null as it has been outdated
final cachedData = await manager.get(key, updatedAt: updatedAt);
```

### Removing data from cache

To remove data from the cache, simply use the same key that you used to store the data:

```dart
await manager.remove(key);
```

If you passed in `queryParams` when storing the data, you can also use the same `queryParams` to remove the respective data from the cache:

```dart
// Removes [0, 1, 2, 3, 4]
await manager.remove(key, queryParams: firstParams);

// Removes [5, 6, 7, 8, 9]
await manager.remove(key, queryParams: secondParams);
```

To remove all the data with the same key, use the following method instead:

```dart
await manager.removeByKey(key);
```

## Customization

If you want to customize and configure the cache manager, you will have to create your own class and store the cache manager instance. **It is important** to only create and use **one** cache manager instance with the same `dbKey` (which can be configured) throughout your application. See below for an example:

```dart
class MyDataCacheManager {
  static DataCacheManager instance = DataCacheManager(
    config: Config(
      dbKey: 'db_key',
      useMemCache: true,
      useNtpDateTime: false,
      cleanupOnInit: false,
      cleanupInterval: Duration(seconds: 30),
      stalePeriod: Duration(days: 30),
      maxCacheSize: 10000000,
    ),
  );
}
```

## Other Implementations

- [firebase_db_cache](https://github.com/zeshuaro/data_cache_manager/tree/main/firebase_db_cache) for caching data fetched from [firebase_database](https://pub.dev/packages/firebase_database)

## Frequently Asked Questions

### What data types are supported?

The supported data types are:
- `int` 
- `double`
- `String`
- `bool`
- `List`
- `Map`

Note that:
- `Iterable` is not supported, use `toList()` to convert any iterables
- `List` and `Map` has to be storing the types specified above

### When do the cached data get removed?

You can use the `stalePeriod` and `maxCacheSize` parameters in `Config` to control when the data get removed.

- `stalePeriod` can be used to define the minimum duration for a cached data to become stale. When the data becomes stale, it will be removed.
- `maxCacheSize` is the maximum cache size in bytes. When the cache size gets over this limit, it will start removing data. The data that has been stale for the longest period of time and has the least amount of usage will be removed first and so on.

### How to schedule the cached data cleanup?

You can use the `cleanupOnInit` and `cleanupInterval` parameters in `Config` to setup when to run and clean the cached data.

- Setting `cleanupOnInit` to `true` will only run the cleanup once when `DataCacheManager` is initialized. This will also override `cleanupInterval` to ensure that the cleanup is only run once.
- You can also define `cleanupInterval` to set how often the cache manager should run and clean the data.