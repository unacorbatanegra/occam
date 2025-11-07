// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

class _TestController extends StateController {
  final list = <int>[].rx;
  Timer? timer;

  @override
  void readyState() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      list.add(list.length);
    });

    super.readyState();
  }

  @override
  void dispose() {
    timer?.cancel();
    list.dispose();
    super.dispose();
  }
}

class _TestPage extends StateWidget<_TestController> {
  const _TestPage();

  @override
  _TestController createState() => _TestController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RxWidget<List<int>>(
        notifier: state.list,
        builder: (ctx, list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (ctx, index) => Text(list[index].toString()),
        ),
      ),
    );
  }
}

void main() {
  group('Test rx disposable attatched to a StateController', () {
    testWidgets('Test async disposable', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _TestPage()));

      expect(find.byType(RxWidget<List<int>>), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      // expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('1'), findsOneWidget);
      await tester.pumpWidget(Container());
      expect(find.byType(RxWidget<List<int>>), findsNothing);

      // FlutterError.onError = (details) => print(details);
    });
  });
}
