import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/bank_card.dart';
import '../../domain/repositories/card_repository.dart';

part 'card_detail_providers.g.dart';

@riverpod
CardRepository cardRepository(Ref ref) => getIt<CardRepository>();

/// A single card, addressed by id.
///
/// A family provider (the generator infers this from `build`'s parameter)
/// because the notifier needs an argument (`cardId`) and Riverpod providers
/// are otherwise fixed at declaration time. Each distinct id gets its own
/// independent notifier instance and its own `AsyncValue` — opening two card
/// details does not make them share state.
///
/// This is the provider a screen reached via a **deep link** depends on: it
/// asks the repository for the id from the URL rather than expecting a
/// `BankCard` object to already be sitting in memory.
@riverpod
class CardDetail extends _$CardDetail {
  @override
  Future<BankCard?> build(String cardId) {
    return ref.read(cardRepositoryProvider).getCard(cardId);
  }
}
