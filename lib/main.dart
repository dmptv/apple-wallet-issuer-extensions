import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';

/// Composition root.
///
/// `configureDependencies` must finish before `runApp` — `getIt` calls inside
/// widget code assume the graph is already built. `WidgetsFlutterBinding` is
/// required here specifically because this `main` is `async` and touches
/// platform channels (indirectly, through packages) before `runApp`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(environment: Env.dev);
  runApp(const ProviderScope(child: BankApp()));
}

class BankApp extends StatelessWidget {
  const BankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bank App Reference',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      routerConfig: appRouter,
    );
  }
}
