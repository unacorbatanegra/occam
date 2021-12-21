part of occam;

extension Rx<T> on T {
  RxNotifier<T> get rx => RxNotifier<T>(this);
}
