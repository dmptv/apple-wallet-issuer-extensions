import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/native/secure_card_display_api.g.dart';

final secureCardDisplayHostApiProvider =
    Provider<SecureCardDisplayHostApi>((ref) => getIt<SecureCardDisplayHostApi>());

/// Whether the native secure-display view for a given card should be on
/// screen right now, plus the auto-hide countdown.
///
/// `autoDispose` matters here more than anywhere else in the app: this
/// state gates whether a `UIImageView` holding a decrypted PAN/PIN image
/// exists at all. If a stale provider survived after the reveal screen
/// closed, the image (and the native `wipe()` call) would never happen —
/// exactly the "screen closed but the SDK still thinks it's initialized"
/// bug the reveal flow exists to prevent.
final cardRevealProvider = NotifierProvider<CardRevealNotifier, CardRevealState>(
  CardRevealNotifier.new,
  isAutoDispose: true,
);

class CardRevealState {
  const CardRevealState({this.isVisible = false, this.remainingSeconds = 0});

  final bool isVisible;
  final int remainingSeconds;

  CardRevealState copyWith({bool? isVisible, int? remainingSeconds}) => CardRevealState(
        isVisible: isVisible ?? this.isVisible,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      );
}

class CardRevealNotifier extends Notifier<CardRevealState> {
  static const _revealDuration = Duration(seconds: 15);

  Timer? _countdown;

  @override
  CardRevealState build() {
    // `wipe()` on dispose covers every way this provider can go away: the
    // countdown reaching zero (see `_startCountdown`), the user navigating
    // back, or the whole screen being popped — one place, not three.
    ref.onDispose(() {
      _countdown?.cancel();
      ref.read(secureCardDisplayHostApiProvider).wipe();
    });
    return const CardRevealState();
  }

  Future<void> reveal() async {
    await ref.read(secureCardDisplayHostApiProvider).initialize();
    if (!ref.mounted) return;
    _startCountdown();
  }

  void hide() {
    _countdown?.cancel();
    state = const CardRevealState();
    ref.read(secureCardDisplayHostApiProvider).wipe();
  }

  void _startCountdown() {
    _countdown?.cancel();
    state = state.copyWith(isVisible: true, remainingSeconds: _revealDuration.inSeconds);
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.remainingSeconds - 1;
      if (next <= 0) {
        timer.cancel();
        // Reuses `hide()` rather than duplicating the wipe call — expiry and
        // a manual dismiss must leave the same end state.
        hide();
        return;
      }
      state = state.copyWith(remainingSeconds: next);
    });
  }
}
