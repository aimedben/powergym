import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/sport_design.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const WelcomeScreen({super.key, required this.onComplete});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final password = _passwordController.text.trim();
    if (password != 'gym2026@') {
      setState(() {
        _isLoading = false;
        _error = 'Mot de passe incorrect';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coach_name', _nameController.text.trim());
    await prefs.setString('coach_phone', _phoneController.text.trim());
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Colors.white;
    final subtextColor = Colors.white70;
    final inputBg = Colors.white.withValues(alpha: 0.15);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/welcome_bg.jpg',
            fit: BoxFit.cover,
          ),
          // Dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 50),

                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: sportPrimaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: SportColors.primary.withValues(alpha: 0.5),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/logo.png', width: 80, height: 80, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'POWERGYM',
                style: TextStyle(
                  fontFamily: SportFonts.black,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'GESTION DES ATHLÈTES',
                style: TextStyle(
                  fontFamily: SportFonts.condensed,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: subtextColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(
                      controller: _nameController,
                      label: 'Nom complet',
                      icon: Icons.person_outline_rounded,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      inputBg: inputBg,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _phoneController,
                      label: 'Numero de telephone',
                      icon: Icons.phone_outlined,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      inputBg: inputBg,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      icon: Icons.lock_outline_rounded,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      inputBg: inputBg,
                      obscure: true,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                  ],
                ),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SportColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SportColors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: SportColors.red, size: 18),
                      const SizedBox(width: 10),
                      Text(_error!, style: const TextStyle(color: SportColors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SportColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text(
                          'COMMENCER',
                          style: TextStyle(
                            fontFamily: SportFonts.condensed,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    required Color subtextColor,
    required Color inputBg,
    TextInputType? keyboardType,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subtextColor, fontSize: 14),
        prefixIcon: Icon(icon, color: SportColors.primary, size: 20),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SportColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: SportColors.red.withValues(alpha: 0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SportColors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
