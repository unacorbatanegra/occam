part of '../../../occam.dart';

abstract class RxInterface<T> extends ValueNotifier<T> with RxMixin<T> {
  RxInterface(super.value);
}

class Rx<T> extends RxInterface<T> {
  Rx(super.value);
}
