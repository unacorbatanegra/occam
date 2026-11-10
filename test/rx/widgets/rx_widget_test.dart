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

      expect(notifier.hasListeners, true);
      expect(notifier.lengthOfListeners, 1);
      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('button')));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsNothing);
      await tester.pumpWidget(Container());
      expect(notifier.hasListeners, false);
      expect(notifier.lengthOfListeners, 0);
      notifier.dispose();
    });

    test('mutating or refreshing Rx after dispose is a safe no-op', () {
      final rxInt = 1.rx;
      final rxBool = false.rx;
      final rxList = <int>[1].rx;

      rxInt.dispose();
      rxBool.dispose();
      rxList.dispose();

      expect(rxInt.disposed, isTrue);
      expect(rxBool.disposed, isTrue);
      expect(rxList.disposed, isTrue);

      expect(() => rxInt.value = 42, returnsNormally);
      expect(rxInt.value, 1);
      expect(() => rxInt(99), returnsNormally);
      expect(() => rxInt.update((v) => v + 1), returnsNormally);
      expect(() => rxInt.refresh(), returnsNormally);

      expect(() => rxBool.toggle(), returnsNormally);
      expect(rxBool.value, isFalse);

      expect(() => rxList.add(2), returnsNormally);
    });
  });
}
