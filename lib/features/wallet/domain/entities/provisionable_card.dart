/// Domain shape of a card eligible for Apple Wallet provisioning.
///
/// A separate entity from `BankCard` (the balance-list card) on purpose: this
/// one exists only in the provisioning flow's vocabulary — `cardHandle`,
/// `eligibilityStatus` — fields `BankCard` has no business knowing about.
/// Merging them would leak SDK-specific concepts into the card-list feature
/// that has nothing to do with Apple Wallet.
enum WalletEligibility {
  eligible,
  nonEligible,
  alreadyProvisioned,
  alreadyProvisionedOnPhone,
  alreadyProvisionedOnWatch,
  unknown;

  /// Mirrors `CardDto._parseState`: unknown values fall back to the safest
  /// reading rather than throwing, because the SDK is free to add new
  /// statuses without warning.
  static WalletEligibility fromRaw(String raw) => switch (raw) {
        'eligible' => WalletEligibility.eligible,
        'nonEligible' => WalletEligibility.nonEligible,
        'alreadyProvisioned' => WalletEligibility.alreadyProvisioned,
        'alreadyProvisionedOnPhone' => WalletEligibility.alreadyProvisionedOnPhone,
        'alreadyProvisionedOnWatch' => WalletEligibility.alreadyProvisionedOnWatch,
        _ => WalletEligibility.unknown,
      };

  bool get canProvision => this == WalletEligibility.eligible;
}

class ProvisionableCard {
  const ProvisionableCard({
    required this.cardReferenceId,
    required this.lastDigits,
    required this.expiry,
    required this.paymentNetwork,
    required this.displayName,
    required this.eligibility,
  });

  final String cardReferenceId;
  final String lastDigits;
  final String expiry;
  final String paymentNetwork;
  final String displayName;
  final WalletEligibility eligibility;
}
