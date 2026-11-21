import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepinventory/core/shared_widgets/adaptive_card_list.dart';

void main() {
  test('columns grow with the available width', () {
    expect(AdaptiveCardList.columnsFor(360), 1);
    expect(AdaptiveCardList.columnsFor(800), 1);
    expect(AdaptiveCardList.columnsFor(900), 2);
    expect(AdaptiveCardList.columnsFor(1300), 3);
    expect(AdaptiveCardList.columnsFor(4000), 3);
  });

  testWidgets('wide: lays cards in several columns; narrow: one column', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Widget app(double width) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: 800,
            child: AdaptiveCardList(
              itemCount: 5,
              itemBuilder: (_, i) => SizedBox(height: 50, child: Text('c$i')),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(1100));
    // Dos columnas: c0 y c1 en la misma fila, c4 solo en la última
    expect(
      tester.getTopLeft(find.text('c0')).dy,
      tester.getTopLeft(find.text('c1')).dy,
    );
    expect(find.text('c4'), findsOneWidget);

    await tester.pumpWidget(app(400));
    expect(
      tester.getTopLeft(find.text('c1')).dy,
      greaterThan(tester.getTopLeft(find.text('c0')).dy),
    );
  });
}
