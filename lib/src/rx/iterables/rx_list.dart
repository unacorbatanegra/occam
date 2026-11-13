part of '../../../occam.dart';

/// A reactive [List]. Behaves like a normal `List<T>` and notifies on any
/// mutation (`add`, `[]=`, `remove`, `clear`, `removeWhere`, `addAll`,
/// `length=`, `assignAll`).
///
/// Wraps the list passed to it — it does not copy — and mutates that same
/// instance in place. With no argument, starts with a fresh, growable empty
/// list.
class RxList<T> extends RxInterface<List<T>> with ListMixin<T> {
  /// Wraps [value], defaulting to a fresh, empty growable list.
  RxList([List<T>? value]) : super(value ?? <T>[]);

  @override
  T operator [](int index) => value[index];

  @override
  void operator []=(int index, T value) {
    this.value[index] = value;
    refresh();
  }

  @override
  void add(T element) {
    value.add(element);
    refresh();
  }

  @override
  bool remove(Object? element) {
    final result = value.remove(element);
    refresh();
    return result;
  }

  @override
  void clear() {
    value.clear();
    refresh();
  }

  @override
  void removeWhere(bool Function(T element) test) {
    value.removeWhere(test);
    refresh();
  }

  @override
  void addAll(Iterable<T> iterable) {
    value.addAll(iterable);
    refresh();
  }

  /// Replaces every element with the contents of [iterable], in place.
  void assignAll(Iterable<T> iterable) {
    value.clear();
    addAll(iterable);
  }

  @override
  int get length => value.length;

  @override
  set length(int newLength) {
    value.length = newLength;
    refresh();
  }
}

/// Adds [RxList.assignAll]'s in-place-replace convenience to plain lists too.
extension Native<T> on List<T> {
  /// Replaces every element with the contents of [iterable], in place.
  void assignAll(Iterable<T> iterable) {
    clear();
    addAll(iterable);
  }
}
