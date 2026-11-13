import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  group('.rx extensions', () {
    test('T.rx builds an Rx<T>', () {
      final counter = 1.rx;
      expect(counter, isA<Rx<int>>());
      expect(counter.value, 1);
    });

    test('bool.rx builds an RxBool', () {
      final flag = false.rx;
      expect(flag, isA<RxBool>());
      expect(flag.value, isFalse);
    });

    test('List<T>.rx builds an RxList<T> wrapping the same list', () {
      final source = [1, 2, 3];
      final list = source.rx;
      expect(list, isA<RxList<int>>());
      expect(list, [1, 2, 3]);

      list.add(4);
      expect(source, [1, 2, 3, 4],
          reason: 'RxList wraps the list it was given, it does not copy it');
    });
  });
}
