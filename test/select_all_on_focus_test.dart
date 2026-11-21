import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/shared_widgets/select_all_on_focus.dart';

void main() {
  Widget host(List<Widget> fields) => MaterialApp(
    home: Scaffold(
      body: SelectAllOnFocus(child: Column(children: fields)),
    ),
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('selects the whole value of a numeric field when focused', (
    tester,
  ) async {
    final number = TextEditingController(text: '15');
    await tester.pumpWidget(
      host([TextField(controller: number, keyboardType: TextInputType.number)]),
    );

    await tester.tap(find.byType(TextField));
    await settle(tester);

    expect(
      number.selection,
      const TextSelection(baseOffset: 0, extentOffset: 2),
    );
  });

  testWidgets('also works with decimal and signed numeric keyboards', (
    tester,
  ) async {
    final decimal = TextEditingController(text: '12,50');
    await tester.pumpWidget(
      host([
        TextField(
          controller: decimal,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
        ),
      ]),
    );

    await tester.tap(find.byType(TextField));
    await settle(tester);

    expect(decimal.selection.extentOffset, 5);
    expect(decimal.selection.baseOffset, 0);
  });

  testWidgets('moving focus between fields of the same form selects each', (
    tester,
  ) async {
    // El caso que fallaba: el foco ya estaba dentro del formulario
    final first = TextEditingController(text: '3');
    final second = TextEditingController(text: '20');
    await tester.pumpWidget(
      host([
        TextField(
          key: const Key('first'),
          controller: first,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        TextField(
          key: const Key('second'),
          controller: second,
          keyboardType: TextInputType.number,
        ),
      ]),
    );
    await settle(tester);

    await tester.tap(find.byKey(const Key('second')));
    await settle(tester);

    expect(
      second.selection,
      const TextSelection(baseOffset: 0, extentOffset: 2),
    );
  });

  testWidgets('text fields are left alone (names are usually appended)', (
    tester,
  ) async {
    final name = TextEditingController(text: 'Camiseta');
    await tester.pumpWidget(host([TextField(controller: name)]));

    await tester.tap(find.byType(TextField));
    await settle(tester);

    expect(name.selection.isCollapsed, isTrue);
  });

  testWidgets('an empty numeric field has nothing to select', (tester) async {
    final empty = TextEditingController();
    await tester.pumpWidget(
      host([TextField(controller: empty, keyboardType: TextInputType.number)]),
    );

    await tester.tap(find.byType(TextField));
    await settle(tester);

    expect(empty.selection.isCollapsed, isTrue);
  });
}
