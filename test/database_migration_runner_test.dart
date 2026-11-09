import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/database/database_migration_runner.dart';
import 'package:keepinventory/core/database/database_schema_creator.dart';

void main() {
  group('DatabaseMigrationRunner', () {
    const paymentMethodAlter =
        'ALTER TABLE sales ADD COLUMN payment_method TEXT';
    final comboStatements = [
      ...DatabaseSchemaCreator.comboTables,
      DatabaseMigrationRunner.saleComboColumnAlter,
    ];

    test(
      'runs only image blob and payment migrations for version 10',
      () async {
        final statements = <String>[];

        await DatabaseMigrationRunner.upgrade(
          oldVersion: 10,
          execute: (sql) async => statements.add(sql),
          query: (_) async => [],
        );

        expect(statements, [
          'ALTER TABLE products ADD COLUMN image_bytes BLOB',
          'ALTER TABLE packs ADD COLUMN image_bytes BLOB',
          paymentMethodAlter,
          ...comboStatements,
        ]);
      },
    );

    test('runs only the payment method migration for version 11', () async {
      final statements = <String>[];

      await DatabaseMigrationRunner.upgrade(
        oldVersion: 11,
        execute: (sql) async => statements.add(sql),
        query: (_) async => [],
      );

      expect(statements, [paymentMethodAlter, ...comboStatements]);
    });

    test('runs only the combo migration for version 12', () async {
      final statements = <String>[];

      await DatabaseMigrationRunner.upgrade(
        oldVersion: 12,
        execute: (sql) async => statements.add(sql),
        query: (_) async => [],
      );

      expect(statements, comboStatements);
    });

    test('runs nothing for version 13', () async {
      final statements = <String>[];

      await DatabaseMigrationRunner.upgrade(
        oldVersion: 13,
        execute: (sql) async => statements.add(sql),
        query: (_) async => [],
      );

      expect(statements, isEmpty);
    });

    test('ignores payment column already existing', () async {
      await DatabaseMigrationRunner.upgrade(
        oldVersion: 11,
        execute: (sql) async {
          if (sql.startsWith('ALTER')) {
            throw StateError('duplicate column name');
          }
        },
        query: (_) async => [],
      );
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
