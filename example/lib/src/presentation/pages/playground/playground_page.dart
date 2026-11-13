import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import '../../widgets/demo_section.dart';
import 'keep_alive_demo.dart';
import 'playground_controller.dart';

/// Every `Rx` / lifecycle feature that the Home page doesn't show, one
/// [DemoSection] each. Open the matching `PlaygroundController` method next to
/// each demo to see the exact call.
class PlaygroundPage extends StateWidget<PlaygroundController> {
  const PlaygroundPage({super.key});

  @override
  PlaygroundController createState() => PlaygroundController();

  @override
  Widget build(BuildContext context, PlaygroundController state) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Rx playground')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DemoSection(
            title: 'readyState() — context is safe after the first frame',
            children: [
              RxWidget<String>(
                notifier: state.status,
                builder: (ctx, v) => Text(v),
              ),
            ],
          ),
          DemoSection(
            title: 'RxBool — toggle() and operators',
            children: [
              RxWidget<bool>(
                notifier: state.flag,
                builder: (ctx, v) => Text(
                  'flag: $v   |   flag & true = ${state.flag & true}   '
                  '|   flag ^ true = ${state.flag ^ true}',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: state.toggleFlag,
                child: const Text('Toggle'),
              ),
            ],
          ),
          DemoSection(
            title: 'call(), update() and addValueListener()',
            children: [
              RxWidget<int>(
                notifier: state.count,
                builder: (ctx, v) =>
                    Text('count: $v', style: text.headlineSmall),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: state.increment,
                    child: const Text('count(count() + 1)'),
                  ),
                  OutlinedButton(
                    onPressed: state.setCountTo5,
                    child: const Text('count(5)'),
                  ),
                  OutlinedButton(
                    onPressed: state.addTen,
                    child: const Text('update(+10)'),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text('Typed listener, no widget — fires on every change:'),
              RxWidget<List<String>>(
                notifier: state.log,
                builder: (ctx, v) =>
                    Text(v.isEmpty ? '(no events yet)' : v.join('\n')),
              ),
            ],
          ),
          DemoSection(
            title: 'bindStream() / closeStream()',
            children: [
              RxWidget<int>(
                notifier: state.ticks,
                builder: (ctx, v) => Text('ticks: $v'),
              ),
              const SizedBox(height: 8),
              RxWidget<bool>(
                notifier: state.ticking,
                builder: (ctx, on) => OutlinedButton(
                  onPressed: state.toggleStream,
                  child: Text(on ? 'closeStream' : 'bindStream'),
                ),
              ),
            ],
          ),
          DemoSection(
            title: 'RxList — notifies on any mutation',
            children: [
              RxWidget<List<int>>(
                notifier: state.items,
                builder: (ctx, v) => Text('items: $v'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: state.listAddAll,
                    child: const Text('addAll'),
                  ),
                  OutlinedButton(
                    onPressed: state.listAssignAll,
                    child: const Text('assignAll'),
                  ),
                  OutlinedButton(
                    onPressed: state.listRemoveEven,
                    child: const Text('removeWhere(even)'),
                  ),
                  OutlinedButton(
                    onPressed: state.listSetFirst,
                    child: const Text('items[0] = 99'),
                  ),
                  OutlinedButton(
                    onPressed: state.listTruncate,
                    child: const Text('length = 2'),
                  ),
                ],
              ),
            ],
          ),
          DemoSection(
            title: 'disposed — never touch an Rx you already disposed',
            children: [
              RxWidget<String>(
                notifier: state.scratchStatus,
                builder: (ctx, v) => Text('scratch: $v'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: state.bumpScratch,
                    child: const Text('Bump scratch'),
                  ),
                  OutlinedButton(
                    onPressed: state.disposeScratch,
                    child: const Text('Dispose scratch'),
                  ),
                ],
              ),
            ],
          ),
          DemoSection(
            title: 'AutomaticKeepAliveClientMixin on a StateController',
            children: [
              const Text(
                'Swipe between the pages: the left controller survives '
                'being scrolled away, the right one is recreated.',
              ),
              SizedBox(
                height: 170,
                child: PageView(
                  children: const [
                    KeepAliveCounter(label: 'kept', keepAlive: true),
                    KeepAliveCounter(label: 'not kept', keepAlive: false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
