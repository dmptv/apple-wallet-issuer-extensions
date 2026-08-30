// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_detail_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cardRepository)
final cardRepositoryProvider = CardRepositoryProvider._();

final class CardRepositoryProvider
    extends $FunctionalProvider<CardRepository, CardRepository, CardRepository>
    with $Provider<CardRepository> {
  CardRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardRepositoryHash();

  @$internal
  @override
  $ProviderElement<CardRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CardRepository create(Ref ref) {
    return cardRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CardRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CardRepository>(value),
    );
  }
}

String _$cardRepositoryHash() => r'f179758871461a5c2ec5f0d4fbb29642837d4d9d';

/// A single card, addressed by id.
///
/// A family provider (the generator infers this from `build`'s parameter)
/// because the notifier needs an argument (`cardId`) and Riverpod providers
/// are otherwise fixed at declaration time. Each distinct id gets its own
/// independent notifier instance and its own `AsyncValue` — opening two card
/// details does not make them share state.
///
/// This is the provider a screen reached via a **deep link** depends on: it
/// asks the repository for the id from the URL rather than expecting a
/// `BankCard` object to already be sitting in memory.

@ProviderFor(CardDetail)
final cardDetailProvider = CardDetailFamily._();

/// A single card, addressed by id.
///
/// A family provider (the generator infers this from `build`'s parameter)
/// because the notifier needs an argument (`cardId`) and Riverpod providers
/// are otherwise fixed at declaration time. Each distinct id gets its own
/// independent notifier instance and its own `AsyncValue` — opening two card
/// details does not make them share state.
///
/// This is the provider a screen reached via a **deep link** depends on: it
/// asks the repository for the id from the URL rather than expecting a
/// `BankCard` object to already be sitting in memory.
final class CardDetailProvider
    extends $AsyncNotifierProvider<CardDetail, BankCard?> {
  /// A single card, addressed by id.
  ///
  /// A family provider (the generator infers this from `build`'s parameter)
  /// because the notifier needs an argument (`cardId`) and Riverpod providers
  /// are otherwise fixed at declaration time. Each distinct id gets its own
  /// independent notifier instance and its own `AsyncValue` — opening two card
  /// details does not make them share state.
  ///
  /// This is the provider a screen reached via a **deep link** depends on: it
  /// asks the repository for the id from the URL rather than expecting a
  /// `BankCard` object to already be sitting in memory.
  CardDetailProvider._({
    required CardDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cardDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cardDetailHash();

  @override
  String toString() {
    return r'cardDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CardDetail create() => CardDetail();

  @override
  bool operator ==(Object other) {
    return other is CardDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cardDetailHash() => r'9e017980eb4c432251d135321385c6a789327f3c';

/// A single card, addressed by id.
///
/// A family provider (the generator infers this from `build`'s parameter)
/// because the notifier needs an argument (`cardId`) and Riverpod providers
/// are otherwise fixed at declaration time. Each distinct id gets its own
/// independent notifier instance and its own `AsyncValue` — opening two card
/// details does not make them share state.
///
/// This is the provider a screen reached via a **deep link** depends on: it
/// asks the repository for the id from the URL rather than expecting a
/// `BankCard` object to already be sitting in memory.

final class CardDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          CardDetail,
          AsyncValue<BankCard?>,
          BankCard?,
          FutureOr<BankCard?>,
          String
        > {
  CardDetailFamily._()
    : super(
        retry: null,
        name: r'cardDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A single card, addressed by id.
  ///
  /// A family provider (the generator infers this from `build`'s parameter)
  /// because the notifier needs an argument (`cardId`) and Riverpod providers
  /// are otherwise fixed at declaration time. Each distinct id gets its own
  /// independent notifier instance and its own `AsyncValue` — opening two card
  /// details does not make them share state.
  ///
  /// This is the provider a screen reached via a **deep link** depends on: it
  /// asks the repository for the id from the URL rather than expecting a
  /// `BankCard` object to already be sitting in memory.

  CardDetailProvider call(String cardId) =>
      CardDetailProvider._(argument: cardId, from: this);

  @override
  String toString() => r'cardDetailProvider';
}

/// A single card, addressed by id.
///
/// A family provider (the generator infers this from `build`'s parameter)
/// because the notifier needs an argument (`cardId`) and Riverpod providers
/// are otherwise fixed at declaration time. Each distinct id gets its own
/// independent notifier instance and its own `AsyncValue` — opening two card
/// details does not make them share state.
///
/// This is the provider a screen reached via a **deep link** depends on: it
/// asks the repository for the id from the URL rather than expecting a
/// `BankCard` object to already be sitting in memory.

abstract class _$CardDetail extends $AsyncNotifier<BankCard?> {
  late final _$args = ref.$arg as String;
  String get cardId => _$args;

  FutureOr<BankCard?> build(String cardId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BankCard?>, BankCard?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BankCard?>, BankCard?>,
              AsyncValue<BankCard?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
