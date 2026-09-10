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
    tearDown(() => notifier.dispose());

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
      expect(notifier.lengthOfListeners, 0);
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

      expect(notifier.lengthOfListeners, 1);
      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('button')));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsNothing);
      await tester.pumpWidget(Container());
      expect(notifier.lengthOfListeners, 0);
    });

    testWidgets('swapping the notifier rebinds listeners and value',
        (tester) async {
      final other = 100.rx;
      addTearDown(other.dispose);
      Widget build(Rx<int> n) => MaterialApp(
            home:
                RxWidget(notifier: n, builder: (ctx, value) => Text('$value')),
          );

      await tester.pumpWidget(build(notifier));
      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(build(other));
      expect(find.text('100'), findsOneWidget);
      expect(notifier.lengthOfListeners, 0,
          reason: 'the old notifier must be unsubscribed');
      expect(other.lengthOfListeners, 1);

      other.value = 200;
      await tester.pump();
      expect(find.text('200'), findsOneWidget);
    });
  });
}
