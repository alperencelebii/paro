import 'core/app_initializer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

/// Main entry point for the application
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dotenv first (before any code that uses ApiConstants)
  // Try to load .env file, but don't crash if it doesn't exist
  // Note: .env file must be added to pubspec.yaml assets if it exists
  await loadEnv();

  // Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize the app
  await initializeApp();
}

// TODO: TO Make Any Feature Premium 
// 
/// if not premium then show purchases page

  // void _requirePremium(VoidCallback onAllowed) {
  //   final subscriptionCubit = context.read<SubscriptionCubit>();
  //   // final purchasesCubit = context.read<PurchasesCubit>();
  //   subscriptionCubit.ensureProStatus().then((isPro) {
  //     if (!mounted) return;
  //     if (isPro) {
  //       onAllowed();
  //     } else {
  //       // purchasesCubit.loadOfferings();
  //       context.pushNamed(AppRoutes.purchasesPage);
  //     }
  //   });
  // }


  /// on call
  /// onPressed: () {
  ///   _requirePremium(() {
  ///     context.pushNamed(AppRoutes.budgetSettings);
  ///   });
  /// },