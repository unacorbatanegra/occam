part of occam;

extension RxExtension<T> on T {
  Rx<T> get rx => Rx<T>(this);
}

extension RxListExtension<T> on List<T> {
  RxList<T> get rx => RxList(this);
}
