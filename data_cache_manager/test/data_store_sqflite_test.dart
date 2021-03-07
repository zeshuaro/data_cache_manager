import 'package:data_cache_manager/data_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  final key = 'key';
  final params = QueryParams({'key': 'value'});
  final emptyParams = QueryParams();
  final value = 0;
  final valueNoParams = 1;
  final now = DateTime.now();
  final dbData = DatabaseData.fromUserValue(
    key: key,
    value: value,
    queryParams: params,
    dateTime: now,
  );
  final dbDataNoParams = DatabaseData.fromUserValue(
    key: key,
    value: valueNoParams,
    queryParams: emptyParams,
    dateTime: now,
  );

  setUp(() async => await dataStore.clear(rebuildDb: true));

  group('testInsert', () {
    Future<void> testInsert(value) async {
      final dbData = DatabaseData.fromUserValue(
        key: key,
        value: value,
        queryParams: params,
        dateTime: now,
      );
      await dataStore.insert(dbData);
      final result = await dataStore.get(key, params);

      expect(result.userValue, value);
      expect(result.useCount, 0);
    }

    test('testInsertNull', () async => await testInsert(null));

    test('testInsertInt', () async => await testInsert(0));

    test('testInsertDouble', () async => await testInsert(0.0));

    test('testInsertString', () async => await testInsert('Hello World!'));

    test('testInsertBool', () async => await testInsert(true));

    test('testInsertList', () async => await testInsert([0, 1, 2, 3, 4]));

    test('testInsertMap', () async => await testInsert({'Hello': 'World!'}));
  });

  group('testGet', () {
    test('testGetEmpty', () async {
      expect(await dataStore.get(key, params), null);
    });

    test('testGetWithQueryParams', () async {
      await dataStore.insert(dbData);
      await dataStore.insert(dbDataNoParams);

      var result = await dataStore.get(key, params);
      expect(result.userValue, value);

      result = await dataStore.get(key, emptyParams);
      expect(result.userValue, valueNoParams);
    });

    test('testGetWithQueryParamsDiffOrder', () async {
      final firstParams = QueryParams({'a': 0, 'b': 1});
      final secondParams = QueryParams({'b': 1, 'a': 0});
      final dbData = DatabaseData.fromUserValue(
        key: key,
        value: value,
        queryParams: firstParams,
        dateTime: now,
      );

      await dataStore.insert(dbData);

      var result = await dataStore.get(key, firstParams);
      expect(result.userValue, value);

      result = await dataStore.get(key, secondParams);
      expect(result.userValue, value);
    });
  });

  test('testUpdate', () async {
    await dataStore.insert(dbData);
    var result = await dataStore.get(key, params);
    expect(result.userValue, value);
    expect(result.useCount, 0);

    final newDbData = dbData.copyWith(id: result.id, useCount: 1);
    await dataStore.update(newDbData);
    result = await dataStore.get(key, params);
    expect(result.userValue, value);
    expect(result.useCount, 1);
  });

  test('testUpsert', () async {
    await dataStore.insert(dbData);
    var result = await dataStore.get(key, params);
    expect(result.userValue, value);
    expect(result.useCount, 0);

    final newDbData = dbData.copyWith(id: result.id, useCount: 1);
    await dataStore.upsert(newDbData);
    result = await dataStore.get(key, params);
    expect(result.userValue, value);
    expect(result.useCount, 1);
  });

  test('testRemove', () async {
    await dataStore.insert(dbData);

    var result = await dataStore.get(key, params);
    expect(result.userValue, value);

    await dataStore.remove(key, params);
    result = await dataStore.get(key, params);
    expect(result, null);
  });

  test('testRemoveByKey', () async {
    await dataStore.insert(dbData);
    await dataStore.insert(dbDataNoParams);

    await dataStore.removeByKey(key);
    var result = await dataStore.get(key, params);
    expect(result, null);
    result = await dataStore.get(key, emptyParams);
    expect(result, null);
  });

  test('testRemoveStale', () async {
    final stalePeriod = Duration(seconds: 1);
    final staleDateTime = DateTime.now().add(stalePeriod);

    await dataStore.insert(dbData);
    await Future.delayed(stalePeriod);

    await dataStore.removeStale(staleDateTime);
    final result = await dataStore.get(key, params);
    expect(result, null);
  });

  test('testClose', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: DataStoreSqflite.onCreate,
      ),
    );
    final dataStore = DataStoreSqflite.fromDb('close_test', db);

    await dataStore.close();
    final dataStoreDb = await dataStore.db();
    expect(dataStoreDb.isOpen, false);
  });
}
