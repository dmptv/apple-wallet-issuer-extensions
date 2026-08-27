import Flutter
import PassKit
import UIKit

/// Implements the Pigeon-generated `IdemiaCardHostApi` protocol by calling
/// `DigitalCardSDK` (currently `FakeDigitalCardSdk.swift` — see that file for
/// why, and for exactly what changes when the real `.xcframework` is linked).
///
/// This class is the only place in the whole project that imports both Pigeon
/// types and SDK types. Confining the translation to one file is what makes
/// swapping the fake for the real SDK a one-file change: everything on the
/// Dart side already speaks Pigeon's vocabulary (`CardHandleData`,
/// `ProvisionableCard`, …), never the SDK's.
final class IdemiaCardBridge: IdemiaCardHostApi {

  // MARK: - IdemiaCardHostApi

  func findCardsByCardHolder(
    cardHolderHandle: String,
    issuerId: String,
    completion: @escaping (Result<[CardHandleData], Error>) -> Void
  ) {
    Task {
      do {
        let handles = try await DigitalCardSDK.cardService.findCardsByCardHolder(
          cardHolderHandle: cardHolderHandle,
          issuerId: issuerId
        )
        completion(.success(handles.map(Self.toPigeon)))
      } catch {
        completion(.failure(error))
      }
    }
  }

  func checkCards(
    issuerId: String,
    cardHandles: [String],
    completion: @escaping (Result<[ProvisionableCard], Error>) -> Void
  ) {
    Task {
      do {
        let cards = try await DigitalCardSDK.inAppPushProvisioningService.checkCards(
          issuerId: issuerId,
          cardHandles: cardHandles,
          // `mobileAppParams` is required only for VISA per the SDK docs; nil
          // is correct for the other networks and is what the real call site
          // will branch on once card-network detection is added.
          mobileAppParams: nil
        )

        // Every successful `checkCards` refreshes the extension's cache. This
        // is the write half of the "app pre-computes, extension only reads"
        // split from the bank's Wallet Extensions requirement — see
        // `SharedCardCache` for the read half and why the split makes the
        // 100ms budget achievable at all.
        SharedCardCache.write(cards: cards.map {
          SharedCardCache.CardSummary(cardReferenceId: $0.cardReferenceId, displayName: $0.cardDisplayName)
        })

        completion(.success(cards.map(Self.toPigeon)))
      } catch {
        completion(.failure(error))
      }
    }
  }

  /// The one method the real SDK also exposes synchronously — no `Task`
  /// needed, and Pigeon reflects that: no `completion` handler, just `throws`.
  func canAddCards(lastDigits: [String]) throws -> [String: String] {
    let result = DigitalCardSDK.inAppPushProvisioningService.canAddCards(lastDigits: lastDigits)
    return result.mapValues { $0.rawValue }
  }

  func startProvisioning(
    request: ProvisioningRequest,
    completion: @escaping (Result<ProvisioningResult, Error>) -> Void
  ) {
    Task {
      do {
        // In the real flow this card would come from a prior `checkCards`
        // call whose result the Dart side cached and echoed back inside
        // `request`. Reconstructed minimally here since the fake service
        // does not persist state between calls the way a real backend-backed
        // session would.
        let card = Card(
          eligibilityCheck: "ok",
          issuerId: "issuer-1",
          primaryAccountIdentifier: nil,
          cardHolderId: nil,
          lastDigits: "0000",
          exp: "0000",
          issuerCardId: nil,
          cardReferenceId: request.cardReferenceId,
          paymentNetwork: "VISA",
          eligibilityStatus: .eligible,
          maskedCardHolderName: nil,
          cardDisplayName: "Card"
        )

        let data = ProvisioningData(
          certificates: request.certificates.map { $0.data },
          nonce: request.nonce.data,
          nonceSignature: request.nonceSignature.data,
          // This closure is the reason the whole bridge exists: it is what
          // the real SDK invokes with a populated `PKAddPaymentPassRequest`,
          // and presenting the resulting `PKAddPaymentPassViewController` is
          // native UIKit work with no Flutter equivalent at all.
          handler: { [weak self] passRequest in
            self?.present(passRequest)
          },
          card: card,
          userAuthorization: request.userAuthorization
        )

        try await DigitalCardSDK.inAppPushProvisioningService.startPushProvisioning(data: data)
        let notified = try await DigitalCardSDK.inAppPushProvisioningService
          .notifyProvisioningCompleted(issuerId: card.issuerId, pass: nil, error: nil)

        completion(.success(ProvisioningResult(success: notified, errorCode: nil, errorMessage: nil)))
      } catch {
        // A production mapper would translate specific SDK/PassKit error
        // cases into the bank's Appendix A codes (`CARD_EXPIRED`,
        // `CARD_LOCKED`, …); this fake path only proves the failure channel
        // reaches Dart intact.
        completion(.success(
          ProvisioningResult(success: false, errorCode: "System Error", errorMessage: "\(error)")
        ))
      }
    }
  }

  // MARK: - Native PassKit presentation

  /// Presents Apple's own add-card screen. This has no Dart counterpart by
  /// design — PassKit requires a real `UIViewController` in the live window
  /// hierarchy, which cannot be represented across a platform channel.
  private func present(_ request: PKAddPaymentPassRequest) {
    guard let controller = PKAddPaymentPassViewController(requestConfiguration: .init(encryptionScheme: .ECC_V2)!, delegate: nil) else {
      return
    }
    DispatchQueue.main.async {
      UIApplication.shared.topmostViewController()?.present(controller, animated: true)
    }
  }

  // MARK: - SDK → Pigeon mapping

  /// Kept as small static functions, not initializers on the Pigeon types
  /// themselves — Pigeon regenerates those types from the schema, so any code
  /// added directly to them would be silently deleted on the next `pigeon`
  /// run. Mapping logic has to live outside the generated file.
  private static func toPigeon(_ handle: CardHandle) -> CardHandleData {
    CardHandleData(
      cardHandle: handle.cardHandle,
      issuerId: handle.issuerId,
      lastDigits: handle.lastDigits,
      expiry: handle.exp,
      state: handle.state.rawValue
    )
  }

  private static func toPigeon(_ card: Card) -> ProvisionableCard {
    ProvisionableCard(
      cardReferenceId: card.cardReferenceId,
      issuerId: card.issuerId,
      lastDigits: card.lastDigits,
      expiry: card.exp,
      paymentNetwork: card.paymentNetwork,
      displayName: card.cardDisplayName,
      eligibilityStatus: card.eligibilityStatus.rawValue
    )
  }
}

private extension UIApplication {
  /// Walking `.rootViewController.presentedViewController` until nil is the
  /// standard way to find "whatever the user is currently looking at" without
  /// the app needing to thread a controller reference through to this bridge.
  func topmostViewController() -> UIViewController? {
    guard let root = connectedScenes
      .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
      .first?.rootViewController
    else { return nil }

    var top = root
    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }
}
