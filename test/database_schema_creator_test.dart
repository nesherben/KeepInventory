import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/database/database_schema_creator.dart';

void main() {
  test('creates tables in dependency order with current columns', () async {
    final statements = <String>[];

    await DatabaseSchemaCreator.create(
      execute: (sql) async => statements.add(sql),
    );

    expect(statements, hasLength(13));
    expect(statements[0], contains('CREATE TABLE promotions'));
    expect(statements[1], contains('CREATE TABLE products'));
    expect(statements[1], contains('image_bytes BLOB'));
    expect(statements[2], contains('CREATE TABLE sales'));
    expect(statements[2], contains('payment_method TEXT'));
    expect(statements[3], contains('CREATE TABLE sale_items'));
    expect(statements[4], contains('CREATE TABLE packs'));
    expect(statements[4], contains('image_bytes BLOB'));
    expect(statements[5], contains('CREATE TABLE pack_items'));
    expect(statements[6], contains('CREATE TABLE sale_packs'));
    expect(statements[3], contains('sale_combo_id INTEGER'));
    expect(statements[7], contains('combos ('));
    expect(statements[8], contains('combo_slots ('));
    expect(statements[9], contains('combo_slot_products ('));
    expect(statements[10], contains('sale_combos ('));
    expect(statements[11], contains('app_meta ('));
    expect(statements[12], contains('fairs ('));
  });
}
