import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/cards/presentation/screens/card_detail_screen.dart';
import '../../features/cards/presentation/screens/cards_screen.dart';
import '../../features/wallet/presentation/extension_simulator_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';

/// Route table.
///
/// Routes are declared centrally rather than with anonymous `Navigator.push`
/// calls scattered across widgets. The payoff is not tidiness: it is that every
/// screen becomes addressable by URL, which is what deep links, push
/// notifications and `restorationId` all need.
///
/// Note what is passed between screens: an **id**, never the object. A route is
/// a URL; it must survive a cold start from a push notification, when no card
/// object exists in memory yet. The destination screen re-reads the card from
/// the repository by id.
abstract final class AppRoutes {
  static const cards = '/cards';

  /// `/cards/:id` — the detail screen.
  static String cardDetail(String id) => '/cards/$id';

  /// Not nested under `/cards` — reaching it does not require an existing
  /// card, only issuer/handle values (a real screen would carry them via
  /// query parameters or extra data), so it stands on its own.
  static const wallet = '/wallet';

  static const extensionSimulator = '/wallet/extension-simulator';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.cards,
  routes: [
    GoRoute(
      path: AppRoutes.cards,
      name: 'cards',
      builder: (context, state) => const CardsScreen(),
      routes: [
        // Nested route: `/cards/:id`. Nesting (rather than a flat
        // `/card-detail`) makes `pop` land on the list automatically, and it
        // reflects the real hierarchy — a card detail has no meaning without
        // the list it belongs to.
        GoRoute(
          path: ':id',
          name: 'cardDetail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return CardDetailScreen(cardId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.wallet,
      name: 'wallet',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: AppRoutes.extensionSimulator,
      name: 'extensionSimulator',
      builder: (context, state) => const ExtensionSimulatorScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Not found')),
    body: Center(child: Text('No route for ${state.uri}')),
  ),
);
