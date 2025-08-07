part of occam;

abstract class _RxInterface<T> extends ValueNotifier<T> with RxMixin<T> {
  _RxInterface(super.value);
}

class Rx<T> extends _RxInterface<T> {
  Rx(super.value);
}
