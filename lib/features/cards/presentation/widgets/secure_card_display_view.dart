import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Embeds the native `SecureCardDisplayPlatformView` (a plain `UIImageView`
/// showing a rendered PAN/PIN image) into the Flutter widget tree.
///
/// This widget never touches the image itself — `creationParams` only tells
/// the native side *which* fake card and *which* field to render; the
/// `UIImage` stays entirely on the platform side (see
/// `SecureCardDisplayPlatformView.swift`). There is deliberately no way to
/// read pixel data back out of this widget.
class SecureCardDisplayView extends StatelessWidget {
  const SecureCardDisplayView({
    required this.cardReferenceId,
    this.kind = SecureCardDisplayKind.pan,
    super.key,
  });

  final String cardReferenceId;
  final SecureCardDisplayKind kind;

  @override
  Widget build(BuildContext context) {
    // Android has no counterpart in this project yet — the whole IDEMIA
    // integration is iOS-only so far (see `project_apple_wallet_provisioning`
    // memory). Guarding here keeps the failure a clear, deliberate "not
    // built for this platform" rather than a channel-not-found crash.
    if (!Theme.of(context).platform.isIOSLike) {
      return const ColoredBox(
        color: Colors.black12,
        child: Center(child: Text('Secure card display is iOS-only in this demo')),
      );
    }

    return UiKitView(
      viewType: 'secure_card_display_view',
      creationParams: {'cardReferenceId': cardReferenceId, 'kind': kind.wireValue},
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

enum SecureCardDisplayKind {
  pan('pan'),
  pin('pin');

  const SecureCardDisplayKind(this.wireValue);

  final String wireValue;
}

extension on TargetPlatform {
  bool get isIOSLike => this == TargetPlatform.iOS;
}
