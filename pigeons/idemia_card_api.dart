import 'package:pigeon/pigeon.dart';

/// Contract for the IDEMIA Digital Card SDK bridge.
///
/// ## Why this shape, not a 1:1 mirror of the Swift SDK
///
/// The real SDK's `startPushProvisioning` takes a `ProvisioningData` whose
/// `handler` field is a Swift **closure** that receives a `PKAddPaymentPassRequest`
/// and drives the native `PKAddPaymentPassViewController`. A closure cannot
/// cross a Pigeon boundary — there is no Dart representation of "a callback the
/// native side invokes with a native-only PassKit object".
///
/// So the boundary is drawn one level higher: Flutter hands over everything the
/// *bank's backend* supplied (certificates, nonce, the signed JWS) and asks for
/// a plain success/failure. Presenting `PKAddPaymentPassViewController` and
/// wiring the SDK's handler closure happens entirely inside the native
/// implementation — see `IdemiaCardBridge.swift`. This is the same principle as
/// `ApiClient` not leaking `DioException`: each layer speaks its own
/// vocabulary, and the translation lives at the seam, not in the caller.
///
/// GENERATED: `lib/core/native/idemia_card_api.g.dart` and
/// `ios/Runner/IdemiaCardApi.g.swift` — regenerate with:
///   dart run pigeon --input pigeons/idemia_card_api.dart
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/native/idemia_card_api.g.dart',
    swiftOut: 'ios/Runner/IdemiaCardApi.g.swift',
    dartOptions: DartOptions(),
    swiftOptions: SwiftOptions(),
    dartPackageName: 'bank_app_reference',
  ),
)
class CardHandleData {
  CardHandleData({
    required this.cardHandle,
    required this.issuerId,
    required this.lastDigits,
    required this.expiry,
    required this.state,
  });

  final String cardHandle;
  final String issuerId;
  final String lastDigits;
  final String expiry;

  /// `ACTIVE` / `NOT_ACTIVE` / `SUSPENDED` / `TERMINATED` — kept as the raw
  /// string from the SDK's `CardState`. Decoding into a Dart enum happens on
  /// the Flutter side, in the same mapper that already parses `CardDto.state`,
  /// so there is exactly one place that knows the four values.
  final String state;
}

class ProvisionableCard {
  ProvisionableCard({
    required this.cardReferenceId,
    required this.issuerId,
    required this.lastDigits,
    required this.expiry,
    required this.paymentNetwork,
    required this.displayName,
    required this.eligibilityStatus,
  });

  final String cardReferenceId;
  final String issuerId;
  final String lastDigits;
  final String expiry;
  final String paymentNetwork;
  final String displayName;

  /// One of the SDK's `Eligibility` raw values: `eligible`, `nonEligible`,
  /// `alreadyProvisioned`, `alreadyProvisionedOnPhone`, `alreadyProvisionedOnWatch`.
  final String eligibilityStatus;
}

/// Everything the bank's backend must supply before provisioning can start.
///
/// Every field here traces to a specific requirement in the bank's technical
/// spec (see the `assetHash`/JWS/certificate walkthrough): the wrapper does no
/// cryptography of its own, it only carries what the backend already signed.
class ProvisioningRequest {
  ProvisioningRequest({
    required this.cardReferenceId,
    required this.certificates,
    required this.nonce,
    required this.nonceSignature,
    required this.userAuthorization,
  });

  final String cardReferenceId;

  /// DER-encoded certificate chain, as the SDK's `ProvisioningData.certificates`
  /// expects (`[Data]` on the Swift side).
  final List<Uint8List> certificates;

  final Uint8List nonce;
  final Uint8List nonceSignature;

  /// The JWS token (`enrollAuth`) signed by the bank's backend with its RSA
  /// private key — becomes `ProvisioningData.userAuthorization`.
  final String userAuthorization;
}

class ProvisioningResult {
  ProvisioningResult({required this.success, this.errorCode, this.errorMessage});

  final bool success;

  /// A code from Appendix A of the bank's spec (`CARD_EXPIRED`, `CARD_LOCKED`,
  /// …) when the SDK or PassKit rejected the request. `null` on success.
  final String? errorCode;
  final String? errorMessage;
}

/// Methods Flutter calls; the Swift side implements them.
///
/// `@async` marks a method as `async` on both sides — Pigeon generates a
/// `Future`-returning Dart method backed by a Swift method using completion
/// handlers (or `async`/`await`, matching the SDK's own signatures almost
/// exactly, since the SDK itself is already async-first).
@HostApi()
abstract class IdemiaCardHostApi {
  @async
  List<CardHandleData> findCardsByCardHolder({
    required String cardHolderHandle,
    required String issuerId,
  });

  @async
  List<ProvisionableCard> checkCards({
    required String issuerId,
    required List<String> cardHandles,
  });

  /// Synchronous in the real SDK (`canAddCards` has no `async` keyword there)
  /// because it only reads local PassKit state — no network round trip, so no
  /// reason to force it through the async machinery on either side.
  Map<String, String> canAddCards({required List<String> lastDigits});

  /// Presents `PKAddPaymentPassViewController` natively and drives it to
  /// completion. The `Future` resolves only after the user finishes the native
  /// flow (or cancels/fails it) — this single call replaces
  /// `generatePassKitRequestConfiguration` + `startPushProvisioning` +
  /// `notifyProvisioningCompleted` from the raw SDK, because all three only
  /// make sense chained together on the native side.
  @async
  ProvisioningResult startProvisioning(ProvisioningRequest request);
}
