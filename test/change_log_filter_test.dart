import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/features/history/data/change_entry_model.dart';
import 'package:keepinventory/features/history/domain/change_day_group.dart';
import 'package:keepinventory/features/history/domain/change_entry.dart';
import 'package:keepinventory/features/history/domain/change_log_filter.dart';

ChangeEntry _entry(
  int id,
  DateTime at, {
  ChangeEntity entity = ChangeEntity.product,
  ChangeAction action = ChangeAction.update,
  String name = 'Camiseta',
  Map<String, Object?> before = const {},
  Map<String, Object?> after = const {},
  String? groupId,
}) => ChangeEntry(
  id: id,
  createdAt: at,
  entity: entity,
  entityId: id,
  entityName: name,
  action: action,
  changedFields: [...after.keys],
  before: before,
  after: after,
  groupId: groupId,
);

void main() {
  final now = DateTime(2026, 11, 20, 12);
  final entries = [
    _entry(
      4,
      now,
      name: 'Taza',
      action: ChangeAction.delete,
      before: {'name': 'Taza'},
    ),
    _entry(
      3,
      now.subtract(const Duration(hours: 2)),
      entity: ChangeEntity.pack,
      name: 'Pack Feria',
      action: ChangeAction.create,
      after: {
        'items': [
          {'name': 'Camiseta', 'quantity': 1},
        ],
      },
    ),
    _entry(
      2,
      now.subtract(const Duration(days: 1)),
      before: {'price': 10.0},
      after: {'price': 12.0},
    ),
    _entry(
      1,
      now.subtract(const Duration(days: 40)),
      entity: ChangeEntity.category,
      name: 'Ropa',
      action: ChangeAction.create,
      after: {'name': 'Ropa'},
    ),
  ];

  group('ChangeLogFilter', () {
    test('no filter keeps everything in order', () {
      const filter = ChangeLogFilter();

      expect(filter.isActive, isFalse);
      expect(filter.apply(entries).map((e) => e.id), [4, 3, 2, 1]);
    });

    test('filters by element type', () {
      final result = const ChangeLogFilter(entity: ChangeEntity.product)
          .apply(entries);

      expect(result.map((e) => e.id), [4, 2]);
    });

    test('filters by action', () {
      final result = const ChangeLogFilter(action: ChangeAction.create)
          .apply(entries);

      expect(result.map((e) => e.id), [3, 1]);
    });

    test('filters from a date on', () {
      final result = ChangeLogFilter(since: DateTime(2026, 11, 20))
          .apply(entries);

      expect(result.map((e) => e.id), [4, 3]);
    });

    test('searches names and stored values, ignoring case', () {
      expect(
        const ChangeLogFilter(query: 'pack').apply(entries).map((e) => e.id),
        [3],
      );
      // También dentro de los valores (componentes del pack)
      expect(
        const ChangeLogFilter(query: 'CAMISETA')
            .apply(entries)
            .map((e) => e.id),
        [3, 2],
      );
      expect(const ChangeLogFilter(query: 'zzz').apply(entries), isEmpty);
    });

    test('filters combine', () {
      final result = ChangeLogFilter(
        entity: ChangeEntity.product,
        action: ChangeAction.update,
        since: DateTime(2026, 11, 1),
        query: 'camis',
      ).apply(entries);

      expect(result.map((e) => e.id), [2]);
    });

    test('copyWith can clear a filter', () {
      final filter = const ChangeLogFilter(
        entity: ChangeEntity.pack,
        action: ChangeAction.delete,
      );

      final cleared = filter.copyWith(clearEntity: true, clearAction: true);

      expect(cleared.entity, isNull);
      expect(cleared.action, isNull);
      expect(cleared.isActive, isFalse);
    });

    test('a blank query is not an active filter', () {
      expect(const ChangeLogFilter(query: '   ').isActive, isFalse);
    });
  });

  group('groupChangesByDay', () {
    test('groups by day keeping newest first', () {
      final groups = groupChangesByDay(entries);

      expect(groups.map((g) => g.day), [
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 19),
        DateTime(2026, 10, 11),
      ]);
      expect(groups.first.entries.map((e) => e.id), [4, 3]);
    });

    test('an empty list gives no groups', () {
      expect(groupChangesByDay(const []), isEmpty);
    });
  });

  group('operationOf', () {
    test('returns the entries that share a group id', () {
      final all = [
        _entry(3, now, groupId: 'g1'),
        _entry(2, now, groupId: 'g1'),
        _entry(1, now),
      ];

      expect(operationOf(all[0], all).map((e) => e.id), [3, 2]);
      expect(operationOf(all[2], all).map((e) => e.id), [1]);
    });
  });

  group('ChangeEntryModel', () {
    test('reads a stored row', () {
      final entry = ChangeEntryModel.fromMap({
        'id': 7,
        'created_at': '2026-11-20T10:30:00.000',
        'entity': 'product',
        'entity_id': 3,
        'entity_name': 'Camiseta',
        'action': 'update',
        'changed_fields': '["price"]',
        'before_json': '{"price":10.0}',
        'after_json': '{"price":12.0}',
        'undone': 1,
        'group_id': 'g',
      });

      expect(entry, isNotNull);
      expect(entry!.entity, ChangeEntity.product);
      expect(entry.action, ChangeAction.update);
      expect(entry.changedFields, ['price']);
      expect(entry.before['price'], 10.0);
      expect(entry.after['price'], 12.0);
      expect(entry.undone, isTrue);
      expect(entry.groupId, 'g');
      expect(entry.createdAt, DateTime(2026, 11, 20, 10, 30));
    });

    test('a corrupted row is skipped instead of breaking the screen', () {
      expect(
        ChangeEntryModel.fromMap({
          'id': 1,
          'created_at': 'no-es-una-fecha',
          'entity': 'product',
          'entity_id': 1,
          'entity_name': 'X',
          'action': 'update',
          'changed_fields': '[]',
          'before_json': '{}',
          'after_json': '{}',
        }),
        isNull,
      );
      expect(
        ChangeEntryModel.fromMap({
          'id': 2,
          'created_at': '2026-11-20T10:30:00.000',
          'entity': 'desconocido',
          'entity_id': 1,
          'entity_name': 'X',
          'action': 'update',
          'changed_fields': '[]',
          'before_json': '{}',
          'after_json': '{}',
        }),
        isNull,
      );
    });
  });
}
