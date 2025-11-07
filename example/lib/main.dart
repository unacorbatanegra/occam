import 'package:flutter/material.dart';

import 'src/catalog/catalog_page.dart';
import 'src/demo_registry.dart';

void main() {
  runApp(const OccamExamplesApp());
}

class OccamExamplesApp extends StatelessWidget {
  const OccamExamplesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Occam Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigoAccent.shade400),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const CatalogPage(),
      },
      onGenerateRoute: DemoRegistry.onGenerateRoute,
    );
  }
}
