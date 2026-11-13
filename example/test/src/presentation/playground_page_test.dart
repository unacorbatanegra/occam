import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tall enough that every section is built and nothing sits under the FAB.
void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _openPlayground(WidgetTester tester) async {
  _tallView(tester);
  await tester.pumpWidget(const MyApp());
  final button = find.text('To Rx playground');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Counter page (main.dart) increments', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(const MyApp());
    final button = find.text('To Counter (the minimal example)');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('readyState runs after the first frame with a safe context',
      (tester) async {
    await _openPlayground(tester);
    expect(find.text('readyState ran — route is /playground'), findsOneWidget);
  });

  testWidgets('RxBool: toggle() and operators', (tester) async {
    await _openPlayground(tester);
    expect(find.textContaining('flag: false'), findsOneWidget);
    await tester.tap(find.text('Toggle'));
    await tester.pump();
    expect(find.textContaining('flag: true'), findsOneWidget);
    expect(find.textContaining('flag & true = true'), findsOneWidget);
  });

  testWidgets('call(), update() and the typed value listener', (tester) async {
    await _openPlayground(tester);
    expect(find.text('(no events yet)'), findsOneWidget);

    await tester.tap(find.text('count(count() + 1)'));
    await tester.pump();
    expect(find.text('count: 1'), findsOneWidget);

    await tester.tap(find.text('count(5)'));
    await tester.pump();
    expect(find.text('count: 5'), findsOneWidget);

    await tester.tap(find.text('update(+10)'));
    await tester.pump();
    expect(find.text('count: 15'), findsOneWidget);
    // Only the last four events are kept.
    expect(
      find.text('count -> 1\ncount -> 5\ncount -> 15'),
      findsOneWidget,
    );
  });

  testWidgets('bindStream pipes a stream into the Rx, closeStream stops it',
      (tester) async {
    await _openPlayground(tester);
    expect(find.text('ticks: 0'), findsOneWidget);

    await tester.tap(find.text('bindStream'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('ticks: 3'), findsOneWidget);

    await tester.tap(find.text('closeStream'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('ticks: 3'), findsOneWidget, reason: 'stream is closed');

    // Leave the page with a stream bound: dispose must cancel it, otherwise
    // the periodic timer would still be pending.
    await tester.tap(find.text('bindStream'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('RxList notifies on addAll/assignAll/removeWhere/[]=/length',
      (tester) async {
    await _openPlayground(tester);
    expect(find.text('items: [1, 2, 3, 4, 5]'), findsOneWidget);

    await tester.tap(find.text('removeWhere(even)'));
    await tester.pump();
    expect(find.text('items: [1, 3, 5]'), findsOneWidget);

    await tester.tap(find.text('items[0] = 99'));
    await tester.pump();
    expect(find.text('items: [99, 3, 5]'), findsOneWidget);

    await tester.tap(find.text('length = 2'));
    await tester.pump();
    expect(find.text('items: [99, 3]'), findsOneWidget);

    await tester.tap(find.text('addAll'));
    await tester.pump();
    expect(find.text('items: [99, 3, 100, 200]'), findsOneWidget);

    await tester.tap(find.text('assignAll'));
    await tester.pump();
    expect(find.text('items: [10, 20, 30]'), findsOneWidget);
  });

  testWidgets('disposed: a disposed Rx is skipped, disposing twice is safe',
      (tester) async {
    await _openPlayground(tester);
    await tester.tap(find.text('Bump scratch'));
    await tester.pump();
    expect(find.text('scratch: alive: 1'), findsOneWidget);

    await tester.tap(find.text('Dispose scratch'));
    await tester.pump();
    expect(find.text('scratch: disposed = true'), findsOneWidget);

    await tester.tap(find.text('Bump scratch'));
    await tester.pump();
    expect(
      find.text('scratch: skipped: check .disposed before touching it'),
      findsOneWidget,
    );

    await tester.tap(find.text('Dispose scratch')); // second dispose: no throw
    await tester.pump();
  });

  testWidgets('AutomaticKeepAlive: kept controller survives, other resets',
      (tester) async {
    await _openPlayground(tester);
    final pages = find.byType(PageView);
    await tester.ensureVisible(pages);

    await tester.tap(find.text('+1 (kept)'));
    await tester.pump();
    expect(find.text('count 1'), findsOneWidget);

    await tester.drag(pages, const Offset(-800, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+1 (not kept)'));
    await tester.pump();
    expect(find.text('count 1'), findsOneWidget);

    await tester.drag(pages, const Offset(800, 0));
    await tester.pumpAndSettle();
    expect(find.text('count 1'), findsOneWidget, reason: 'kept state survived');

    await tester.drag(pages, const Offset(-800, 0));
    await tester.pumpAndSettle();
    expect(find.text('count 0'), findsOneWidget, reason: 'recreated from zero');
  });
}
