import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

class Page1 extends StateWidget<Page1Controller> {
  const Page1({Key? key}) : super(key: key);

  @override
  Page1Controller createState() => Page1Controller();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page 1'),
      ),
    );
  }
}

class Page1Controller extends StateController<Page1>
    with AutomaticKeepAliveClientMixin<Page1> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.build(context);
  }

  @override
  bool get wantKeepAlive => true;
}

class Page2 extends StateWidget<Page2Controller> {
  const Page2({Key? key}) : super(key: key);

  @override
  Page2Controller createState() => Page2Controller();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page 2'),
      ),
    );
  }
}

class Page2Controller extends StateController<Page2>
    with AutomaticKeepAliveClientMixin<Page2> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.build(context);
  }

  @override
  bool get wantKeepAlive => true;
}
