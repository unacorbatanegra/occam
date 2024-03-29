part of occam;

class RxBool extends _RxInterface<bool> {
  RxBool(bool value) : super(value);

  /// The logical conjunction ("and") of this and [other].
  ///
  /// Returns `true` if both this and [other] are `true`, and `false` otherwise.

  bool operator &(bool other) => other && value;

  /// The logical disjunction ("inclusive or") of this and [other].
  ///
  /// Returns `true` if either this or [other] is `true`, and `false` otherwise.

  bool operator |(bool other) => other || value;

  /// The logical exclusive disjunction ("exclusive or") of this and [other].
  ///
  /// Returns whether this and [other] are neither both `true` nor both `false`.

  bool operator ^(bool other) => !other == value;

  /// Returns either `"true"` for `true` and `"false"` for `false`.
  @override
  String toString() {
    return '$value';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is bool) return other == value;
    if (other is RxBool) return other.value == value;
    return false;
  }

  void toggle() {
    value = !value;
    refresh();
  }

  @override
  int get hashCode => value.hashCode;
}
