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

  final defaultKey = 'key';
  final defaultData = 0;
  final defaultManager = DataCacheManager(dataStore: dataStore);
  final managerNoMemCache = DataCacheManager(
    config: Config(useMemCache: false),
    dataStore: dataStore,
  );

  setUp(() async {
    await defaultManager.clear();
    await managerNoMemCache.clear();
  });

  group('testAdd', () {
    Future<void> testAdd(data) async {
      final addResult = await managerNoMemCache.add(defaultKey, data);
      final updatedAt = addResult.updatedAt;
      expect(addResult.value, data);
      expect(addResult.location, CacheLoc.server);
      expect(addResult.useCount, 0);

      final getResult = await managerNoMemCache.get(defaultKey);
      expect(getResult?.value, data);
      expect(getResult?.location, CacheLoc.local);
      expect(
        getResult?.updatedAt.millisecondsSinceEpoch,
        updatedAt.millisecondsSinceEpoch,
      );
      expect(getResult?.useCount, 1);
    }

    test('testAddNull', () async => await testAdd(null));

    test('testAddInt', () async => await testAdd(0));

    test('testAddDouble', () async => await testAdd(0.0));

    test('testAddString', () async => await testAdd('Hello World!'));

    test('testAddBool', () async => await testAdd(true));

    test('testAddList', () async => await testAdd([0, 1, 2, 3, 4]));

    test('testAddMap', () async => await testAdd({'Hello': 'World!'}));

    test('testAddIterable', () {
      expect(
        defaultManager.add(defaultKey, Iterable.empty()),
        throwsA(isInstanceOf<UnsupportedDataType>()),
      );
    });

    test('testAddListIterable', () {
      expect(
        defaultManager.add(defaultKey, [Iterable.empty()]),
        throwsA(isInstanceOf<UnsupportedDataType>()),
      );
    });

    test('testAddMapIterable', () {
      expect(
        defaultManager.add(defaultKey, {defaultKey: Iterable.empty()}),
        throwsA(isInstanceOf<UnsupportedDataType>()),
      );
    });
  });

  group('testGet', () {
    test('testGetEmpty', () async {
      expect(await defaultManager.get(defaultKey), null);
    });

    test('testGetWithQueryParams', () async {
      final queryParams = {'limit': 5};
      final limitedData = 'limited';
      final unlimitedData = 'unlimited';

      await defaultManager.add(
        defaultKey,
        limitedData,
        queryParams: queryParams,
      );
      await defaultManager.add(defaultKey, unlimitedData);

      var result = await defaultManager.get(
        defaultKey,
        queryParams: queryParams,
      );
      expect(result?.value, limitedData);

      result = await defaultManager.get(defaultKey);
      expect(result?.value, unlimitedData);
    });

    test('testGetWithQueryParamsDiffOrder', () async {
      final firstParams = {'a': 0, 'b': 1};
      final secondParams = {'b': 1, 'a': 0};

      await defaultManager.add(
        defaultKey,
        defaultData,
        queryParams: firstParams,
      );

      var result = await defaultManager.get(
        defaultKey,
        queryParams: firstParams,
      );
      expect(result?.value, defaultData);

      result = await defaultManager.get(
        defaultKey,
        queryParams: secondParams,
      );
      expect(result?.value, defaultData);
    });

    test('testGetWithUpToDateCache', () async {
      final updatedAt = DateTime.now().subtract(Duration(days: 1));
      await defaultManager.add(defaultKey, defaultData);

      final result = await defaultManager.get(
        defaultKey,
        updatedAt: updatedAt,
      );
      expect(result?.value, defaultData);
    });

    test('testGetWithOutdatedCache', () async {
      final updatedAt = DateTime.now().add(Duration(days: 1));
      await defaultManager.add(defaultKey, defaultData);

      final result = await defaultManager.get(
        defaultKey,
        updatedAt: updatedAt,
      );
      expect(result, null);
    });

    test('testGetWithoutMemCache', () async {
      await managerNoMemCache.add(defaultKey, defaultData);
      var result = await managerNoMemCache.get(defaultKey);

      expect(result?.value, defaultData);
      expect(result?.location, CacheLoc.local);
    });

    test('testRemoveSameKeyData', () async {
      final queryParams = {'limit': 5};
      final updatedAt = DateTime.now().add(Duration(days: 1));
      await defaultManager.add(defaultKey, defaultData);
      await defaultManager.add(
        defaultKey,
        defaultData,
        queryParams: queryParams,
      );

      var result = await defaultManager.get(
        defaultKey,
        updatedAt: updatedAt,
        removeSameKeyData: true,
      );
      expect(result, null);
      result = await defaultManager.get(
        defaultKey,
        queryParams: queryParams,
      );
      expect(result, null);
    });

    test('testDataUseCount', () async {
      final useCount = 5;
      await defaultManager.add(defaultKey, defaultData);

      for (var count = 0; count < useCount; count++) {
        final result = await defaultManager.get(defaultKey);
        expect(result?.useCount, count + 1);
      }
    });
  });

  test('testRemove', () async {
    await defaultManager.add(defaultKey, defaultData);

    var result = await defaultManager.get(defaultKey);
    expect(result?.value, defaultData);

    await defaultManager.remove(defaultKey);
    result = await defaultManager.get(defaultKey);
    expect(result, null);
  });

  test('testRemoveByKey', () async {
    final queryParams = {'limit': 5};
    await defaultManager.add(defaultKey, defaultData);
    await defaultManager.add(
      defaultKey,
      defaultData,
      queryParams: queryParams,
    );

    await defaultManager.removeByKey(defaultKey);
    var result = await defaultManager.get(defaultKey);
    expect(result, null);
    result = await defaultManager.get(
      defaultKey,
      queryParams: queryParams,
    );
    expect(result, null);
  });

  test('testScheduleCleanup', () async {
    var manager = DataCacheManager(
      config: Config(cleanupInterval: const Duration(seconds: 5)),
      dataStore: dataStore,
    );
    expect(manager.isCleanupTaskSet, true);
  });

  test('testRemoveStale', () async {
    final stalePeriod = Duration(seconds: 1);
    var manager = DataCacheManager(
      config: Config(stalePeriod: stalePeriod),
      dataStore: dataStore,
    );
    await manager.clear();

    await manager.add(defaultKey, defaultData);
    await Future.delayed(stalePeriod);
    await manager.removeStale();
    final result = await manager.get(defaultKey);
    expect(result, null);
  });

  test('testWithNtp', () async {
    var manager = DataCacheManager(
      config: Config(useNtpDateTime: true),
      dataStore: dataStore,
    );
    await manager.clear();

    final result = await manager.add(defaultKey, defaultData);
    expect(result.value, defaultData);
  });
}
