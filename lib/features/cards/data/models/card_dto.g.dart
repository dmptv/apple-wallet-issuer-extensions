// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardDto _$CardDtoFromJson(Map<String, dynamic> json) => CardDto(
  id: json['cardReferenceId'] as String,
  displayName: json['cardDisplayName'] as String,
  lastDigits: json['lastDigits'] as String,
  expiry: json['exp'] as String,
  paymentNetwork: json['paymentNetwork'] as String,
  state: json['state'] as String,
  balanceMinor: (json['balanceMinorUnits'] as num).toInt(),
  currency: json['currency'] as String,
);

Map<String, dynamic> _$CardDtoToJson(CardDto instance) => <String, dynamic>{
  'cardReferenceId': instance.id,
  'cardDisplayName': instance.displayName,
  'lastDigits': instance.lastDigits,
  'exp': instance.expiry,
  'paymentNetwork': instance.paymentNetwork,
  'state': instance.state,
  'balanceMinorUnits': instance.balanceMinor,
  'currency': instance.currency,
};
