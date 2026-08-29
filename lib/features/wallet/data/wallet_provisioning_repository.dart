import 'dart:typed_data';

import 'package:injectable/injectable.dart';

// The generated file also defines a `ProvisionableCard` (the wire DTO) —
// `hide` keeps only the Pigeon plumbing this file needs and leaves the
// domain-layer `ProvisionableCard` from the other import unambiguous, without
// resorting to an `as` prefix on every reference.
import '../../../core/native/card_tokenization_api.g.dart' hide ProvisionableCard;
import '../domain/entities/provisionable_card.dart';

/// The domain-facing contract. Notice it never mentions Pigeon, the SDK, or
/// PassKit by name in its signatures — same inversion as `CardRepository`:
/// the presentation layer depends on this interface, not on the generated API.
abstract interface class WalletProvisioningRepository {
  Future<List<ProvisionableCard>> checkEligibleCards({
    required String issuerId,
    required List<String> cardHandles,
  });

  /// True if provisioning succeeded. On failure, throws with the issuer's
  /// error code attached — mapped the same way `HttpException.errorCode`
  /// becomes a `BusinessFailure` in the card-balance feature, so the two
  /// features render errors through one shared vocabulary.
  Future<void> addToAppleWallet(String cardReferenceId);
}

/// Talks to the generated Pigeon client directly.
///
/// This is the one class in the whole `wallet` feature allowed to import
/// `card_tokenization_api.g.dart` — the same containment rule as `ApiClient`
/// being the only place that imports `dio`.
@LazySingleton(as: WalletProvisioningRepository)
class WalletProvisioningRepositoryImpl implements WalletProvisioningRepository {
  WalletProvisioningRepositoryImpl(this._hostApi);

  final CardTokenizationHostApi _hostApi;

  @override
  Future<List<ProvisionableCard>> checkEligibleCards({
    required String issuerId,
    required List<String> cardHandles,
  }) async {
    final cards = await _hostApi.checkCards(
      issuerId: issuerId,
      cardHandles: cardHandles,
    );

    // A second native call, `canAddCards`, is what actually knows whether
    // PassKit will accept the card (already-provisioned, ineligible device,
    // …) — `checkCards` alone only proves the *card* qualifies, not that
    // *this device* can take it. Both must pass, matching the SDK's own
    // two-step contract (`checkCards` then `canAddCards`, as its usage guide
    // shows) — skipping the second call would report a card "eligible" that
    // PassKit is about to reject.
    final eligibility = await _hostApi.canAddCards(
      lastDigits: cards.map((c) => c.lastDigits).toList(),
    );

    return cards.map((dto) {
      final rawEligibility = eligibility[dto.lastDigits] ?? dto.eligibilityStatus;
      return ProvisionableCard(
        cardReferenceId: dto.cardReferenceId,
        lastDigits: dto.lastDigits,
        expiry: dto.expiry,
        paymentNetwork: dto.paymentNetwork,
        displayName: dto.displayName,
        eligibility: WalletEligibility.fromRaw(rawEligibility),
      );
    }).toList(growable: false);
  }

  @override
  Future<void> addToAppleWallet(String cardReferenceId) async {
    // The certificate/nonce/JWS the real backend would supply here. Hardcoded
    // per the "bypass limitations for now" plan: `FakeDigitalCardSdk.swift`
    // never inspects these bytes, so any deterministic placeholder exercises
    // the full Dart → Pigeon → Swift → back round trip without needing a
    // running bank backend.
    final request = ProvisioningRequest(
      cardReferenceId: cardReferenceId,
      certificates: [Uint8List.fromList(const [0x30, 0x82])],
      nonce: Uint8List.fromList(List.generate(16, (i) => i)),
      nonceSignature: Uint8List.fromList(List.generate(32, (i) => i)),
      userAuthorization: 'fake-jws-token-for-local-testing',
    );

    final result = await _hostApi.startProvisioning(request);
    if (!result.success) {
      throw WalletProvisioningException(
        code: result.errorCode ?? 'System Error',
        message: result.errorMessage,
      );
    }
  }
}

/// Deliberately not a `Failure` subtype: this exception is thrown by the data
/// layer and caught by whatever notifier calls `addToAppleWallet`, which maps
/// it into a `BusinessFailure` the same way `HttpException` is mapped —
/// keeping the wallet feature symmetric with the balance feature's error
/// handling instead of inventing a second pattern.
class WalletProvisioningException implements Exception {
  const WalletProvisioningException({required this.code, this.message});

  final String code;
  final String? message;

  @override
  String toString() => 'WalletProvisioningException($code): $message';
}
