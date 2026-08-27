import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/widgets/failure_view.dart';
import '../../domain/entities/bank_card.dart';
import '../providers/card_detail_providers.dart';

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

class _CardDetailBody extends StatelessWidget {
  const _CardDetailBody({required this.card});

  final BankCard card;

  @override
  Widget build(BuildContext context) {
    // Deliberately minimal: the PAN/CVV/PIN view is not this screen. That data
    // is rendered by CardSecureDisplay's own UIImage output (see the IDEMIA
    // integration notes) precisely so a full PAN never exists as text
    // anywhere Flutter — or a screenshot — could capture it.
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
        ],
      ),
    );
  }
}
