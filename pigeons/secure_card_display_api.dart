import 'package:pigeon/pigeon.dart';

/// Contract for the lifecycle of the card-tokenization SDK's `CardSecureDisplay`
/// module (see section 5.2 of the bank's SDK spec).
///
/// ## Why no method here returns the rendered image
///
/// The whole point of `CardSecureDisplay` is that the full PAN/PIN never
/// exists as text or bytes any caller can log, cache, or ship elsewhere.
/// Returning image bytes across this API would put pixel data of a secret
/// value into Dart memory — technically not the PAN as a string, but still
/// a needless copy of sensitive material crossing a boundary that does not
/// need it to cross.
///
/// Instead, rendering happens entirely on the native side, inside a
/// `FlutterPlatformView` (`SecureCardDisplayPlatformView.swift`) that calls
/// `FakeSecureCardDisplayService.getCardDataImage`/`getCardPinImage`
/// directly and shows the result in a native `UIImageView`. Flutter only
/// ever asks for the *view* (via `UiKitView`), never the image data — the
/// same "hand over a native view, not bytes" principle already used for
/// `PKAddPaymentPassViewController` in `CardTokenizationBridge`.
///
/// This file therefore only covers what genuinely needs Dart-side control:
/// the module's lifecycle (`initialize`/`wipe`) and the one method whose
/// result — a system pasteboard write — has no visual representation for a
/// platform view to own.
///
/// GENERATED: `lib/core/native/secure_card_display_api.g.dart` and
/// `ios/Runner/SecureCardDisplayApi.g.swift` — regenerate with:
///   dart run pigeon --input pigeons/secure_card_display_api.dart
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/native/secure_card_display_api.g.dart',
    swiftOut: 'ios/Runner/SecureCardDisplayApi.g.swift',
    dartPackageName: 'bank_app_reference',
    // See `wallet_extension_simulator_api.dart` for why this is disabled:
    // `card_tokenization_api.dart` already generates the shared `PigeonError`
    // class into the same `Runner` target.
    swiftOptions: SwiftOptions(includeErrorClass: false),
  ),
)
@HostApi()
abstract class SecureCardDisplayHostApi {
  @async
  void initialize();

  @async
  bool isInitialized();

  @async
  void copyPanToClipboard({required String cardReferenceId, required double ttlSeconds});

  @async
  void wipe();
}
