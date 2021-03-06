part of occam;

abstract class RxInterface<T> extends ValueNotifier<T>
    with RxMixin<T>, RxNotifierMixin<T> {
  RxInterface(T value) : super(value);
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
}

class Rx<T> extends RxInterface<T> with RxMixin<T>, RxNotifierMixin<T> {
  Rx(T value) : super(value);
}

mixin RxNotifierMixin<T> on ValueNotifier<T> {
  final Map<Stream, StreamSubscription> _subscriptions = {};

  final _listeners = <VoidCallback>[];

  // RxNotifier(T value) : super(value);

  final Map<ValueChanged<T>, VoidCallback> _valueListeners = {};

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    super.removeListener(listener);
  }

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

  FutureOr closeStream(Stream<T> stream) {
    if (_subscriptions.containsKey(stream)) {
      return _subscriptions.remove(stream)!.cancel();
    }
  }

  void bindStream(Stream<T> stream) {
    late StreamSubscription subscription;
    subscription = stream.asBroadcastStream().listen(
      (event) {
        value = event;
      },
      onDone: () {
        subscription.cancel();
        _subscriptions.remove(subscription);
      },
    );
    _subscriptions[stream] = subscription;
  }

  @override
  T get value => super.value;

  /// To prevent potential thrown exceptions.
  bool _disposed = false;

  bool get disposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    for (final listener in _listeners) {
      removeListener(listener);
    }
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
