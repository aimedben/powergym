import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/athlete_service.dart';
import '../services/theme_provider.dart';
import '../models/athlete.dart';
import '../models/subscription.dart';
import '../theme/sport_design.dart';
import '../widgets/stat_card.dart';
import '../widgets/athlete_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/sport_section_header.dart';
import '../widgets/sport_button.dart';
import 'athletes_screen.dart';
import 'subscriptions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _gymName = 'PowerGym Seddouk';
  int _expiredCount = 0;
  int _notifCount = 0;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gymName = prefs.getString('coach_gym') ?? 'PowerGym Seddouk';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  void _updateCounts(AthleteService service) {
    int expired = 0;
    int notif = 0;
    for (final athlete in service.athletes) {
      if (athlete.id == null) continue;
      final sub = service.getLatestSubscription(athlete.id!);
      if (sub == null) continue;
      if (sub.status == SubscriptionStatus.expired) {
        expired++;
        notif++;
      } else if (sub.status == SubscriptionStatus.expiringSoon) {
        final days = sub.daysUntilExpiry;
        if (days <= 7) notif++;
      }
      if (!sub.isPaid) notif++;
    }
    _expiredCount = expired;
    _notifCount = notif;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Si on n'est pas sur l'onglet Accueil, y retourner
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
        // Si déjà sur Accueil → ne rien faire (ne jamais quitter l'app)
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/dash.jpg', fit: BoxFit.cover),
            ),
            IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboardContent(),
                const _AthletesTab(),
                const _SubscriptionsTab(),
                _buildSettingsTab(),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Consumer<AthleteService>(
      builder: (context, athleteService, child) {
        final athletes = athleteService.athletes;
        final stats = athleteService.getStats();
        _updateCounts(athleteService);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(),
                    const SizedBox(height: 28),
                    _buildStatsGrid(stats),
                    const SizedBox(height: 28),
                    const SportSectionHeader(
                      title: 'Actions Rapides',
                      icon: Icons.bolt,
                      accentColor: SportColors.cyan,
                    ),
                    const SizedBox(height: 14),
                    _buildQuickActions(),
                    const SizedBox(height: 28),
                    _buildExpiringSoon(athleteService),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeHeader() {
    final textColor = Colors.white;
    final subColor = Colors.white70;
    final iconBg = Colors.white.withValues(alpha: 0.10);
    final iconColor = Colors.white70;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: sportPrimaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: SportColors.primary.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('assets/logo.png', width: 44, height: 44, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POWERGYM',
                    style: TextStyle(
                      fontFamily: SportFonts.black,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 1.5,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ATHLETE MANAGEMENT',
                    style: TextStyle(
                      fontFamily: SportFonts.condensed,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: subColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/notifications'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.notifications_none_rounded, color: iconColor, size: 22),
                    if (_notifCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _notifCount > 9 ? '9+' : '$_notifCount',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, int> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        StatCard(icon: Icons.people, value: stats['total'] ?? 0, label: 'Total', color: SportColors.primaryBright),
        StatCard(icon: Icons.check_circle, value: stats['active'] ?? 0, label: 'Actifs', color: SportColors.green),
        StatCard(icon: Icons.warning, value: stats['expiring'] ?? 0, label: 'Expirants', color: SportColors.amber),
        StatCard(icon: Icons.cancel, value: stats['expired'] ?? 0, label: 'Expirés', color: SportColors.red),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: SportButton(
            label: 'AJOUTER',
            icon: Icons.person_add,
            gradient: sportPrimaryGradient,
            height: 50,
            onPressed: () => Navigator.pushNamed(context, '/add-athlete'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SportButton(
            label: 'VOIR TOUS',
            icon: Icons.people,
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
            ),
            height: 50,
            onPressed: () => setState(() => _currentIndex = 1),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiringSoon(AthleteService athleteService) {
    final now = DateTime.now();
    final textColor = Colors.white;
    final subColor = Colors.white70;
    
    // Collect athletes with active or expiring subscriptions, sorted by urgency
    final expiringAthletes = <MapEntry<Athlete, Subscription>>[];
    for (final athlete in athleteService.athletes) {
      if (athlete.id == null) continue;
      final sub = athleteService.getLatestSubscription(athlete.id!);
      if (sub == null) continue;
      // Show active (≤14 days left) and expiringSoon, skip expired
      final daysLeft = sub.daysUntilExpiry;
      if (daysLeft >= 0 && daysLeft <= 14) {
        expiringAthletes.add(MapEntry(athlete, sub));
      }
    }
    
    // Sort: soonest expiry first
    expiringAthletes.sort((a, b) => a.value.daysUntilExpiry.compareTo(b.value.daysUntilExpiry));
    
    final displayList = expiringAthletes.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SportSectionHeader(
          title: 'Expirant Bientôt',
          icon: Icons.warning_amber_rounded,
          accentColor: const Color(0xFFF97316),
          trailing: expiringAthletes.isNotEmpty
              ? TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: const Text('VOIR TOUT'),
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (displayList.isEmpty)
          const EmptyState(
            icon: Icons.check_circle_outline,
            message: 'Aucun abonnement expirant bientôt.',
          )
        else
          ...displayList.map((entry) {
            final athlete = entry.key;
            final sub = entry.value;
            final daysLeft = sub.daysUntilExpiry;
            
            // Color coding
            final Color statusColor;
            final String statusText;
            if (daysLeft <= 3) {
              statusColor = const Color(0xFFEF4444); // red
              statusText = daysLeft == 0 ? "Expire aujourd'hui" : "$daysLeft jour${daysLeft > 1 ? 's' : ''} restant${daysLeft > 1 ? 's' : ''}";
            } else if (daysLeft <= 7) {
              statusColor = const Color(0xFFF97316); // orange
              statusText = "$daysLeft jours restants";
            } else {
              statusColor = const Color(0xFFFBBF24); // yellow
              statusText = "$daysLeft jours restants";
            }
            
            final subscriptionLabel = sub.type.name[0].toUpperCase() + sub.type.name.substring(1);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context, rootNavigator: true).pushNamed(
                    '/athlete-detail',
                    arguments: athlete.id.toString(),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withValues(alpha: 0.45),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Urgency indicator
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            daysLeft <= 3 ? Icons.error_outline : Icons.schedule,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Athlete info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                athlete.name,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$subscriptionLabel • Exp: ${_formatShortDate(sub.endDate)}',
                                style: TextStyle(
                                  color: subColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: subColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildSettingsTab() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final textColor = Colors.white;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  'PARAMÈTRES',
                  style: TextStyle(
                    fontFamily: SportFonts.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _SettingsItem(icon: Icons.person, title: 'Profil Coach', subtitle: 'Modifier votre profil', color: SportColors.primaryBright, onTap: () => Navigator.pushNamed(context, '/coach-profile')),
                _SettingsItem(
                  icon: themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
                  title: 'Thème',
                  subtitle: themeProvider.isDark ? 'Mode Sombre' : 'Mode Clair',
                  color: SportColors.violet,
                  trailing: Switch(
                    value: themeProvider.isDark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    activeColor: SportColors.primary,
                  ),
                  onTap: () => themeProvider.toggleTheme(),
                ),
                _SettingsItem(icon: Icons.business, title: 'Nom de la salle', subtitle: _gymName, color: SportColors.cyan, onTap: () => _showEditGymDialog()),
                _SettingsItem(icon: Icons.attach_money, title: 'Tarifs', subtitle: 'Personnaliser les prix', color: const Color(0xFF10B981), onTap: () => Navigator.pushNamed(context, '/pricing')),
                _SettingsItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: _notificationsEnabled ? 'Activées' : 'Désactivées',
                  color: SportColors.green,
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notifications_enabled', value);
                      setState(() => _notificationsEnabled = value);
                    },
                    activeColor: SportColors.primary,
                  ),
                  onTap: () {},
                ),
                _SettingsItem(icon: Icons.info_outline, title: 'À propos', subtitle: 'Version 1.0.0', color: SportColors.amber, onTap: () {}),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditGymDialog() {
    final controller = TextEditingController(text: _gymName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Modifier le nom de la salle',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Nom de la salle',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('coach_gym', name);
                setState(() => _gymName = name);
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: SportColors.cyan),
            child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final navBg = Colors.black.withValues(alpha: 0.6);
    final borderColor = Colors.white.withValues(alpha: 0.10);

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.dashboard, label: 'ACCUEIL', isActive: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
              _NavItem(icon: Icons.people, label: 'ATHLÈTES', isActive: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
              _NavItem(icon: Icons.card_membership, label: 'ABOS', isActive: _currentIndex == 2, badgeCount: _expiredCount, onTap: () => setState(() => _currentIndex = 2)),
              _NavItem(icon: Icons.settings, label: 'PARAMÈTRES', isActive: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = Colors.black.withValues(alpha: 0.45);
    final textColor = Colors.white;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontFamily: SportFonts.condensed, color: textColor, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isActive, this.badgeCount = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = SportColors.primary;
    final inactiveColor = Colors.white54;
    final activeBg = activeColor.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: isActive ? activeColor : inactiveColor, size: 24),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: 6,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: SportFonts.condensed,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.8,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsItem({required this.icon, required this.title, required this.subtitle, required this.color, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final titleColor = Colors.white;
    final subtitleColor = Colors.white70;
    final chevronColor = Colors.white38;

    return Card(
      color: Colors.black.withValues(alpha: 0.45),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontFamily: SportFonts.condensed, fontWeight: FontWeight.w800, color: titleColor)),
        subtitle: Text(subtitle, style: TextStyle(color: subtitleColor)),
        trailing: trailing ?? Icon(Icons.chevron_right, color: chevronColor),
        onTap: onTap,
      ),
    );
  }
}

class _AthletesTab extends StatelessWidget {
  const _AthletesTab();
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => const AthletesScreen(showBackButton: false)),
    );
  }
}

class _SubscriptionsTab extends StatelessWidget {
  const _SubscriptionsTab();
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => const SubscriptionsScreen(showBackButton: false)),
    );
  }
}
