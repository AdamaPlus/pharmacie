import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

class LicenseValidationView extends StatefulWidget {
  const LicenseValidationView({super.key});

  @override
  State<LicenseValidationView> createState() => _LicenseValidationViewState();
}

class _LicenseValidationViewState extends State<LicenseValidationView> {
  final _licenseController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscureLicense = true;

  void _handleValidate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simuler un léger chargement premium
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final state = Provider.of<AppStateProvider>(context, listen: false);
    final isValid = await state.validateLicense(_licenseController.text);

    setState(() {
      _isLoading = false;
    });

    if (isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Licence activée avec succès ! Merci pour votre confiance.',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Clé de licence invalide. Veuillez réessayer.';
      });
    }
  }

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF10B981);
    const primaryBg = Color(0xFF0F172A);
    const secondaryBg = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: primaryBg,
      body: Stack(
        children: [
          // Background Decorative Gradients
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeColor.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withOpacity(0.15),
              ),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: secondaryBg.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lock/Key Icon with glowing effect
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.vpn_key_rounded,
                          size: 38,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      Text(
                        'Activation Requise',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        'Votre période d\'essai de 6 jours est expirée. Saisissez votre clé de licence pour activer l\'application de façon définitive.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // License Input
                      TextFormField(
                        controller: _licenseController,
                        obscureText: _obscureLicense,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Saisissez la clé de licence',
                          hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                          prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF64748B), size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureLicense ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureLicense = !_obscureLicense;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: primaryBg.withOpacity(0.6),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: themeColor, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir votre clé de licence';
                          }
                          return null;
                        },
                      ),

                      // Error message if invalid
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Validate Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: themeColor.withOpacity(0.3),
                          ),
                          onPressed: _isLoading ? null : _handleValidate,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Valider la clé',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded, size: 16),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
