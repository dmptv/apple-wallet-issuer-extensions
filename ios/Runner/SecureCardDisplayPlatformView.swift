import FakeSecureCardDisplay
import Flutter
import UIKit

/// Hosts a `UIImageView` showing the rendered PAN or PIN image, entirely on
/// the native side.
///
/// This is the only place `FakeSecureCardDisplayService.getCardDataImage`/
/// `getCardPinImage` is called. The `UIImage` they return never leaves this
/// class — it goes straight into `imageView.image`, never serialized, never
/// handed back across the Pigeon boundary. Flutter only knows this view
/// exists; it has no access to what is drawn inside it.
final class SecureCardDisplayPlatformView: NSObject, FlutterPlatformView {
  private let imageView = UIImageView()

  /// - Parameters:
  ///   - cardReferenceId: which fake card's data to render.
  ///   - kind: `"pan"` or `"pin"` — which of the two fake images to show.
  init(cardReferenceId: String, kind: String) {
    super.init()
    imageView.contentMode = .center
    imageView.backgroundColor = .secondarySystemBackground

    Task {
      do {
        let image = kind == "pin"
          ? try await SecureCardDisplayBridge.service.getCardPinImage(cardReferenceId: cardReferenceId)
          : try await SecureCardDisplayBridge.service.getCardDataImage(cardReferenceId: cardReferenceId)
        await MainActor.run { self.imageView.image = image }
      } catch {
        // A fake-data lookup miss (unknown id) or a `wipe()`/not-initialized
        // race — nothing sensitive to show, so the view just stays blank
        // rather than surfacing an error UI here. The Dart side already
        // knows the initialize/wipe lifecycle via `SecureCardDisplayHostApi`.
      }
    }
  }

  func view() -> UIView { imageView }
}

/// Registered in `AppDelegate` under the view type name `"secure_card_display_view"`,
/// which the Dart-side `UiKitView` must reference by the same string.
final class SecureCardDisplayPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    let params = args as? [String: Any]
    return SecureCardDisplayPlatformView(
      cardReferenceId: params?["cardReferenceId"] as? String ?? "",
      kind: params?["kind"] as? String ?? "pan"
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}
