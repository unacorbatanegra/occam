part of '../../../occam.dart';

/// Shorthand to wrap any value as a reactive [Rx]: `1.rx`, `Model().rx`.
extension RxExtension<T> on T {
  /// Wraps this value in an [Rx].
  Rx<T> get rx => Rx<T>(this);
}

/// Shorthand to wrap a [bool] as a reactive [RxBool]: `false.rx`.
extension RxBoolExtension on bool {
  /// Wraps this value in an [RxBool].
  RxBool get rx => RxBool(this);
}

/// Shorthand to wrap a [List] as a reactive [RxList]: `<int>[].rx`.
extension RxListExtension<T> on List<T> {
  /// Wraps this list in an [RxList]. Wraps in place — see [RxList].
  RxList<T> get rx => RxList(this);
}
