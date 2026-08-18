import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/theme_provider.dart';
import 'theme/sport_design.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/athletes_screen.dart';
import 'screens/athlete_detail_screen.dart';
import 'screens/add_athlete_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/coach_profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/pricing_settings_screen.dart';

class PowerGymApp extends StatefulWidget {
  final bool onboardingComplete;

  const PowerGymApp({super.key, required this.onboardingComplete});

  @override
  State<PowerGymApp> createState() => _PowerGymAppState();
}

class _PowerGymAppState extends State<PowerGymApp> {
  late bool _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _onboardingComplete = widget.onboardingComplete;
  }

  void _completeOnboarding() {
    setState(() => _onboardingComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PowerGym',
          debugShowCheckedModeBanner: false,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeProvider.themeMode,
          home: _onboardingComplete ? const DashboardScreen() : WelcomeScreen(onComplete: _completeOnboarding),
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DARK THEME - Cinematic Sport
  // ═══════════════════════════════════════════════════════════════════
  ThemeData _buildDarkTheme() {
    const Color primaryColor = SportColors.primary;
    const Color secondaryColor = SportColors.green;
    const Color accentColor = SportColors.cyan;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: SportFonts.medium,
      textTheme: sportTextTheme(Brightness.dark),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: SportColors.surfaceDark,
        error: SportColors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: SportColors.bgDark,
      cardColor: SportColors.cardDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: SportColors.bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: SportFonts.black,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: SportColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 12,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SportColors.surfaceDark,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SportColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SportColors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: Colors.white54, fontFamily: SportFonts.medium),
        hintStyle: const TextStyle(color: Colors.white30),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: SportFonts.condensed,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontFamily: SportFonts.condensed, fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.06), thickness: 1),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LIGHT THEME - Clean Sport
  // ═══════════════════════════════════════════════════════════════════
  ThemeData _buildLightTheme() {
    const Color primaryColor = SportColors.primary;
    const Color secondaryColor = Color(0xFF059669);
    const Color accentColor = Color(0xFF0891B2);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: SportFonts.medium,
      textTheme: sportTextTheme(Brightness.light),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: SportColors.surfaceLight,
        error: Color(0xFFDC2626),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: SportColors.textLight,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: SportColors.bgLight,
      cardColor: SportColors.cardLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: SportColors.bgLight,
        elevation: 0,
        centerTitle: false,
        foregroundColor: SportColors.textLight,
        titleTextStyle: TextStyle(
          fontFamily: SportFonts.black,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: SportColors.textLight,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: SportColors.textLight),
      ),
      cardTheme: CardThemeData(
        color: SportColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SportColors.surfaceLight,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: SportFonts.condensed,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontFamily: SportFonts.condensed, fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      dividerTheme: DividerThemeData(color: Colors.black.withValues(alpha: 0.06), thickness: 1),
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/welcome':
        return MaterialPageRoute(builder: (_) => WelcomeScreen(onComplete: () {}));
      case '/':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/athletes':
        return MaterialPageRoute(builder: (_) => const AthletesScreen());
      case '/athlete-detail':
        final athleteId = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => AthleteDetailScreen(athleteId: athleteId ?? ''));
      case '/add-athlete':
        return MaterialPageRoute(builder: (_) => const AddAthleteScreen());
      case '/edit-athlete':
        final athleteId = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => AddAthleteScreen(athleteId: athleteId));
      case '/subscriptions':
        return MaterialPageRoute(builder: (_) => const SubscriptionsScreen());
      case '/coach-profile':
        return MaterialPageRoute(builder: (_) => const CoachProfileScreen());
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case '/pricing':
        return MaterialPageRoute(builder: (_) => const PricingSettingsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
    }
  }
}
