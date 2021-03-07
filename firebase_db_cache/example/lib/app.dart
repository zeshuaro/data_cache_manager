import 'package:data_cache_manager/data_cache_manager.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_db_cache/firebase_db_cache.dart';
import 'package:flutter/material.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseDbCache _firebaseDbCache = FirebaseDbCache();
  final _rootRef = FirebaseDatabase.instance.reference();
  final _key = 'key';
  final _value = 'value';
  Future<CachedData> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Data Cache Manager'),
        ),
        body: Center(
          child: FutureBuilder<CachedData>(
            future: _futureData,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                final data = snapshot.data;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cached data: ${data.value}\n'),
                        Text('Cache location: ${data.location}\n'),
                        Text('Updated at: ${data.updatedAt}\n'),
                        Text('Last used at: ${data.lastUsedAt}\n'),
                        Text('Use count: ${data.useCount}\n'),
                      ],
                    ),
                    RaisedButton(
                      onPressed: () async {
                        setState(() => _futureData = null);
                        final query = _rootRef.child(_key);
                        _futureData = _firebaseDbCache.get(query);
                      },
                      child: Text('Refresh'),
                    ),
                    SizedBox(height: 16),
                    RaisedButton(
                      onPressed: () async {
                        setState(() => _futureData = null);
                        final now = DateTime.now();
                        final query = _rootRef.child(_key);
                        _futureData =
                            _firebaseDbCache.get(query, updatedAt: now);
                      },
                      child: Text('Update'),
                    ),
                  ],
                );
              }

              return CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }

  Future<CachedData> _fetchData() async {
    await _rootRef.child(_key).set(_value);
    final query = _rootRef.child(_key);
    return _firebaseDbCache.get(query);
  }
}
