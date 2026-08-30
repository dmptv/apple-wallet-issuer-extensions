// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_reveal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(secureCardDisplayHostApi)
final secureCardDisplayHostApiProvider = SecureCardDisplayHostApiProvider._();

final class SecureCardDisplayHostApiProvider
    extends
        $FunctionalProvider<
          SecureCardDisplayHostApi,
          SecureCardDisplayHostApi,
          SecureCardDisplayHostApi
        >
    with $Provider<SecureCardDisplayHostApi> {
  SecureCardDisplayHostApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureCardDisplayHostApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureCardDisplayHostApiHash();

  @$internal
  @override
  $ProviderElement<SecureCardDisplayHostApi> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SecureCardDisplayHostApi create(Ref ref) {
    return secureCardDisplayHostApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecureCardDisplayHostApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecureCardDisplayHostApi>(value),
    );
  }
}

String _$secureCardDisplayHostApiHash() =>
    r'310f870bf16015d6fcd3dbbc5ed8f7e51ce74e43';

/// Whether the native secure-display view for a given card should be on
/// screen right now, plus the auto-hide countdown.
///
/// `@riverpod class` is `autoDispose` by default, which matters here more
/// than anywhere else in the app: this state gates whether a `UIImageView`
/// holding a decrypted PAN/PIN image exists at all. If a stale provider
/// survived after the reveal screen closed, the image (and the native
/// `wipe()` call) would never happen — exactly the "screen closed but the SDK
/// still thinks it's initialized" bug the reveal flow exists to prevent.

@ProviderFor(CardReveal)
final cardRevealProvider = CardRevealProvider._();

/// Whether the native secure-display view for a given card should be on
/// screen right now, plus the auto-hide countdown.
///
/// `@riverpod class` is `autoDispose` by default, which matters here more
/// than anywhere else in the app: this state gates whether a `UIImageView`
/// holding a decrypted PAN/PIN image exists at all. If a stale provider
/// survived after the reveal screen closed, the image (and the native
/// `wipe()` call) would never happen — exactly the "screen closed but the SDK
/// still thinks it's initialized" bug the reveal flow exists to prevent.
final class CardRevealProvider
    extends $NotifierProvider<CardReveal, CardRevealState> {
  /// Whether the native secure-display view for a given card should be on
  /// screen right now, plus the auto-hide countdown.
  ///
  /// `@riverpod class` is `autoDispose` by default, which matters here more
  /// than anywhere else in the app: this state gates whether a `UIImageView`
  /// holding a decrypted PAN/PIN image exists at all. If a stale provider
  /// survived after the reveal screen closed, the image (and the native
  /// `wipe()` call) would never happen — exactly the "screen closed but the SDK
  /// still thinks it's initialized" bug the reveal flow exists to prevent.
  CardRevealProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardRevealProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardRevealHash();

  @$internal
  @override
  CardReveal create() => CardReveal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CardRevealState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CardRevealState>(value),
    );
  }
}

String _$cardRevealHash() => r'129d4aa8422f3d47b1561a96bbc58c5098be6b8d';

/// Whether the native secure-display view for a given card should be on
/// screen right now, plus the auto-hide countdown.
///
/// `@riverpod class` is `autoDispose` by default, which matters here more
/// than anywhere else in the app: this state gates whether a `UIImageView`
/// holding a decrypted PAN/PIN image exists at all. If a stale provider
/// survived after the reveal screen closed, the image (and the native
/// `wipe()` call) would never happen — exactly the "screen closed but the SDK
/// still thinks it's initialized" bug the reveal flow exists to prevent.

abstract class _$CardReveal extends $Notifier<CardRevealState> {
  CardRevealState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CardRevealState, CardRevealState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CardRevealState, CardRevealState>,
              CardRevealState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
