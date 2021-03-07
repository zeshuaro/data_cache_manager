/// Exception for unsupported cache data type.
class UnsupportedDataType implements Exception {
  final message = 'Only data types of int, double, String, '
      'List and Map are supported.';

  @override
  String toString() => message;
}
