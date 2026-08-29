import 'money.dart';

/// Lifecycle of a card as the issuer sees it.
///
/// Mirrors the states a tokenisation platform reports (the card-tokenization
/// SDK's `CardState` uses the same four), which keeps the mapping at the
/// data boundary trivial.
enum CardState { active, inactive, suspended, terminated }

/// A payment card, as the rest of the app understands it.
///
/// Deliberately **does not** carry the PAN, CVV, or expiry-with-year in a form
/// usable for a transaction. Those never enter the domain layer at all: they
/// are shown by a dedicated secure-display component and are not part of any
/// object that could end up in a log line, a crash report, or a cache.
///
/// The class is immutable with an explicit `copyWith`. `freezed` would generate
/// this; it is written by hand here so that nothing about the core model is
/// hidden behind codegen.
class BankCard {
  const BankCard({
    required this.id,
    required this.displayName,
    required this.lastDigits,
    required this.expiry,
    required this.paymentNetwork,
    required this.state,
    required this.balance,
  });

  /// Stable issuer-side identifier. Survives reissue of the physical card,
  /// which is why it — and not the PAN — is the key everywhere.
  final String id;

  final String displayName;

  /// Last four digits. Safe to display and to log.
  final String lastDigits;

  /// `MM/YY`. Kept as text: it is a label, never used for date arithmetic.
  final String expiry;

  /// `VISA`, `MASTERCARD`, `UZCARD`, `HUMO`…
  final String paymentNetwork;

  final CardState state;
  final Money balance;

  /// Whether the card can be used at all right now.
  ///
  /// This lives in the entity rather than in the UI because it is a business
  /// rule: if the definition changes, every screen should change with it.
  bool get isUsable => state == CardState.active;

  BankCard copyWith({
    String? id,
    String? displayName,
    String? lastDigits,
    String? expiry,
    String? paymentNetwork,
    CardState? state,
    Money? balance,
  }) {
    return BankCard(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      lastDigits: lastDigits ?? this.lastDigits,
      expiry: expiry ?? this.expiry,
      paymentNetwork: paymentNetwork ?? this.paymentNetwork,
      state: state ?? this.state,
      balance: balance ?? this.balance,
    );
  }

  /// Value equality matters for more than tests: Riverpod and Flutter both skip
  /// rebuilds when the new value equals the old one. Without `==`, every
  /// refresh that returns identical data would still repaint the list.
  @override
  bool operator ==(Object other) =>
      other is BankCard &&
      other.id == id &&
      other.displayName == displayName &&
      other.lastDigits == lastDigits &&
      other.expiry == expiry &&
      other.paymentNetwork == paymentNetwork &&
      other.state == state &&
      other.balance == balance;

  @override
  int get hashCode => Object.hash(
        id,
        displayName,
        lastDigits,
        expiry,
        paymentNetwork,
        state,
        balance,
      );

  /// No PAN here, and none should ever be added — `toString` output reaches
  /// crash reporters.
  @override
  String toString() => 'BankCard($id, •••• $lastDigits, $state)';
}
