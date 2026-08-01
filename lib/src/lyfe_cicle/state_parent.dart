part of '../../occam.dart';

/// A widget that reads a [StateController] owned by an ancestor [StateWidget].
///
/// Use it for a child that needs its parent's controller instead of one of its
/// own. The controller is resolved by walking up the element tree and handed to
/// [build] as a parameter:
///
/// ```dart
/// class ChildConsumer extends ParentState<HomeController> {
///   const ChildConsumer({super.key});
///
///   @override
///   Widget build(BuildContext context, HomeController state) {
///     return TextButton(onPressed: state.onTap, child: const Text('tap'));
///   }
/// }
/// ```
///
/// The nearest matching ancestor wins, so nesting two providers of the same type
/// resolves to the inner one. Because resolution goes through the element and
/// not through the widget object, mounting the same `const ParentState()` object
/// several times gives each instance its own provider.
abstract class ParentState<T extends StateController> extends Widget {
  const ParentState({super.key});

  /// Describes this widget's UI.
  ///
  /// [state] is the controller of the nearest ancestor `StateWidget<T>`.
  Widget build(BuildContext context, T state);

  @override
  ParentStateElement<T> createElement() {
    assert(
      T != StateController,
      'Provide a concrete controller type: '
      '$runtimeType extends ParentState<MyController>',
    );
    return ParentStateElement<T>(this);
  }
}

class ParentStateElement<T extends StateController> extends ComponentElement {
  ParentStateElement(ParentState<T> super.widget);

  @override
  ParentState<T> get widget => super.widget as ParentState<T>;

  /// Resolved lazily on first build, when ancestors are reachable, and dropped
  /// on [deactivate] so a widget reinserted elsewhere resolves again.
  T? _provided;

  @override
  Widget build() => widget.build(this, _provided ??= _findProvider());

  /// The nearest ancestor controller of type [T].
  T _findProvider() {
    T? found;
    visitAncestorElements((element) {
      if (element is StateElement && element.state is T) {
        found = element.state as T;
        return false;
      }
      return true;
    });
    if (found == null) {
      throw FlutterError(
        '${widget.runtimeType} could not find an ancestor StateWidget<$T>.\n'
        'ParentState reads a controller owned by a parent, so a '
        'StateWidget<$T> must sit above it in the widget tree.',
      );
    }
    return found!;
  }

  @override
  void update(ParentState<T> newWidget) {
    super.update(newWidget);
    rebuild(force: true);
  }

  @override
  void deactivate() {
    _provided = null;
    super.deactivate();
  }
}
