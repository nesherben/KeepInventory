import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/database/database_schema_creator.dart';

void main() {
  test('creates tables in dependency order with current columns', () async {
    final statements = <String>[];

    await DatabaseSchemaCreator.create(
      execute: (sql) async => statements.add(sql),
    );

    expect(statements, hasLength(15));
    expect(statements[0], contains('categories ('));
    expect(statements[1], contains('CREATE TABLE promotions'));
    expect(statements[2], contains('CREATE TABLE products'));
    expect(statements[2], contains('image_bytes BLOB'));
    expect(statements[3], contains('CREATE TABLE sales'));
    expect(statements[3], contains('payment_method TEXT'));
    expect(statements[4], contains('CREATE TABLE sale_items'));
    expect(statements[5], contains('CREATE TABLE packs'));
    expect(statements[5], contains('image_bytes BLOB'));
    expect(statements[6], contains('CREATE TABLE pack_items'));
    expect(statements[7], contains('CREATE TABLE sale_packs'));
    expect(statements[4], contains('sale_combo_id INTEGER'));
    expect(statements[8], contains('combos ('));
    expect(statements[9], contains('combo_slots ('));
    expect(statements[10], contains('combo_slot_products ('));
    expect(statements[11], contains('sale_combos ('));
    expect(statements[12], contains('app_meta ('));
    expect(statements[13], contains('fairs ('));
    expect(statements[2], contains('category_id INTEGER'));
    expect(statements[9], contains('category_id INTEGER'));
  });
}
