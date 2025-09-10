import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  group('Rx<List<T>>', () {
    test('List', () {
      final list = <int>[].rx;
      var counter = 0;

      void listener() => counter++;

      list.addListener(listener);

      list.add(0);

      expect(list.isNotEmpty, true);
      expect(list.hasListeners, true);
      expect(list.length, 1);

      expect(counter, 1);

      list.removeWhere((element) => element == 1);
      expect(counter, 2);

      expect(list.length, 1);
      list.remove(0);

      expect(list.isEmpty, true);
      expect(counter, 3);
      list.removeListener(listener);
      expect(list.hasListeners, false);
    });
  });
}
