import UIKit

/// Fake implementation of ``SecureCardDisplayService``.
///
/// An `actor` so concurrent callers cannot race on `initialized` — matches
/// how the real SDK's `initialize`/`isInitialized` pair is documented to
/// behave (call once, check status afterwards).
public actor FakeSecureCardDisplayService: SecureCardDisplayService {
  public init() {}

  private var initialized = false

  public func initialize() async throws {
    initialized = true
  }

  public func isInitialized() async -> Bool {
    initialized
  }

  public func getCardDataImage(cardReferenceId: String) async throws -> UIImage {
    try requireInitialized()
    guard let bytes = FakeCardVault.panByCardReferenceId[cardReferenceId] else {
      throw SecureCardDisplayError.unknownCard
    }
    // The one place these bytes exist as a `String` in this whole module:
    // local to this call, alive only long enough to hand to Core Text, gone
    // when the function returns. Nothing stores it, logs it, or returns it.
    let pan = String(decoding: bytes, as: UTF8.self)
    return Self.renderImage(text: Self.grouped(pan, by: 4))
  }

  public func getCardPinImage(cardReferenceId: String) async throws -> UIImage {
    try requireInitialized()
    guard let bytes = FakeCardVault.pinByCardReferenceId[cardReferenceId] else {
      throw SecureCardDisplayError.unknownCard
    }
    let pin = String(decoding: bytes, as: UTF8.self)
    return Self.renderImage(text: pin)
  }

  public func copyPanToClipboard(cardReferenceId: String, ttl: TimeInterval) async throws {
    try requireInitialized()
    guard let bytes = FakeCardVault.panByCardReferenceId[cardReferenceId] else {
      throw SecureCardDisplayError.unknownCard
    }
    let pan = String(decoding: bytes, as: UTF8.self)
    // `expirationDate` is what gives this its TTL — the system clears the
    // pasteboard item itself once it passes, no timer of our own needed.
    UIPasteboard.general.setItems(
      [[UIPasteboard.typeAutomatic: pan]],
      options: [.expirationDate: Date().addingTimeInterval(ttl)]
    )
  }

  public func wipe() async {
    // The real module clears decrypted buffers it holds *between* calls.
    // This fake never retains one past a single call's stack frame, so there
    // is nothing to zero here — the method stays so callers exercise the
    // same lifecycle contract they would against the real SDK.
  }

  private func requireInitialized() throws {
    guard initialized else { throw SecureCardDisplayError.notInitialized }
  }

  private static func grouped(_ digits: String, by size: Int) -> String {
    stride(from: 0, to: digits.count, by: size).map { offset -> String in
      let start = digits.index(digits.startIndex, offsetBy: offset)
      let end = digits.index(start, offsetBy: size, limitedBy: digits.endIndex) ?? digits.endIndex
      return String(digits[start..<end])
    }.joined(separator: " ")
  }

  private static func renderImage(text: String, fontSize: CGFloat = 28) -> UIImage {
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .semibold),
      .foregroundColor: UIColor.label,
    ]
    let size = (text as NSString).size(withAttributes: attributes)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
      (text as NSString).draw(at: .zero, withAttributes: attributes)
    }
  }
}
