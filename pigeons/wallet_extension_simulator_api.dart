import 'package:pigeon/pigeon.dart';

/// A debug-only channel to the Wallet Extension's logic, called directly by
/// our own UI instead of by the real Apple Wallet.
///
/// This is intentionally a **separate** Pigeon file from `card_tokenization_api.dart`:
/// that one describes production API surface (what the app calls to talk to
/// the SDK); this one describes a test harness that will not exist once real
/// device testing with the issuer entitlement is possible. Keeping them apart
/// means deleting the harness later is a two-file removal, not a search for
/// which methods in a shared file were "the real ones."
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/native/wallet_extension_simulator_api.g.dart',
    swiftOut: 'ios/Runner/WalletExtensionSimulatorApi.g.swift',
    dartPackageName: 'bank_app_reference',
    // `PigeonError` is generated fresh, at file (not namespaced) scope, by
    // every Pigeon input — fine when each `.g.swift` lands in its own target,
    // but `card_tokenization_api.dart` already generated one into the same `Runner`
    // target. Disabling it here and letting the other file's copy be the only
    // one is exactly the documented escape hatch for "another generated Swift
    // file in the same directory."
    swiftOptions: SwiftOptions(includeErrorClass: false),
  ),
)
class ExtensionStatusResult {
  ExtensionStatusResult({
    required this.passEntriesAvailable,
    required this.requiresAuthentication,
    required this.elapsedMicroseconds,
  });

  final bool passEntriesAvailable;
  final bool requiresAuthentication;

  /// Measured natively, around the exact call the real Wallet times against
  /// its ~100ms budget — see `ExtensionSimulatorBridge.simulateStatus`. Kept
  /// as a plain int rather than a `Duration` because Pigeon has no `Duration`
  /// type; the Dart side converts it back.
  final int elapsedMicroseconds;
}

class PassEntryData {
  PassEntryData({required this.cardReferenceId, required this.displayName});

  final String cardReferenceId;
  final String displayName;
}

@HostApi()
abstract class WalletExtensionSimulatorHostApi {
  /// Instantiates `ServiceProvider` (the same class the real extension uses)
  /// and calls `status(completion:)` directly — a plain method call, not a
  /// system-routed one — timing it the way Wallet's own 100ms budget would.
  @async
  ExtensionStatusResult simulateStatus();

  /// `LAContext.evaluatePolicy` with Face ID/Touch ID — the same
  /// authentication gate `requiresAuthentication` would trigger for a real
  /// UI Extension, run here as a plain call from the main app instead of a
  /// second `.appex` process.
  @async
  bool authenticate();

  /// Calls `ServiceProvider.passEntries(completion:)` directly, mapping the
  /// resulting `PKIssuerProvisioningExtensionPassEntry` array to plain data.
  @async
  List<PassEntryData> simulatePassEntries();
}
