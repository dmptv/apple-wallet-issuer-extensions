import 'package:injectable/injectable.dart';

import '../../../../core/di/injection.dart';
import '../models/card_dto.dart';
import 'card_remote_data_source.dart';

/// Stands in for the real backend during local UI work.
///
/// Bound only under [Env.dev] — see the `@Environment` annotation — so it can
/// never accidentally ship in a production build; `injection.config.dart` would
/// have no `prod` registration for [CardRemoteDataSource] if this were the only
/// implementation, which turns "fake shipped to prod" into a build-time error
/// instead of an incident.
@LazySingleton(as: CardRemoteDataSource, env: [Env.dev])
class FakeCardRemoteDataSource implements CardRemoteDataSource {
  @override
  Future<List<CardDto>> fetchCards() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const [
      CardDto(
        id: 'card-1',
        displayName: 'Everyday Visa',
        lastDigits: '4242',
        expiry: '0928',
        paymentNetwork: 'VISA',
        state: 'ACTIVE',
        balanceMinor: 1254300,
        currency: 'KZT',
      ),
      CardDto(
        id: 'card-2',
        displayName: 'Savings Mastercard',
        lastDigits: '8890',
        expiry: '0327',
        paymentNetwork: 'MASTERCARD',
        state: 'SUSPENDED',
        balanceMinor: 42000,
        currency: 'USD',
      ),
    ];
  }
}
