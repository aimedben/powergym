import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/subscription.dart';
import '../services/pricing_service.dart';
import '../theme/sport_design.dart';

class PricingSettingsScreen extends StatelessWidget {
  const PricingSettingsScreen({super.key});

  static const Map<SubscriptionType, String> _typeLabels = {
    SubscriptionType.monthly: 'Monthly',
    SubscriptionType.quarterly: '3 Months',
    SubscriptionType.semester: '6 Months',
    SubscriptionType.annual: '1 Year',
  };

  static const Map<SubscriptionType, IconData> _typeIcons = {
    SubscriptionType.monthly: Icons.calendar_month,
    SubscriptionType.quarterly: Icons.date_range,
    SubscriptionType.semester: Icons.calendar_today,
    SubscriptionType.annual: Icons.event,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? SportColors.cardDark : Colors.white;
    final textColor = isDark ? Colors.white : SportColors.textLight;
    final subColor = isDark ? Colors.white38 : SportColors.textLightMuted;

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
          'TARIFS',
          style: TextStyle(
            fontFamily: SportFonts.black,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<PricingService>(
        builder: (context, pricing, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SportColors.cyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SportColors.cyan.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: SportColors.cyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Personnalisez le prix de chaque type d\'abonnement. Les nouveau athletes utiliseront ces tarifs.',
                        style: TextStyle(color: subColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Price cards
              ...SubscriptionType.values.where((t) => t != SubscriptionType.custom).map((type) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PricingCard(
                    type: type,
                    label: _typeLabels[type]!,
                    icon: _typeIcons[type]!,
                    price: pricing.getPrice(type),
                    cardColor: cardColor,
                    textColor: textColor,
                    subColor: subColor,
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Reset button
              Center(
                child: TextButton.icon(
                  onPressed: () => _resetPrices(context),
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Reset to defaults'),
                  style: TextButton.styleFrom(
                    foregroundColor: subColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _resetPrices(BuildContext context) {
    final pricing = context.read<PricingService>();
    const defaults = {
      SubscriptionType.monthly: '1500',
      SubscriptionType.quarterly: '4500',
      SubscriptionType.semester: '6000',
      SubscriptionType.annual: '15000',
    };
    for (final entry in defaults.entries) {
      pricing.updatePrice(entry.key, entry.value);
    }
  }
}

class _PricingCard extends StatefulWidget {
  final SubscriptionType type;
  final String label;
  final IconData icon;
  final String price;
  final Color cardColor;
  final Color textColor;
  final Color subColor;

  const _PricingCard({
    required this.type,
    required this.label,
    required this.icon,
    required this.price,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.price);
  }

  @override
  void didUpdateWidget(_PricingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.price != widget.price) {
      _controller.text = widget.price;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEditing
              ? SportColors.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
          width: _isEditing ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SportColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: SportColors.primary, size: 22),
          ),
          const SizedBox(width: 14),

          // Label + duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: SportFonts.condensed,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: widget.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getDurationHint(widget.type),
                  style: TextStyle(color: widget.subColor, fontSize: 11),
                ),
              ],
            ),
          ),

          // Price field
          SizedBox(
            width: 100,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              onTap: () => setState(() => _isEditing = true),
              onSubmitted: (v) => _save(),
              style: TextStyle(
                fontFamily: SportFonts.condensed,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: SportColors.green,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                suffixText: ' DA',
                suffixStyle: TextStyle(
                  color: widget.subColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
          ),

          // Save button
          if (_isEditing)
            IconButton(
              onPressed: _save,
              icon: Icon(Icons.check_circle, color: SportColors.green, size: 26),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32),
            ),
        ],
      ),
    );
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    context.read<PricingService>().updatePrice(widget.type, value);
    setState(() => _isEditing = false);
    FocusScope.of(context).unfocus();
  }

  String _getDurationHint(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly: return '30 jours';
      case SubscriptionType.quarterly: return '3 mois';
      case SubscriptionType.semester: return '6 mois';
      case SubscriptionType.annual: return '12 mois';
      case SubscriptionType.custom: return 'Custom';
    }
  }
}
