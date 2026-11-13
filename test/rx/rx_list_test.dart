import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  group('RxList', () {
    test('add/remove/removeWhere notify and mutate', () {
      final list = <int>[].rx;
      var counter = 0;
      void listener() => counter++;
      list.addListener(listener);

      list.add(0);
      expect(list.isNotEmpty, true);
      expect(list.lengthOfListeners, 1);
      expect(list.length, 1);
      expect(counter, 1);

      list.removeWhere((element) => element == 1);
      expect(counter, 2);
      expect(list.length, 1);

      list.remove(0);
      expect(list.isEmpty, true);
      expect(counter, 3);

      list.removeListener(listener);
      expect(list.lengthOfListeners, 0);
    });

    test('operator []= mutates in place and notifies', () {
      final list = [1, 2, 3].rx;
      var notified = 0;
      list.addListener(() => notified++);

      list[1] = 20;

      expect(list, [1, 20, 3]);
      expect(notified, 1);
    });

    test('operator [] reads by index', () {
      final list = [10, 20, 30].rx;
      expect(list[1], 20);
    });

    test('clear empties the list and notifies', () {
      final list = [1, 2, 3].rx;
      var notified = 0;
      list.addListener(() => notified++);

      list.clear();

      expect(list, isEmpty);
      expect(notified, 1);
    });

    test('addAll appends and notifies once', () {
      final list = [1].rx;
      var notified = 0;
      list.addListener(() => notified++);

      list.addAll([2, 3]);

      expect(list, [1, 2, 3]);
      expect(notified, 1);
    });

    test('length= truncates/grows and notifies', () {
      final list = [1, 2, 3].rx;
      var notified = 0;
      list.addListener(() => notified++);

      list.length = 1;

      expect(list, [1]);
      expect(notified, 1);
    });

    test('assignAll replaces the contents in place', () {
      final list = [1, 2, 3].rx;
      var notified = 0;
      list.addListener(() => notified++);

      list.assignAll([9, 8]);

      expect(list, [9, 8]);
      expect(notified, greaterThan(0));
    });

    test('wraps and mutates the list it was constructed with', () {
      final source = [1, 2];
      final list = RxList<int>(source);

      list.add(3);

      expect(source, [1, 2, 3],
          reason: 'RxList wraps the given list, it does not copy it');
    });

    test('default constructor with no argument starts empty and mutable', () {
      final list = RxList<int>();
      expect(list, isEmpty);

      list.add(1);

      expect(list, [1]);
    });
  });

  group('List<T>.assignAll extension', () {
    test('replaces the contents of a plain growable list', () {
      final list = [1, 2, 3];
      list.assignAll([9]);
      expect(list, [9]);
    });
  });
}
