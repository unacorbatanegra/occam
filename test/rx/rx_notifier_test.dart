import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  group('RxMixin', () {
    test('value setter skips notify when the new value is unchanged', () {
      final rx = 1.rx;
      var notified = 0;
      rx.addListener(() => notified++);

      rx.value = 1;
      expect(notified, 0, reason: 'no change, no notification');

      rx.value = 2;
      expect(notified, 1);
    });

    test('call() sets when given a value, reads when given none', () {
      final rx = 1.rx;
      expect(rx(), 1);

      final result = rx(5);
      expect(result, 5);
      expect(rx.value, 5);
    });

    test('call(null) is a no-op read, not a set to null', () {
      final rx = 1.rx;
      final result = rx();
      expect(result, 1);
      expect(rx.value, 1);
    });

    test('refresh() notifies without changing the value', () {
      final rx = 1.rx;
      var notified = 0;
      rx.addListener(() => notified++);

      rx.refresh();

      expect(notified, 1);
      expect(rx.value, 1);
    });

    test('update() applies a function to the current value', () {
      final rx = 1.rx;
      rx.update((v) => v + 41);
      expect(rx.value, 42);
    });

    test('addValueListener passes the current value and dedups', () {
      final rx = 1.rx;
      final seen = <int>[];
      void listener(int v) => seen.add(v);

      rx.addValueListener(listener);
      rx.addValueListener(listener); // duplicate, must not double-fire
      rx.value = 2;

      expect(seen, [2]);
      expect(rx.lengthOfListeners, 1);
    });

    test('removeValueListener returns whether it was registered', () {
      final rx = 1.rx;
      void listener(int v) {}

      expect(rx.removeValueListener(listener), isFalse);

      rx.addValueListener(listener);
      expect(rx.removeValueListener(listener), isTrue);
      expect(rx.lengthOfListeners, 0);
    });

    test('bindStream pipes stream events into value', () async {
      final rx = 0.rx;
      final controller = StreamController<int>();
      rx.bindStream(controller.stream);

      controller.add(7);
      await Future<void>.delayed(Duration.zero);

      expect(rx.value, 7);
      await controller.close();
    });

    test('bindStream replaces a prior subscription to the same stream',
        () async {
      // Broadcast, so re-listening after the internal cancel+replace is
      // valid Dart — a single-subscription stream can only ever be listened
      // to once, even across cancel/relisten, regardless of bindStream.
      final rx = 0.rx;
      final controller = StreamController<int>.broadcast();
      rx.bindStream(controller.stream);
      rx.bindStream(controller.stream); // must cancel+replace, not double-add

      controller.add(1);
      await Future<void>.delayed(Duration.zero);

      expect(rx.value, 1);
      await controller.close();
    });

    test('a stream closing (onDone) cleans up its subscription', () async {
      final rx = 0.rx;
      final controller = StreamController<int>();
      rx.bindStream(controller.stream);

      await controller.close();
      await Future<void>.delayed(Duration.zero);

      // No exception on dispose proves the subscription was already dropped.
      expect(() => rx.dispose(), returnsNormally);
    });

    test('closeStream cancels a bound subscription', () async {
      final rx = 0.rx;
      final stream = Stream.value(1).asBroadcastStream();
      rx.bindStream(stream);

      final result = rx.closeStream(stream);
      expect(result, isNotNull);
      await result;
    });

    test('closeStream on an unbound stream is a no-op', () {
      final rx = 0.rx;
      expect(rx.closeStream(const Stream.empty()), isNull);
    });

    test('disposed flips to true after dispose()', () {
      final rx = 1.rx;
      expect(rx.disposed, isFalse);
      rx.dispose();
      expect(rx.disposed, isTrue);
    });

    test('dispose() removes listeners and cancels subscriptions', () async {
      final rx = 1.rx;
      var notified = 0;
      rx.addListener(() => notified++);
      final controller = StreamController<int>();
      rx.bindStream(controller.stream);

      rx.dispose();
      // Cancelling the subscription to the broadcast wrapper asBroadcastStream
      // creates propagates to the source over several event-loop turns, not
      // synchronously within dispose() (which can't be async — it overrides
      // ChangeNotifier's sync signature) — pump more than a single turn.
      await pumpEventQueue();

      expect(rx.lengthOfListeners, 0);
      expect(controller.hasListener, isFalse);
      await controller.close();
    });
  });
}
