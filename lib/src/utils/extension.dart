part of occam;

extension NavigationExtension on StateController {
  /// Access to `Flutter` navigator
  NavigatorState get navigator => Navigator.of(context);

  /// Access to the ```ModalRoute.of(context)!.settings.arguments]``` arguments
  Object? get navArgs => ModalRoute.of(context)!.settings.arguments;
}
