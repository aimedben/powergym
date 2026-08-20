import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/athlete_service.dart';
import '../models/athlete.dart';
import '../models/subscription.dart';
import '../theme/sport_design.dart';
import '../widgets/subscription_status_badge.dart';
import '../widgets/empty_state.dart';

class SubscriptionsScreen extends StatefulWidget {
  final bool showBackButton;

  const SubscriptionsScreen({super.key, this.showBackButton = true});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ─── Multi-select state ───
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _enterSelectionMode(int subId) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(subId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(int subId) {
    setState(() {
      if (_selectedIds.contains(subId)) {
        _selectedIds.remove(subId);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(subId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indicatorColor = isDark ? SportColors.green : const Color(0xFF059669);
    final labelColor = indicatorColor;
    final unselectedColor = isDark ? Colors.white54 : const Color(0xFF94A3B8);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : SportColors.textLight;

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelectionMode();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(isDark, indicatorColor, labelColor, unselectedColor),
        body: Consumer<AthleteService>(
          builder: (context, athleteService, child) {
            final athletes = athleteService.athletes;

            final active = <MapEntry<Athlete, Subscription>>[];
            final expiring = <MapEntry<Athlete, Subscription>>[];
            final expired = <MapEntry<Athlete, Subscription>>[];

            for (final athlete in athletes) {
              if (athlete.id == null) continue;
              final sub = athleteService.getLatestSubscription(athlete.id!);
              if (sub == null || sub.id == null) continue;
              switch (sub.status) {
                case SubscriptionStatus.active:
                  active.add(MapEntry(athlete, sub));
                  break;
                case SubscriptionStatus.expiringSoon:
                  expiring.add(MapEntry(athlete, sub));
                  break;
                case SubscriptionStatus.expired:
                  expired.add(MapEntry(athlete, sub));
                  break;
              }
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildSubscriptionList(active, 'Aucun abonnement actif', Icons.check_circle_outline),
                _buildSubscriptionList(expiring, 'Aucun abonnement expirant', Icons.warning_amber_outlined),
                _buildSubscriptionList(expired, 'Aucun abonnement expiré', Icons.cancel_outlined),
              ],
            );
          },
        ),
        bottomNavigationBar: _isSelectionMode ? _buildSelectionBar() : null,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // APP BARS
  // ═══════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildNormalAppBar(
    bool isDark,
    Color indicatorColor,
    Color labelColor,
    Color unselectedColor,
  ) {
    final textColor = isDark ? Colors.white : SportColors.textLight;

    return AppBar(
      leading: widget.showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text(
        'ABONNEMENTS',
        style: TextStyle(
          fontFamily: SportFonts.black,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.checklist, color: textColor),
          tooltip: 'Sélection multiple',
          onPressed: () => setState(() => _isSelectionMode = true),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: indicatorColor,
        indicatorWeight: 3,
        labelColor: labelColor,
        unselectedLabelColor: unselectedColor,
        labelStyle: const TextStyle(fontFamily: SportFonts.condensed, fontSize: 13, fontWeight: FontWeight.w800),
        tabs: const [
          Tab(text: 'Actif'),
          Tab(text: 'Expirant'),
          Tab(text: 'Expiré'),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : SportColors.textLight;

    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.close, color: textColor),
        onPressed: _exitSelectionMode,
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          '${_selectedIds.length} SÉLECTIONNÉ(S)',
          key: ValueKey(_selectedIds.length),
          style: TextStyle(
            fontFamily: SportFonts.black,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: SportColors.red,
            letterSpacing: 1.2,
          ),
        ),
      ),
      actions: [
        Consumer<AthleteService>(
          builder: (context, athleteService, child) {
            return TextButton.icon(
              onPressed: () {
                // Find all subscription IDs in current lists
                final allSubIds = _getAllSubIds(athleteService);
                setState(() {
                  if (_selectedIds.length == allSubIds.length) {
                    _selectedIds.clear();
                    _isSelectionMode = false;
                  } else {
                    _selectedIds.addAll(allSubIds);
                  }
                });
              },
              icon: const Icon(Icons.select_all, size: 20, color: SportColors.primary),
              label: const Text('TOUT', style: TextStyle(
                fontFamily: SportFonts.condensed, fontSize: 12, fontWeight: FontWeight.w800,
                color: SportColors.primary, letterSpacing: 0.8,
              )),
            );
          },
        ),
      ],
    );
  }

  Set<int> _getAllSubIds(AthleteService athleteService) {
    final ids = <int>{};
    for (final athlete in athleteService.athletes) {
      if (athlete.id == null) continue;
      final sub = athleteService.getLatestSubscription(athlete.id!);
      if (sub != null && sub.id != null) ids.add(sub.id!);
    }
    return ids;
  }

  // ═══════════════════════════════════════════════════════════════════
  // SELECTION ACTION BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSelectionBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? SportColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Material(
        color: SportColors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _showBulkDeleteDialog(),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SportColors.red.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_forever, color: SportColors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SUPPRIMER (${_selectedIds.length})',
                  style: const TextStyle(
                    fontFamily: SportFonts.condensed,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: SportColors.red,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SUBSCRIPTION LIST
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSubscriptionList(
    List<MapEntry<Athlete, Subscription>> entries,
    String emptyMessage,
    IconData emptyIcon,
  ) {
    if (entries.isEmpty) return EmptyState(icon: emptyIcon, message: emptyMessage);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final athlete = entries[index].key;
        final subscription = entries[index].value;
        final isExpired = subscription.status == SubscriptionStatus.expired;
        final isSelected = subscription.id != null && _selectedIds.contains(subscription.id);

        final cardBg = isExpired
            ? (isDark ? SportColors.red.withValues(alpha: 0.1) : const Color(0xFFFEF2F2))
            : null;
        final borderColor = isSelected
            ? SportColors.primary
            : isExpired
                ? SportColors.red.withValues(alpha: 0.4)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06));
        final nameColor = isExpired
            ? SportColors.red
            : (isDark ? Colors.white : SportColors.textLight);
        final subTextColor = isDark ? Colors.white54 : const Color(0xFF64748B);
        final dateColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: borderColor,
                width: isSelected ? 2.5 : (isExpired ? 1.5 : 1),
              ),
            ),
            child: InkWell(
              onTap: () {
                if (_isSelectionMode && subscription.id != null) {
                  _toggleSelection(subscription.id!);
                } else {
                  Navigator.of(context, rootNavigator: true).pushNamed(
                    '/athlete-detail',
                    arguments: athlete.id.toString(),
                  );
                }
              },
              onLongPress: () {
                if (subscription.id != null) {
                  _enterSelectionMode(subscription.id!);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Selection indicator
                        if (_isSelectionMode) ...[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? SportColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? SportColors.primary : (isDark ? Colors.white24 : Colors.black26),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 12),
                        ],
                        _buildAthleteAvatar(athlete),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                athlete.name,
                                style: TextStyle(
                                  fontFamily: SportFonts.condensed,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: nameColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_getSubscriptionTypeLabel(subscription.type)} • ${subscription.price.toStringAsFixed(0)} DA',
                                style: TextStyle(fontSize: 12, color: subTextColor),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_formatDate(subscription.startDate)} - ${_formatDate(subscription.endDate)}',
                                style: TextStyle(fontSize: 11, color: dateColor),
                              ),
                            ],
                          ),
                        ),
                        if (!_isSelectionMode)
                          SubscriptionStatusBadge(status: subscription.status, showPulse: isExpired),
                      ],
                    ),
                  ),
                  // Selection mode left accent
                  if (_isSelectionMode)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 4,
                        decoration: BoxDecoration(
                          color: isSelected ? SportColors.primary : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BULK DELETE DIALOG
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _showBulkDeleteDialog() async {
    final count = _selectedIds.length;
    final athleteService = context.read<AthleteService>();

    // Get names of selected athletes
    final names = <String>[];
    for (final athlete in athleteService.athletes) {
      if (athlete.id == null) continue;
      final sub = athleteService.getLatestSubscription(athlete.id!);
      if (sub != null && sub.id != null && _selectedIds.contains(sub.id!)) {
        names.add(athlete.name);
      }
      if (names.length >= 5) break;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? SportColors.surfaceDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SportColors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever, color: SportColors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Supprimer',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supprimer $count abonnement${count > 1 ? 's' : ''} ?',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : SportColors.textLightMuted,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final name in names)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $name',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.7)
                              : SportColors.textLight,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (count > 5)
                    Text(
                      '... et ${count - 5} autre${count - 5 > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.5)
                            : SportColors.textLightMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : SportColors.textLightMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: SportColors.red.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Supprimer', style: TextStyle(color: SportColors.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      for (final subId in _selectedIds) {
        await athleteService.deleteSubscription(subId);
      }
      if (mounted) {
        _exitSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count abonnement${count > 1 ? 's' : ''} supprimé${count > 1 ? 's' : ''}'),
            backgroundColor: SportColors.red,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildAthleteAvatar(Athlete athlete) {
    final hasPhoto = athlete.photoPath != null && athlete.photoPath!.isNotEmpty;
    final color = _getGenderColor(athlete.gender);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: hasPhoto
          ? ClipOval(child: Image.asset(athlete.photoPath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildInitials(color, athlete.name)))
          : _buildInitials(color, athlete.name),
    );
  }

  Widget _buildInitials(Color color, String name) {
    return Center(
      child: Text(
        _getInitials(name),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }

  Color _getGenderColor(String gender) {
    if (gender == 'female') return SportColors.pink;
    return SportColors.primaryBright;
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  String _getSubscriptionTypeLabel(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly: return 'Mensuel';
      case SubscriptionType.quarterly: return '3 Mois';
      case SubscriptionType.semester: return '6 Mois';
      case SubscriptionType.annual: return '1 An';
      case SubscriptionType.custom: return 'Perso';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
