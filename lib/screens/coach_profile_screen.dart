import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../services/database_service.dart';
import '../theme/sport_design.dart';

class CoachProfileScreen extends StatefulWidget {
  const CoachProfileScreen({super.key});

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  String _name = 'Coach';
  String _gym = 'PowerGym Seddouk';
  File? _photoFile;
  String? _photoPath;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _gymController = TextEditingController();

  // Revenue stats
  bool _isLoadingStats = true;
  double _totalRevenue = 0;
  double _paidRevenue = 0;
  double _unpaidRevenue = 0;
  double _monthRevenue = 0;
  double _yearRevenue = 0;
  int _totalSubscriptions = 0;
  int _paidCount = 0;
  int _unpaidCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadRevenueStats();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('coach_name') ?? 'Coach';
      _gym = prefs.getString('coach_gym') ?? 'PowerGym Seddouk';
      _photoPath = prefs.getString('coach_photo');
      if (_photoPath != null) _photoFile = File(_photoPath!);
      _nameController.text = _name;
      _gymController.text = _gym;
    });
  }

  Future<void> _loadRevenueStats() async {
    try {
      final db = context.read<DatabaseService>();
      final allSubs = await db.getAllSubscriptions();

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final yearStart = DateTime(now.year, 1, 1);

      double total = 0, paid = 0, unpaid = 0, month = 0, year = 0;
      int paidCnt = 0, unpaidCnt = 0;

      for (final sub in allSubs) {
        total += sub.price;
        if (sub.isPaid) {
          paid += sub.price;
          paidCnt++;
        } else {
          unpaid += sub.price;
          unpaidCnt++;
        }
        if (!sub.startDate.isBefore(monthStart)) {
          month += sub.price;
        }
        if (!sub.startDate.isBefore(yearStart)) {
          year += sub.price;
        }
      }

      setState(() {
        _totalRevenue = total;
        _paidRevenue = paid;
        _unpaidRevenue = unpaid;
        _monthRevenue = month;
        _yearRevenue = year;
        _totalSubscriptions = allSubs.length;
        _paidCount = paidCnt;
        _unpaidCount = unpaidCnt;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coach_name', _nameController.text);
    await prefs.setString('coach_gym', _gymController.text);
    if (_photoPath != null) await prefs.setString('coach_photo', _photoPath!);
    setState(() {
      _name = _nameController.text;
      _gym = _gymController.text;
      _isEditing = false;
    });
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choisir une photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF3B82F6)),
                title: const Text('Caméra'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF10B981)),
                title: const Text('Galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _photoFile = File(picked.path);
          _photoPath = picked.path;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? SportColors.cardDark : Colors.white;
    final textColor = isDark ? Colors.white : SportColors.textLight;
    final subtextColor = isDark ? Colors.white38 : SportColors.textLightMuted;
    final accentColor = SportColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PROFIL',
          style: TextStyle(
            fontFamily: SportFonts.black,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w700, color: SportColors.green)),
            )
          else
            IconButton(
              icon: Icon(Icons.edit_rounded, color: textColor),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Photo + Name
            _buildPhotoSection(accentColor, isDark),
            const SizedBox(height: 32),

            // ── REVENUE STATS ──
            Text(
              'REVENUS',
              style: TextStyle(
                fontFamily: SportFonts.black,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),

            if (_isLoadingStats)
              const Center(child: CircularProgressIndicator(color: SportColors.green))
            else ...[
              // Main revenue card
              _buildMainRevenueCard(cardColor, textColor, subtextColor, isDark),
              const SizedBox(height: 12),

              // Breakdown row
              Row(
                children: [
                  Expanded(child: _buildStatMini(
                    label: 'Paye',
                    value: _formatPrice(_paidRevenue),
                    count: '$_paidCount abo',
                    color: SportColors.green,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatMini(
                    label: 'Impaye',
                    value: _formatPrice(_unpaidRevenue),
                    count: '$_unpaidCount abo',
                    color: SportColors.red,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                  )),
                ],
              ),
              const SizedBox(height: 12),

              // Monthly + Yearly
              Row(
                children: [
                  Expanded(child: _buildStatMini(
                    label: 'Ce mois',
                    value: _formatPrice(_monthRevenue),
                    count: '${_getMonthLabel()}',
                    color: SportColors.cyan,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatMini(
                    label: 'Cette annee',
                    value: _formatPrice(_yearRevenue),
                    count: '${_getYearLabel()}',
                    color: SportColors.violet,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                  )),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // ── INFO CARDS ──
            Text(
              'INFORMATIONS',
              style: TextStyle(
                fontFamily: SportFonts.black,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),

            _buildInfoCard(
              icon: Icons.person,
              label: 'Nom complet',
              controller: _nameController,
              isEditing: _isEditing,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
              accentColor: accentColor,
            ),
            const SizedBox(height: 10),
            _buildInfoCard(
              icon: Icons.business,
              label: 'Nom de la salle',
              controller: _gymController,
              isEditing: _isEditing,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
              accentColor: accentColor,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // REVENUE CARDS
  // ═══════════════════════════════════════════

  Widget _buildMainRevenueCard(Color cardColor, Color textColor, Color subtextColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981),
            const Color(0xFF059669),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'TOTAL REVENUS',
                style: TextStyle(
                  fontFamily: SportFonts.condensed,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatPrice(_totalRevenue),
            style: const TextStyle(
              fontFamily: SportFonts.black,
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_totalSubscriptions abonnements au total',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini({
    required String label,
    required String value,
    required String count,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: SportFonts.condensed,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: subtextColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: SportFonts.condensed,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: TextStyle(
              fontSize: 11,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    final p = price.toInt();
    if (p >= 1000) {
      final thousands = p ~/ 1000;
      final rest = p % 1000;
      if (rest == 0) return '$thousands 000 DA';
      return '$thousands ${rest.toString().padLeft(3, '0')} DA';
    }
    return '$p DA';
  }

  String _getMonthLabel() {
    const months = ['', 'Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aou', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[DateTime.now().month];
  }

  String _getYearLabel() => '${DateTime.now().year}';

  // ═══════════════════════════════════════════
  // PHOTO + INFO
  // ═══════════════════════════════════════════

  Widget _buildPhotoSection(Color accentColor, bool isDark) {
    final textColor = isDark ? Colors.white : SportColors.textLight;
    final subtextColor = isDark ? Colors.white38 : SportColors.textLightMuted;

    return Column(
      children: [
        GestureDetector(
          onTap: _isEditing ? _pickPhoto : null,
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor, accentColor.withValues(alpha: 0.6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _photoFile != null
                    ? ClipOval(
                        child: Image.file(_photoFile!, fit: BoxFit.cover, width: 120, height: 120),
                      )
                    : const Center(
                        child: Icon(Icons.person, size: 52, color: Colors.white),
                      ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC), width: 3),
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _name,
          style: TextStyle(
            fontFamily: SportFonts.black,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _gym,
          style: TextStyle(
            fontFamily: SportFonts.condensed,
            fontSize: 13,
            color: subtextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEditing ? accentColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: label,
                      hintStyle: TextStyle(color: subtextColor),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 11, color: subtextColor, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(controller.text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
