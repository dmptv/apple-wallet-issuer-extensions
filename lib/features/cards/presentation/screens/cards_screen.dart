import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/failure_view.dart';
import '../providers/cards_providers.dart';
import '../widgets/card_tile.dart';

/// The card list.
///
/// `ConsumerWidget`, not `ConsumerStatefulWidget`: there is no local state here.
/// Everything the screen shows comes from the provider, and everything it does
/// goes back through the notifier. A screen with no `setState` is a screen with
/// no state-synchronisation bugs.
class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.wallet_outlined),
            tooltip: 'Add to Apple Wallet',
            onPressed: () => context.push(AppRoutes.wallet),
          ),
        ],
        // `isRefreshing` is true only when loading arrived on top of existing
        // data (via copyWithPrevious). This is what lets the list stay on
        // screen with a small progress hint instead of being replaced.
        bottom: cards.isRefreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(cardsProvider.notifier).refresh(),
        child: cards.when(
          // `skipLoadingOnRefresh` is the default and is what we want: during a
          // refresh the previous data keeps rendering, and only a genuine
          // first-load shows the spinner.
          data: (list) => _CardList(cards: list),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => FailureView(
            failure: error is Failure ? error : UnknownFailure(cause: error),
            onRetry: () => ref.read(cardsProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }
}

class _CardList extends StatelessWidget {
  const _CardList({required this.cards});

  final List<dynamic> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      // The empty state must still scroll, otherwise RefreshIndicator has
      // nothing to pull on and the user cannot retry. `AlwaysScrollable` is the
      // fix; forgetting it is a very common bug in exactly this layout.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No cards yet')),
        ],
      );
    }

    // `.builder`, never a `Column` inside a `SingleChildScrollView`: builder
    // constructs only the visible rows plus a small cache extent, so memory and
    // build cost stay flat regardless of list length.
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return CardTile(
          card: card,
          // A stable key tied to the identity of the data, not to the position.
          // Without it, deleting a card would leave the removed row's state
          // attached to whatever slid into its place.
          key: ValueKey(card.id),
          onTap: () => context.push(AppRoutes.cardDetail(card.id)),
        );
      },
    );
  }
}
