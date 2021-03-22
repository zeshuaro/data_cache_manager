import 'dart:io';

import 'package:data_cache_manager/src/data_store/data_store_stub.dart';
import 'package:data_cache_manager/src/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// A Sqflite implementation of [DataStore].
class DataStoreSqflite implements DataStore {
  /// The database file name.
  final String dbName;
  Future<Database>? _db;

  DataStoreSqflite({this.dbName = 'data_store_sqflite'})
      : _db = _initDb('$dbName.db');

  @visibleForTesting
  DataStoreSqflite.fromDb(this.dbName, Database db) : _db = Future.value(db);

  static const _cacheTable = 'cache';
  static const _id = '_id';
  static const _cacheKey = 'cacheKey';
  static const _params = 'queryParams';
  static const _dataType = 'dataType';
  static const _cacheData = 'cacheData';
  static const _updatedAt = 'updatedAt';
  static const _lastUsedAt = 'lastUsedAt';
  static const _useCount = 'useCount';

  static Future<Database> _initDb(String dbName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    await Directory(dbPath).create(recursive: true);
    final db = await openDatabase(path, version: 1, onCreate: onCreate);

    return db;
  }

  @visibleForTesting
  static Future<void> onCreate(Database db, int version) async {
    await db.execute(
      'create table $_cacheTable ('
      '$_id integer primary key autoincrement, '
      '$_cacheKey text not null, '
      '$_params text, '
      '$_dataType integer not null, '
      '$_cacheData text, '
      '$_updatedAt integer not null, '
      '$_lastUsedAt integer not null, '
      '$_useCount integer not null)',
    );
  }

  @override
  Future<void> insert(DatabaseData data) async {
    final db = await _getDb();
    await db.insert(_cacheTable, data.toJson());
  }

  @override
  Future<void> clear({bool rebuildDb = false}) async {
    final db = await _getDb();
    await db.delete(_cacheTable);
    if (rebuildDb) await db.execute('vacuum');
  }

  @override
  Future<void> close() async {
    final db = await _getDb();
    if (db.isOpen) await db.close();
  }

  @override
  Future<DatabaseData?> get(String key, QueryParams queryParams) async {
    DatabaseData? dbData;
    final db = await _getDb();
    final maps = await _queryByKeyAndParams(db, key, queryParams);
    if (maps.isNotEmpty) dbData = DatabaseData.fromJson(maps.first);

    return dbData;
  }

  @override
  Future<DatabaseData?> getAndUpdate(
    String key,
    QueryParams queryParams,
    DateTime lastUsedAt,
  ) async {
    DatabaseData? dbData;
    final db = await _getDb();

    await db.transaction((txn) async {
      final maps = await _queryByKeyAndParams(txn, key, queryParams);
      if (maps.isNotEmpty) {
        dbData = DatabaseData.fromJson(maps.first);
        final newDbData = dbData!.copyWith(
          lastUsedAt: lastUsedAt,
          useCount: dbData!.useCount + 1,
        );
        await _updateData(txn, newDbData);
      }
    });

    return dbData;
  }

  @override
  Future<void> open() async {
    final db = await _getDb();
    if (!db.isOpen) _db = _initDb(dbName);
  }

  @override
  Future<void> remove(
    String key,
    QueryParams queryParams, {
    bool rebuildDb = false,
  }) async {
    final db = await _getDb();
    await db.delete(
      _cacheTable,
      where: '$_cacheKey = ? and $_params = ?',
      whereArgs: [key, queryParams.asStr],
    );
    if (rebuildDb) await db.execute('vacuum');
  }

  @override
  Future<void> removeByKey(String key, {bool rebuildDb = false}) async {
    final db = await _getDb();
    await db.delete(
      _cacheTable,
      where: '$_cacheKey = ?',
      whereArgs: [key],
    );
    if (rebuildDb) await db.execute('vacuum');
  }

  @override
  Future<List<DatabaseData>> removeOversized(int maxCacheSize) async {
    final removedData = <DatabaseData>[];
    final db = await _getDb();
    final file = File(db.path);

    while (file.lengthSync() > maxCacheSize) {
      final maps = await db.query(
        _cacheTable,
        orderBy: '$_lastUsedAt, $_useCount',
        limit: 1,
      );
      if (maps.isEmpty) break;

      final dbData = DatabaseData.fromJson(maps.first);
      removedData.add(dbData);
      await remove(
        dbData.key,
        dbData.queryParams,
        rebuildDb: true,
      );
    }

    return removedData;
  }

  @override
  Future<List<DatabaseData>> removeStale(DateTime staleDateTime) async {
    final removedData = <DatabaseData>[];
    final db = await _getDb();
    final maps = await db.query(
      _cacheTable,
      where: '$_lastUsedAt <= ?',
      whereArgs: [staleDateTime.millisecondsSinceEpoch],
    );

    for (final map in maps) {
      final dbData = DatabaseData.fromJson(map);
      removedData.add(dbData);
      await remove(dbData.key, dbData.queryParams);
    }

    return removedData;
  }

  @override
  Future<void> update(DatabaseData data) async {
    final db = await _getDb();
    await _updateData(db, data);
  }

  @override
  Future<void> upsert(DatabaseData data) async {
    final db = await _getDb();
    await db.transaction((txn) async {
      final maps = await _queryByKeyAndParams(txn, data.key, data.queryParams);
      if (maps.isEmpty) {
        await txn.insert(_cacheTable, data.toJson());
      } else {
        final id = maps.first['_id'];
        await _updateData(txn, data.copyWith(id: id));
      }
    });
  }

  @visibleForTesting
  Future<Database?> db() async => await _db;

  Future<Database> _getDb() async {
    return (await (_db)) ?? await _initDb(dbName);
  }

  Future<List<Map<String, dynamic>>> _queryByKeyAndParams(
    dynamic db,
    String key,
    QueryParams queryParams,
  ) async {
    assert(db is Database || db is Transaction);
    return await db.query(
      _cacheTable,
      where: '$_cacheKey = ? and $_params = ?',
      whereArgs: [key, queryParams.asStr],
    );
  }

  Future<void> _updateData(dynamic db, DatabaseData data) async {
    assert(db is Database || db is Transaction);
    await db.update(
      _cacheTable,
      data.toJson(),
      where: '$_id = ?',
      whereArgs: [data.id],
    );
  }
}
