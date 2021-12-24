part of occam;

class RxList<T> extends RxInterface<List<T>> with ListMixin<T> {
  RxList([List<T> value = const []]) : super(value);

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

  void asignAll(Iterable<T> iterable) {
    value.clear();
    value.addAll(iterable);
  }

  @override
  bool get hasListeners => _listeners.isNotEmpty;

  @override
  int get length => value.length;

  @override
  set length(int newLength) {
    value.length = newLength;
    refresh();
  }
}
