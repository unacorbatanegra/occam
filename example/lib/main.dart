import 'package:flutter/material.dart';

import 'src/presentation/pages/home/bottom/bottom_page.dart';
import 'src/presentation/pages/home/home_page.dart';
import 'src/presentation/pages/second/second_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      
      initialRoute: '/',
      routes: {
        '/': (ctx) => const HomePage(),
        '/secondPage': (ctx) => const SecondPage(),
        '/bottom': (ctx) => const BottomPage(),
      },
    );
  }
}
