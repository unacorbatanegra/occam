import 'package:flutter/material.dart';

import 'src/presentation/pages/home/bottom/bottom_page.dart';
import 'src/presentation/pages/home/home_page.dart';
import 'src/presentation/pages/second/second_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Occam Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        cardTheme: const CardThemeData(
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
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
