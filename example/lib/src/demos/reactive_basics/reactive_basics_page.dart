import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

part 'reactive_basics_controller.dart';

class ReactiveBasicsPage extends StateWidget<ReactiveBasicsController> {
  const ReactiveBasicsPage({super.key});

  static const routeName = '/reactive-basics';

  @override
  ReactiveBasicsController createState() => ReactiveBasicsController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reactive primitives & models')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.resetCounter,
        icon: const Icon(Icons.refresh),
        label: const Text('Reset counter'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          RxWidget<String>(
            notifier: state.readyMessage,
            builder:
                (context, value) =>
                    Text(value, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Counter powered by Rx<int>',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RxWidget<int>(
                  notifier: state.counter,
                  builder:
                      (context, value) => Text(
                        'Count: $value',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: state.increment,
                      icon: const Icon(Icons.add),
                      label: const Text('Increment'),
                    ),
                    ElevatedButton.icon(
                      onPressed: state.decrement,
                      icon: const Icon(Icons.remove),
                      label: const Text('Decrement'),
                    ),
                    ElevatedButton.icon(
                      onPressed: state.addTen,
                      icon: const Icon(Icons.exposure_plus_1),
                      label: const Text('+10 via update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'RxBool toggles UI state',
            child: RxWidget<bool>(
              notifier: state.notificationsEnabled,
              builder:
                  (context, value) => SwitchListTile(
                    value: value,
                    title: Text(
                      value
                          ? 'Notifications are enabled'
                          : 'Notifications are off',
                    ),
                    subtitle: const Text(
                      'Toggle to see the controller mutating reactive booleans.',
                    ),
                    onChanged: state.toggleNotifications,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Mutable models with refresh()',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RxWidget<UserProfile>(
                  notifier: state.profile,
                  builder:
                      (context, profile) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${profile.name}'),
                          Text('Level: ${profile.level}'),
                          Text(
                            'Marketing opt-in: ${profile.marketingOptIn ? 'Yes' : 'No'}',
                          ),
                        ],
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: state.rotateName,
                      child: const Text('Assign new user'),
                    ),
                    OutlinedButton(
                      onPressed: state.promoteUser,
                      child: const Text('Mutate & refresh'),
                    ),
                    OutlinedButton(
                      onPressed: state.toggleMarketingConsent,
                      child: const Text('Toggle consent'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
