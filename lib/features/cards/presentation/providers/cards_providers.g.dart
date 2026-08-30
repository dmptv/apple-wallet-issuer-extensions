// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cards_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bridge from the get_it graph into Riverpod.
///
/// ## Why two DI mechanisms at all
///
/// Riverpod is itself a dependency-injection container, so having get_it beside
/// it looks redundant. The split is deliberate:
///
///  * **get_it + injectable** owns the data and domain graph — repositories,
///    data sources, the Dio instance. Those have no relationship to the widget
///    tree, and annotating them keeps the wiring generated instead of
///    hand-maintained.
///  * **Riverpod** owns presentation state — things with a lifecycle tied to
///    screens, that must be overridable per test and per widget subtree.
///
/// This is also what the job market asks for: `get_it`/`injectable` appear as
/// an explicit requirement independent of the state-management choice.
///
/// The seam below is what makes it testable: override this one provider and
/// the entire data layer is replaced, without get_it ever being touched.

@ProviderFor(watchCards)
final watchCardsProvider = WatchCardsProvider._();

/// Bridge from the get_it graph into Riverpod.
///
/// ## Why two DI mechanisms at all
///
/// Riverpod is itself a dependency-injection container, so having get_it beside
/// it looks redundant. The split is deliberate:
///
///  * **get_it + injectable** owns the data and domain graph — repositories,
///    data sources, the Dio instance. Those have no relationship to the widget
///    tree, and annotating them keeps the wiring generated instead of
///    hand-maintained.
///  * **Riverpod** owns presentation state — things with a lifecycle tied to
///    screens, that must be overridable per test and per widget subtree.
///
/// This is also what the job market asks for: `get_it`/`injectable` appear as
/// an explicit requirement independent of the state-management choice.
///
/// The seam below is what makes it testable: override this one provider and
/// the entire data layer is replaced, without get_it ever being touched.

final class WatchCardsProvider
    extends $FunctionalProvider<WatchCards, WatchCards, WatchCards>
    with $Provider<WatchCards> {
  /// Bridge from the get_it graph into Riverpod.
  ///
  /// ## Why two DI mechanisms at all
  ///
  /// Riverpod is itself a dependency-injection container, so having get_it beside
  /// it looks redundant. The split is deliberate:
  ///
  ///  * **get_it + injectable** owns the data and domain graph — repositories,
  ///    data sources, the Dio instance. Those have no relationship to the widget
  ///    tree, and annotating them keeps the wiring generated instead of
  ///    hand-maintained.
  ///  * **Riverpod** owns presentation state — things with a lifecycle tied to
  ///    screens, that must be overridable per test and per widget subtree.
  ///
  /// This is also what the job market asks for: `get_it`/`injectable` appear as
  /// an explicit requirement independent of the state-management choice.
  ///
  /// The seam below is what makes it testable: override this one provider and
  /// the entire data layer is replaced, without get_it ever being touched.
  WatchCardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchCardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchCardsHash();

  @$internal
  @override
  $ProviderElement<WatchCards> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchCards create(Ref ref) {
    return watchCards(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchCards value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchCards>(value),
    );
  }
}

String _$watchCardsHash() => r'55040e70e57f63bbc954c8a126fdabcdccde0009';

/// The card list, as the UI consumes it.
///
/// `@riverpod class` generates an `autoDispose` provider by default — this
/// state belongs to a screen, so a background refresh must not keep running
/// after the user navigates away. Opting into `keepAlive: true` would be the
/// escape hatch if that were ever wrong here; it isn't.

@ProviderFor(Cards)
final cardsProvider = CardsProvider._();

/// The card list, as the UI consumes it.
///
/// `@riverpod class` generates an `autoDispose` provider by default — this
/// state belongs to a screen, so a background refresh must not keep running
/// after the user navigates away. Opting into `keepAlive: true` would be the
/// escape hatch if that were ever wrong here; it isn't.
final class CardsProvider
    extends $StreamNotifierProvider<Cards, List<BankCard>> {
  /// The card list, as the UI consumes it.
  ///
  /// `@riverpod class` generates an `autoDispose` provider by default — this
  /// state belongs to a screen, so a background refresh must not keep running
  /// after the user navigates away. Opting into `keepAlive: true` would be the
  /// escape hatch if that were ever wrong here; it isn't.
  CardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardsHash();

  @$internal
  @override
  Cards create() => Cards();
}

String _$cardsHash() => r'7ee076dd8eb5d4e9adb2a0adbd593ef6d13388fa';

/// The card list, as the UI consumes it.
///
/// `@riverpod class` generates an `autoDispose` provider by default — this
/// state belongs to a screen, so a background refresh must not keep running
/// after the user navigates away. Opting into `keepAlive: true` would be the
/// escape hatch if that were ever wrong here; it isn't.

abstract class _$Cards extends $StreamNotifier<List<BankCard>> {
  Stream<List<BankCard>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<BankCard>>, List<BankCard>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BankCard>>, List<BankCard>>,
              AsyncValue<List<BankCard>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
