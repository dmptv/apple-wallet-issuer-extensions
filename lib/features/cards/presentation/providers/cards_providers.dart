import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/bank_card.dart';
import '../../domain/usecases/watch_cards.dart';

part 'cards_providers.g.dart';

/// Bridge from the get_it graph into Riverpod.
///
/// ## Why two DI mechanisms at all
///
/// Riverpod is itself a dependency-injection container, so having get_it beside
/// it looks redundant. The split is deliberate:
///
///  * **get_it + injectable** owns the data and domain graph — repositories,
///    data sources, the Dio instance. Those have no relationship to the widget
///    tree, and annotating them keeps the wiring generated instead of
///    hand-maintained.
///  * **Riverpod** owns presentation state — things with a lifecycle tied to
///    screens, that must be overridable per test and per widget subtree.
///
/// This is also what the job market asks for: `get_it`/`injectable` appear as
/// an explicit requirement independent of the state-management choice.
///
/// The seam below is what makes it testable: override this one provider and
/// the entire data layer is replaced, without get_it ever being touched.
@riverpod
WatchCards watchCards(Ref ref) => getIt<WatchCards>();

/// The card list, as the UI consumes it.
///
/// `@riverpod class` generates an `autoDispose` provider by default — this
/// state belongs to a screen, so a background refresh must not keep running
/// after the user navigates away. Opting into `keepAlive: true` would be the
/// escape hatch if that were ever wrong here; it isn't.
@riverpod
class Cards extends _$Cards {
  /// Runs on first listen. Riverpod wraps the stream in `AsyncValue`
  /// automatically: `loading` until the first event, then `data`, and `error`
  /// if the stream throws — so no manual state juggling is needed here.
  @override
  Stream<List<BankCard>> build() {
    return ref.read(watchCardsProvider)();
  }

  /// Pull-to-refresh.
  ///
  /// The important line is `copyWithPrevious`: it marks the state as loading
  /// **while keeping the current list attached**, so the UI can show a spinner
  /// in the app bar without blanking the content. Assigning a bare
  /// `AsyncValue.loading()` would drop the data and flash an empty screen on
  /// every refresh.
  Future<void> refresh() async {
    if (_refreshing) return; // re-entrancy guard: see note below
    _refreshing = true;

    // `copyWithPrevious` is `@internal` to the riverpod package — using it
    // outside is a documented, widely-used escape hatch (there is no public
    // equivalent yet) for exactly this "loading, but keep showing the old
    // value" case. Flagged here rather than silenced globally so the trade-off
    // stays visible at the call site.
    // ignore: invalid_use_of_internal_member
    state = const AsyncValue<List<BankCard>>.loading().copyWithPrevious(state);

    try {
      await for (final cards in ref.read(watchCardsProvider)(forceRefresh: true)) {
        // The provider may have been disposed while the network was in flight
        // (user navigated away). Writing to a disposed notifier throws.
        if (!ref.mounted) return;
        state = AsyncValue.data(cards);
      }
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      // ignore: invalid_use_of_internal_member
      final errorState = AsyncValue<List<BankCard>>.error(error, stackTrace);
      // ignore: invalid_use_of_internal_member
      state = errorState.copyWithPrevious(state);
    } finally {
      _refreshing = false;
    }
  }

  /// Guards against overlapping refreshes — a user can pull twice, and a
  /// timer-driven refresh can land on top of a manual one.
  ///
  /// Two refreshes of the *same* data are not "the latest wins": cancelling
  /// the in-flight one and restarting would starve if the request is slower
  /// than the trigger interval. Ignoring the second call guarantees progress.
  ///
  /// The check and the assignment sit with no `await` between them, so on a
  /// single-threaded isolate the check-then-act cannot interleave.
  bool _refreshing = false;
}
