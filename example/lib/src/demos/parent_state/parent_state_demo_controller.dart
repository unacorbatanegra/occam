part of 'parent_state_demo_page.dart';

class ParentStateDemoController extends StateController<ParentStateDemoPage> {
  final taps = 0.rx;
  final lastAction = ''.rx;
  final history = <String>[].rx;

  void recordAction(String label) {
    taps.value++;
    lastAction(label);
    history.add('${DateTime.now().toIso8601String()} — $label');
  }

  @override
  void dispose() {
    taps.dispose();
    lastAction.dispose();
    history.dispose();
    super.dispose();
  }
}

