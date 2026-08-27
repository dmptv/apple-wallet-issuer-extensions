import PassKit
import UIKit

/// The Non-UI Issuer Provisioning Extension.
///
/// `PKIssuerProvisioningExtensionHandler` is the real Apple base class (from
/// `PassKit`, `ios(14.0)+`) — subclassing it and overriding `status`/`passEntries`
/// is the entire contract; there is no protocol to conform to and nothing else
/// to configure beyond the `Info.plist` extension point declared for the
/// `CardStatusExtension` target.
///
/// ## Who calls this in production, and when
///
/// Never this project's own code, and never through the Pigeon channel. iOS
/// itself instantiates this class in a **separate process** when the user opens
/// Apple Wallet or Settings → Wallet & Apple Pay and the system is deciding
/// which issuers to list.
///
/// ## Why this file also compiles into `Runner`
///
/// Nothing in this class is extension-process-specific — it is an ordinary
/// `NSObject` subclass. Compiling it into `Runner` too (see the
/// `xcodeproj`-driven target setup) lets a debug screen instantiate
/// `ServiceProvider()` directly and call `status`/`passEntries` as plain
/// method calls, timing them, without needing the real Wallet to ever invoke
/// this code. That harness proves the *logic* (100ms budget, Keychain-only
/// reads) without proving the *system integration* (Apple actually routing a
/// Wallet tap here) — the integration half stays permanently unverifiable
/// without the issuer entitlement, and the debug screen is honest about that
/// distinction rather than pretending to close the gap.
class ServiceProvider: PKIssuerProvisioningExtensionHandler {
  override func status(completion: @escaping (PKIssuerProvisioningExtensionStatus) -> Void) {
    let status = PKIssuerProvisioningExtensionStatus()

    if let summary = SharedCardCache.read() {
      status.passEntriesAvailable = summary.hasProvisionableCards
      // `requiresAuthentication = true` is what makes iOS launch the UI
      // Extension (FaceID/TouchID) before calling `passEntries` in the real
      // flow. The debug harness reproduces the same gate manually with
      // `LAContext`, since there is no separate UI Extension target here.
      status.requiresAuthentication = true
    } else {
      // No cache means the main app has never run since install, or the
      // Keychain item was cleared. Reporting "nothing available" here is the
      // safe default — it is what happens the very first time a user
      // installs the app and opens Wallet before ever launching it.
      status.passEntriesAvailable = false
      status.requiresAuthentication = false
    }

    status.remotePassEntriesAvailable = false // Apple Watch companion path — out of scope here.
    completion(status)
  }

  override func passEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
    guard let summary = SharedCardCache.read() else {
      completion([])
      return
    }

    let entries = summary.cards.compactMap { card -> PKIssuerProvisioningExtensionPassEntry? in
      // `art` has no default and is not optional in Apple's initializer — a
      // real integration would ship a rasterised card-network logo per brand.
      // A solid-fill placeholder keeps the call legal without pretending to
      // solve a design problem this debug harness is not about.
      guard let art = Self.placeholderArt() else { return nil }
      guard let configuration = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2) else {
        return nil
      }
      return PKIssuerProvisioningExtensionPaymentPassEntry(
        identifier: card.cardReferenceId,
        title: card.displayName,
        art: art,
        addRequestConfiguration: configuration
      )
    }

    completion(entries)
  }

  private static func placeholderArt() -> CGImage? {
    let size = CGSize(width: 200, height: 126) // Apple's documented card-art aspect ratio.
    UIGraphicsBeginImageContextWithOptions(size, true, 1)
    defer { UIGraphicsEndImageContext() }
    UIColor.systemIndigo.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    return UIGraphicsGetImageFromCurrentImageContext()?.cgImage
  }
}
