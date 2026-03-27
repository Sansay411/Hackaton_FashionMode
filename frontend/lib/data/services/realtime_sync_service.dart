import 'dart:async';

class RealtimeSyncService {
  Timer? _timer;
  bool _isTicking = false;

  void start({
    required Duration interval,
    required Future<void> Function() onTick,
  }) {
    stop();
    _timer = Timer.periodic(interval, (_) async {
      if (_isTicking) {
        return;
      }

      _isTicking = true;
      try {
        await onTick();
      } finally {
        _isTicking = false;
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isTicking = false;
  }
}
