import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

part 'parent_state_demo_controller.dart';

class ParentStateDemoPage extends StateWidget<ParentStateDemoController> {
  const ParentStateDemoPage({super.key});

  static const routeName = '/parent-state';

  @override
  ParentStateDemoController createState() => ParentStateDemoController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sharing controllers with ParentState')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RxWidget<int>(
              notifier: state.taps,
              builder:
                  (context, count) => Text(
                    'Actions triggered: $count',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Buttons below are stateless widgets that access the shared controller '
              'instance through ParentStateMixin.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                ControllerActionButton(icon: Icons.play_arrow, label: 'Start'),
                ControllerActionButton(icon: Icons.pause, label: 'Pause'),
                ControllerActionButton(icon: Icons.stop, label: 'Stop'),
                ControllerActionButton(
                  icon: Icons.fast_forward,
                  label: 'Fast-forward',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Expanded(child: ActivityFeed()),
          ],
        ),
      ),
    );
  }
}

class ControllerActionButton extends ParentState<ParentStateDemoController> {
  const ControllerActionButton({
    required this.label,
    required this.icon,
    super.key,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => state.recordAction(label),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class ActivityFeed extends ParentState<ParentStateDemoController> {
  const ActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest action',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RxWidget<String>(
              notifier: state.lastAction,
              builder: (context, action) {
                if (action.isEmpty) {
                  return const Text('Try tapping any button above.');
                }
                return Text('You selected "$action".');
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Full history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RxWidget<List<String>>(
                notifier: state.history,
                builder: (context, actions) {
                  if (actions.isEmpty) {
                    return const Center(child: Text('No actions yet.'));
                  }
                  return ListView.builder(
                    itemCount: actions.length,
                    itemBuilder:
                        (context, index) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.bolt, size: 18),
                          title: Text(actions[index]),
                        ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
