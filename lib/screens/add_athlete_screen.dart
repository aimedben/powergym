import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../services/athlete_service.dart';
import '../services/pricing_service.dart';
import '../models/athlete.dart';
import '../models/subscription.dart';
import '../models/body_measurement.dart';

class AddAthleteScreen extends StatefulWidget {
  final String? athleteId;

  const AddAthleteScreen({super.key, this.athleteId});

  @override
  State<AddAthleteScreen> createState() => _AddAthleteScreenState();
}

class _AddAthleteScreenState extends State<AddAthleteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _priceController = TextEditingController(text: '1500');

  // Body measurements
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _chestController = TextEditingController();
  final _abdomenController = TextEditingController();
  final _thighController = TextEditingController();
  final _armController = TextEditingController();
  final _measureNotesController = TextEditingController();

  SubscriptionType _selectedSubscriptionType = SubscriptionType.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _measureDate = DateTime.now();
  DateTime? _birthDate;
  DateTime? _paymentDate;
  bool _isPaid = true;
  String _selectedGender = 'male';
  File? _photoFile;
  bool _isLoading = false;

  bool get isEditing => widget.athleteId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadAthleteData();
    } else {
      // Set initial price from PricingService
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final pricing = context.read<PricingService>();
          _priceController.text = pricing.getPrice(_selectedSubscriptionType);
        }
      });
    }
  }

  void _loadAthleteData() {
    try {
      final athleteService = context.read<AthleteService>();
      final athlete = athleteService.getAthleteById(widget.athleteId!);
      if (athlete != null) {
        _firstNameController.text = athlete.firstName ?? '';
        _nameController.text = athlete.name;
        _phoneController.text = athlete.phone;
        _emailController.text = athlete.email ?? '';
        _birthDate = athlete.birthDate;
        _selectedGender = athlete.gender;
        if (athlete.photoPath != null) _photoFile = File(athlete.photoPath!);
        final sub = athleteService.getLatestSubscription(athlete.id!);
        if (sub != null) {
          _selectedSubscriptionType = sub.type;
          _priceController.text = sub.price.toStringAsFixed(0);
          _startDate = sub.startDate;
          _isPaid = sub.isPaid;
          _paymentDate = sub.paymentDate;
        }

        // Load latest body measurement
        final measurements = athleteService.getMeasurements(athlete.id!);
        if (measurements != null && measurements.isNotEmpty) {
          final latest = measurements.first;
          _measureDate = latest.date;
          _weightController.text = latest.weight?.toString() ?? '';
          _heightController.text = latest.height?.toString() ?? '';
          _chestController.text = latest.chest?.toString() ?? '';
          _abdomenController.text = latest.abdomen?.toString() ?? '';
          _thighController.text = latest.thigh?.toString() ?? '';
          _armController.text = latest.arm?.toString() ?? '';
          _measureNotesController.text = latest.notes ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error loading athlete data: $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _chestController.dispose();
    _abdomenController.dispose();
    _thighController.dispose();
    _armController.dispose();
    _measureNotesController.dispose();
    super.dispose();
  }

  DateTime _calculateEndDate() {
    switch (_selectedSubscriptionType) {
      case SubscriptionType.monthly:
        return DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
      case SubscriptionType.quarterly:
        return DateTime(_startDate.year, _startDate.month + 3, _startDate.day);
      case SubscriptionType.semester:
        return DateTime(_startDate.year, _startDate.month + 6, _startDate.day);
      case SubscriptionType.annual:
        return DateTime(_startDate.year + 1, _startDate.month, _startDate.day);
      case SubscriptionType.custom:
        return _startDate.add(const Duration(days: 30));
    }
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
      if (picked != null) setState(() => _photoFile = File(picked.path));
    }
  }

  Future<DateTime?> _pickDate(BuildContext context, {required DateTime initial, DateTime? first, DateTime? last}) async {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first ?? DateTime(1940),
      lastDate: last ?? DateTime(2035),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await _pickDate(context, initial: _startDate, first: DateTime(2020));
    if (picked != null && picked != _startDate) setState(() => _startDate = picked);
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final picked = await _pickDate(context, initial: _birthDate ?? DateTime(2000), last: DateTime.now());
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
    final picked = await _pickDate(context, initial: _paymentDate ?? DateTime.now(), first: DateTime(2020));
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _selectMeasureDate(BuildContext context) async {
    final picked = await _pickDate(context, initial: _measureDate, last: DateTime.now());
    if (picked != null) setState(() => _measureDate = picked);
  }

  /// Copy photo to permanent app directory so it survives reinstalls
  Future<String?> _savePhotoPermanently() async {
    if (_photoFile == null) return null;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/photos');
      if (!await photosDir.exists()) await photosDir.create(recursive: true);
      final fileName = 'athlete_${DateTime.now().millisecondsSinceEpoch}${p.extension(_photoFile!.path)}';
      final destPath = '${photosDir.path}/$fileName';
      await _photoFile!.copy(destPath);
      return destPath;
    } catch (e) {
      return _photoFile?.path; // Fallback to temp path
    }
  }

  BodyMeasurement? _buildMeasurement(int athleteId, {int? existingId}) {
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final chest = double.tryParse(_chestController.text.trim());
    final abdomen = double.tryParse(_abdomenController.text.trim());
    final thigh = double.tryParse(_thighController.text.trim());
    final arm = double.tryParse(_armController.text.trim());
    final notes = _measureNotesController.text.trim();

    // Skip if no measurement data entered
    if (weight == null && height == null && chest == null && abdomen == null &&
        thigh == null && arm == null && notes.isEmpty) {
      return null;
    }

    return BodyMeasurement(
      id: existingId,
      athleteId: athleteId,
      date: _measureDate,
      weight: weight,
      height: height,
      chest: chest,
      abdomen: abdomen,
      thigh: thigh,
      arm: arm,
      notes: notes.isEmpty ? null : notes,
    );
  }

  Future<void> _saveAthlete() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final athleteService = context.read<AthleteService>();
      final endDate = _calculateEndDate();
      final price = double.tryParse(_priceController.text) ?? 0.0;

      // Copy photo to permanent storage
      final permanentPhotoPath = await _savePhotoPermanently();

      if (isEditing) {
        final existing = athleteService.getAthleteById(widget.athleteId!);
        if (existing != null) {
          final updated = existing.copyWith(
            firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
              email: null,
              birthDate: _birthDate,
              notes: existing.notes,
            gender: _selectedGender,
            photoPath: permanentPhotoPath ?? _photoFile?.path,
            startDate: _startDate,
          );
          await athleteService.updateAthlete(updated);

          // Update existing subscription dates, type, price and payment info
          final currentSub = athleteService.getLatestSubscription(existing.id!);
          if (currentSub != null) {
            final updatedSub = currentSub.copyWith(
              type: _selectedSubscriptionType,
              startDate: _startDate,
              endDate: endDate,
              price: price,
              isPaid: _isPaid,
              paymentDate: _isPaid ? (_paymentDate ?? _startDate) : null,
            );
            await athleteService.updateSubscription(updatedSub);
          }

          // Upsert latest measurement
          final measurements = athleteService.getMeasurements(existing.id!);
          final existingMeasurement = measurements != null && measurements.isNotEmpty ? measurements.first : null;
          final measurement = _buildMeasurement(existing.id!, existingId: existingMeasurement?.id);
          if (measurement != null) {
            if (existingMeasurement != null) {
              await athleteService.updateMeasurement(measurement);
            } else {
              await athleteService.addMeasurement(measurement);
            }
          }
        }
      } else {
        final athlete = Athlete(
          firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: null,
          birthDate: _birthDate,
          notes: null,
          startDate: _startDate,
          gender: _selectedGender,
          photoPath: permanentPhotoPath ?? _photoFile?.path,
        );
        final athleteId = await athleteService.addAthlete(athlete);
        if (athleteId > 0) {
          final subscription = Subscription(
            athleteId: athleteId,
            type: _selectedSubscriptionType,
            startDate: _startDate,
            endDate: endDate,
            price: price,
            isPaid: _isPaid,
            paymentDate: _isPaid ? (_paymentDate ?? _startDate) : null,
          );
          await athleteService.addSubscription(subscription);

          final measurement = _buildMeasurement(athleteId);
          if (measurement != null) {
            await athleteService.addMeasurement(measurement);
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Athlète modifié !' : 'Athlète ajouté !'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white38 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Modifier l\'athlète' : 'Ajouter un athlète',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Photo + Gender
            _buildPhotoSection(isDark, cardColor, textColor),
            const SizedBox(height: 24),

            // Gender Toggle
            _buildGenderToggle(isDark, cardColor, textColor),
            const SizedBox(height: 24),

            // ═══ Basic Information ═══
            _buildSectionHeader('INFORMATIONS', Icons.person, const Color(0xFF3B82F6)),
            const SizedBox(height: 12),
            _buildTextField(_firstNameController, 'Prénom', Icons.badge_outlined, isDark),
            const SizedBox(height: 12),
            _buildTextField(_nameController, 'Nom', Icons.person_outline, isDark, required: true),
            const SizedBox(height: 12),
            _buildTextField(_phoneController, 'Numéro de téléphone', Icons.phone_outlined, isDark,
                keyboardType: TextInputType.phone, required: true),
            const SizedBox(height: 12),
            _buildDateField(
              isDark: isDark,
              textColor: textColor,
              subtextColor: subtextColor,
              icon: Icons.cake_outlined,
              color: const Color(0xFFEC4899),
              label: 'Date de naissance',
              value: _birthDate ?? DateTime(2000),
              onTap: () => _selectBirthDate(context),
            ),

            const SizedBox(height: 24),

            // ═══ Subscription & Payment ═══
            _buildSectionHeader('ABONNEMENT & PAIEMENT', Icons.card_membership, const Color(0xFF10B981)),
            const SizedBox(height: 12),
            _buildSubscriptionTypeSelector(isDark, cardColor, textColor),
            const SizedBox(height: 12),
            _buildTextField(_priceController, 'Prix (DA)', Icons.attach_money, isDark,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildDateField(
              isDark: isDark,
              textColor: textColor,
              subtextColor: subtextColor,
              icon: Icons.calendar_today,
              color: const Color(0xFF3B82F6),
              label: 'Date d\'inscription',
              value: _startDate,
              onTap: () => _selectStartDate(context),
            ),
            const SizedBox(height: 12),
            _buildPaidToggle(isDark, cardColor, textColor),
            if (_isPaid) ...[
              const SizedBox(height: 12),
              _buildDateField(
                isDark: isDark,
                textColor: textColor,
                subtextColor: subtextColor,
                icon: Icons.payments_outlined,
                color: const Color(0xFF10B981),
                label: 'Date de paiement',
                value: _paymentDate ?? DateTime.now(),
                onTap: () => _selectPaymentDate(context),
              ),
            ],
            const SizedBox(height: 12),
            _buildEndDatePreview(isDark),

            const SizedBox(height: 24),

            // ═══ Body Measurements ═══
            _buildSectionHeader('MESURES DU CORPS', Icons.monitor_weight_outlined, const Color(0xFF8B5CF6)),
            const SizedBox(height: 12),
            _buildDateField(
              isDark: isDark,
              textColor: textColor,
              subtextColor: subtextColor,
              icon: Icons.event_note_outlined,
              color: const Color(0xFF8B5CF6),
              label: 'Date de mesure',
              value: _measureDate,
              onTap: () => _selectMeasureDate(context),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_weightController, 'Poids (kg)', Icons.scale_outlined, isDark,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(_heightController, 'Taille (cm)', Icons.height, isDark,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_chestController, 'Poitrine (cm)', Icons.straighten_outlined, isDark,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(_abdomenController, 'Tour de taille (cm)', Icons.circle_outlined, isDark,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_thighController, 'Cuisse (cm)', Icons.accessibility_new_outlined, isDark,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(_armController, 'Bras (cm)', Icons.fitness_center, isDark,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(_measureNotesController, 'Notes', Icons.notes_outlined, isDark, maxLines: 3),

            const SizedBox(height: 32),

            // Save Button
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(bool isDark, Color cardColor, Color textColor) {
    final accentColor = _selectedGender == 'female' ? const Color(0xFFEC4899) : const Color(0xFF3B82F6);
    return Center(
      child: GestureDetector(
        onTap: _pickPhoto,
        child: Stack(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accentColor, accentColor.withOpacity(0.6)],
                ),
                boxShadow: [
                  BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: _photoFile != null
                  ? ClipOval(child: Image.file(_photoFile!, fit: BoxFit.cover))
                  : Icon(
                      _selectedGender == 'female' ? Icons.person_3 : Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
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
    );
  }

  Widget _buildGenderToggle(bool isDark, Color cardColor, Color textColor) {
    final subtextColor = isDark ? Colors.white38 : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedGender = 'male'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedGender == 'male' ? const Color(0xFF3B82F6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('♂', style: TextStyle(fontSize: 18, color: _selectedGender == 'male' ? Colors.white : subtextColor)),
                    const SizedBox(width: 6),
                    Text('Homme', style: TextStyle(fontWeight: FontWeight.w700, color: _selectedGender == 'male' ? Colors.white : subtextColor)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedGender = 'female'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedGender == 'female' ? const Color(0xFFEC4899) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('♀', style: TextStyle(fontSize: 18, color: _selectedGender == 'female' ? Colors.white : subtextColor)),
                    const SizedBox(width: 6),
                    Text('Femme', style: TextStyle(fontWeight: FontWeight.w700, color: _selectedGender == 'female' ? Colors.white : subtextColor)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isDark,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool required = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null : null,
    );
  }

  Widget _buildDateField({
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
    required IconData icon,
    required Color color,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: subtextColor, fontSize: 14)),
            const Spacer(),
            Text(
              '${value!.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidToggle(bool isDark, Color cardColor, Color textColor) {
    final subtextColor = isDark ? Colors.white38 : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isPaid = true;
                if (_paymentDate == null) _paymentDate = DateTime.now();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isPaid ? const Color(0xFF10B981) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: _isPaid ? Colors.white : subtextColor),
                    const SizedBox(width: 6),
                    Text('Payé', style: TextStyle(fontWeight: FontWeight.w700, color: _isPaid ? Colors.white : subtextColor)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isPaid = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_isPaid ? const Color(0xFFEF4444) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel_outlined, size: 18, color: !_isPaid ? Colors.white : subtextColor),
                    const SizedBox(width: 6),
                    Text('Impayé', style: TextStyle(fontWeight: FontWeight.w700, color: !_isPaid ? Colors.white : subtextColor)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTypeSelector(bool isDark, Color cardColor, Color textColor) {
    final types = [
      {'type': SubscriptionType.monthly, 'label': 'Mensuel', 'icon': Icons.calendar_month},
    ];

    return Column(
      children: [
        Row(
          children: types.map((t) => Expanded(child: _buildTypeChip(t, isDark))).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeChip(Map<String, dynamic> t, bool isDark) {
    final isSelected = _selectedSubscriptionType == t['type'];
    final color = const Color(0xFF10B981);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubscriptionType = t['type'];
        });
        final pricing = context.read<PricingService>();
        _priceController.text = pricing.getPrice(t['type']);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)), width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(t['icon'], color: isSelected ? color : (isDark ? Colors.white38 : const Color(0xFF64748B)), size: 22),
            const SizedBox(height: 6),
            Text(t['label'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? color : (isDark ? Colors.white54 : const Color(0xFF64748B)))),
          ],
        ),
      ),
    );
  }

  Widget _buildEndDatePreview(bool isDark) {
    final endDate = _calculateEndDate();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available, color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 10),
          Text(
            'Abonnement se termine : ${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}',
            style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveAthlete,
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(
                isEditing ? 'Modifier l\'athlète' : 'Ajouter l\'athlète',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer l\'athlète', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet athlète ?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              context.read<AthleteService>().deleteAthlete(int.parse(widget.athleteId!));
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Athlète supprimé'), backgroundColor: Color(0xFFEF4444)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}