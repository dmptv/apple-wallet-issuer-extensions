import Foundation
import PassKit

/// Stand-in for `import DigitalCardSdk`.
///
/// The real `.xcframework` cannot be linked into this project: its
/// entitlement (`com.apple.developer.payment-pass-provisioning`) is granted
/// only to a registered card issuer's Team ID, and a personal Apple Developer
/// account's provisioning profile does not carry it. Adding the entitlement
/// key without that grant does not fail at runtime — it fails to *build*,
/// because code signing rejects an entitlement the profile does not authorize.
///
/// So this file re-declares the SDK's public surface exactly as read from its
/// `.swiftinterface` (see the project notes on `DigitalCardSdk.xcframework`
/// 1.5.6) and backs it with hardcoded, deterministic responses. The type
/// names, method signatures, and enum cases below are not invented — they are
/// copied from the real module. That is what makes the swap-in trivial later:
/// only this file changes, `CardTokenizationBridge.swift` never learns the
/// difference.
enum CardState: String, Codable, Equatable {
  case NOT_ACTIVE
  case ACTIVE
  case SUSPENDED
  case TERMINATED
}

enum Eligibility: String {
  case eligible
  case nonEligible
  case alreadyProvisioned
  case alreadyProvisionedOnPhone
  case alreadyProvisionedOnWatch
}

struct CardHandle: Hashable {
  let lastDigits: String
  let exp: String
  let issuerId: String
  let state: CardState
  let cardHandle: String
}

struct Card: Hashable {
  let eligibilityCheck: String
  let issuerId: String
  let primaryAccountIdentifier: String?
  let cardHolderId: String?
  let lastDigits: String
  let exp: String
  let issuerCardId: String?
  let cardReferenceId: String
  let paymentNetwork: String
  let eligibilityStatus: Eligibility
  let maskedCardHolderName: String?
  let cardDisplayName: String
}

struct ProvisioningData {
  let certificates: [Data]
  let nonce: Data
  let nonceSignature: Data
  let handler: (PKAddPaymentPassRequest) -> Void
  let card: Card
  let userAuthorization: String
}

protocol CardService {
  func findCardsByCardHolder(cardHolderHandle: String, issuerId: String) async throws -> [CardHandle]
}

protocol InAppPushProvisioningService {
  func checkCards(issuerId: String, cardHandles: [String], mobileAppParams: MobileAppParams?) async throws -> [Card]
  func generatePassKitRequestConfiguration(card: Card) throws -> PKAddPaymentPassRequestConfiguration?
  func startPushProvisioning(data: ProvisioningData) async throws
  func notifyProvisioningCompleted(issuerId: String, pass: PKPaymentPass?, error: Error?) async throws -> Bool
  func canAddCards(lastDigits: [String]) -> [String: Eligibility]
}

struct MobileAppParams: Codable, Equatable {
  let vClientAppId: String
}

enum FakeSdkError: Error {
  case notImplementedOnSimulator
}

/// Facade matching `DigitalCardSDK.cardService` / `.inAppPushProvisioningService`.
enum DigitalCardSDK {
  static let cardService: CardService = FakeCardService()
  static let inAppPushProvisioningService: InAppPushProvisioningService = FakeInAppPushProvisioningService()
}

/// Hardcoded so the bridge, the Flutter call, and the Pigeon round trip are
/// all exercised end to end without a real backend or a real device — this is
/// exactly the `FakeBalanceService` pattern from the Dart side, just written
/// in Swift for the native seam.
final class FakeCardService: CardService {
  func findCardsByCardHolder(cardHolderHandle: String, issuerId: String) async throws -> [CardHandle] {
    [
      CardHandle(lastDigits: "4242", exp: "0928", issuerId: issuerId, state: .ACTIVE, cardHandle: "handle-visa-1"),
      CardHandle(lastDigits: "8890", exp: "0327", issuerId: issuerId, state: .SUSPENDED, cardHandle: "handle-mc-1"),
    ]
  }
}

final class FakeInAppPushProvisioningService: InAppPushProvisioningService {
  /// Keyed by the same handles `FakeCardService.findCardsByCardHolder` hands
  /// out, so a real call sequence (find → check) sees a consistent card
  /// across both steps — the crash this replaced came from every handle
  /// collapsing to the *same* hardcoded `lastDigits`, which made downstream
  /// `Dictionary(uniqueKeysWithValues:)` see duplicate keys and crash. Kept as
  /// static data, not computed, so the "fake" stays obviously fake.
  private static let byHandle: [String: (lastDigits: String, network: String, name: String)] = [
    "handle-visa-1": ("4242", "VISA", "Everyday Visa"),
    "handle-mc-1": ("8890", "MASTERCARD", "Savings Mastercard"),
  ]

  func checkCards(issuerId: String, cardHandles: [String], mobileAppParams: MobileAppParams?) async throws -> [Card] {
    cardHandles.map { handle in
      let fallback = (lastDigits: "0000", network: "VISA", name: "Card")
      let info = Self.byHandle[handle] ?? fallback
      return Card(
        eligibilityCheck: "ok",
        issuerId: issuerId,
        primaryAccountIdentifier: nil,
        cardHolderId: nil,
        lastDigits: info.lastDigits,
        exp: "0928",
        issuerCardId: nil,
        cardReferenceId: handle,
        paymentNetwork: info.network,
        eligibilityStatus: .eligible,
        maskedCardHolderName: nil,
        cardDisplayName: info.name
      )
    }
  }

  func generatePassKitRequestConfiguration(card: Card) throws -> PKAddPaymentPassRequestConfiguration? {
    // The real SDK builds this from the card + issuer metadata. On the
    // simulator `PKAddPaymentPassViewController` refuses to present regardless
    // (documented behaviour, PassKit needs a real Secure Element) so returning
    // a minimal configuration is enough to prove the call chain compiles and
    // runs — it is never actually presented in this environment.
    PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2)
  }

  func startPushProvisioning(data: ProvisioningData) async throws {
    // Real SDK: this triggers PKAddPaymentPassViewController via `data.handler`.
    // Faked here as an immediate synthetic success so the bridge's async
    // Pigeon round trip (Dart → Swift → back to Dart) is fully exercised.
    try await Task.sleep(nanoseconds: 300_000_000)
  }

  func notifyProvisioningCompleted(issuerId: String, pass: PKPaymentPass?, error: Error?) async throws -> Bool {
    error == nil
  }

  func canAddCards(lastDigits: [String]) -> [String: Eligibility] {
    // `nonEligible` is what the real SDK returns on a simulator too — this
    // fake preserves that so a developer testing against the fake sees the
    // same "not eligible" signal they would see running the real SDK here,
    // rather than a falsely optimistic `eligible`.
    //
    // `Dictionary(uniqueKeysWithValues:)` is a documented crasher on any
    // duplicate key — a real production bug hit here once already, when two
    // fake cards briefly shared the same `lastDigits`. Last-4-digits is not
    // globally unique in the first place (different issuers/networks can
    // collide), so this construction is wrong for any caller, fake or real.
    // `uniquingKeysWith:` makes the "last write wins" policy explicit instead
    // of leaving it as an uncaught fatal error.
    Dictionary(lastDigits.map { ($0, Eligibility.nonEligible) }, uniquingKeysWith: { _, latest in latest })
  }
}
