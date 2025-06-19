part of occam;

mixin RxMixin<T> on ValueNotifier<T> {
  T call([T? newValue]) {
    if (newValue != null) {
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

  Map<Stream, StreamSubscription>? _subscriptions;

  List<VoidCallback>? _listeners;

  Map<ValueChanged<T>, VoidCallback>? _valueListeners;

  @override
  void addListener(VoidCallback listener) {
    if (_listeners == null) {
      _listeners = [];
    }
    _listeners!.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _listeners!.remove(listener);
  }

  @visibleForTesting
  int get lengthOfListeners => _listeners!.length;

  void addValueListener(ValueChanged<T> listener) {
    if (_valueListeners == null) {
      _valueListeners = {};
    }
    if (!_valueListeners!.containsKey(listener)) {
      _valueListeners![listener] = () => listener(value);
      addListener(_valueListeners![listener]!);
    }
  }

  bool removeValueListener(ValueChanged<T> listener) {
    if (_valueListeners == null) {
      throw 'No `ValueListeners were added';
    }
    if (!_valueListeners!.containsKey(listener)) return false;
    removeListener(_valueListeners!.remove(listener)!);
    return true;
  }

  FutureOr closeStream(Stream<T> stream) {
    if (_subscriptions!.containsKey(stream)) {
      return _subscriptions!.remove(stream)!.cancel();
    }
  }

  void bindStream(Stream<T> stream) {
    if (_subscriptions == null) {
      _subscriptions = {};
    }
    late StreamSubscription subscription;
    subscription = stream.asBroadcastStream().listen(
      (event) => value = event,
      onDone: () {
        subscription.cancel();
        _subscriptions!.remove(subscription);
      },
    );
    _subscriptions![stream] = subscription;
  }

  /// To prevent potential thrown exceptions.
  bool _disposed = false;

  @override
  bool get hasListeners => _listeners!.isNotEmpty;

  bool get disposed => _disposed;
}
