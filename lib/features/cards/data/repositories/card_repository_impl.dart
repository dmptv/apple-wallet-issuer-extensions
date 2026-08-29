import 'package:injectable/injectable.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../domain/entities/bank_card.dart';
import '../../domain/repositories/card_repository.dart';
import '../datasources/card_local_data_source.dart';
import '../datasources/card_remote_data_source.dart';

/// Offline-first implementation: cache first, network second, cache updated.
///
/// This is the "stale-while-revalidate" pattern. The user sees data on the
/// first frame even with no connection; fresh data replaces it when it arrives.
@LazySingleton(as: CardRepository)
class CardRepositoryImpl implements CardRepository {
  const CardRepositoryImpl({
    required this._remote,
    required this._local,
  });

  final CardRemoteDataSource _remote;
  final CardLocalDataSource _local;

  @override
  Stream<List<BankCard>> watchCards({bool forceRefresh = false}) async* {
    var emittedFromCache = false;

    if (!forceRefresh) {
      try {
        final cached = await _local.readCards();
        // An empty cache is not worth emitting: it would make the UI flash an
        // "empty" state for a moment before the network fills it in. Better to
        // stay in `loading` until there is something real to show.
        if (cached.isNotEmpty) {
          emittedFromCache = true;
          yield cached;
        }
      } catch (_) {
        // A broken cache must never block the network path — the app should
        // still work with a corrupted database, just slower.
      }
    }

    try {
      final dtos = await _remote.fetchCards();
      final cards = dtos.map((dto) => dto.toEntity()).toList(growable: false);

      // Written before yielding so that a listener reacting to this emission
      // (e.g. by navigating and re-reading the cache) cannot observe stale
      // rows. Ordering matters more than it looks.
      await _local.replaceAll(cards);
      yield cards;
    } catch (error) {
      // The decisive rule of offline-first: if the user is already looking at
      // cached data, a failed refresh is not an error state. Replacing visible
      // content with an error screen is strictly worse than showing data that
      // is a few minutes old.
      //
      // A production app would surface this as a subtle "not up to date"
      // indicator rather than swallowing it entirely.
      if (!emittedFromCache) {
        throw mapExceptionToFailure(error);
      }
    }
  }

  @override
  Future<BankCard?> getCard(String id) async {
    try {
      return await _local.readCard(id);
    } catch (error) {
      throw mapExceptionToFailure(error);
    }
  }
}
