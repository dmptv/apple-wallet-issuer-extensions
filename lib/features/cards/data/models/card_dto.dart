import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/bank_card.dart';
import '../../domain/entities/money.dart';

part 'card_dto.g.dart';

/// Wire format for a card.
///
/// ## Why a DTO and not the entity directly
///
/// The entity is shaped by what the app needs; the DTO is shaped by what the
/// backend happens to send. Keeping them separate means a renamed JSON field
/// or a new API version changes exactly one file, and the domain never learns
/// that `state` arrives as the string `"ACTIVE"` rather than an enum.
///
/// It costs a mapping function. That cost is the point — the mapper is where
/// unknown enum values, nulls, and format surprises are handled once.
///
/// GENERATED: `card_dto.g.dart` (fromJson/toJson) — run `build_runner`.
@JsonSerializable()
class CardDto {
  const CardDto({
    required this.id,
    required this.displayName,
    required this.lastDigits,
    required this.expiry,
    required this.paymentNetwork,
    required this.state,
    required this.balanceMinor,
    required this.currency,
  });

  factory CardDto.fromJson(Map<String, dynamic> json) => _$CardDtoFromJson(json);

  @JsonKey(name: 'cardReferenceId')
  final String id;

  @JsonKey(name: 'cardDisplayName')
  final String displayName;

  @JsonKey(name: 'lastDigits')
  final String lastDigits;

  /// `MMYY` on the wire — reformatted for display during mapping.
  @JsonKey(name: 'exp')
  final String expiry;

  @JsonKey(name: 'paymentNetwork')
  final String paymentNetwork;

  /// Raw string; intentionally not decoded into the enum by the generator so
  /// that an unknown value cannot throw during deserialisation.
  @JsonKey(name: 'state')
  final String state;

  @JsonKey(name: 'balanceMinorUnits')
  final int balanceMinor;

  @JsonKey(name: 'currency')
  final String currency;

  Map<String, dynamic> toJson() => _$CardDtoToJson(this);

  BankCard toEntity() {
    return BankCard(
      id: id,
      displayName: displayName,
      lastDigits: lastDigits,
      expiry: _formatExpiry(expiry),
      paymentNetwork: paymentNetwork,
      state: _parseState(state),
      balance: Money(minorUnits: balanceMinor, currency: currency),
    );
  }

  /// `"0226"` → `"02/26"`. Left as-is when the input is not the expected shape:
  /// a malformed expiry is a cosmetic problem, not a reason to fail the whole
  /// card list.
  static String _formatExpiry(String raw) {
    if (raw.length != 4) return raw;
    return '${raw.substring(0, 2)}/${raw.substring(2)}';
  }

  /// Unknown states map to `inactive` rather than throwing.
  ///
  /// This is the safe default in a payments context: if the backend introduces
  /// `PENDING_ACTIVATION` tomorrow, an old build treats the card as unusable —
  /// annoying but harmless. Defaulting to `active` would let a card the issuer
  /// considers restricted look spendable.
  static CardState _parseState(String raw) {
    return switch (raw.toUpperCase()) {
      'ACTIVE' => CardState.active,
      'NOT_ACTIVE' || 'INACTIVE' => CardState.inactive,
      'SUSPENDED' => CardState.suspended,
      'TERMINATED' => CardState.terminated,
      _ => CardState.inactive,
    };
  }
}
