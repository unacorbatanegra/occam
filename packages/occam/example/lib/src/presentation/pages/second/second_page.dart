import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import 'second_controller.dart';

class SecondPage extends StateWidget<SecondController> {
  const SecondPage({Key? key}) : super(key: key);

  @override
  SecondController createState() => SecondController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.onButton,
        child: const Icon(Icons.add),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RxWidget<String>(
            notifier: state.notifier,
            builder: (ctx, value) => Text(value),
          ),
          Center(
            child: ElevatedButton(
              onPressed: state.back,
              child: const Text('Back'),
            ),
          ),
          RxWidget<int>(
            notifier: state.counter,
            builder: (ctx, v) => Text('reactive $v'),
          ),
          Expanded(
            child: RxWidget<List<String>>(
              notifier: state.list,
              builder: (ctx, value) => ListView.separated(
                itemBuilder: (ctx, idx) => ListTile(
                  title: Text(value[idx]),
                ),
                separatorBuilder: (ctx, idx) => SizedBox.shrink(),
                itemCount: state.list.length,
              ),
            ),
          )
        ],
      ),
    );
  }
}
