// ignore_for_file: public_member_api_docs, sort_constructors_first
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
}

// @GenerateNiceMocks([MockSpec<MyPageController>()])
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
