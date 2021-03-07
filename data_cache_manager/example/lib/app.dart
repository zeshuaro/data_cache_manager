import 'package:data_cache_manager/data_cache_manager.dart';
import 'package:flutter/material.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _manager = DefaultDataCacheManager.instance;
  final String _key = 'key';
  CachedData _cachedData;

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
                        Text('Cached data: ${_cachedData.value}\n'),
                        Text('Cache location: ${_cachedData.location}\n'),
                        Text('Updated at: ${_cachedData.updatedAt}\n'),
                        Text('Last used at: ${_cachedData.lastUsedAt}\n'),
                        Text('Use count: ${_cachedData.useCount}\n'),
                      ],
                    ),
                    RaisedButton(
                      onPressed: () async {
                        setState(() => _cachedData = null);
                        final data = await _manager.get(_key);
                        setState(() => _cachedData = data);
                      },
                      child: Text('Refresh'),
                    ),
                    SizedBox(height: 16),
                    RaisedButton(
                      onPressed: () async {
                        setState(() => _cachedData = null);
                        final now = DateTime.now();
                        final data = await _manager.get(_key, updatedAt: now);
                        setState(() => _cachedData = data);
                        await _fetchData();
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

  // Mock data fetch from some API
  Future<void> _fetchData() async {
    await _manager.clear();
    await Future.delayed(const Duration(seconds: 2));
    final data = await _manager.add(_key, 'data');
    setState(() => _cachedData = data);
  }
}
