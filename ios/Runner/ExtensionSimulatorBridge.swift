import PassKit

/// Implements the debug-only `WalletExtensionSimulatorHostApi`.
///
/// See `ServiceProvider.swift` for why calling it directly, from `Runner`, is
/// valid: the class has no dependency on actually running inside an
/// `.appex` process. `AuthViewController` (the real UI Extension's principal
/// class) follows the identical reasoning.
final class ExtensionSimulatorBridge: WalletExtensionSimulatorHostApi {
  private let provider = ServiceProvider()

  func simulateStatus(completion: @escaping (Result<ExtensionStatusResult, Error>) -> Void) {
    let start = DispatchTime.now()
    provider.status { status in
      let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
      completion(.success(ExtensionStatusResult(
        passEntriesAvailable: status.passEntriesAvailable,
        requiresAuthentication: status.requiresAuthentication,
        elapsedMicroseconds: Int64(elapsed / 1_000)
      )))
    }
  }

  func authenticate(completion: @escaping (Result<Bool, Error>) -> Void) {
    // Drives the actual `CardAuthUIExtension` principal class — its
    // `viewDidLoad` triggers the same `LAContext` call the real `.appex`
    // would run, before Wallet ever shows it on screen. `loadViewIfNeeded()`
    // is enough to fire `viewDidLoad`; the biometric/passcode prompt is a
    // system UI independent of this controller ever being presented, so
    // there is no need to push it onto a navigation stack for the harness.
    let controller = AuthViewController()
    controller.completionHandler = { result in
      DispatchQueue.main.async { completion(.success(result == .authorized)) }
    }
    controller.loadViewIfNeeded()
  }

  func simulatePassEntries(completion: @escaping (Result<[PassEntryData], Error>) -> Void) {
    provider.passEntries { entries in
      let mapped = entries.map {
        PassEntryData(cardReferenceId: $0.identifier, displayName: $0.title)
      }
      completion(.success(mapped))
    }
  }
}
