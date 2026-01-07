part of occam;

mixin RxMixin<T> on ValueNotifier<T> {
  static const _noValue = Object();

  T call([Object? newValue = _noValue]) {
    if (!identical(newValue, _noValue) && newValue != value) {
      value = newValue as T;
    }
    return value;
  }

  void refresh() => notifyListeners();

  @override
  set value(T newValue) {
    if (newValue != super.value) super.value = newValue;
  }

  void update(T Function(T value) fn) => value = fn(super.value);

  Map<Stream, StreamSubscription>? _subscriptions;
  List<VoidCallback>? _listeners;
  Map<ValueChanged<T>, VoidCallback>? _valueListeners;
  bool _disposed = false;

  void _checkDisposed() {
    if (_disposed) throw StateError('Cannot use RxMixin after disposal');
  }

  @override
  void addListener(VoidCallback listener) {
    _checkDisposed();
    (_listeners ??= []).add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _checkDisposed();
    super.removeListener(listener);
    _listeners?.remove(listener);
  }

  @visibleForTesting
  int get lengthOfListeners => _listeners?.length ?? 0;

  void addValueListener(ValueChanged<T> listener) {
    _checkDisposed();
    if ((_valueListeners ??= {})[listener] != null) return;
    addListener(_valueListeners![listener] = () => listener(value));
  }

  bool removeValueListener(ValueChanged<T> listener) {
    _checkDisposed();
    if (_valueListeners == null) throw StateError('No ValueListeners were added');
    final wrapper = _valueListeners!.remove(listener);
    if (wrapper == null) return false;
    removeListener(wrapper);
    return true;
  }

  FutureOr<void> closeStream(Stream<T> stream) =>
      _subscriptions?.remove(stream)?.cancel();

  void bindStream(Stream<T> stream) {
    _checkDisposed();
    _subscriptions?.remove(stream)?.cancel();
    (_subscriptions ??= {})[stream] =
        (stream.isBroadcast ? stream : stream.asBroadcastStream()).listen(
      (event) => value = event,
      onError: (e, s) => debugPrint('RxMixin error: $e'),
      onDone: () => _subscriptions?.remove(stream),
    );
  }

  @override
  bool get hasListeners => _listeners?.isNotEmpty ?? false;

  bool get disposed => _disposed;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _listeners?.forEach(super.removeListener);
    _listeners = null;
    _valueListeners?.values.forEach(super.removeListener);
    _valueListeners = null;
    _subscriptions?.values.forEach((s) => s.cancel());
    _subscriptions = null;
    super.dispose();
  }
}
