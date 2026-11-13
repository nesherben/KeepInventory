import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/database/database_helper.dart';
import 'package:keepinventory/core/services/backup_validator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('backup_validator_test');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  /// Crea una BD en [name] con las tablas de la app y los datos pedidos.
  Future<File> makeDb(
    String name, {
    int products = 0,
    int sales = 0,
    int userVersion = DatabaseHelper.schemaVersion,
    String? appVersion = '1.17.3',
    bool withAppTables = true,
  }) async {
    final path = '${dir.path}/$name';
    final db = await databaseFactory.openDatabase(path);
    if (withAppTables) {
      await db.execute('CREATE TABLE products (id INTEGER PRIMARY KEY)');
      await db.execute('CREATE TABLE sales (id INTEGER PRIMARY KEY)');
      await db.execute('CREATE TABLE app_meta (key TEXT PRIMARY KEY, value TEXT)');
      for (var i = 0; i < products; i++) {
        await db.insert('products', {'id': i});
      }
      for (var i = 0; i < sales; i++) {
        await db.insert('sales', {'id': i});
      }
      if (appVersion != null) {
        await db.insert('app_meta', {
          'key': DatabaseHelper.appVersionKey,
          'value': appVersion,
        });
      }
    } else {
      await db.execute('CREATE TABLE other (id INTEGER PRIMARY KEY)');
    }
    await db.execute('PRAGMA user_version = $userVersion');
    await db.close();
    return File(path);
  }

  test('lee versión, productos y ventas de una copia válida', () async {
    final file = await makeDb('ok.db', products: 3, sales: 2);

    final info = await BackupValidator.inspect(file);

    expect(info.isValid, isTrue);
    expect(info.products, 3);
    expect(info.sales, 2);
    expect(info.appVersion, '1.17.3');
    expect(info.schemaVersion, DatabaseHelper.schemaVersion);
    expect(info.needsMigration, isFalse);
    expect(info.isEmpty, isFalse);
  });

  test('una copia sin productos ni ventas se detecta como vacía', () async {
    final info = await BackupValidator.inspect(await makeDb('empty.db'));

    expect(info.isValid, isTrue);
    expect(info.isEmpty, isTrue);
  });

  test('una copia solo con categorías u otros datos no está vacía', () async {
    final file = await makeDb('categories_only.db');
    final db = await databaseFactory.openDatabase(file.path);
    await db.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY)');
    await db.insert('categories', {'id': 1});
    await db.close();

    final info = await BackupValidator.inspect(file);

    expect(info.products, 0);
    expect(info.sales, 0);
    expect(info.otherRows, 1);
    expect(info.isEmpty, isFalse);
  });

  test('una copia de un esquema anterior pide migración', () async {
    final info = await BackupValidator.inspect(
      await makeDb('old.db', products: 1, userVersion: 12),
    );

    expect(info.isValid, isTrue);
    expect(info.needsMigration, isTrue);
  });

  test('una copia sin versión de app sigue siendo válida', () async {
    final info = await BackupValidator.inspect(
      await makeDb('noversion.db', products: 1, appVersion: null),
    );

    expect(info.isValid, isTrue);
    expect(info.appVersion, isNull);
  });

  test('rechaza una copia de un esquema más nuevo', () async {
    final info = await BackupValidator.inspect(
      await makeDb(
        'newer.db',
        products: 1,
        userVersion: DatabaseHelper.schemaVersion + 1,
      ),
    );

    expect(info.isValid, isFalse);
    expect(info.problem, BackupProblem.newer);
  });

  test('rechaza una base de datos que no es de KeepInventory', () async {
    final info = await BackupValidator.inspect(
      await makeDb('other.db', withAppTables: false),
    );

    expect(info.problem, BackupProblem.notABackup);
  });

  test('rechaza un archivo dañado', () async {
    final file = File('${dir.path}/corrupt.db')
      ..writeAsBytesSync(List.filled(4096, 7));

    final info = await BackupValidator.inspect(file);

    expect(info.problem, BackupProblem.corrupt);
  });
}
