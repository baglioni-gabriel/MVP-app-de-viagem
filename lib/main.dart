import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

import 'config/theme.dart';
import 'config/routes.dart';

/// Entry point for the Wayv travel social network.
///
/// Initialisation order:
///   1. Flutter engine
///   2. Environment variables (.env)
///   3. Firebase SDK
///   4. Run the app inside a Riverpod [ProviderScope]
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  await dotenv.load(fileName: '.env');

  // Firebase — initialise with platform-specific options.
  // TODO: Replace with DefaultFirebaseOptions after running `flutterfire configure`
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: TravelSocialApp(),
    ),
  );
}

/// Root widget — wraps the app with the GoRouter and the design theme.
///
/// Uses [ConsumerWidget] so the router can react to provider changes
/// (e.g. auth state) and refresh its redirect logic.
class TravelSocialApp extends ConsumerWidget {
  const TravelSocialApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Wayv',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
