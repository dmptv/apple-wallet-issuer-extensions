// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(walletRepository)
final walletRepositoryProvider = WalletRepositoryProvider._();

final class WalletRepositoryProvider
    extends
        $FunctionalProvider<
          WalletProvisioningRepository,
          WalletProvisioningRepository,
          WalletProvisioningRepository
        >
    with $Provider<WalletProvisioningRepository> {
  WalletRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletRepositoryHash();

  @$internal
  @override
  $ProviderElement<WalletProvisioningRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WalletProvisioningRepository create(Ref ref) {
    return walletRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletProvisioningRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalletProvisioningRepository>(value),
    );
  }
}

String _$walletRepositoryHash() => r'85d3ce8f2b91c12b64a5a039dd0c40ba44c66526';

@ProviderFor(Wallet)
final walletProvider = WalletProvider._();

final class WalletProvider extends $NotifierProvider<Wallet, WalletState> {
  WalletProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletHash();

  @$internal
  @override
  Wallet create() => Wallet();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalletState>(value),
    );
  }
}

String _$walletHash() => r'1f5bb182e81bd97ecb35d3960514dcd0940d9daf';

abstract class _$Wallet extends $Notifier<WalletState> {
  WalletState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WalletState, WalletState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WalletState, WalletState>,
              WalletState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
