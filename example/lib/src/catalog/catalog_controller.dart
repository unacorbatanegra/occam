part of 'catalog_page.dart';

class CatalogController extends StateController<CatalogPage> {
  final lastOpened = ''.rx;

  List<DemoEntry> get demos => DemoRegistry.demos;

  void openDemo(DemoEntry entry) {
    lastOpened(entry.title);
    Navigator.of(context).pushNamed(
      entry.routeName,
      arguments: entry.arguments,
    );
  }

  @override
  void dispose() {
    lastOpened.dispose();
    super.dispose();
  }
}
