part of '../../occam.dart';

abstract class RxInterface<T> extends ValueNotifier<T> with RxMixin<T> {
  RxInterface(super.value);
}

class Rx<T> extends RxInterface<T> {
  Rx(super.value);
}

mixin RxMixin<T> on ValueNotifier<T> {
  T call([T? newValue]) {
    if (newValue != null && newValue != value) {
      value = newValue;
    }
    return value;
  }

  void refresh() => notifyListeners();

  @override
  set value(T newValue) {
    if (newValue != super.value) super.value = newValue;
  }

  void update(T Function(T value) fn) {
    value = fn(super.value);
  }

  final Map<Stream<T>, StreamSubscription<T>> _subscriptions = {};

  final _listeners = <VoidCallback>[];

  final Map<ValueChanged<T>, VoidCallback> _valueListeners = {};

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _listeners.remove(listener);
  }

  @visibleForTesting
  int get lengthOfListeners => _listeners.length;

  void addValueListener(ValueChanged<T> listener) {
    if (!_valueListeners.containsKey(listener)) {
      _valueListeners[listener] = () => listener(value);
      addListener(_valueListeners[listener]!);
    }
  }

  bool removeValueListener(ValueChanged<T> listener) {
    if (!_valueListeners.containsKey(listener)) return false;
    removeListener(_valueListeners.remove(listener)!);
    return true;
  }

  Future<void>? closeStream(Stream<T> stream) {
    return _subscriptions.remove(stream)?.cancel();
  }

  void bindStream(Stream<T> stream) {
    closeStream(stream);

    late StreamSubscription<T> subscription;

    subscription = stream.asBroadcastStream().listen(
      (event) => value = event,
      onDone: () {
        subscription.cancel();
        _subscriptions.remove(stream);
      },
    );

    _subscriptions[stream] = subscription;
  }

  /// To prevent potential thrown exceptions.
  bool _disposed = false;

  bool get disposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    for (final listener in List<VoidCallback>.from(_listeners)) {
      removeListener(listener);
    }
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
