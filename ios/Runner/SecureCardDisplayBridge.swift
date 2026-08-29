import FakeSecureCardDisplay
import Flutter

/// Implements the Pigeon-generated `SecureCardDisplayHostApi`.
///
/// Owns the one shared `FakeSecureCardDisplayService` instance for the
/// process — `SecureCardDisplayPlatformView` reads from the same instance
/// via `SecureCardDisplayBridge.service`, so `initialize()`/`wipe()` called
/// from Dart actually affect what the platform view renders.
final class SecureCardDisplayBridge: SecureCardDisplayHostApi {
  static let service = FakeSecureCardDisplayService()

  func initialize(completion: @escaping (Result<Void, Error>) -> Void) {
    Task {
      do {
        try await Self.service.initialize()
        completion(.success(()))
      } catch {
        completion(.failure(error))
      }
    }
  }

  func isInitialized(completion: @escaping (Result<Bool, Error>) -> Void) {
    Task {
      completion(.success(await Self.service.isInitialized()))
    }
  }

  func copyPanToClipboard(
    cardReferenceId: String,
    ttlSeconds: Double,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    Task {
      do {
        try await Self.service.copyPanToClipboard(cardReferenceId: cardReferenceId, ttl: ttlSeconds)
        completion(.success(()))
      } catch {
        completion(.failure(error))
      }
    }
  }

  func wipe(completion: @escaping (Result<Void, Error>) -> Void) {
    Task {
      await Self.service.wipe()
      completion(.success(()))
    }
  }
}
