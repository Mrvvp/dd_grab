import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

final countdownProvider = StateNotifierProvider<CountdownNotifier, int>((ref) {
  return CountdownNotifier();
});

class CountdownNotifier extends StateNotifier<int> {
  Timer? _timer;

  CountdownNotifier() : super(6); // default 5 seconds

  void startCountdown({int from = 6, required VoidCallback onComplete}) {
    state = from;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state > 1) {
        state--;
      } else {
        timer.cancel();
        onComplete();
      }
    });
  }

  void cancel() {
    _timer?.cancel();
  }
}
