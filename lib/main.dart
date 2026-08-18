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

  // ─── Request storage permissions ───
  try {
    if (Platform.isAndroid) {
      await _requestStoragePermission();
    }
  } catch (e) {
    // Permission failed — continue with internal storage
  }

  // ─── Initialize database ───
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

  // ─── Sync photos from Supabase ───
  try {
    final photoSync = PhotoSyncService();
    await photoSync.syncPhotos();
  } catch (e) {
    // Photo sync failed — continue without photos
  }

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

/// Request storage permissions for external Documents/powergym/ access
Future<void> _requestStoragePermission() async {
  try {
    // Android 11+ (API 30+): MANAGE_EXTERNAL_STORAGE for full access
    if (await Permission.manageExternalStorage.isGranted) return;

    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return;

    // Fallback: try legacy storage permission
    final legacyStatus = await Permission.storage.request();
    if (legacyStatus.isGranted) return;

    // If still denied, app will use internal storage fallback
  } catch (e) {
    // Permission handling failed — continue with internal storage
  }
}
