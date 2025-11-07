import 'package:flutter/material.dart';

import 'demos/parent_state/parent_state_demo_page.dart';
import 'demos/reactive_basics/reactive_basics_page.dart';
import 'demos/rx_list/rx_list_demo_page.dart';
import 'demos/stream_binding/stream_binding_page.dart';

typedef DemoBuilder = Widget Function(RouteSettings settings);

class DemoEntry {
  const DemoEntry({
    required this.title,
    required this.description,
    required this.routeName,
    required this.builder,
    this.arguments,
    this.category,
  });

  final String title;
  final String description;
  final String routeName;
  final DemoBuilder builder;
  final Object? arguments;
  final String? category;
}

class DemoRegistry {
  static final List<DemoEntry> demos = [
    DemoEntry(
      title: 'Reactive basics',
      description:
          'Create reactive primitives, mutate models, and trigger updates with refresh().',
      routeName: ReactiveBasicsPage.routeName,
      builder: (_) => const ReactiveBasicsPage(),
      arguments:
          'readyState runs after the first frame so routes and context are available.',
      category: 'Fundamentals',
    ),
    DemoEntry(
      title: 'ParentState sharing',
      description:
          'Stateless children reuse the controller from a parent StateWidget.',
      routeName: ParentStateDemoPage.routeName,
      builder: (_) => const ParentStateDemoPage(),
      category: 'Composition',
    ),
    DemoEntry(
      title: 'RxList operations',
      description:
          'Observe list mutations such as add, remove, reorder, and assignAll.',
      routeName: RxListDemoPage.routeName,
      builder: (_) => const RxListDemoPage(),
      category: 'Collections',
    ),
    DemoEntry(
      title: 'Stream binding',
      description:
          'Bind streams directly to reactive values and dispose subscriptions safely.',
      routeName: StreamBindingPage.routeName,
      builder: (_) => const StreamBindingPage(),
      category: 'Reactivity',
    ),
  ];

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    DemoEntry? match;
    for (final demo in demos) {
      if (demo.routeName == settings.name) {
        match = demo;
        break;
      }
    }
    if (match == null) {
      return null;
    }
    final arguments = settings.arguments ?? match.arguments;
    final routeSettings = RouteSettings(
      name: match.routeName,
      arguments: arguments,
    );
    return MaterialPageRoute(
      builder: (_) => match!.builder(routeSettings),
      settings: routeSettings,
    );
  }
}

