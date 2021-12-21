// part of occam;

// abstract class DisposerNotifier {
//   final _disposer = _DisposerNotifier();

//   void addListener(VoidCallback fn) => _disposer.addListener(fn);

//   void removeListener(VoidCallback fn) => _disposer.removeListener(fn);

//   void dispose() {
//     _disposer.dispose();
//   }
// }

// class _DisposerNotifier extends ChangeNotifier {
//   @override
//   void dispose() {
//     notifyListeners();
//     super.dispose();
//   }
// }

// mixin DisposerMixin<T extends StatefulWidget> on State<T>
//     implements DisposerNotifier {
//   @override
//   final _disposer = _DisposerNotifier();

//   @override
//   void addListener(VoidCallback fn) => _disposer.addListener(fn);

//   @override
//   void removeListener(VoidCallback fn) => _disposer.removeListener(fn);

//   @override
//   void dispose() {
//     _disposer.dispose();
//     super.dispose();
//   }
// }
