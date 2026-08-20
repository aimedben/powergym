import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/athlete_service.dart';
import '../services/pricing_service.dart';
import '../models/athlete.dart';
import '../models/subscription.dart';
import '../models/body_measurement.dart';
import '../theme/sport_design.dart';
import '../widgets/subscription_status_badge.dart';

class AthleteDetailScreen extends StatelessWidget {
  final String athleteId;

  const AthleteDetailScreen({super.key, required this.athleteId});

  // ═══════════════════════════════════════════════════════════════════
  // THEME HELPERS
  // ═══════════════════════════════════════════════════════════════════

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  Color _bg(BuildContext c) => _isDark(c) ? const Color(0xFF0A0E1A) : SportColors.bgLight;
  Color _surface(BuildContext c) => _isDark(c) ? const Color(0xFF1E293B) : Colors.white;
  Color _surfaceBorder(BuildContext c) => _isDark(c) ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);
  Color _textPrimary(BuildContext c) => _isDark(c) ? Colors.white : SportColors.textLight;
  Color _textSecondary(BuildContext c) => _isDark(c) ? Colors.white38 : SportColors.textLightMuted;
  Color _textMuted(BuildContext c) => _isDark(c) ? Colors.white24 : const Color(0xFF94A3B8);
  Color _overlayLight(BuildContext c) => _isDark(c) ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);
  Color _overlayMedium(BuildContext c) => _isDark(c) ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08);
  Color _iconBtnBg(BuildContext c) => _isDark(c) ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08);

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Consumer<AthleteService>(
      builder: (context, athleteService, child) {
        final athlete = athleteService.getAthleteById(athleteId);
        if (athlete == null) {
          return Scaffold(
            backgroundColor: _bg(context),
            appBar: AppBar(title: const Text('Athlète')),
            body: Center(
              child: Text('Athlète introuvable', style: TextStyle(color: _textSecondary(context))),
            ),
          );
        }

        final subscription = athleteService.getLatestSubscription(athlete.id!);
        final status = athleteService.getSubscriptionStatus(athlete.id!);
        final color = _getGenderColor(athlete.gender);

        return Scaffold(
          backgroundColor: _bg(context),
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, athlete, color),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildNameSection(context, athlete, status),
                      const SizedBox(height: 24),
                      _buildQuickStats(context, athlete, subscription, status),
                      const SizedBox(height: 24),
                      if (subscription != null)
                        _buildSubscriptionCard(context, subscription, status),
                      const SizedBox(height: 16),
                      _buildContactCard(context, athlete),
                      const SizedBox(height: 16),
                      _buildMeasurementsCard(context, athleteService, athlete),
                      const SizedBox(height: 16),
                      if (athlete.notes != null && athlete.notes!.isNotEmpty)
                        _buildNotesCard(context, athlete),
                      const SizedBox(height: 24),
                      _buildActionButtons(context, athlete),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SLIVER APP BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar(BuildContext context, Athlete athlete, Color color) {
    final bgColor = _bg(context);
    final isDark = _isDark(context);

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: bgColor,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _iconBtnBg(context),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_ios_new, color: _textPrimary(context), size: 20),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => _quickRenew(context, athlete),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.autorenew_rounded, color: Color(0xFF10B981), size: 20),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/edit-athlete', arguments: athleteId),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _iconBtnBg(context),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.edit_rounded, color: _textPrimary(context), size: 20),
          ),
        ),
        GestureDetector(
          onTap: () => _showDeleteConfirmation(context, athlete),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _iconBtnBg(context),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_outline_rounded, color: _textPrimary(context), size: 20),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: isDark ? 0.3 : 0.15),
                color.withValues(alpha: isDark ? 0.1 : 0.05),
                bgColor,
              ],
            ),
          ),
          child: Center(
            child: _buildSliverAvatar(context, athlete, color),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAvatar(BuildContext context, Athlete athlete, Color color) {
    final hasPhoto = athlete.photoPath != null && athlete.photoPath!.isNotEmpty;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.6)],
              ),
        image: hasPhoto
            ? DecorationImage(image: FileImage(File(athlete.photoPath!)), fit: BoxFit.cover)
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: hasPhoto
          ? null
          : Center(
              child: Text(
                _getInitials(athlete.name),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // NAME SECTION
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildNameSection(BuildContext context, Athlete athlete, SubscriptionStatus? status) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${athlete.firstName != null && athlete.firstName!.isNotEmpty ? '${athlete.firstName} ' : ''}${athlete.name}',
              style: TextStyle(
                fontFamily: SportFonts.black,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _textPrimary(context),
                letterSpacing: -1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 8),
            Text(
              athlete.gender == 'female' ? '♀' : '♂',
              style: TextStyle(
                fontSize: 24,
                color: athlete.gender == 'female' ? SportColors.pink : SportColors.primaryBright,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (status != null)
          SubscriptionStatusBadge(
            status: status,
            showPulse: status == SubscriptionStatus.expired,
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUICK STATS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildQuickStats(BuildContext context, Athlete athlete, Subscription? subscription, SubscriptionStatus? status) {
    return Row(
      children: [
        _buildStatItem(
          context: context,
          icon: Icons.calendar_today_rounded,
          label: 'Membre depuis',
          value: _formatDateShort(athlete.startDate),
          color: SportColors.primaryBright,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          context: context,
          icon: Icons.access_time_rounded,
          label: 'Jours actifs',
          value: _getDaysActive(athlete.startDate),
          color: SportColors.cyan,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          context: context,
          icon: Icons.payments_rounded,
          label: 'Prix',
          value: subscription != null ? '${subscription.price.toStringAsFixed(0)} DA' : 'N/A',
          color: SportColors.green,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: _isDark(context) ? 0.08 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontFamily: SportFonts.condensed,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: SportFonts.condensed,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _textSecondary(context),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SUBSCRIPTION CARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSubscriptionCard(BuildContext context, Subscription subscription, SubscriptionStatus? status) {
    final isExpired = status == SubscriptionStatus.expired;
    final isExpiring = status == SubscriptionStatus.expiringSoon;
    final daysLeft = subscription.endDate.difference(DateTime.now()).inDays;
    final isDark = _isDark(context);

    final statusColor = isExpired
        ? SportColors.red
        : isExpiring
            ? SportColors.amber
            : SportColors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: isDark ? 0.2 : 0.1),
            _surface(context),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.card_membership_rounded, color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                    'ABONNEMENT',
                      style: TextStyle(
                        fontFamily: SportFonts.condensed,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getSubscriptionTypeLabel(subscription.type),
                      style: TextStyle(fontSize: 13, color: _textSecondary(context)),
                    ),
                  ],
                ),
              ),
              SubscriptionStatusBadge(status: status!, showPulse: isExpired),
            ],
          ),
          const SizedBox(height: 20),
          // Progress Bar
          if (!isExpired) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progression',
                  style: TextStyle(fontSize: 12, color: _textSecondary(context)),
                ),
                Text(
                  '$daysLeft jours restants',
                  style: TextStyle(
                    fontFamily: SportFonts.condensed,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isExpiring ? SportColors.amber : SportColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _getSubscriptionProgress(subscription),
                backgroundColor: _overlayLight(context),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExpiring ? SportColors.amber : SportColors.green,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Dates Row
          Row(
            children: [
              _buildDateInfo(context, 'Début', _formatDate(subscription.startDate)),
              const SizedBox(width: 16),
              _buildDateInfo(context, 'Fin', _formatDate(subscription.endDate)),
              const Spacer(),
              if (!isExpired)
                Text(
                  '${subscription.price.toStringAsFixed(0)} DA',
                  style: TextStyle(
                    fontFamily: SportFonts.condensed,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(context),
                  ),
                ),
            ],
          ),
          // Payment status
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: (subscription.isPaid ? SportColors.green : SportColors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (subscription.isPaid ? SportColors.green : SportColors.red).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  subscription.isPaid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 18,
                  color: subscription.isPaid ? SportColors.green : SportColors.red,
                ),
                const SizedBox(width: 10),
                Text(
                  subscription.isPaid ? 'Payé' : 'Impayé',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: subscription.isPaid ? SportColors.green : SportColors.red,
                  ),
                ),
                const Spacer(),
                if (subscription.isPaid && subscription.paymentDate != null)
                  Text(
                    'Payé le ${_formatDate(subscription.paymentDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary(context),
                    ),
                  )
                else
                  Text(
                    'Paiement en attente',
                    style: TextStyle(fontSize: 12, color: _textMuted(context)),
                  ),
              ],
            ),
          ),
          // Renew Button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showRenewDialog(context, subscription),
              icon: const Icon(Icons.edit_calendar, size: 20),
              label: Text(isExpired ? 'Renouveler l\'abonnement' : 'Modifier l\'abonnement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isExpired ? SportColors.red : SportColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: _textSecondary(context))),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textPrimary(context),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONTACT CARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildContactCard(BuildContext context, Athlete athlete) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _surfaceBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SportColors.primaryBright.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.contact_phone_rounded, color: SportColors.primaryBright, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                'INFORMATIONS DE CONTACT',
                style: TextStyle(
                  fontFamily: SportFonts.condensed,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (athlete.phone.isNotEmpty)
            _buildContactRow(
              context: context,
              icon: Icons.phone_rounded,
              label: 'Téléphone',
              value: athlete.phone,
              color: SportColors.primaryBright,
            ),
          if (athlete.phone.isNotEmpty && athlete.birthDate != null)
            const SizedBox(height: 14),
          if (athlete.birthDate != null)
            _buildContactRow(
              context: context,
              icon: Icons.cake_outlined,
              label: 'Date de naissance',
              value: _formatDate(athlete.birthDate!),
              color: SportColors.pink,
            ),
          if (athlete.phone.isEmpty && athlete.birthDate == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aucune information de contact',
                style: TextStyle(color: _textMuted(context), fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: _textSecondary(context))),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BODY MEASUREMENTS CARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildMeasurementsCard(BuildContext context, AthleteService athleteService, Athlete athlete) {
    final measurements = athleteService.getMeasurements(athlete.id!);
    final measurement = (measurements != null && measurements.isNotEmpty) ? measurements.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _surfaceBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SportColors.violet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.monitor_weight_outlined, color: SportColors.violet, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MESURES DU CORPS',
                      style: TextStyle(
                        fontFamily: SportFonts.condensed,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      measurement != null
                          ? 'Dernière mesure le ${_formatDate(measurement.date)}'
                          : 'Aucune mesure enregistrée',
                      style: TextStyle(fontSize: 13, color: _textSecondary(context)),
                    ),
                  ],
                ),
              ),
              if (measurement != null)
                GestureDetector(
                  onTap: () => _showMeasurementDialog(context, athleteService, athlete, measurement),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SportColors.violet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded, color: SportColors.violet, size: 18),
                  ),
                ),
            ],
          ),
          if (measurement != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMeasureItem(context, Icons.scale_outlined, 'Poids', '${_fmtNum(measurement.weight)} kg', SportColors.primaryBright),
                const SizedBox(width: 12),
                _buildMeasureItem(context, Icons.height, 'Taille', '${_fmtNum(measurement.height)} cm', SportColors.cyan),
                const SizedBox(width: 12),
                _buildMeasureItem(context, Icons.straighten_outlined, 'Poitrine', '${_fmtNum(measurement.chest)} cm', SportColors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMeasureItem(context, Icons.circle_outlined, 'Tour de taille', '${_fmtNum(measurement.abdomen)} cm', SportColors.amber),
                const SizedBox(width: 12),
                _buildMeasureItem(context, Icons.accessibility_new_outlined, 'Cuisse', '${_fmtNum(measurement.thigh)} cm', SportColors.pink),
                const SizedBox(width: 12),
                _buildMeasureItem(context, Icons.fitness_center, 'Bras', '${_fmtNum(measurement.arm)} cm', SportColors.violet),
              ],
            ),
            if (measurement.notes != null && measurement.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _overlayLight(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded, size: 16, color: SportColors.violet),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        measurement.notes!,
                        style: TextStyle(fontSize: 13, color: _textSecondary(context), height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showMeasurementDialog(context, athleteService, athlete, measurement),
              icon: const Icon(Icons.add_chart_rounded, size: 18),
              label: Text(measurement != null ? 'Modifier les mesures' : 'Ajouter des mesures'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SportColors.violet,
                side: const BorderSide(color: SportColors.violet, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasureItem(BuildContext context, IconData icon, String label, String value, Color color) {
    final hasValue = value != 'N/A';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.8), size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: SportFonts.condensed,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: hasValue ? _textPrimary(context) : _textMuted(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: SportFonts.condensed,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: _textSecondary(context),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // NOTES CARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildNotesCard(BuildContext context, Athlete athlete) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _surfaceBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SportColors.violet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.note_alt_rounded, color: SportColors.violet, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                'Notes',
                style: TextStyle(
                  fontFamily: SportFonts.condensed,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            athlete.notes!,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary(context),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildActionButtons(BuildContext context, Athlete athlete) {
    final isDark = _isDark(context);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/edit-athlete', arguments: athleteId),
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: const Text('Modifier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SportColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteConfirmation(context, athlete),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: const Text('Supprimer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: SportColors.red,
              side: const BorderSide(color: SportColors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════════

  void _showMeasurementDialog(BuildContext context, AthleteService athleteService, Athlete athlete, BodyMeasurement? current) {
    final isDark = _isDark(context);
    DateTime date = current?.date ?? DateTime.now();
    final weightController = TextEditingController(text: current?.weight?.toString() ?? '');
    final heightController = TextEditingController(text: current?.height?.toString() ?? '');
    final chestController = TextEditingController(text: current?.chest?.toString() ?? '');
    final abdomenController = TextEditingController(text: current?.abdomen?.toString() ?? '');
    final thighController = TextEditingController(text: current?.thigh?.toString() ?? '');
    final armController = TextEditingController(text: current?.arm?.toString() ?? '');
    final notesController = TextEditingController(text: current?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    InputDecoration dec(String label, IconData icon) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _textSecondary(context)),
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _surfaceBorder(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _surfaceBorder(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SportColors.violet, width: 2),
          ),
        );

    Widget field(TextEditingController c, String label, IconData icon) => TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: _textPrimary(context)),
          decoration: dec(label, icon),
        );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: SportColors.violet,
                    brightness: isDark ? Brightness.dark : Brightness.light,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setDialogState(() => date = picked);
          }

          return AlertDialog(
            backgroundColor: _surface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              current != null ? 'Modifier les mesures' : 'Ajouter des mesures',
              style: TextStyle(color: _textPrimary(context), fontWeight: FontWeight.w800),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: _surfaceBorder(context).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _surfaceBorder(context)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_note_outlined, size: 18, color: SportColors.violet),
                            const SizedBox(width: 10),
                            Text(
                              'Date de mesure',
                              style: TextStyle(color: _textSecondary(context), fontSize: 14),
                            ),
                            const Spacer(),
                            Text(
                              fmt(date),
                              style: TextStyle(
                                color: _textPrimary(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: field(weightController, 'Poids (kg)', Icons.scale_outlined)),
                        const SizedBox(width: 8),
                        Expanded(child: field(heightController, 'Taille (cm)', Icons.height)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: field(chestController, 'Poitrine (cm)', Icons.straighten_outlined)),
                        const SizedBox(width: 8),
                        Expanded(child: field(abdomenController, 'Tour de taille (cm)', Icons.circle_outlined)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: field(thighController, 'Cuisse (cm)', Icons.accessibility_new_outlined)),
                        const SizedBox(width: 8),
                        Expanded(child: field(armController, 'Bras (cm)', Icons.fitness_center)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      style: TextStyle(color: _textPrimary(context)),
                      decoration: dec('Notes', Icons.notes_outlined),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler', style: TextStyle(color: _textSecondary(context))),
              ),
              TextButton(
                onPressed: () async {
                  double? parse(String t) => double.tryParse(t.trim());
                  final measurement = BodyMeasurement(
                    id: current?.id,
                    athleteId: athlete.id!,
                    date: date,
                    weight: parse(weightController.text),
                    height: parse(heightController.text),
                    chest: parse(chestController.text),
                    abdomen: parse(abdomenController.text),
                    thigh: parse(thighController.text),
                    arm: parse(armController.text),
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );
                  if (current != null) {
                    await athleteService.updateMeasurement(measurement);
                  } else {
                    await athleteService.addMeasurement(measurement);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: SportColors.violet.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Enregistrer', style: TextStyle(color: SportColors.violet, fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _quickRenew(BuildContext context, Athlete athlete) {
    final isDark = _isDark(context);
    final athleteService = context.read<AthleteService>();
    final currentSub = athleteService.getLatestSubscription(athlete.id!);
    final now = DateTime.now();
    final newEnd = DateTime(now.year, now.month + 1, now.day);
    final price = currentSub?.price ?? 1500.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.autorenew_rounded, color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 12),
            Text('Renouveler rapidement', style: TextStyle(color: _textPrimary(context), fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Renouveler l\'abonnement de ${athlete.name} pour 1 mois ?',
              style: TextStyle(color: _textSecondary(context)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  Text(
                    '${now.day}/${now.month}/${now.year} → ${newEnd.day}/${newEnd.month}/${newEnd.year}',
                    style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Price: ${price.toStringAsFixed(0)} DA',
              style: TextStyle(color: _textSecondary(context), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: _textSecondary(context))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (currentSub != null) {
                final updated = currentSub.copyWith(
                  startDate: now,
                  endDate: newEnd,
                  isPaid: true,
                  paymentDate: now,
                );
                await athleteService.updateSubscription(updated);
              } else {
                final newSub = Subscription(
                  athleteId: athlete.id!,
                  type: SubscriptionType.monthly,
                  startDate: now,
                  endDate: newEnd,
                  price: price,
                  isPaid: true,
                  paymentDate: now,
                );
                await athleteService.addSubscription(newSub);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${athlete.name} renouvelé jusqu\'au ${newEnd.day}/${newEnd.month}/${newEnd.year}'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
            child: const Text('Renouveler', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Athlete athlete) {
    final isDark = _isDark(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Supprimer l\'athlète',
          style: TextStyle(color: _textPrimary(context), fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${athlete.name} ? Cette action est irréversible.',
          style: TextStyle(color: _textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: _textSecondary(context))),
          ),
          TextButton(
            onPressed: () {
              context.read<AthleteService>().deleteAthlete(athlete.id!);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${athlete.name} a été supprimé'),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: SportColors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showRenewDialog(BuildContext context, Subscription currentSubscription) {
    SubscriptionType selectedType = currentSubscription.type;
    DateTime startDate = currentSubscription.startDate;
    final pricingService = context.read<PricingService>();
    final athleteService = context.read<AthleteService>();
    final priceController = TextEditingController(text: currentSubscription.price.toStringAsFixed(0));
    final isDark = _isDark(context);

    DateTime calcEnd(DateTime from, SubscriptionType type) {
      switch (type) {
        case SubscriptionType.monthly:
          return DateTime(from.year, from.month + 1, from.day);
        case SubscriptionType.quarterly:
          return DateTime(from.year, from.month + 3, from.day);
        case SubscriptionType.semester:
          return DateTime(from.year, from.month + 6, from.day);
        case SubscriptionType.annual:
          return DateTime(from.year + 1, from.month, from.day);
        case SubscriptionType.custom:
          return DateTime(from.year, from.month + 1, from.day);
      }
    }

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickStartDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: startDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: SportColors.primary,
                    brightness: isDark ? Brightness.dark : Brightness.light,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setDialogState(() => startDate = picked);
            }
          }

          return AlertDialog(
          backgroundColor: _surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Modifier l\'abonnement',
            style: TextStyle(color: _textPrimary(context), fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<SubscriptionType>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Type',
                  labelStyle: TextStyle(color: _textSecondary(context)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _surfaceBorder(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _surfaceBorder(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SportColors.primary, width: 2),
                  ),
                ),
                dropdownColor: _surface(context),
                style: TextStyle(color: _textPrimary(context)),
                items: const [
                  DropdownMenuItem(value: SubscriptionType.monthly, child: Text('Mensuel')),
                ],
                onChanged: (v) => setDialogState(() {
                  selectedType = v!;
                  priceController.text = pricingService.getPrice(v);
                }),
              ),
              const SizedBox(height: 12),
              // Start date picker
              InkWell(
                onTap: pickStartDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: _surfaceBorder(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _surfaceBorder(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: SportColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Date de début',
                        style: TextStyle(color: _textSecondary(context), fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        fmt(startDate),
                        style: TextStyle(
                          color: _textPrimary(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // End date preview (recalculated)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: SportColors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SportColors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_available, size: 18, color: SportColors.green),
                    const SizedBox(width: 10),
                    Text(
                      'Date de fin: ${fmt(calcEnd(startDate, selectedType))}',
                      style: TextStyle(
                        color: SportColors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: _textPrimary(context)),
                decoration: InputDecoration(
                  labelText: 'Prix (DA)',
                  labelStyle: TextStyle(color: _textSecondary(context)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _surfaceBorder(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _surfaceBorder(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SportColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: _textSecondary(context))),
            ),
            TextButton(
              onPressed: () async {
                final price = double.tryParse(priceController.text) ?? 0;
                final endDate = calcEnd(startDate, selectedType);

                // Update the existing subscription with new dates/type/price
                final updatedSub = currentSubscription.copyWith(
                  type: selectedType,
                  startDate: startDate,
                  endDate: endDate,
                  price: price,
                );
                await athleteService.updateSubscription(updatedSub);

                // Also update athlete startDate
                final athlete = athleteService.getAthleteById(int.parse(athleteId));
                if (athlete != null) {
                  final updatedAthlete = athlete.copyWith(startDate: startDate);
                  await athleteService.updateAthlete(updatedAthlete);
                }

                if (context.mounted) Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: SportColors.green.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Enregistrer', style: TextStyle(color: SportColors.green, fontWeight: FontWeight.w800)),
            ),
          ],
        );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Color _getGenderColor(String gender) {
    if (gender == 'female') return SportColors.pink;
    return SportColors.primaryBright;
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  String _getDaysActive(DateTime startDate) {
    final days = DateTime.now().difference(startDate).inDays;
    return '$days jours';
  }

  double _getSubscriptionProgress(Subscription subscription) {
    final total = subscription.endDate.difference(subscription.startDate).inDays;
    final elapsed = DateTime.now().difference(subscription.startDate).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return SportColors.green;
      case SubscriptionStatus.expiringSoon:
        return SportColors.amber;
      case SubscriptionStatus.expired:
        return SportColors.red;
    }
  }

  IconData _getStatusIcon(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Icons.check_rounded;
      case SubscriptionStatus.expiringSoon:
        return Icons.warning_rounded;
      case SubscriptionStatus.expired:
        return Icons.close_rounded;
    }
  }

  String _getSubscriptionTypeLabel(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly: return 'Forfait Mensuel';
      case SubscriptionType.quarterly: return 'Forfait Trimestriel';
      case SubscriptionType.semester: return 'Forfait Semestriel';
      case SubscriptionType.annual: return 'Forfait Annuel';
      case SubscriptionType.custom: return 'Forfait Personnalisé';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _fmtNum(double? value) {
    if (value == null) return 'N/A';
    final text = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return text;
  }

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
