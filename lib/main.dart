import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/athlete_service.dart';
import 'services/notification_service.dart';
import 'services/reminder_scheduler.dart';
import 'services/seed_service.dart';
import 'services/theme_provider.dart';
import 'services/pricing_service.dart';
import 'services/photo_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0E1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ─── Initialize database (always internal — no permission needed) ───
  final databaseService = DatabaseService();

  // Restore from external backup if it exists (first launch / reinstall)
  try {
    await databaseService.restoreFromExternal();
  } catch (e) {
    // Restore failed — continue with fresh database
  }

  // One-shot: fix 3000 → 1500 DA prices
  try {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('prices_fixed_1500') ?? false)) {
      await databaseService.fixPrices3000To1500();
      await prefs.setBool('prices_fixed_1500', true);
    }
  } catch (e) {
    // Price fix failed — continue
  }

  // Seed data only if database is empty (first time ever)
  try {
    await seedFromSupabase(databaseService);
  } catch (e) {
    // Seed failed — continue without seed data
  }

  // ─── Request storage permission AFTER app starts (non-blocking) ───
  // This ensures the dialog can show on all devices including Xiaomi/MIUI
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _requestStoragePermission();
  });

  final athleteService = AthleteService(databaseService);
  await athleteService.loadAthletes();
  await athleteService.loadAllMeasurements();

  final notificationService = NotificationService();
  final reminderScheduler = ReminderScheduler();

  try {
    await notificationService.initialize();
    await reminderScheduler.refreshOnAppLaunch();
  } catch (e) {
    // Notification init failed — continue without notifications
  }

  final themeProvider = ThemeProvider();
  final pricingService = PricingService();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<PricingService>.value(value: pricingService),
        ChangeNotifierProvider<AthleteService>.value(value: athleteService),
        Provider<DatabaseService>.value(value: databaseService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<ReminderScheduler>.value(value: reminderScheduler),
      ],
      child: PowerGymApp(onboardingComplete: onboardingComplete),
    ),
  );
}

/// Request storage permissions for external Documents/powergym/ backup
/// - Android 11+: MANAGE_EXTERNAL_STORAGE requires settings redirect
/// - Android 10 and below: standard permission dialog
/// - App works perfectly without this permission (internal DB only)
Future<void> _requestStoragePermission() async {
  if (!Platform.isAndroid) return;

  try {
    // Skip if already granted
    if (await Permission.manageExternalStorage.isGranted) return;

    // On Android 11+ (API 30+), .request() may silently deny on some devices
    // Try requesting first — some devices WILL show the dialog
    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return;

    // If permanently denied or not available, try legacy permission (Android 9 and below)
    final legacyStatus = await Permission.storage.request();
    if (legacyStatus.isGranted) return;

    // On Xiaomi/MIUI and other devices, the dialog may not appear at all.
    // The app continues to work with internal storage — no crash.
    // External backup feature is simply unavailable without this permission.
  } catch (e) {
    // Permission handling failed — app works fine without external storage
  }
}
