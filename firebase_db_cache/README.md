# Firebase Database Cache

A Flutter plugin for fetching Firebase Realtime Database data with read from cache first then server.

[![pub package](https://img.shields.io/pub/v/firebase_db_cache.svg)](https://pub.dartlang.org/packages/firebase_db_cache)
[![docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://pub.dev/documentation/firebase_db_cache/latest/)
[![MIT License](https://img.shields.io/github/license/zeshuaro/data_cache_manager.svg)](https://github.com/zeshuaro/data_cache_manager/blob/main/firebase_db_cache/LICENSE)
[![firebase_db_cache](https://github.com/zeshuaro/data_cache_manager/actions/workflows/firebase_db_cache.yml/badge.svg)](https://github.com/zeshuaro/data_cache_manager/actions/workflows/firebase_db_cache.yml)
[![codecov](https://codecov.io/gh/zeshuaro/data_cache_manager/branch/main/graph/badge.svg?token=BA2LTD1XI1&flag=firebase_db_cache)](https://codecov.io/gh/zeshuaro/data_cache_manager)
[![pedantic](https://img.shields.io/badge/style-pedantic-40c4ff.svg)](https://github.com/google/pedantic)

This plugin is designed for applications using the `Query.once()` method in `firebase_database` plugin, and is implemented with read from cache first then server.

## Getting Started

Add this to your project's `pubspec.yaml` file:

```yml
dependencies:
  firebase_db_cache: ^1.0.0
```

## Usage

The simpliest usage is to pass in a Firebase Database `Query` for fetching your data. The first fetch will automatically fetch the data from Firebase and cache it locally. Subsequential calls will then always return the data from cache if it is still available. If not, it will fallback to fetch the data from Firebase.

```dart
import 'package:firebase_db_cache/firebase_db_cache.dart';

final firebaseDbCache = FirebaseDbCache();
final rootRef = FirebaseDatabase.instance.reference()

final query = rootRef.child('posts');
final cachedData = await firebaseDbCache.get(query);

// The value is same as DataSnapshot.value in firebase_database
print(cachedData.value)  
```

### Fetching up-to-date data

**PLEASE NOTE** This plugin does not compare the data on server and in cache to determine if it should fetch from server or cache. Instead, it relies on the `updatedAt` parameter that you can pass in. And so your application should implement the logic to fetch a `DateTime` which can be used to indicate if the cache is outdated or not.

Once you have obtained the `DateTime` information, you can pass it in to `get()` and will be used to determine if the cache has outdated. If this is the case, the outdated cache will be removed and the data will be fetched from server. The updated data will also be cached again.

```dart
final updatedAt = DateTime.now();
final cachedData = await firebaseDbCache.get(query, updatedAt: updatedAt);
```

### Removing data with the same key

`FirebaseDbCache` can be used to query and cache paginated data. For example:

```dart
// Query to fetch data on first page
final firstQuery = rootRef.child('posts').limitToFirst(5);
final firstData = await firebaseDbCache.get(firstQuery);

// Query to fetch data on second page
final secondQuery = rootRef.child('posts').limitToFirst(10).limitToLast(5);
final secondData = await firebaseDbCache.get(secondQuery);
```

However, when you use a `DateTime` to indicate the data has been outdated, the cached results on both the pages should become outdated. You can pass in `updatedAt` to all the `get()` method calls to ensure all the pages are up-to-date:

```dart
final firstData = await firebaseDbCache.get(
    firstQuery, 
    updatedAt: updatedAt,
);
final secondData = await firebaseDbCache.get(
    secondQuery, 
    updatedAt: updatedAt,
);
```

Alternatively, you can use the `removeSameKeyData` parameter to remove all outdated data with the same key:

```dart
// If the first cached data is outdated, it will be removed along with all the 
// other data with the same key
final firstData = await firebaseDbCache.get(
    firstQuery, 
    updatedAt: updatedAt,
    removeSameKeyData: true,
);

// The second cached data is removed already and so this will be fetching data 
// from Firebase
final secondData = await firebaseDbCache.get(secondQuery);
```

## Customization

You can customize the underlying cache manager and pass it in to `FirebaseDbCache` when initializing it, refer to [here](https://github.com/zeshuaro/data_cache_manager#customization) for the available options that you can customize it and for more details.

```dart
// Customized cache manager
final manager = DataCacheManager(config: Config());

// Initialise FirebaseDbCache with the customized cache manager
final firebaseDbCache = FirebaseDbCache(manager);
```