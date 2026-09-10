import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

class Page1 extends StateWidget<Page1Controller> {
  const Page1({super.key});

  @override
  Page1Controller createState() => Page1Controller();

  @override
  Widget build(BuildContext context, Page1Controller state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page 1')),
      body: const Center(child: Icon(Icons.home, size: 64)),
    );
  }
}

class Page1Controller extends StateController<Page1> {}

class Page2 extends StateWidget<Page2Controller> {
  const Page2({super.key});

  @override
  Page2Controller createState() => Page2Controller();

  @override
  Widget build(BuildContext context, Page2Controller state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page 2')),
      body: const Center(child: Icon(Icons.settings, size: 64)),
    );
  }
}

class Page2Controller extends StateController<Page2> {}
