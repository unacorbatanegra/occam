import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  testWidgets(
    "State",
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MyPage()));
      expect(find.byKey(const Key("rx")), findsOneWidget);
      final button = find.byType(TextButton);
      expect(find.text("1"), findsOneWidget);
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pump();
      expect(find.text("2"), findsOneWidget);
    },
  );
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
  const MyPage({Key? key}) : super(key: key);

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
