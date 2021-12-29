part of occam;

extension RxExtension<T> on T {
  Rx<T> get rx => Rx<T>(this);
}
extension RxBoolExtension on bool {
  // RxBool get rx => RxBool(this);
}

extension RxListExtension<T> on List<T> {
  RxList<T> get rx => RxList(this);
}
