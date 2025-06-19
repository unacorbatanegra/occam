import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import 'home_controller.dart';
import 'nested/nested_child.dart';
import 'widgets/child_consumer.dart';

class HomePage extends StateWidget<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomeController createState() => HomeController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Occam Demo'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.onButton,
        child: const Icon(Icons.add),
      ),
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        // crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: RxWidget<int>(
              notifier: state.counter,
              builder: (ctx, v) => Text(
                '$v',
              ),
            ),
          ),
          RxWidget<Model>(
            notifier: state.model,
            builder: (ctx, v) => Text('reactive $v'),
          ),
          CupertinoButton(
            child: Text('Change reactive'),
            onPressed: state.onTap,
          ),
          RxWidget<bool>(
            notifier: state.isSwitched,
            builder: (ctx, value) => SwitchListTile(
              title: Text('RxBool Switch'),
              value: value,
              onChanged: (_) => state.toggleSwitch(),
            ),
          ),
          RxWidget<String>(
            notifier: state.combinedMessage.rx,
            builder: (ctx, msg) => msg.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(msg, style: TextStyle(color: Colors.green)),
                  )
                : SizedBox.shrink(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: state.addItem,
                child: Text('Add Item'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: state.removeItem,
                child: Text('Remove Item'),
              ),
            ],
          ),
          SizedBox(
            height: 100,
            child: RxWidget<List<String>>(
              notifier: state.items,
              builder: (ctx, items) => ListView.builder(
                itemCount: items.length,
                itemBuilder: (ctx, idx) => ListTile(
                  title: Text(items[idx]),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              state.model.value.name = 'Updated Name';
              state.model.value.age =
                  (int.parse(state.model.value.age) + 1).toString();
              state.model.refresh();
            },
            child: Text('Update Model'),
          ),
          // ValueListenableBuilder(valueListenable: valueListenable, builder: builder)
          const ChildConsumer(),
          const NestedChild(),
          Center(
            child: ElevatedButton(
              onPressed: state.toSecondPage,
              child: const Text('To Second page'),
            ),
          ),
          // Center(
          //   child: ElevatedButton(
          //     onPressed: state.toBottom,
          //     child: const Text('To Bottom'),
          //   ),
          // ),
        ],
      ),
    );
  }
}
