part of 'stream_binding_page.dart';

class StreamBindingController extends StateController<StreamBindingPage> {
  final elapsedSeconds = 0.rx;
  final isRunning = false.rx;
  final logs = <String>[].rx;

  Stream<int>? _boundStream;

  @override
  void initState() {
    super.initState();
    elapsedSeconds.addValueListener(_handleTick);
  }

  void startTimer() {
    if (isRunning.value) return;
    logs.add('Started stream at ${DateTime.now().toIso8601String()}');
    elapsedSeconds(0);
    isRunning(true);
    _boundStream = Stream.periodic(
      const Duration(seconds: 1),
      (count) => count + 1,
    );
    elapsedSeconds.bindStream(_boundStream!);
  }

  void stopTimer() {
    if (!isRunning.value) return;
    logs.add('Stopped stream at ${elapsedSeconds.value}s');
    isRunning(false);
    _cancelStream();
  }

  void bumpManually() {
    elapsedSeconds.update((value) => value + 1);
    logs.add('Manual increment to ${elapsedSeconds.value}s');
  }

  void _handleTick(int seconds) {
    if (!isRunning.value) return;
    logs.add('Stream emitted $seconds s');
  }

  void _cancelStream() {
    final stream = _boundStream;
    if (stream == null) return;
    elapsedSeconds.closeStream(stream);
    _boundStream = null;
  }

  @override
  void dispose() {
    _cancelStream();
    elapsedSeconds.removeValueListener(_handleTick);
    elapsedSeconds.dispose();
    isRunning.dispose();
    logs.dispose();
    super.dispose();
  }
}

