import 'dart:async';

import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

part 'stream_binding_controller.dart';

class StreamBindingPage extends StateWidget<StreamBindingController> {
  const StreamBindingPage({super.key});

  static const routeName = '/stream-binding';

  @override
  StreamBindingController createState() => StreamBindingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('bindStream & closeStream')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RxWidget<int>(
              notifier: state.elapsedSeconds,
              builder:
                  (context, seconds) => Center(
                    child: Text(
                      '$seconds s',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            RxWidget<bool>(
              notifier: state.isRunning,
              builder:
                  (context, running) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: running ? null : state.startTimer,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start stream'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: running ? state.stopTimer : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop stream'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: state.bumpManually,
                        icon: const Icon(Icons.plus_one),
                        label: const Text('Manual +1'),
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 24),
            Text('Event log', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: RxWidget<List<String>>(
                notifier: state.logs,
                builder: (context, logs) {
                  if (logs.isEmpty) {
                    return const Center(
                      child: Text('Trigger the timer to see stream events.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder:
                        (context, index) => const Divider(height: 0),
                    itemBuilder:
                        (context, index) => ListTile(
                          leading: const Icon(Icons.bubble_chart),
                          title: Text(logs[index]),
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
