import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/athlete_service.dart';
import '../services/pricing_service.dart';
import '../models/athlete.dart';
import '../models/subscription.dart';
import '../theme/sport_design.dart';
import '../widgets/athlete_card.dart';
import '../widgets/empty_state.dart';

class AthletesScreen extends StatefulWidget {
  final bool showBackButton;

  const AthletesScreen({super.key, this.showBackButton = true});

  @override
  State<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends State<AthletesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  String _genderFilter = 'all'; // 'all', 'male', 'female'

  // ─── Multi-select state ───
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _enterSelectionMode(int athleteId) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(athleteId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(int athleteId) {
    setState(() {
      if (_selectedIds.contains(athleteId)) {
        _selectedIds.remove(athleteId);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(athleteId);
      }
    });
  }

  void _selectAll(List<Athlete> athletes) {
    setState(() {
      if (_selectedIds.length == athletes.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.addAll(athletes.map((a) => a.id!));
      }
    });
  }

  List<Athlete> _filterAthletes(List<Athlete> athletes) {
    var filtered = athletes;

    // Gender filter
    if (_genderFilter != 'all') {
      filtered = filtered.where((a) => a.gender == _genderFilter).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((athlete) {
        return athlete.name.toLowerCase().contains(query) ||
            athlete.phone.toLowerCase().contains(query) ||
            (athlete.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? SportColors.bgDark : SportColors.bgLight;
    final surfaceColor = isDark ? SportColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : SportColors.textLight;

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelectionMode();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
        body: Column(
          children: [
            // ─── Gender Filter Bar ───
            if (!_isSelectionMode) _buildGenderFilterBar(),
            // ─── Athlete List ───
            Expanded(
              child: Consumer<AthleteService>(
                builder: (context, athleteService, child) {
                  final athletes = _filterAthletes(athleteService.athletes);

                  if (athletes.isEmpty && _searchQuery.isNotEmpty) {
                    return EmptyState(
                      icon: Icons.search_off,
                      message: 'No athletes found for\n"$_searchQuery"',
                    );
                  }

                  if (athletes.isEmpty && _genderFilter != 'all') {
                    final label = _genderFilter == 'male' ? 'men' : 'women';
                    return EmptyState(
                      icon: _genderFilter == 'male' ? Icons.male : Icons.female,
                      message: 'No $label found.',
                    );
                  }

                  if (athletes.isEmpty) {
                    return const EmptyState(
                      icon: Icons.people_outline,
                      message: 'No athletes yet.\nTap + to add your first athlete!',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: athletes.length,
                    itemBuilder: (context, index) {
                      final athlete = athletes[index];
                      final isSelected = _selectedIds.contains(athlete.id);

                      if (_isSelectionMode) {
                        // No Dismissible in selection mode
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AthleteCard(
                            athlete: athlete,
                            isSelected: isSelected,
                            isSelectionMode: true,
                            subscriptionStatus: athlete.id != null
                                ? athleteService.getSubscriptionStatus(athlete.id!)
                                : null,
                            onTap: () {
                              if (_isSelectionMode && athlete.id != null) {
                                _toggleSelection(athlete.id!);
                              }
                            },
                            onLongPress: () {
                              if (athlete.id != null) {
                                _toggleSelection(athlete.id!);
                              }
                            },
                          ),
                        );
                      }

                      return Dismissible(
                        key: Key('athlete_${athlete.id}'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await _showDeleteConfirmation(context, athlete);
                        },
                        onDismissed: (direction) {
                          athleteService.deleteAthlete(athlete.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${athlete.name} removed'),
                              backgroundColor: const Color(0xFF1E293B),
                              action: SnackBarAction(
                                label: 'Undo',
                                textColor: SportColors.primary,
                                onPressed: () {
                                  athleteService.addAthlete(athlete);
                                },
                              ),
                            ),
                          );
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: SportColors.red,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
                        ),
                        child: AthleteCard(
                          athlete: athlete,
                          subscriptionStatus: athlete.id != null
                              ? athleteService.getSubscriptionStatus(athlete.id!)
                              : null,
                          onTap: () {
                            if (_isSelectionMode && athlete.id != null) {
                              _toggleSelection(athlete.id!);
                            } else {
                              Navigator.of(context, rootNavigator: true).pushNamed(
                                '/athlete-detail',
                                arguments: athlete.id.toString(),
                              );
                            }
                          },
                          onLongPress: () {
                            if (athlete.id != null) {
                              _enterSelectionMode(athlete.id!);
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _isSelectionMode ? null : FloatingActionButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed('/add-athlete'),
          backgroundColor: SportColors.primary,
          child: const Icon(Icons.person_add, size: 28, color: Colors.white),
        ),
        // ─── Selection Action Bar ───
        bottomNavigationBar: _isSelectionMode ? _buildSelectionBar() : null,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // APP BARS
  // ═══════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildNormalAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : SportColors.textLight;

    return AppBar(
      leading: widget.showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search athletes...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.35)),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            )
          : Text(
              'ATHLETES',
              style: TextStyle(
                fontFamily: SportFonts.black,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 1.2,
              ),
            ),
      actions: [
        if (_isSearching)
          IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          )
        else ...[
          IconButton(
            icon: Icon(Icons.search, color: textColor),
            onPressed: () {
              setState(() => _isSearching = true);
            },
          ),
          IconButton(
            icon: Icon(Icons.checklist, color: textColor),
            tooltip: 'Select multiple',
            onPressed: () {
              setState(() {
                _isSelectionMode = true;
              });
            },
          ),
        ],
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? SportColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : SportColors.textLight;
    final selectedColor = SportColors.primary;

    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.close, color: textColor),
        onPressed: _exitSelectionMode,
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          '${_selectedIds.length} SELECTED',
          key: ValueKey(_selectedIds.length),
          style: TextStyle(
            fontFamily: SportFonts.black,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: selectedColor,
            letterSpacing: 1.2,
          ),
        ),
      ),
      actions: [
        // Select all
        Consumer<AthleteService>(
          builder: (context, athleteService, child) {
            final filtered = _filterAthletes(athleteService.athletes);
            final allSelected = filtered.isNotEmpty &&
                filtered.every((a) => _selectedIds.contains(a.id));
            return TextButton.icon(
              onPressed: () => _selectAll(filtered),
              icon: Icon(
                allSelected ? Icons.deselect : Icons.select_all,
                size: 20,
                color: selectedColor,
              ),
              label: Text(
                allSelected ? 'NONE' : 'ALL',
                style: TextStyle(
                  fontFamily: SportFonts.condensed,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selectedColor,
                  letterSpacing: 0.8,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SELECTION ACTION BAR (bottom)
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
      child: Row(
        children: [
          // Delete button
          Expanded(
            child: _SelectionActionButton(
              label: 'SUPPRIMER',
              icon: Icons.delete_forever,
              color: SportColors.red,
              count: _selectedIds.length,
              onPressed: () => _showBulkDeleteDialog(),
            ),
          ),
          const SizedBox(width: 12),
          // Renew button
          Expanded(
            child: _SelectionActionButton(
              label: 'RENOUVELER',
              icon: Icons.autorenew,
              color: SportColors.green,
              count: _selectedIds.length,
              onPressed: () => _showBulkRenewDialog(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // GENDER FILTER BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildGenderFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121826) : const Color(0xFFF1F5F9);
    final maleColor = SportColors.primaryBright;
    final femaleColor = SportColors.pink;

    int maleCount = 0;
    int femaleCount = 0;
    final athleteService = context.read<AthleteService>();
    for (final a in athleteService.athletes) {
      if (a.gender == 'male') {
        maleCount++;
      } else {
        femaleCount++;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // All
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _genderFilter = 'all'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _genderFilter == 'all'
                      ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _genderFilter == 'all'
                        ? (isDark ? Colors.white24 : Colors.black26)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people,
                      size: 20,
                      color: _genderFilter == 'all'
                          ? (isDark ? Colors.white : SportColors.textLight)
                          : (isDark ? Colors.white38 : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All',
                      style: TextStyle(
                        fontFamily: SportFonts.condensed,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _genderFilter == 'all'
                            ? (isDark ? Colors.white : SportColors.textLight)
                            : (isDark ? Colors.white38 : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Male
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _genderFilter = 'male'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _genderFilter == 'male' ? maleColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _genderFilter == 'male' ? maleColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '♂',
                      style: TextStyle(
                        fontSize: 20,
                        color: _genderFilter == 'male' ? maleColor : (isDark ? Colors.white38 : const Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$maleCount Hommes',
                      style: TextStyle(
                        fontFamily: SportFonts.condensed,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _genderFilter == 'male' ? maleColor : (isDark ? Colors.white38 : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Female
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _genderFilter = 'female'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _genderFilter == 'female' ? femaleColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _genderFilter == 'female' ? femaleColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '♀',
                      style: TextStyle(
                        fontSize: 20,
                        color: _genderFilter == 'female' ? femaleColor : (isDark ? Colors.white38 : const Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$femaleCount Femmes',
                      style: TextStyle(
                        fontFamily: SportFonts.condensed,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _genderFilter == 'female' ? femaleColor : (isDark ? Colors.white38 : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BULK DELETE DIALOG
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _showBulkDeleteDialog() async {
    final count = _selectedIds.length;
    final athleteService = context.read<AthleteService>();

    // Get names of selected athletes
    final names = _selectedIds
        .map((id) => athleteService.getAthleteById(id)?.name ?? 'Unknown')
        .take(5)
        .toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voulez-vous supprimer $count athlète${count > 1 ? 's' : ''} ?',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < names.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${names[i]}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                      ),
                    ),
                  if (count > 5)
                    Text(
                      '... et ${count - 5} autre${count - 5 > 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cette action est irréversible.',
              style: TextStyle(color: SportColors.red, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
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
      await athleteService.deleteMultiple(_selectedIds.toList());
      if (mounted) {
        _exitSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count athlète${count > 1 ? 's' : ''} supprimé${count > 1 ? 's' : ''}'),
            backgroundColor: SportColors.red,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // BULK RENEW DIALOG
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _showBulkRenewDialog() async {
    final count = _selectedIds.length;
    final athleteService = context.read<AthleteService>();

    // Get names
    final names = _selectedIds
        .map((id) => athleteService.getAthleteById(id)?.name ?? 'Unknown')
        .take(5)
        .toList();

    SubscriptionType selectedType = SubscriptionType.monthly;
    final pricingService = context.read<PricingService>();
    final priceController = TextEditingController(text: pricingService.getPrice(SubscriptionType.monthly));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SportColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.autorenew, color: SportColors.green, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Renouveler $count',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Athletes list preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < names.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${names[i]}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                        ),
                      ),
                    if (count > 5)
                      Text(
                        '... et ${count - 5} autre${count - 5 > 1 ? 's' : ''}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Subscription type dropdown
              DropdownButtonFormField<SubscriptionType>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Type d\'abonnement',
                  labelStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SportColors.green, width: 2),
                  ),
                ),
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: SubscriptionType.monthly, child: Text('Monthly')),
                  DropdownMenuItem(value: SubscriptionType.quarterly, child: Text('Quarterly')),
                  DropdownMenuItem(value: SubscriptionType.semester, child: Text('Semester')),
                  DropdownMenuItem(value: SubscriptionType.annual, child: Text('Annual')),
                ],
                onChanged: (v) => setDialogState(() {
                  selectedType = v!;
                  priceController.text = pricingService.getPrice(v);
                }),
              ),
              const SizedBox(height: 12),

              // Price field
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Prix (DA)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SportColors.green, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                backgroundColor: SportColors.green.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Renouveler', style: TextStyle(color: SportColors.green, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final price = double.tryParse(priceController.text) ?? pricingService.getPriceDouble(selectedType);
      await athleteService.renewMultiple(
        athleteIds: _selectedIds.toList(),
        type: selectedType,
        price: price,
        isPaid: true,
      );
      if (mounted) {
        _exitSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count abonnement${count > 1 ? 's' : ''} renouvelé${count > 1 ? 's' : ''}'),
            backgroundColor: SportColors.green,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SINGLE DELETE (swipe)
  // ═══════════════════════════════════════════════════════════════════

  Future<bool?> _showDeleteConfirmation(BuildContext context, Athlete athlete) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Athlete',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to remove ${athlete.name}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: SportColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SELECTION ACTION BUTTON (bottom bar)
// ═══════════════════════════════════════════════════════════════════

class _SelectionActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onPressed;

  const _SelectionActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                '$label ($count)',
                style: TextStyle(
                  fontFamily: SportFonts.condensed,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
