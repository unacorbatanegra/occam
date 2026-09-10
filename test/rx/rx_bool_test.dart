import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  group('RxBool', () {
    test('operator & is logical and', () {
      expect(RxBool(true) & true, isTrue);
      expect(RxBool(true) & false, isFalse);
      expect(RxBool(false) & true, isFalse);
    });

    test('operator | is logical or', () {
      expect(RxBool(false) | false, isFalse);
      expect(RxBool(false) | true, isTrue);
      expect(RxBool(true) | false, isTrue);
    });

    test('operator ^ is logical xor', () {
      expect(RxBool(true) ^ true, isFalse);
      expect(RxBool(true) ^ false, isTrue);
      expect(RxBool(false) ^ false, isFalse);
    });

    test('toggle flips the value and notifies', () {
      final flag = RxBool(false);
      var notified = 0;
      flag.addListener(() => notified++);

      flag.toggle();

      expect(flag.value, isTrue);
      expect(notified, 1);
    });

    test('toString reflects the value', () {
      expect(RxBool(true).toString(), 'true');
      expect(RxBool(false).toString(), 'false');
    });

    test('== compares against a raw bool', () {
      // ignore: unrelated_type_equality_checks
      expect(RxBool(true) == true, isTrue);
      // ignore: unrelated_type_equality_checks
      expect(RxBool(true) == false, isFalse);
    });

    test('== compares against another RxBool by value', () {
      expect(RxBool(true) == RxBool(true), isTrue);
      expect(RxBool(true) == RxBool(false), isFalse);
    });

    test('== is false against an unrelated type', () {
      // ignore: unrelated_type_equality_checks
      expect(RxBool(true) == 'true', isFalse);
    });

    test('== is reflexive for the same instance', () {
      final flag = RxBool(true);
      // ignore: no_self_compare
      expect(flag == flag, isTrue);
    });

    test('hashCode matches the underlying value', () {
      expect(RxBool(true).hashCode, true.hashCode);
    });

    test('.rx extension builds an RxBool', () {
      final flag = true.rx;
      expect(flag, isA<RxBool>());
      expect(flag.value, isTrue);
    });
  });
}
