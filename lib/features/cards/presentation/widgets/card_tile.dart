import 'package:flutter/material.dart';

import '../../domain/entities/bank_card.dart';

/// One row in the card list.
///
/// A `StatelessWidget` with a `const` constructor, which is not cosmetic: a
/// const widget is canonicalised by the compiler, so when the parent rebuilds
/// with identical arguments Flutter can skip this subtree entirely instead of
/// re-running `build` and diffing it. On a long list that is the difference
/// between a smooth scroll and dropped frames.
class CardTile extends StatelessWidget {
  const CardTile({required this.card, required this.onTap, super.key});

  final BankCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimmed = !card.isUsable;

    return ListTile(
      onTap: onTap,
      leading: _NetworkBadge(network: card.paymentNetwork, dimmed: dimmed),
      title: Text(
        card.displayName,
        style: theme.textTheme.titleMedium?.copyWith(
          color: dimmed ? theme.disabledColor : null,
        ),
      ),
      subtitle: Text('•••• ${card.lastDigits}   ${card.expiry}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            card.balance.format(),
            style: theme.textTheme.titleMedium?.copyWith(
              // Tabular figures keep the decimal points aligned down the
              // column. Without it, amounts of different widths jitter — the
              // kind of detail a "pixel-perfect" requirement is really about.
              fontFeatures: const [FontFeature.tabularFigures()],
              color: dimmed ? theme.disabledColor : null,
            ),
          ),
          if (dimmed)
            Text(
              _stateLabel(card.state),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }

  static String _stateLabel(CardState state) => switch (state) {
        CardState.active => '',
        CardState.inactive => 'Not activated',
        CardState.suspended => 'Suspended',
        CardState.terminated => 'Closed',
      };
}

class _NetworkBadge extends StatelessWidget {
  const _NetworkBadge({required this.network, required this.dimmed});

  final String network;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dimmed ? scheme.surfaceContainerHighest : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        // Two letters is enough to distinguish networks and avoids shipping
        // brand assets, which carry licensing constraints.
        network.length >= 2 ? network.substring(0, 2).toUpperCase() : network,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
