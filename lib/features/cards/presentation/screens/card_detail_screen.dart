import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/widgets/failure_view.dart';
import '../../domain/entities/bank_card.dart';
import '../providers/card_detail_providers.dart';
import '../providers/card_reveal_provider.dart';
import '../widgets/secure_card_display_view.dart';

/// Reached either by tapping a [CardTile] or, cold-start, straight from a
/// notification deep link — `context.push('/cards/$id')` with nothing else in
/// memory. The screen depends only on [cardId] and re-derives everything else
/// through [cardDetailProvider], so both paths behave identically.
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({required this.cardId, super.key});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(cardDetailProvider(cardId));

    return Scaffold(
      appBar: AppBar(title: const Text('Card details')),
      body: card.when(
        data: (card) => card == null
            ? const Center(child: Text('Card not found'))
            : _CardDetailBody(card: card),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FailureView(
          failure: error is Failure ? error : UnknownFailure(cause: error),
          onRetry: () => ref.invalidate(cardDetailProvider(cardId)),
        ),
      ),
    );
  }
}

class _CardDetailBody extends ConsumerWidget {
  const _CardDetailBody({required this.card});

  final BankCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reveal = ref.watch(cardRevealProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.displayName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('•••• ${card.lastDigits}'),
          Text('Expires ${card.expiry}'),
          Text(card.paymentNetwork),
          const SizedBox(height: 16),
          Text(
            card.balance.format(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          // The full PAN never becomes Dart text anywhere on this screen —
          // see `SecureCardDisplayView` and `IdemiaCardBridge` notes for why.
          if (reveal.isVisible) ...[
            SizedBox(
              height: 60,
              child: SecureCardDisplayView(cardReferenceId: card.id),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hides in ${reveal.remainingSeconds}s'),
                TextButton(
                  onPressed: () => ref.read(cardRevealProvider.notifier).hide(),
                  child: const Text('Hide'),
                ),
              ],
            ),
          ] else
            OutlinedButton(
              onPressed: () => ref.read(cardRevealProvider.notifier).reveal(),
              child: const Text('Show full card number'),
            ),
        ],
      ),
    );
  }
}
