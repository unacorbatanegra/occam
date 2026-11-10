// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

// class MockMyPageController extends Mock implements MyPageController {}

void main() {
  testWidgets(
    "Navigation",
    (tester) async {
      // final controller = MockMyPageController();
      await tester.pumpWidget(
        const MaterialApp(
          home: MyPage(),
        ),
      );

      // controller.onPressed();
      // verify(controller.onPressed());
      expect(find.byKey(const Key("rx")), findsOneWidget);
      final button = find.byType(TextButton);
      expect(find.text("1"), findsOneWidget);
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pump();
      expect(find.text("2"), findsOneWidget);
      // verify(controller.onPressed()).called(1);
    },
  );

  testWidgets(
    'Async Rx mutation after StateController is disposed does not throw',
    (tester) async {
      final completer = Completer<int>();
      await tester.pumpWidget(
        MaterialApp(
          home: AsyncPage(completer: completer),
        ),
      );

      final controller = tester.state<AsyncPageController>(
        find.byType(AsyncPage),
      );
      expect(controller.context, isA<BuildContext>());

      final future = controller.loadAsync();
      expect(controller.isLoading.value, isTrue);

      // Unmount the page before the async operation completes.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      expect(controller.mounted, isFalse);
      expect(controller.isLoading.disposed, isTrue);
      expect(controller.counter.disposed, isTrue);

      // Completing the future mutates disposed Rx variables; should be a no-op.
      completer.complete(10);
      await expectLater(future, completes);
      expect(tester.takeException(), isNull);
    },
  );
}

class AsyncPageController extends StateController<AsyncPage> {
  final isLoading = false.rx;
  final counter = 0.rx;

  Future<void> loadAsync() async {
    isLoading.value = true;
    final result = await widget.completer.future;
    counter.value = result;
    isLoading.value = false;
  }

  @override
  void dispose() {
    isLoading.dispose();
    counter.dispose();
    super.dispose();
  }
}

class AsyncPage extends StateWidget<AsyncPageController> {
  const AsyncPage({
    required this.completer,
    super.key,
  });

  final Completer<int> completer;

  @override
  AsyncPageController createState() => AsyncPageController();

  @override
  Widget build(BuildContext context) {
    return RxWidget<int>(
      notifier: state.counter,
      builder: (ctx, value) => Text('$value'),
    );
  }
}

class MyPageController extends StateController {
  final counter = 1.rx;

  void onPressed() {
    counter.value += 1;
  }

  @override
  void dispose() {
    counter.dispose();
    super.dispose();
  }
}

class MyPage extends StateWidget<MyPageController> {
  const MyPage({
    super.key,
  });

  @override
  MyPageController createState() => MyPageController();

  @override
  Widget build(BuildContext context) {
    return RxWidget(
      key: const Key('rx'),
      notifier: state.counter,
      builder: (ctx, value) => TextButton(
        onPressed: state.onPressed,
        child: Text(value.toString()),
      ),
    );
  }
}
