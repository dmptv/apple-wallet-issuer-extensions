import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

/// The service locator.
///
/// Only `injection.dart` and the Riverpod bridge providers are allowed to touch
/// this. Reaching for `getIt<Something>()` from inside a widget or a repository
/// turns the locator into a global variable and hides real dependencies — the
/// classic complaint about service locators, and it is avoidable purely by
/// discipline: everything else receives its dependencies through constructors.
final getIt = GetIt.instance;

/// GENERATED: `injection.config.dart` — produced by `injectable_generator`
/// from the `@injectable` / `@LazySingleton` annotations across the codebase.
/// Regenerate with:
///   dart run build_runner build --delete-conflicting-outputs
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies({String? environment}) async {
  getIt.init(environment: environment);
}

/// Environment names used by `@Environment(...)` on registrations.
///
/// This is how the same graph serves a real backend, a mocked one for UI work,
/// and the test suite — without a single `if (kDebugMode)` in the app code.
abstract final class Env {
  static const dev = 'dev';
  static const prod = 'prod';
  static const test = 'test';
}
