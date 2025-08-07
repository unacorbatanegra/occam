# Occam

[![Flutter](https://img.shields.io/badge/Flutter-3.32.7-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8.1-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A minimalist Flutter state management ecosystem that provides clean architecture with reactive state management.

## 🎯 Overview

Occam is a Flutter state management solution built on the principle of **1 View = 1 Controller**. It offers a simple, safe, and maintainable approach to state management with automatic disposal and reactive UI updates.

### Core Philosophy

- **Simple**: Minimal API with only essential features
- **Clean Architecture**: Strict separation between View (UI) and Controller (Logic)
- **Safe**: Automatic disposal of reactive variables to prevent memory leaks
- **Reactive**: Built-in reactive types that automatically update UI when values change

## 📦 Packages

This repository contains the following packages:

### 🎮 [occam](packages/occam/) - Core State Management Library

The main state management library providing:

- **StateWidget**: Base class for UI components with 1:1 controller relationship
- **StateController**: Base class for logic with lifecycle management
- **Reactive Types**: `Rx<T>`, `RxBool`, `RxList<T>` with automatic UI updates
- **RxWidget**: Widget that rebuilds when reactive values change
- **Navigation Utilities**: Simplified navigation with `navigator` and `navArgs`

```dart
class HomePage extends StateWidget<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomeController createState() => HomeController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          RxWidget<int>(
            notifier: state.counter,
            builder: (context, value) => Text('Count: $value'),
          ),
          ElevatedButton(
            onPressed: state.incrementCounter,
            child: Text('Increment'),
          ),
        ],
      ),
    );
  }
}

class HomeController extends StateController {
  final counter = 0.rx;
  
  void incrementCounter() {
    counter.value++;
  }
  
  @override
  void dispose() {
    counter.dispose();
    super.dispose();
  }
}
```

### 🔧 [occam_linter](packages/occam_linter/) - Linting Rules

Custom linting rules to enforce Occam best practices and patterns.

## 🚀 Quick Start

### Installation

Add Occam to your `pubspec.yaml`:

```yaml
dependencies:
  occam: ^1.0.2
```

### Basic Usage

1. **Create a Controller**:

```dart
class UserController extends StateController {
  final userName = "".rx;
  final userPosts = <String>[].rx;
  
  @override
  void readyState() async {
    await loadUserData();
  }
  
  Future<void> loadUserData() async {
    userName.value = "John Doe";
    userPosts.assignAll(["Post 1", "Post 2"]);
  }
  
  @override
  void dispose() {
    userName.dispose();
    userPosts.dispose();
    super.dispose();
  }
}
```

2. **Create a View**:

```dart
class UserPage extends StateWidget<UserController> {
  const UserPage({Key? key}) : super(key: key);

  @override
  UserController createState() => UserController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Profile')),
      body: Column(
        children: [
          RxWidget<String>(
            notifier: state.userName,
            builder: (context, name) => Text('Hello $name'),
          ),
          RxWidget<List<String>>(
            notifier: state.userPosts,
            builder: (context, posts) => ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(posts[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🛠️ Development

This project uses [Melos](https://melos.invertase.dev/) for monorepo management.

### Prerequisites

- Flutter 3.32.7
- Dart 3.8.1
- Melos

### Setup

1. **Install Melos**:
```bash
dart pub global activate melos
```

2. **Install dependencies**:
```bash
melos bootstrap
```

3. **Set Flutter version**:
```bash
melos run set
```

### Available Scripts

- `melos run analyze` - Run static analysis
- `melos run get` - Get dependencies for all packages
- `melos run set` - Set Flutter version

### Project Structure

```
occam/
├── packages/
│   ├── occam/           # Core state management library
│   └── occam_linter/    # Custom linting rules
├── melos.yaml          # Monorepo configuration
└── README.md           # This file
```

## 📚 Key Features

### Reactive Types

- **Rx<T>**: Generic reactive wrapper with callable syntax
- **RxBool**: Specialized boolean with toggle and logical operators
- **RxList<T>**: Reactive list with automatic UI updates

### Lifecycle Management

- **initState()**: Called when widget mounts
- **readyState()**: Called after mount with safe context access
- **dispose()**: Automatic cleanup of reactive variables

### Navigation Utilities

- **navigator**: Direct access to Navigator
- **navArgs**: Access to route arguments

### Advanced Features

- **Stream Binding**: Automatic subscription management
- **Value Listeners**: Callbacks for value changes
- **Disposal Callbacks**: Register cleanup functions

## 🎨 Best Practices

1. **Always dispose reactive variables** in controller's `dispose()` method
2. **Use 1:1 relationship** - One view per controller
3. **Keep controllers logic-free** - No UI widgets in controllers
4. **Keep views widget-only** - No business logic in views
5. **Use reactive types** for state that needs UI updates
6. **Leverage readyState()** for context-safe initialization

## 📖 Documentation

- [Occam Core Package](packages/occam/README.md) - Detailed documentation for the main library
- [Occam Linter Package](packages/occam_linter/README.md) - Linting rules documentation

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](packages/occam/LICENSE) file for details.

## 🙏 Credits

Credits to: @roipeker for the original inspiration.

---

**Note**: This package is primarily for personal use and the API may change over time. 