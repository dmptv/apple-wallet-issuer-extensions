import Foundation
import Security

/// The one thing the main app and `CardStatusExtension` share: a small,
/// pre-computed answer to "does this issuer have provisionable cards right
/// now?", written to the Keychain under an App Group access group.
///
/// ## Why Keychain and not, say, `UserDefaults(suiteName:)`
///
/// Both are shared via the same App Group mechanism, but the bank's spec is
/// explicit: card-related data in the extension's reachable storage must live
/// in Keychain, never `UserDefaults`/`CoreData` (see the "Безопасность
/// данных" note on Wallet Extensions). This cache holds no PAN or CVV — only a
/// count and a timestamp — but keeping it in the same storage the real cache
/// will later use keeps this code structurally honest about where sensitive
/// data is allowed to live.
///
/// ## Why the extension can stay under 100ms
///
/// Because by the time `status()` runs, this value has *already* been
/// written — by the main app, at launch or after a card-list refresh. The
/// extension's job is a single Keychain read, not a computation.
enum SharedCardCache {
  /// Must match the App Group configured on both the `Runner` and
  /// `CardStatusExtension` targets' entitlements.
  private static let accessGroup = "group.kz.demo.bankAppReference"
  private static let account = "provisionable_card_summary"
  private static let service = "kz.demo.bankAppReference.cardCache"

  /// Only what the extension needs to build a `PKIssuerProvisioningExtensionPassEntry`
  /// — an id and a display title. Explicitly **not** last-4-digits or network:
  /// the entry the extension shows is Apple's own UI chrome, not a full card
  /// summary, so there is nothing here worth calling sensitive, but the habit
  /// of caching only what is displayed (never PAN/CVV) is the one this file
  /// exists to model correctly.
  struct CardSummary: Codable {
    let cardReferenceId: String
    let displayName: String
  }

  struct Summary: Codable {
    let cards: [CardSummary]
    let cachedAt: Date

    var hasProvisionableCards: Bool { !cards.isEmpty }
  }

  /// Called by the main app whenever the eligible-card list is refreshed —
  /// see `CardTokenizationBridge.checkCards`, which writes here after every
  /// successful call.
  static func write(cards: [CardSummary]) {
    let summary = Summary(cards: cards, cachedAt: Date())
    guard let data = try? JSONEncoder().encode(summary) else { return }

    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccount: account,
      kSecAttrService: service,
      kSecAttrAccessGroup: accessGroup,
    ]

    // Keychain has no upsert primitive: delete-then-add is the standard
    // pattern, and it is cheap enough that doing it on every write is not a
    // concern here (writes happen on app launch / refresh, not per frame).
    SecItemDelete(query as CFDictionary)

    var addQuery = query
    addQuery[kSecValueData] = data
    addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
    SecItemAdd(addQuery as CFDictionary, nil)
  }

  /// Called by `CardStatusExtension.status()`. A single `SecItemCopyMatching`
  /// call — no network, no disk beyond the Keychain's own store — is what
  /// keeps this comfortably under the SDK's 100ms budget.
  static func read() -> Summary? {
    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccount: account,
      kSecAttrService: service,
      kSecAttrAccessGroup: accessGroup,
      kSecReturnData: true,
      kSecMatchLimit: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data else { return nil }
    return try? JSONDecoder().decode(Summary.self, from: data)
  }
}
