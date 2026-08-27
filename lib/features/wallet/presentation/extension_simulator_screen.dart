import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/native/wallet_extension_simulator_api.g.dart';

final _simulatorApiProvider =
    Provider<WalletExtensionSimulatorHostApi>((ref) => WalletExtensionSimulatorHostApi());

/// Reproduces, step by step and driven by our own button instead of the real
/// Apple Wallet, the sequence documented in the bank's spec:
///
///   Wallet opens → status() [<100ms budget] → (if requiresAuthentication)
///   UI Extension biometric prompt → passEntries() → cards shown
///
/// What this screen proves: the *logic* is correct and the *timing budget* is
/// achievable, because `status()` only reads a Keychain value the main app
/// wrote earlier — never that the *real* Wallet will call this code, which
/// stays unverifiable without the issuer entitlement. Each step below says so
/// explicitly rather than implying more than it demonstrates.
class ExtensionSimulatorScreen extends ConsumerStatefulWidget {
  const ExtensionSimulatorScreen({super.key});

  @override
  ConsumerState<ExtensionSimulatorScreen> createState() => _ExtensionSimulatorScreenState();
}

enum _Step { idle, checkingStatus, authenticating, loadingEntries, done, deniedNoEntries, authFailed }

class _ExtensionSimulatorScreenState extends ConsumerState<ExtensionSimulatorScreen> {
  _Step _step = _Step.idle;
  ExtensionStatusResult? _status;
  List<PassEntryData> _entries = const [];
  String? _error;

  Future<void> _runFlow() async {
    final api = ref.read(_simulatorApiProvider);
    setState(() {
      _step = _Step.checkingStatus;
      _error = null;
      _entries = const [];
    });

    try {
      // Step 1 — the gate check every Wallet-installed-app answers before
      // Apple decides whether to list it at all.
      final status = await api.simulateStatus();
      setState(() => _status = status);

      if (!status.passEntriesAvailable) {
        setState(() => _step = _Step.deniedNoEntries);
        return;
      }

      if (status.requiresAuthentication) {
        setState(() => _step = _Step.authenticating);
        final authenticated = await api.authenticate();
        if (!authenticated) {
          setState(() => _step = _Step.authFailed);
          return;
        }
      }

      // Step 3 — only reached after status + (optional) auth pass, exactly
      // as the real Wallet sequence gates it.
      setState(() => _step = _Step.loadingEntries);
      final entries = await api.simulatePassEntries();
      setState(() {
        _entries = entries;
        _step = _Step.done;
      });
    } catch (error) {
      setState(() {
        _error = '$error';
        _step = _Step.idle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulate Wallet Extension')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'This calls the same ServiceProvider and AuthViewController '
                'classes the real CardStatusExtension.appex and '
                'CardAuthUIExtension.appex use — but called directly from '
                'this app, not by Apple Wallet. It proves the logic and '
                'timing, not that the system will ever invoke them for real.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _step == _Step.idle || _step == _Step.done ? _runFlow : null,
            child: const Text('Step 2 — Simulate opening Apple Wallet'),
          ),
          const SizedBox(height: 24),
          _StepTile(
            label: 'status() — gate check',
            active: _step == _Step.checkingStatus,
            done: _status != null,
            detail: _status == null
                ? null
                : '${_status!.elapsedMicroseconds} µs   '
                    'passEntriesAvailable=${_status!.passEntriesAvailable}   '
                    'requiresAuth=${_status!.requiresAuthentication}',
            // The bank's spec budget is ~100ms = 100,000µs. Flagging red this
            // early is the whole point of measuring natively rather than
            // trusting that "it's just a Keychain read" is fast enough.
            warn: _status != null && _status!.elapsedMicroseconds > 100000,
          ),
          if (_step == _Step.deniedNoEntries)
            const _InfoBanner(
              'No cards in the cache — same as a fresh install Wallet '
              'has never seen this app in. Open the cards screen first '
              'to populate SharedCardCache.',
            ),
          if (_status?.requiresAuthentication ?? false) ...[
            _StepTile(
              label: 'Face ID / Touch ID (CardAuthUIExtension)',
              active: _step == _Step.authenticating,
              done: _step.index > _Step.authenticating.index,
            ),
            if (_step == _Step.authFailed)
              const _InfoBanner('Authentication was cancelled or failed.'),
          ],
          _StepTile(
            label: 'passEntries() — cards Wallet would render',
            active: _step == _Step.loadingEntries,
            done: _step == _Step.done,
          ),
          if (_error != null) _InfoBanner('Error: $_error'),
          if (_entries.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._entries.map(
              (e) => ListTile(
                leading: const Icon(Icons.credit_card),
                title: Text(e.displayName),
                subtitle: Text(e.cardReferenceId),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.label,
    required this.active,
    required this.done,
    this.detail,
    this.warn = false,
  });

  final String label;
  final bool active;
  final bool done;
  final String? detail;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final icon = active
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done
                ? (warn ? Theme.of(context).colorScheme.error : Colors.green)
                : Theme.of(context).disabledColor,
          );

    return ListTile(
      leading: icon,
      title: Text(label),
      subtitle: detail == null
          ? null
          : Text(
              detail!,
              style: warn ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
            ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}
