import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  group('RxWidget', () {
    late Rx<int> notifier;
    setUp(() {
      notifier = 1.rx;
    });

    testWidgets('Reactive changes', (tester) async {
      int calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: RxWidget(
            notifier: notifier,
            builder: (ctx, value) {
              calls++;
              return CupertinoButton(
                key: const Key('button'),
                onPressed: () => notifier.value = 2,
                child: Text('$value'),
              );
            },
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(calls, 1);
      await tester.tap(find.byKey(const Key('button')));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsNothing);
      expect(calls, 2);
    });
    testWidgets('Lyfecicle listeners', (tester) async {
      expect(notifier.hasListeners, false);

      await tester.pumpWidget(
        MaterialApp(
          home: RxWidget(
            notifier: notifier,
            builder: (ctx, value) {
              return CupertinoButton(
                key: const Key('button'),
                onPressed: () => notifier.value++,
                child: Text('$value'),
              );
            },
          ),
        ),
      );
      expect(notifier.hasListeners, true);
      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('button')));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsNothing);
      await tester.pumpWidget(Container());
      expect(notifier.hasListeners, false);
    });
  });
}
