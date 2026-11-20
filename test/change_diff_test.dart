import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/history/domain/change_diff.dart';
import 'package:keepinventory/features/history/domain/change_entry.dart';

void main() {
  group('ChangeTracking.diff', () {
    test('an edit keeps only the fields that changed', () {
      final diff = ChangeTracking.diff(
        ChangeEntity.product,
        before: {'name': 'Camiseta', 'price': 10.0, 'cost': 4.0},
        after: {'name': 'Camiseta', 'price': 12.0, 'cost': 4.0},
      );

      expect(diff, isNotNull);
      expect(diff!.changedFields, ['price']);
      expect(diff.before, {'price': 10.0});
      expect(diff.after, {'price': 12.0});
    });

    test('stock-only edits produce no entry', () {
      // `units` no es un campo de configuración
      final diff = ChangeTracking.diff(
        ChangeEntity.product,
        before: {'name': 'Camiseta', 'price': 10.0, 'units': 5},
        after: {'name': 'Camiseta', 'price': 10.0, 'units': 9},
      );

      expect(diff, isNull);
    });

    test('no change at all produces no entry', () {
      final diff = ChangeTracking.diff(
        ChangeEntity.category,
        before: {'name': 'Ropa'},
        after: {'name': 'Ropa'},
      );

      expect(diff, isNull);
    });

    test('a creation only has the after values, without nulls', () {
      final diff = ChangeTracking.diff(
        ChangeEntity.product,
        after: {
          'name': 'Taza',
          'price': 5.99,
          'cost': 1.5,
          'category_id': null,
          'promotion_id': null,
        },
      );

      expect(diff!.before, isEmpty);
      expect(diff.after, {'name': 'Taza', 'price': 5.99, 'cost': 1.5});
      expect(diff.changedFields, ['name', 'price', 'cost']);
    });

    test('a deletion only has the before values', () {
      final diff = ChangeTracking.diff(
        ChangeEntity.promotion,
        before: {
          'name': '3 por 12',
          'type': 'bundle_fixed_price',
          'threshold': 3,
          'discount_value': 12.0,
        },
      );

      expect(diff!.after, isEmpty);
      expect(diff.before['threshold'], 3);
      expect(diff.changedFields, hasLength(4));
    });

    test('compares lists deeply (pack components, combo slots)', () {
      final items = [
        {'product_id': 1, 'name': 'Camiseta', 'quantity': 1},
      ];
      final same = ChangeTracking.diff(
        ChangeEntity.pack,
        before: {'name': 'Pack', 'items': items},
        after: {
          'name': 'Pack',
          'items': [
            {'product_id': 1, 'name': 'Camiseta', 'quantity': 1},
          ],
        },
      );
      final changed = ChangeTracking.diff(
        ChangeEntity.pack,
        before: {'name': 'Pack', 'items': items},
        after: {
          'name': 'Pack',
          'items': [
            {'product_id': 1, 'name': 'Camiseta', 'quantity': 2},
          ],
        },
      );

      expect(same, isNull);
      expect(changed!.changedFields, ['items']);
    });

    test('ints and doubles with the same value are not a change', () {
      final diff = ChangeTracking.diff(
        ChangeEntity.product,
        before: {'price': 10},
        after: {'price': 10.0},
      );

      expect(diff, isNull);
    });

    test('image changes are detected through their marker', () {
      final diff = ChangeTracking.diff(
        ChangeEntity.product,
        before: {'name': 'A', ChangeTracking.imageField: null},
        after: {'name': 'A', ChangeTracking.imageField: 12345},
      );

      expect(diff!.changedFields, [ChangeTracking.imageField]);
    });

    test('returns null when there is nothing to compare', () {
      expect(ChangeTracking.diff(ChangeEntity.product), isNull);
    });
  });

  group('db values', () {
    test('entities and actions round-trip and unknown values are null', () {
      for (final entity in ChangeEntity.values) {
        expect(ChangeEntity.fromDb(entity.dbValue), entity);
      }
      for (final action in ChangeAction.values) {
        expect(ChangeAction.fromDb(action.dbValue), action);
      }
      expect(ChangeEntity.fromDb('otro'), isNull);
      expect(ChangeAction.fromDb(null), isNull);
    });
  });
}
