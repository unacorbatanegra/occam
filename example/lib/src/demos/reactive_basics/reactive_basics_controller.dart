part of 'reactive_basics_page.dart';

class ReactiveBasicsController extends StateController<ReactiveBasicsPage> {
  final counter = 0.rx;
  final notificationsEnabled = false.rx;
  final readyMessage = ''.rx;
  final profile = UserProfile(
    name: 'Alex',
    level: 1,
    marketingOptIn: true,
  ).rx;

  final List<String> _names = ['Jordan', 'River', 'Kai', 'Sam', 'Nova'];
  int _currentNameIndex = 0;

  @override
  void readyState() {
    super.readyState();
    final args = ModalRoute.of(context)?.settings.arguments;
    final message =
        (args is String && args.isNotEmpty) ? args : 'All updates flow through Rx.';
    readyMessage(message);
  }

  void increment() => counter.value++;

  void decrement() => counter.value--;

  void addTen() => counter.update((value) => value + 10);

  void resetCounter() => counter(0);

  void toggleNotifications(bool value) => notificationsEnabled(value);

  void rotateName() {
    final next = _names[_currentNameIndex % _names.length];
    _currentNameIndex++;
    profile.value = profile.value.copyWith(name: next, level: 1);
  }

  void promoteUser() {
    profile.value.level++;
    profile.refresh();
  }

  void toggleMarketingConsent() {
    profile.value.marketingOptIn = !profile.value.marketingOptIn;
    profile.refresh();
  }

  @override
  void dispose() {
    counter.dispose();
    notificationsEnabled.dispose();
    readyMessage.dispose();
    profile.dispose();
    super.dispose();
  }
}

class UserProfile {
  UserProfile({
    required this.name,
    required this.level,
    required this.marketingOptIn,
  });

  String name;
  int level;
  bool marketingOptIn;

  UserProfile copyWith({
    String? name,
    int? level,
    bool? marketingOptIn,
  }) {
    return UserProfile(
      name: name ?? this.name,
      level: level ?? this.level,
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
    );
  }
}

