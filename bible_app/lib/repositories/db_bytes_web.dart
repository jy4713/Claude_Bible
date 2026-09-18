import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> writeDbBytes(String path, Uint8List bytes) async {
  await databaseFactoryFfiWebBasicWebWorker.writeDatabaseBytes(path, bytes);
}
