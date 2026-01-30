import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/database/database.dart';
import 'core/di/providers.dart';
import 'presentation/providers/theme_provider.dart';
import 'services/background/background_service.dart';
import 'services/notification/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize database
  final database = AppDatabase();
  
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize background service
  await BackgroundService.initialize();

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      notificationServiceProvider.overrideWithValue(notificationService),
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
  );

  // Process scheduled rules on app start (catch-up mechanism)
  try {
    await BackgroundService.processScheduledRulesFromContainer(database, notificationService);
  } catch (e) {
    // Log error but don't prevent app from starting
    debugPrint('Error processing scheduled rules: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FinanceApp(),
    ),
  );
}
