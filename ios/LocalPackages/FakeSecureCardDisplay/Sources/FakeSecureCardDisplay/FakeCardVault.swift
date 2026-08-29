import Foundation

/// Fake backing store standing in for the real SDK's own encrypted-at-rest,
/// decrypted-on-demand vault.
///
/// Deliberately **not** a database (SQLCipher/GRDB or otherwise). The bank's
/// IDEMIA spec explicitly forbids persisting card data in
/// UserDefaults/CoreData/Keychain (see its "Нефункциональные требования"
/// section) — any on-device persistent store is extra attack surface once
/// the device is jailbroken, encrypted-at-rest or not, because the key to
/// decrypt it has to live on the device too. Hardcoded, compiled-in bytes are
/// the closest fake analogue to "already resolved by the real SDK's own
/// private memory, never touched by our code as text or written to disk".
///
/// Stored as `[UInt8]`, not `String` — a `String` is not guaranteed to be
/// zeroed by simply dropping the reference (copy-on-write buffers, small
/// string optimization), so callers that need to "forget" a value work with
/// bytes they can overwrite in place.
enum FakeCardVault {
  // Two call sites in the app use two different fake id namespaces for the
  // same two demo cards: the Wallet-provisioning flow's `handle-visa-1`/
  // `handle-mc-1` (from `FakeInAppPushProvisioningService`) and the card
  // list's `card-1`/`card-2` (from `FakeCardRemoteDataSource`, Dart-side).
  // Both are aliased to the same underlying bytes here rather than picking
  // one — reconciling the two fake id schemes into a single source of truth
  // is a real fix that belongs on the Dart side, not something this display
  // module should paper over silently.
  static let panByCardReferenceId: [String: [UInt8]] = [
    "handle-visa-1": Array("4242424242424242".utf8),
    "handle-mc-1": Array("5500000000008890".utf8),
    "card-1": Array("4242424242424242".utf8),
    "card-2": Array("5500000000008890".utf8),
  ]

  static let pinByCardReferenceId: [String: [UInt8]] = [
    "handle-visa-1": Array("1234".utf8),
    "handle-mc-1": Array("4321".utf8),
    "card-1": Array("1234".utf8),
    "card-2": Array("4321".utf8),
  ]
}
