import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> initDatabaseFactory() async {
  // Use basic web worker (regular Worker, not SharedWorker) for broader support.
  databaseFactory = databaseFactoryFfiWebBasicWebWorker;
}
