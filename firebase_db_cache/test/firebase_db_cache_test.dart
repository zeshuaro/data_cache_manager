import 'package:data_cache_manager/data_cache_manager.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_db_cache/firebase_db_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockQuery extends Mock implements Query {}

class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() async {
  sqfliteFfiInit();

  final dbName = 'data_store_test';
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: DataStoreSqflite.onCreate,
    ),
  );
  final dataStore = DataStoreSqflite.fromDb(dbName, db);
  final manager = DataCacheManager(dataStore: dataStore);
  final firebaseDbCache = FirebaseDbCache(manager);

  setUp(() async => await manager.clear(rebuildDb: true));

  final query = MockQuery();
  final snapshot = MockDataSnapshot();
  final key = 'key';
  final keyName = 'path';
  final value = 0;

  when(query.path).thenReturn(key);
  when(query.buildArguments()).thenReturn({keyName: key});
  when(query.once()).thenAnswer((_) => Future.value(snapshot));
  when(snapshot.value).thenReturn(value);

  test('testGetFromServer', () async {
    final result = await firebaseDbCache.get(query);
    expect(result.value, value);
    expect(result.location, CacheLoc.server);
  });

  test('testGetFromCache', () async {
    var result = await firebaseDbCache.get(query);
    final updatedAt = result.updatedAt;
    expect(result.value, value);
    expect(result.location, CacheLoc.server);

    result = await firebaseDbCache.get(query);
    expect(result.value, value);
    expect(result.location, CacheLoc.memory);
    expect(result.updatedAt, updatedAt);
  });

  test('testGetFromOutdatedCache', () async {
    final updatedAt = DateTime.now().add(Duration(days: 1));

    var result = await firebaseDbCache.get(query);
    expect(result.value, value);
    expect(result.location, CacheLoc.server);

    result = await firebaseDbCache.get(query, updatedAt: updatedAt);
    expect(result.value, value);
    expect(result.location, CacheLoc.server);
  });

  test('testRemoveSameKeyData', () async {
    final queryWithParams = MockQuery();
    final snapshotWithParams = MockDataSnapshot();
    final otherValue = 1;
    final updatedAt = DateTime.now().add(Duration(days: 1));

    when(queryWithParams.path).thenReturn(key);
    when(queryWithParams.buildArguments())
        .thenReturn({keyName: key, 'limit': 1});
    when(queryWithParams.once())
        .thenAnswer((_) => Future.value(snapshotWithParams));
    when(snapshotWithParams.value).thenReturn(otherValue);

    // First get should return data from server
    var result = await firebaseDbCache.get(query);
    expect(result.value, value);
    expect(result.location, CacheLoc.server);
    result = await firebaseDbCache.get(queryWithParams);
    expect(result.value, otherValue);
    expect(result.location, CacheLoc.server);

    // Second get should return data from memory cache
    result = await firebaseDbCache.get(query);
    expect(result.value, value);
    expect(result.location, CacheLoc.memory);
    result = await firebaseDbCache.get(queryWithParams);
    expect(result.value, otherValue);
    expect(result.location, CacheLoc.memory);

    // Get with updated datetime should return data from server
    result = await firebaseDbCache.get(
      query,
      updatedAt: updatedAt,
      removeSameKeyData: true,
    );
    expect(result.value, value);
    expect(result.location, CacheLoc.server);
    result = await firebaseDbCache.get(queryWithParams);
    expect(result.value, otherValue);
    expect(result.location, CacheLoc.server);
  });
}
