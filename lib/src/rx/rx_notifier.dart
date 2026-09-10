import 'dart:async';

import 'package:flutter/foundation.dart';

/// Base type for every reactive value in occam: a [ValueNotifier] with the
/// extra listener/stream bookkeeping from [RxMixin].
abstract class RxInterface<T> extends ValueNotifier<T> with RxMixin<T> {
  /// Creates the notifier with an initial [value].
  RxInterface(super.value);
}

/// A plain reactive value. Build one with `value.rx` or `Rx<T>(value)`.
class Rx<T> extends RxInterface<T> {
  /// Creates the notifier with an initial [value].
  Rx(super.value);
}

/// Listener/stream bookkeeping shared by every `Rx*` type.
mixin RxMixin<T> on ValueNotifier<T> {
  static const Object _noArg = Object();

  /// `rx(newValue)` sets and returns the new value; `rx()` just reads it —
  /// safe to use directly as a callback, e.g. `onTap: rx`. Distinguishes "no
  /// argument" from an explicit `null`, so a nullable `Rx<T?>` can still be
  /// set to `null` via `rx(null)`.
  T call([Object? newValue = _noArg]) {
    if (!identical(newValue, _noArg) && newValue != value) {
      value = newValue as T;
    }
    return value;
  }

  /// Forces [notifyListeners] without changing [value] — needed after
  /// mutating a field *inside* an object held by this notifier.
  void refresh() => notifyListeners();

  /// Skips notifying listeners when [newValue] equals the current value.
  @override
  set value(T newValue) {
    if (newValue != super.value) super.value = newValue;
  }

  /// Sets [value] to the result of applying [fn] to the current value.
  void update(T Function(T value) fn) {
    value = fn(super.value);
  }

  final Map<Stream<T>, StreamSubscription<T>> _subscriptions = {};

  final _listeners = <VoidCallback>[];

  final Map<ValueChanged<T>, VoidCallback> _valueListeners = {};

  @override
  void addListener(VoidCallback listener) {
    _checkDisposed();
    _listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _checkDisposed();
    super.removeListener(listener);
    _listeners.remove(listener);
  }

  /// Number of listeners currently attached, for tests.
  @visibleForTesting
  int get lengthOfListeners => _listeners.length;

  /// Subscribes [listener] to value changes, called once immediately with
  /// the current value is not implied — it only fires on the next change.
  /// Adding the same [listener] twice is a no-op.
  void addValueListener(ValueChanged<T> listener) {
    _checkDisposed();
    if (!_valueListeners.containsKey(listener)) {
      _valueListeners[listener] = () => listener(value);
      addListener(_valueListeners[listener]!);
    }
  }

  /// Unsubscribes a [listener] added with [addValueListener]. Returns whether
  /// it was actually registered.
  bool removeValueListener(ValueChanged<T> listener) {
    _checkDisposed();
    if (!_valueListeners.containsKey(listener)) return false;
    removeListener(_valueListeners.remove(listener)!);
    return true;
  }

  /// Cancels the subscription created by [bindStream] for this [stream], if
  /// any. Returns `null` when [stream] was never bound.
  Future<void>? closeStream(Stream<T> stream) {
    _checkDisposed();
    return _subscriptions.remove(stream)?.cancel();
  }

  /// Pipes every event from [stream] into [value]. Binding the same [stream]
  /// again replaces the previous subscription. The subscription is cancelled
  /// automatically when [stream] closes, and on [dispose].
  void bindStream(Stream<T> stream) {
    _checkDisposed();
    _subscriptions.remove(stream)?.cancel();

    late StreamSubscription<T> subscription;

    subscription = stream
        .asBroadcastStream(
      // Without this, cancelling our subscription below only detaches
      // our listener from the broadcast wrapper — the wrapper stays
      // subscribed to the original [stream] forever (that's the
      // documented default), leaking it until [stream] itself completes.
      onCancel: (wrapperSubscription) => wrapperSubscription.cancel(),
    )
        .listen(
      (event) => value = event,
      onDone: () {
        subscription.cancel();
        _subscriptions.remove(stream);
      },
    );

    _subscriptions[stream] = subscription;
  }

  bool _disposed = false;

  /// `true` once [dispose] has run; check before touching a notifier you
  /// don't own the lifecycle of.
  bool get disposed => _disposed;

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('$runtimeType used after dispose()');
    }
  }

  /// Idempotent: a second call is a no-op instead of throwing, so disposing
  /// a notifier you don't own the lifecycle of is always safe.
  @override
  void dispose() {
    if (_disposed) return;
    for (final listener in List<VoidCallback>.from(_listeners)) {
      removeListener(listener);
    }
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _disposed = true;
    super.dispose();
  }
}
