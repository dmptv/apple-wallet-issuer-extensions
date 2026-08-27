import 'package:injectable/injectable.dart';

import '../entities/bank_card.dart';
import '../repositories/card_repository.dart';

/// One business operation: "show me my cards".
///
/// ## Is a use case worth it here?
///
/// Honest answer: for a pure pass-through it is ceremony. This one earns its
/// place by holding a rule that is *not* the repository's business — hiding
/// terminated cards, and ordering usable cards first — so the rule lives in one
/// place instead of being re-implemented by every screen that lists cards.
///
/// If a use case ever reduces to `=> repository.something()` with no added
/// behaviour, delete it and let the notifier depend on the repository. A layer
/// that only forwards is a layer that only costs.
@injectable
class WatchCards {
  const WatchCards(this._repository);

  final CardRepository _repository;

  /// `call` lets the class be invoked like a function: `watchCards()`.
  Stream<List<BankCard>> call({bool forceRefresh = false}) {
    return _repository.watchCards(forceRefresh: forceRefresh).map(_present);
  }

  List<BankCard> _present(List<BankCard> cards) {
    // A terminated card is gone for good — showing it only invites support
    // calls. Suspended cards stay visible because the user can act on them.
    final visible = cards.where((c) => c.state != CardState.terminated).toList();

    visible.sort((a, b) {
      // Usable cards first; within each group, the biggest balance first.
      if (a.isUsable != b.isUsable) return a.isUsable ? -1 : 1;
      if (a.balance.currency == b.balance.currency) {
        return b.balance.compareTo(a.balance);
      }
      // Different currencies cannot be compared without a rate — fall back to
      // a stable, meaningless-but-deterministic order rather than throwing.
      return a.displayName.compareTo(b.displayName);
    });

    return visible;
  }
}
