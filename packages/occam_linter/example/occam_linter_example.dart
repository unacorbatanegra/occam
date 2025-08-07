import 'package:occam/occam.dart';

class HomeController extends StateController {
  final counter = 0.rx; // ⚠️ Rx variable 'counter' must be disposed
  final name = "".rx; // ⚠️ Rx variable 'name' must be disposed
  final items = <String>[].rx; // ✓ OK - disposed properly

  @override
  void dispose() {
    items.dispose();
    super.dispose();
  }
}
