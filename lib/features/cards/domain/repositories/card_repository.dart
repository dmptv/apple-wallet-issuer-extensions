import '../entities/bank_card.dart';

/// The contract the domain depends on. The implementation lives in `data/`.
///
/// This inversion is the whole point of Clean Architecture: `domain` imports
/// nothing from `data`, so business rules can be compiled and tested without
/// Dio, sqflite, or a running backend anywhere in the graph.
abstract interface class CardRepository {
  /// Cards for the signed-in customer, newest state first.
  ///
  /// Returns a stream rather than a Future because the repository is
  /// offline-first: it emits the cached list immediately (so the screen has
  /// content on the first frame), then emits again when the network responds.
  ///
  /// The alternative — a Future that resolves only after the network — is
  /// simpler, but it means a blank screen on every cold start and nothing at
  /// all when offline.
  ///
  /// Errors: emits a `Failure` through the stream's error channel. A network
  /// failure *after* a successful cache emission is deliberately swallowed by
  /// the implementation — stale data beats an error banner over data the user
  /// can already see.
  Stream<List<BankCard>> watchCards({bool forceRefresh = false});

  /// A single card. Reads cache first, same contract as above.
  Future<BankCard?> getCard(String id);
}
