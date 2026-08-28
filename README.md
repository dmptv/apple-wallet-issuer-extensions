# Apple Wallet Issuer Extensions — Flutter Reference

A reference Flutter project demonstrating how a bank's mobile app integrates
with **Apple Wallet's In-App Provisioning** — both the flow that runs *inside*
the app, and the two native Wallet Extensions that let a user add a card
*without* opening the app at all.

## The two provisioning paths

1. **In-app**: the user taps "Add to Apple Wallet" inside the app. The app
   talks to a card-tokenization SDK (modeled here on IDEMIA's Digital Card
   SDK) through a Swift bridge, which drives PassKit directly.
2. **From Apple Wallet / Settings, app not running**: iOS launches two
   separate `.appex` targets in their own processes — a Non-UI extension
   that answers "do you have cards to offer?" in under 100ms, and a UI
   extension that gates the flow behind Face ID/Touch ID. Neither extension
   can talk to the app directly; both read a cache the app populated in
   advance, via a Keychain item shared through an App Group.

A debug screen in the app drives both extension classes directly (they're
also compiled into the main target) so the logic and the 100ms budget are
verifiable without the Apple-issued entitlement that real Wallet invocation
requires.

## Architecture

Clean Architecture, feature-first: `domain` (entities, repository
interfaces, use cases) has zero dependency on `data` or `presentation`, so
business rules compile and could be tested without Dio, sqflite, or a
backend anywhere in the graph.

```
lib/
├── core/           # cross-feature: network, database, DI, error, router
└── features/
    ├── cards/      # offline-first card list (domain / data / presentation)
    └── wallet/     # provisioning + the native bridge
```

## Frameworks and why

| Framework | Role | Why this one |
|---|---|---|
| **flutter_riverpod** | State management | Compile-safe DI without `BuildContext`, testable via `ProviderContainer` outside the widget tree, `isAutoDispose` gives explicit control over a provider's lifetime — needed here so a screen's polling/timer state dies when the screen does. |
| **get_it** + **injectable** | Data/domain-layer DI | Riverpod handles presentation-layer state well; it's not the tool for wiring a large graph of repositories and data sources that have nothing to do with the widget tree. `injectable`'s code-generated registration (`@LazySingleton`, `@Environment`) keeps that graph declarative instead of hand-assembled in one giant function. |
| **dio** | HTTP client | Interceptor chain is what makes the single-flight auth-refresh and the exception-translation boundary (`ErrorInterceptor` → typed `AppException`) possible without scattering `try/catch` across every call site. |
| **go_router** | Navigation | Declarative routes, nested routing (`/cards/:id`), and URL-addressable screens — the baseline a deep link or push notification needs, which an ad-hoc `Navigator.push` tree doesn't give you. |
| **sqflite** | Local cache | Chosen over `drift` deliberately: visible, hand-written SQL over a generated ORM, so every query in this reference project is readable without trusting a code generator. Also sidesteps a real `analyzer` version conflict between `drift_dev` and Riverpod 3's tooling. |
| **pigeon** | Dart ↔ Swift bridge | Generates a typed client/host pair from one Dart schema — the alternative, a hand-written `MethodChannel` with manual `Map<String, dynamic>` (de)serialization on both sides, is exactly where platform-channel bugs live. Two separate schemas (`idemia_card_api.dart`, `wallet_extension_simulator_api.dart`) keep the production bridge and the debug-only harness from ever being confused with each other. |
| **mocktail** | Test doubles | No code generation, plain Dart mocks/spies — kept deliberately light; this project caps test depth per feature by design (breadth across the platform mattered more here than exhaustive coverage). |

## Native layer (`ios/`)

- **`Runner/IdemiaCardBridge.swift`** — implements the Pigeon-generated host
  API, translating between Pigeon's plain data types and the SDK's own
  (`CardHandle`, `Card`, `Eligibility`, …).
- **`Runner/FakeDigitalCardSdk.swift`** — a local mirror of the real IDEMIA
  SDK's public surface (types copied from its `.swiftinterface`, not
  invented), backing a deterministic fake implementation. The real
  `.xcframework` needs an Apple-issued issuer entitlement
  (`com.apple.developer.payment-pass-provisioning`) that a personal
  developer account cannot obtain — swapping the fake for the real SDK later
  touches this one file only.
- **`CardStatusExtension/ServiceProvider.swift`** — the real Non-UI Issuer
  Provisioning Extension, subclassing PassKit's
  `PKIssuerProvisioningExtensionHandler`.
- **`CardAuthUIExtension/AuthViewController.swift`** — the real UI
  extension, conforming to
  `PKIssuerProvisioningExtensionAuthorizationProviding`.
- **`Runner/SharedCardCache.swift`** — the Keychain-backed, App-Group-shared
  cache both extensions and the main app read/write. Compiled into all three
  targets.

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Regenerating the native bridge after editing a `pigeons/*.dart` schema:

```bash
dart run pigeon --input pigeons/idemia_card_api.dart
dart run pigeon --input pigeons/wallet_extension_simulator_api.dart
```
