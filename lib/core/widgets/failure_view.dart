import 'package:flutter/material.dart';

import '../error/failures.dart';

/// Turns a [Failure] into something a user can act on.
///
/// One switch, in one file, is what the mapping in `failure_mapper.dart` was
/// for: every screen in the app renders errors identically, and a new
/// [Failure] subtype is a compiler error here until it is handled — the same
/// exhaustiveness guarantee the sealed class gives on the way in.
class FailureView extends StatelessWidget {
  const FailureView({required this.failure, required this.onRetry, super.key});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, text, showRetry) = switch (failure) {
      NetworkFailure() => (
          Icons.wifi_off,
          'No connection. Check your network and try again.',
          true,
        ),
      // Never show `message` for auth failures — an issuer's session-expiry
      // text can leak details about why access was revoked.
      UnauthorizedFailure() => (
          Icons.lock_outline,
          'Your session expired. Please sign in again.',
          false,
        ),
      BusinessFailure(:final code) => (
          Icons.info_outline,
          _businessMessage(code),
          false,
        ),
      ServerFailure() => (
          Icons.dns_outlined,
          'Something went wrong on our end. Please try again shortly.',
          true,
        ),
      CacheFailure() => (
          Icons.storage_outlined,
          'Could not read local data.',
          true,
        ),
      UnknownFailure() => (
          Icons.error_outline,
          'Unexpected error. Please try again.',
          true,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (showRetry) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }

  /// The mapping from Appendix A of the SDK spec is exactly this shape:
  /// server-defined code in, user-safe copy out, one entry per code.
  static String _businessMessage(String code) => switch (code) {
        'CARD_EXPIRED' => 'This card has expired. Please reissue it.',
        'CARD_LOCKED' => 'This card is locked. Contact support.',
        'CARD_SUSPENDED' => 'This card is temporarily suspended.',
        'CARD_TERMINATED' => 'This card is no longer active.',
        'CARD_NOT_FOUND' => 'Please check the card details and try again.',
        _ => 'This action could not be completed.',
      };
}
