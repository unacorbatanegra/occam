part of occam;

/// Provides `AutomaticKeepAliveClientMixin` wiring for [StateController]s.
///
/// ```dart
/// class RootPageController extends StateController<RootPage>
///     with KeepAliveStateMixin {
///   // Optionally override `keepAlive` to toggle the behavior dynamically.
/// }
/// ```
///
/// When used, the controller becomes responsible for driving the widget build
/// through [buildWithStateWidget]. The default implementation simply delegates
/// to `widget.build(context)` while ensuring that the keep-alive handle is kept
/// up to date.
@optionalTypeArgs
mixin KeepAliveStateMixin<T extends StateWidget> on StateController<T>
    implements StateWidgetBuildMixin<T> {
  KeepAliveHandle? _keepAliveHandle;

  /// Whether the associated subtree should be kept alive.
  ///
  /// Override this getter to toggle the keep-alive behavior at runtime.
  @protected
  bool get keepAlive => true;

  @protected
  bool get wantKeepAlive => keepAlive;

  void _ensureKeepAlive() {
    assert(_keepAliveHandle == null);
    _keepAliveHandle = KeepAliveHandle();
    KeepAliveNotification(_keepAliveHandle!).dispatch(context);
  }

  void _releaseKeepAlive() {
    _keepAliveHandle?.dispose();
    _keepAliveHandle = null;
  }

  /// Ensures any `AutomaticKeepAlive` ancestors stay in sync with [keepAlive].
  @protected
  void updateKeepAlive() {
    if (wantKeepAlive) {
      if (_keepAliveHandle == null) {
        _ensureKeepAlive();
      }
    } else if (_keepAliveHandle != null) {
      _releaseKeepAlive();
    }
  }

  @override
  void initState() {
    super.initState();
    if (wantKeepAlive) {
      _ensureKeepAlive();
    }
  }

  @override
  void deactivate() {
    if (_keepAliveHandle != null) {
      _releaseKeepAlive();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (_keepAliveHandle != null) {
      _releaseKeepAlive();
    }
    super.dispose();
  }

  @override
  Widget buildWithStateWidget(BuildContext context) {
    if (wantKeepAlive && _keepAliveHandle == null) {
      _ensureKeepAlive();
    } else if (!wantKeepAlive && _keepAliveHandle != null) {
      _releaseKeepAlive();
    }
    return widget.build(context);
  }
}
