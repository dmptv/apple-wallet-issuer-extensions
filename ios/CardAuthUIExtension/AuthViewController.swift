import LocalAuthentication
import PassKit
import UIKit

/// The UI Issuer Provisioning Extension.
///
/// `PKIssuerProvisioningExtensionAuthorizationProviding` is the real Apple
/// protocol (`PassKit`, `ios(14.0)+`, confirmed from the framework header —
/// not guessed): a single `completionHandler` property the extension must
/// call exactly once, with `.authorized` or `.canceled`. Everything else —
/// what's on screen, how authentication happens — is up to the extension.
///
/// ## Who calls this in production, and when
///
/// Apple Wallet, in a **separate process**, immediately after
/// `CardStatusExtension`'s `status()` reports `requiresAuthentication = true`
/// (see `ServiceProvider.swift`). The system presents this view controller's
/// view inside Wallet's own UI chrome — there is no navigation code here for
/// that, it is entirely out of this extension's control.
///
/// ## Why this file also compiles into `Runner`
///
/// Same reasoning as `ServiceProvider`: nothing here is
/// extension-process-specific, it is an ordinary `UIViewController`. The
/// debug harness (`ExtensionSimulatorBridge.authenticate`) instantiates this
/// exact class and drives its `completionHandler`, so the demo exercises the
/// real extension code — the actual protocol conformance and actual
/// `LAContext` call the real `.appex` would run — not a hand-rolled
/// approximation living only in the harness.
class AuthViewController: UIViewController, PKIssuerProvisioningExtensionAuthorizationProviding {
  /// The protocol's sole requirement. Wallet sets this before presenting the
  /// view controller; the extension must invoke it exactly once when
  /// authentication finishes, one way or the other.
  var completionHandler: ((PKIssuerProvisioningExtensionAuthorizationResult) -> Void)?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    authenticate()
  }

  private func authenticate() {
    let context = LAContext()
    var evaluationError: NSError?

    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &evaluationError) else {
      completionHandler?(.canceled)
      return
    }

    context.evaluatePolicy(
      .deviceOwnerAuthentication,
      localizedReason: "Confirm it's you to add this card to Apple Wallet"
    ) { [weak self] success, _ in
      DispatchQueue.main.async {
        self?.completionHandler?(success ? .authorized : .canceled)
      }
    }
  }
}
