import 'package:data_cache_manager/data_cache_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_db_cache/firebase_db_cache.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseDbCache _firebaseDbCache = FirebaseDbCache();
  final _rootRef = FirebaseDatabase.instance.reference();
  final _key = 'key';
  final _value = 'value';
  CachedData? _cachedData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Data Cache Manager'),
        ),
        body: Center(
          child: Builder(
            builder: (context) {
              if (_cachedData != null) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cached data: ${_cachedData!.value}\n'),
                        Text('Cache location: ${_cachedData!.location}\n'),
                        Text('Updated at: ${_cachedData!.updatedAt}\n'),
                        Text('Last used at: ${_cachedData!.lastUsedAt}\n'),
                        Text('Use count: ${_cachedData!.useCount}\n'),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() => _cachedData = null);
                        final query = _rootRef.child(_key);
                        final data = await _firebaseDbCache.get(query);
                        setState(() => _cachedData = data);
                      },
                      child: Text('Refresh'),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() => _cachedData = null);
                        final now = DateTime.now();
                        final query = _rootRef.child(_key);
                        final data =
                            await _firebaseDbCache.get(query, updatedAt: now);
                        setState(() => _cachedData = data);
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

  Future<void> _fetchData() async {
    await _rootRef.child(_key).set(_value);
    final query = _rootRef.child(_key);
    final data = await _firebaseDbCache.get(query);
    setState(() => _cachedData = data);
  }
}
