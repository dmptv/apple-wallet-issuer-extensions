import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../domain/entities/provisionable_card.dart';
import 'wallet_provider.dart';

/// Exercises the full chain end to end:
/// button tap → Notifier → Repository → generated Pigeon client
///   → MethodChannel → IdemiaCardBridge.swift → FakeDigitalCardSdk → back
///   → SharedCardCache (Keychain).
///
/// The load is triggered by an explicit button, not `initState`, on purpose:
/// this screen doubles as the "step 1" of a two-step manual demo —
///   (1) here: fetch cards, which as a side effect populates the Keychain
///       cache `CardStatusExtension`/`ServiceProvider` will later read;
///   (2) on `ExtensionSimulatorScreen`: replay what Wallet would do with
///       that cache, independently, on demand.
/// Splitting them into two taps makes the "app pre-computes, extension only
/// reads" ordering visible instead of implicit in a screen's lifecycle.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Apple Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Simulate Wallet Extension',
            onPressed: () => context.push(AppRoutes.extensionSimulator),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              // Step 1 of the manual demo: fetches cards from the native
              // bridge and — as a side effect inside `IdemiaCardBridge.checkCards`
              // — writes their summaries into `SharedCardCache` (Keychain,
              // shared via the App Group with `CardStatusExtension`). Nothing
              // downstream of this tap is visible in the UI; the only way to
              // see it happened is the extension simulator screen reading it back.
              icon: const Icon(Icons.download_outlined),
              label: const Text('Step 1 — Load cards & save to Keychain'),
              onPressed: state.isLoading
                  ? null
                  : () => ref.read(walletProvider.notifier).loadEligibleCards(
                        issuerId: 'issuer-1',
                        cardHandles: ['handle-visa-1', 'handle-mc-1'],
                      ),
            ),
          ),
          if (state.lastError != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(12),
              child: Text(state.lastError!),
            ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: state.cards.length,
                    itemBuilder: (context, index) {
                      final card = state.cards[index];
                      final isProvisioning = state.provisioningCardId == card.cardReferenceId;
                      return ListTile(
                        key: ValueKey(card.cardReferenceId),
                        title: Text(card.displayName),
                        subtitle: Text('•••• ${card.lastDigits}   ${card.paymentNetwork}'),
                        trailing: isProvisioning
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : FilledButton(
                                // `canProvision` gates the button, not just its
                                // visual state — the native `startProvisioning`
                                // call is never attempted for a card PassKit
                                // already rejected, matching the SDK docs'
                                // "only eligible/alreadyProvisioned can proceed"
                                // rule.
                                onPressed: card.eligibility.canProvision
                                    ? () => ref
                                        .read(walletProvider.notifier)
                                        .addToWallet(card.cardReferenceId)
                                    : null,
                                child: Text(_buttonLabel(card.eligibility)),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static String _buttonLabel(WalletEligibility eligibility) => switch (eligibility) {
        WalletEligibility.eligible => 'Add to Wallet',
        WalletEligibility.nonEligible => 'Not eligible',
        WalletEligibility.alreadyProvisioned => 'Already added',
        WalletEligibility.alreadyProvisionedOnPhone => 'Added on iPhone',
        WalletEligibility.alreadyProvisionedOnWatch => 'Added on Watch',
        WalletEligibility.unknown => 'Unavailable',
      };
}
