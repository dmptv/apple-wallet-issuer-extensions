import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../data/wallet_provisioning_repository.dart';
import '../domain/entities/provisionable_card.dart';

final walletRepositoryProvider =
    Provider<WalletProvisioningRepository>((ref) => getIt<WalletProvisioningRepository>());

/// State for the "add to Apple Wallet" screen: the list of eligible cards,
/// plus which one (if any) is mid-provisioning.
///
/// `Notifier<T>`, not `AsyncNotifier<T>`: `state` here is not "the async
/// result of one operation" but a small hand-rolled state machine with two
/// independent axes (the list, and a per-card "is this one provisioning right
/// now" flag). `AsyncValue` only models one axis well, so forcing this into it
/// would mean stuffing the in-flight card id into the `data` payload — a
/// worse fit than writing the four fields directly.
class WalletState {
  const WalletState({
    this.cards = const [],
    this.isLoading = false,
    this.provisioningCardId,
    this.lastError,
  });

  final List<ProvisionableCard> cards;
  final bool isLoading;

  /// Non-null exactly while a `startProvisioning` call for this id is in
  /// flight — drives a per-row spinner instead of blocking the whole screen.
  final String? provisioningCardId;

  final String? lastError;

  WalletState copyWith({
    List<ProvisionableCard>? cards,
    bool? isLoading,
    String? provisioningCardId,
    bool clearProvisioningCardId = false,
    String? lastError,
    bool clearError = false,
  }) {
    return WalletState(
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      provisioningCardId:
          clearProvisioningCardId ? null : (provisioningCardId ?? this.provisioningCardId),
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
  isAutoDispose: true,
);

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() => const WalletState();

  Future<void> loadEligibleCards({
    required String issuerId,
    required List<String> cardHandles,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cards = await ref.read(walletRepositoryProvider).checkEligibleCards(
            issuerId: issuerId,
            cardHandles: cardHandles,
          );
      if (!ref.mounted) return;
      state = state.copyWith(cards: cards, isLoading: false);
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, lastError: '$error');
    }
  }

  /// Re-entrancy guard, same shape as `CardsNotifier.refresh`: a double-tap on
  /// the same card (or a tap while a previous one is still finishing) must not
  /// start a second native `startProvisioning` call — PassKit does not queue
  /// concurrent add-card flows, it would either crash or present a second
  /// modal on top of the first.
  Future<void> addToWallet(String cardReferenceId) async {
    if (state.provisioningCardId != null) return;

    state = state.copyWith(provisioningCardId: cardReferenceId, clearError: true);
    try {
      await ref.read(walletRepositoryProvider).addToAppleWallet(cardReferenceId);
      if (!ref.mounted) return;
      state = state.copyWith(clearProvisioningCardId: true);
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(clearProvisioningCardId: true, lastError: '$error');
    }
  }
}
