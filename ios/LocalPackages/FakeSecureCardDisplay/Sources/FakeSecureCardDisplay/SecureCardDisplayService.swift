import UIKit

/// Mirrors IDEMIA's `SecureCardDisplay` module (see the bank's IDEMIA SDK
/// technical spec, section 5.2). The real module ships inside
/// `DigitalCardSdk.xcframework` as a self-contained unit alongside
/// `InAppPushProvisioning`; this fake is shipped the same way — as its own
/// local Swift package — so any target that needs card reveal (Runner today,
/// a card-detail extension later) can link it without pulling in the rest of
/// the provisioning bridge.
///
/// Every method returns rendered pixels (`UIImage`), never a `String`
/// carrying PAN or PIN digits — a caller that only has this protocol cannot
/// get the plaintext value out as text even if it wanted to.
public protocol SecureCardDisplayService: Sendable {
  func initialize() async throws
  func isInitialized() async -> Bool

  /// Full PAN, grouped for display, rendered into an image by this module —
  /// never returned as a `String`.
  func getCardDataImage(cardReferenceId: String) async throws -> UIImage

  /// Card PIN, rendered into an image the same way.
  func getCardPinImage(cardReferenceId: String) async throws -> UIImage

  /// Places the PAN on the system pasteboard with an expiry, so it does not
  /// linger there indefinitely.
  func copyPanToClipboard(cardReferenceId: String, ttl: TimeInterval) async throws

  /// Clears any decrypted material this instance is holding. Callers must
  /// invoke this when the app backgrounds or the reveal screen closes.
  func wipe() async
}

public enum SecureCardDisplayError: Error {
  case notInitialized
  case unknownCard
}
