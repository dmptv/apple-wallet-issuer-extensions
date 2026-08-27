import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/bank_card.dart';
import '../../domain/repositories/card_repository.dart';

final cardRepositoryProvider =
    Provider<CardRepository>((ref) => getIt<CardRepository>());

/// A single card, addressed by id.
///
/// `family` because the notifier needs an argument (`cardId`) and Riverpod
/// providers are otherwise fixed at declaration time. Each distinct id gets its
/// own independent notifier instance and its own `AsyncValue` — opening two
/// card details does not make them share state.
///
/// This is the provider a screen reached via a **deep link** depends on: it
/// asks the repository for the id from the URL rather than expecting a
/// `BankCard` object to already be sitting in memory.
final cardDetailProvider =
    AsyncNotifierProvider.family<CardDetailNotifier, BankCard?, String>(
  CardDetailNotifier.new,
  isAutoDispose: true,
);

class CardDetailNotifier extends AsyncNotifier<BankCard?> {
  CardDetailNotifier(this._cardId);

  /// The `family` argument, captured by the constructor the provider calls
  /// (`create: (arg) => CardDetailNotifier(arg)`, spelled here as a tear-off).
  /// `AsyncNotifier.build()` itself takes no parameters — this is how the id
  /// reaches it.
  final String _cardId;

  @override
  Future<BankCard?> build() {
    return ref.read(cardRepositoryProvider).getCard(_cardId);
  }
}
