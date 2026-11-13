// Occam example — this file is what pub.dev shows, so it is self-contained:
// the whole package is the four pieces used by `CounterPage` below.
//
//   StateWidget      the view: widgets only, no logic
//   StateController  the controller: logic only, no widgets
//   .rx              a reactive value (a ValueNotifier you dispose yourself)
//   RxWidget         the only widget that listens — wrap just what changes
//
// Run it and use the buttons on the home screen to open each demo:
//
//   /            HomePage        Rx<int>, Rx<Model> + refresh(), ParentState
//                                (also nested), navigation
//   /counter     CounterPage     the minimal example, in this file
//   /playground  PlaygroundPage  readyState, RxBool, call/update,
//                                addValueListener, bindStream/closeStream,
//                                RxList, disposed, AutomaticKeepAlive
//   /secondPage  SecondPage      RxList<String> rendered as a list
//   /bottom      BottomPage      a StateWidget per tab with PageStorage
import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import 'src/presentation/pages/home/bottom/bottom_page.dart';
import 'src/presentation/pages/home/home_page.dart';
import 'src/presentation/pages/playground/playground_page.dart';
import 'src/presentation/pages/second/second_page.dart';

void main() {
  runApp(const MyApp());
}

/// The view. `createState` is the pairing with its controller, and the
/// controller *for this instance* arrives in `build` as a parameter.
class CounterPage extends StateWidget<CounterController> {
  const CounterPage({super.key});

  @override
  CounterController createState() => CounterController();

  @override
  Widget build(BuildContext context, CounterController state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      floatingActionButton: FloatingActionButton(
        onPressed: state.increment,
        child: const Icon(Icons.add),
      ),
      body: Center(
        // Only this subtree rebuilds when the counter changes.
        child: RxWidget<int>(
          notifier: state.counter,
          builder: (ctx, value) => Text(
            '$value',
            style: Theme.of(ctx).textTheme.displayMedium,
          ),
        ),
      ),
    );
  }
}

/// The controller: a regular `State`, so `initState`/`dispose` work as usual,
/// plus `readyState()` (runs after the first frame, when `context` is safe).
class CounterController extends StateController<CounterPage> {
  final counter = 0.rx;

  void increment() => counter.value++;

  @override
  void dispose() {
    counter.dispose(); // occam never disposes an Rx for you
    super.dispose();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Occam Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        cardTheme: const CardThemeData(
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const HomePage(),
        '/counter': (ctx) => const CounterPage(),
        '/playground': (ctx) => const PlaygroundPage(),
        '/secondPage': (ctx) => const SecondPage(),
        '/bottom': (ctx) => const BottomPage(),
      },
    );
  }
}
