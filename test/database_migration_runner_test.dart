import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/database/database_migration_runner.dart';

void main() {
  group('DatabaseMigrationRunner', () {
    test('runs only image blob migrations for version 10', () async {
      final statements = <String>[];

      await DatabaseMigrationRunner.upgrade(
        oldVersion: 10,
        execute: (sql) async => statements.add(sql),
        query: (_) async => [],
      );

      expect(statements, [
        'ALTER TABLE products ADD COLUMN image_bytes BLOB',
        'ALTER TABLE packs ADD COLUMN image_bytes BLOB',
      ]);
    });

    test('skips the fair-name alter when the column already exists', () async {
      final statements = <String>[];
      final queries = <String>[];

      await DatabaseMigrationRunner.upgrade(
        oldVersion: 3,
        execute: (sql) async => statements.add(sql),
        query: (sql) async {
          queries.add(sql);
          return [
            <String, Object?>{'name': 'fair_name'},
          ];
        },
      );

      expect(queries, ['PRAGMA table_info(sales)']);
      expect(
        statements,
        isNot(contains('ALTER TABLE sales ADD COLUMN fair_name TEXT')),
      );
    });

    test('attempts the fair-name alter if column inspection fails', () async {
      final statements = <String>[];

      await DatabaseMigrationRunner.upgrade(
        oldVersion: 3,
        execute: (sql) async => statements.add(sql),
        query: (_) async => throw StateError('metadata unavailable'),
      );

      expect(
        statements,
        contains('ALTER TABLE sales ADD COLUMN fair_name TEXT'),
      );
    });

    test(
      'runs repair and image migrations when upgrading from version 9',
      () async {
        final statements = <String>[];

        await DatabaseMigrationRunner.upgrade(
          oldVersion: 9,
          execute: (sql) async => statements.add(sql),
          query: (_) async => [],
        );

        expect(
          statements,
          containsAll([
            'ALTER TABLE sale_items ADD COLUMN promo_type TEXT',
            'ALTER TABLE sale_items ADD COLUMN promo_threshold INTEGER',
            'ALTER TABLE sale_items ADD COLUMN promo_discount REAL',
            'ALTER TABLE products ADD COLUMN image_bytes BLOB',
            'ALTER TABLE packs ADD COLUMN image_bytes BLOB',
          ]),
        );
      },
    );
  });
}
