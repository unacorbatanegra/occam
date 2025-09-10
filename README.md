# Occam

[![pub package](https://img.shields.io/pub/v/occam.svg)](https://pub.dev/packages/occam)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)

Minimalist state management for Flutter based on native StatefulWidget.

## Philosophy

Occam follows the principle of **"Occam's Razor"** - the simplest solution is often the best. In a world of complex state management solutions, Occam provides:

- **Minimal API surface** - Only what you need, nothing more
- **Native Flutter patterns** - Built on StatefulWidget, not against it
- **Explicit over implicit** - Clear lifecycle management and disposal
- **One way to do things** - Reduces decision fatigue and cognitive load

### Why Occam?

Most state management packages grow complex over time, accumulating features that most projects don't need. Occam stays focused on the essentials:

1. **Clean separation** of UI and business logic
2. **Reactive updates** without magic or hidden complexity  
3. **Memory safety** through explicit disposal patterns
4. **Familiar patterns** that Flutter developers already know

## Core Concept

**1 View = 1 Controller**

- **View**: Pure UI widgets, no business logic
- **Controller**: All logic, no widgets
- **Reactive**: Simple reactive types with explicit disposal

## Quick Start

### 1. Add to pubspec.yaml
```yaml
dependencies:
  occam: ^1.0.2
```

### 2. Create a Page
```dart
class HomePage extends StateWidget<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomeController createState() => HomeController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Occam Demo')),
      floatingActionButton: FloatingActionButton(
        onPressed: state.increment,
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: RxWidget<int>(
          notifier: state.counter,
          builder: (context, value) => Text('Count: $value'),
        ),
      ),
    );
  }
}
```

### 3. Create a Controller
```dart
class HomeController extends StateController {
  final counter = 0.rx;

  @override
  void initState() {
    super.initState();
    // Widget mounted
  }

  @override
  void readyState() {
    // Context is safe here
  }

  void increment() {
    counter.value++;
  }

  @override
  void dispose() {
    counter.dispose(); // Always dispose reactive types
    super.dispose();
  }
}
```

## Reactive Types

```dart
// Create reactive variables
final count = 0.rx;
final name = 'John'.rx;
final isActive = true.rx;
final items = <String>[].rx;

// Update values
count.value = 10;
name.value = 'Jane';
isActive.value = false;
items.value.add('item');

// Listen to changes with RxWidget
RxWidget<int>(
  notifier: count,
  builder: (context, value) => Text('$value'),
)
```

## Lifecycle Methods

- `initState()`: Widget mounted
- `readyState()`: Context is safe, use for navigation args
- `dispose()`: Clean up resources

## Key Features

- ✅ **Simple**: Based on native Flutter StatefulWidget
- ✅ **Clean**: Separation of UI and logic
- ✅ **Reactive**: Automatic UI updates
- ✅ **Safe**: Explicit disposal prevents memory leaks
- ✅ **Minimal**: No unnecessary features

## Package Details

### Dependencies
- **Flutter SDK**: >=3.0.0 <4.0.0
- **Zero external dependencies** - Only uses Flutter's built-in widgets and Dart's core libraries
- **Minimal footprint** - No heavy packages or complex abstractions

### Architecture
- **StateWidget**: Custom StatefulWidget that enforces the View-Controller pattern
- **StateController**: Enhanced State class with additional lifecycle methods
- **Rx Types**: Lightweight reactive primitives with explicit disposal
- **RxWidget**: Simple widget for listening to reactive changes

### Memory Management
Occam prioritizes memory safety through:
- **Explicit disposal** of reactive types in `dispose()`
- **No hidden listeners** or automatic cleanup that can cause memory leaks
- **Clear ownership** - each controller owns its reactive variables

### Performance
- **Minimal overhead** - Built on native Flutter patterns
- **Efficient updates** - Only rebuilds widgets that actually changed
- **No reflection** or code generation required


## Credits

Inspired by @roipeker's work on state management patterns.
