import 'dart:typed_data';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state_provider.dart';
import '../models/pharmacy_models.dart';


class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  final _formKeyLogin = GlobalKey<FormState>();
  final _formKeyRegister = GlobalKey<FormState>();

  // Login controllers
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePin = true;

  // Register controllers
  final _regNameController = TextEditingController(); // Nom de la pharmacie
  final _regQuartierController =
      TextEditingController(); // Quartier / localisation
  final _regAdminNameController =
      TextEditingController(); // Nom complet de l'admin
  final _regUsernameController =
      TextEditingController(); // Nom d'utilisateur de l'admin
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  final _regPinCodeController = TextEditingController();
  final _regContact1Controller = TextEditingController();
  final _regContact2Controller = TextEditingController();
  Uint8List? _regLogoBytes;

  bool _obscureRegPassword = true;
  bool _obscureRegConfirmPassword = true;

  String? _errorMessage;
  String? _successMessage;
  String? _usernameError;
  String? _passwordError;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _regNameController.dispose();
    _regQuartierController.dispose();
    _regAdminNameController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _regPinCodeController.dispose();
    _regContact1Controller.dispose();
    _regContact2Controller.dispose();
    super.dispose();
  }

  void _handleLogin() {
    _usernameError = null;
    _passwordError = null;
    _errorMessage = null;
    _successMessage = null;

    if (!(_formKeyLogin.currentState?.validate() ?? false)) return;

    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final bool success = provider.loginPharmacy(username, password, '');

    if (success) {
      // Login réussi : réinitialiser le form pour éviter toute interférence
      _formKeyLogin.currentState?.reset();
      return;
    }

    final input = username.toLowerCase();
    final bool isUserOrAdminMatch = provider.users.any((u) {
      final uName = u.username.trim().toLowerCase();
      final uEmail = (u.email ?? '').trim().toLowerCase();
      final uFull = (u.fullName ?? '').trim().toLowerCase();
      final uPin = u.pinCode.trim().toLowerCase();
      final uEmpId = u.employeeId.trim().toLowerCase();

      return (uName.isNotEmpty && (input == uName || uName.contains(input))) ||
          (uEmail.isNotEmpty && (input == uEmail || uEmail.contains(input))) ||
          (uFull.isNotEmpty && (input == uFull || uFull.startsWith(input) || uFull.split(' ').contains(input))) ||
          (uPin.isNotEmpty && input == uPin) ||
          (uEmpId.isNotEmpty && input == uEmpId);
    }) ||
    (provider.pharmacyContact2.trim().toLowerCase().isNotEmpty &&
        (input == provider.pharmacyContact2.trim().toLowerCase() || provider.pharmacyContact2.trim().toLowerCase().contains(input))) ||
    (provider.pharmacyContact1.trim().toLowerCase().isNotEmpty &&
        (input == provider.pharmacyContact1.trim().toLowerCase() || provider.pharmacyContact1.trim().toLowerCase().contains(input))) ||
    (provider.pharmacyName.trim().toLowerCase().isNotEmpty &&
        (input == provider.pharmacyName.trim().toLowerCase() || provider.pharmacyName.trim().toLowerCase().contains(input)));

    if (!isUserOrAdminMatch && provider.users.isNotEmpty) {
      _usernameError = 'Identifiant incorrect ou inexistant';
    } else {
      _passwordError = 'Mot de passe incorrect';
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formKeyLogin.currentState?.validate();
    });
  }

  void _handlePharmacyRegistration() {
    if (_formKeyRegister.currentState!.validate()) {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
      });
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      provider.registerPharmacy(
        name: _regNameController.text.trim(),
        quartier: _regQuartierController.text.trim(),
        adminFullName: _regAdminNameController.text.trim(),
        username: _regUsernameController.text.trim().toLowerCase(),
        password: _regPasswordController.text,
        pinCode: '',

        contact1: _regContact1Controller.text.trim(),
        contact2: _regContact2Controller.text.trim(),
        logo: _regLogoBytes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF10B981);
    final state = Provider.of<AppStateProvider>(context);
    final bool pharmacyRegistered = state.pharmacyName.isNotEmpty;

    // Premier lancement = inscription, sinon connexion
    final bool showRegister = !pharmacyRegistered;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fond image pharmacie ──
          Image.asset('assets/images/pharmacy_bg.png', fit: BoxFit.cover),

          // ── Overlay sombre complet pour centrage ──
          Container(color: const Color(0xAA0F172A)),

          // ── Formulaire centré ──
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      width: 460,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.78),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.45),
                            blurRadius: 50,
                            offset: const Offset(0, 24),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // En-tête
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: themeColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Image.asset(
                                    'assets/images/app_icon.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PharmaGuinée',
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    showRegister
                                        ? 'Créez votre pharmacie'
                                        : 'Bienvenue — Connectez-vous',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Alertes
                          if (_errorMessage != null) ...[
                            _alertBox(
                              _errorMessage!,
                              Colors.redAccent,
                              Icons.error_outline_rounded,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_successMessage != null) ...[
                            _alertBox(
                              _successMessage!,
                              themeColor,
                              Icons.check_circle_outline_rounded,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Formulaire selon l'état
                          if (showRegister)
                            _buildRegisterForm(themeColor)
                          else
                            _buildLoginForm(themeColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // FORMULAIRE CONNEXION
  // ══════════════════════════════════════════
  Widget _buildLoginForm(Color themeColor) {
    return Form(
      key: _formKeyLogin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _loginField(
            label: "Nom d'utilisateur ou Email",
            controller: _usernameController,
            icon: Icons.person_outline_rounded,
            hint: "username ou email@gmail.com",
            themeColor: themeColor,
            forceLowerCase: true,
            onSubmit: (_) => _handleLogin(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Champ requis';
              if (_usernameError != null) return _usernameError;
              return null;
            },
            onChanged: (v) {
              if (_usernameError != null) {
                setState(() => _usernameError = null);
              }
            },
          ),
          const SizedBox(height: 18),
          _loginField(
            label: 'Mot de passe',
            controller: _passwordController,
            icon: Icons.lock_outline_rounded,
            hint: 'Votre mot de passe',
            themeColor: themeColor,
            obscure: _obscurePassword,
            onSubmit: (_) => _handleLogin(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Champ requis';
              if (_passwordError != null) return _passwordError;
              return null;
            },
            onChanged: (v) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(themeColor),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Mot de passe oublié ?',
                style: GoogleFonts.inter(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _primaryBtn(
            'Se connecter',
            Icons.login_rounded,
            themeColor,
            _handleLogin,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // FORMULAIRE INSCRIPTION
  // ══════════════════════════════════════════
  Widget _buildRegisterForm(Color themeColor) {
    return Form(
      key: _formKeyRegister,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo picker
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _regLogoBytes != null
                      ? Image.memory(_regLogoBytes!, fit: BoxFit.cover)
                      : Icon(
                          Icons.add_photo_alternate_rounded,
                          color: themeColor.withOpacity(0.7),
                          size: 32,
                        ),
                ),
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null && result.files.single.bytes != null) {
                      setState(() => _regLogoBytes = result.files.single.bytes);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0F172A),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 20),
              child: Text(
                _regLogoBytes != null ? 'Logo importé ✓' : 'Logo (optionnel)',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
              ),
            ),
          ),

          _regField(
            'Nom de la pharmacie',
            _regNameController,
            Icons.apartment_rounded,
            themeColor,
            required: true,
          ),
          const SizedBox(height: 12),
          _regField(
            'Quartier / Localisation',
            _regQuartierController,
            Icons.location_on_rounded,
            themeColor,
            required: true,
          ),
          const SizedBox(height: 12),
          _regField(
            'Votre nom complet (Admin)',
            _regAdminNameController,
            Icons.person_outline_rounded,
            themeColor,
            required: true,
          ),
          const SizedBox(height: 12),
          _regField(
            'Nom d\'utilisateur (Admin)',
            _regUsernameController,
            Icons.person_outline_rounded,
            themeColor,
            required: true,
          ),
          const SizedBox(height: 12),

          _regField(
            'Email',
            _regContact2Controller,
            Icons.email_rounded,
            themeColor,
            isEmail: true,
            required: true,
          ),
          const SizedBox(height: 12),
          _regField(
            'Téléphone',
            _regContact1Controller,
            Icons.phone_rounded,
            themeColor,
            required: true,
            isPhone: true,
          ),
          const SizedBox(height: 12),
          _regField(
            'Mot de passe',
            _regPasswordController,
            Icons.lock_outline_rounded,
            themeColor,
            obscure: _obscureRegPassword,
            required: true,
            minLength: 4,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscureRegPassword = !_obscureRegPassword),
            ),
          ),
          const SizedBox(height: 12),
          _regField(
            'Confirmer le mot de passe',
            _regConfirmPasswordController,
            Icons.lock_outline_rounded,
            themeColor,
            obscure: _obscureRegConfirmPassword,
            required: true,
            // Passer un getter pour lire la valeur en temps réel lors de la validation
            confirmGetter: () => _regPasswordController.text,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 18,
              ),
              onPressed: () => setState(
                () => _obscureRegConfirmPassword = !_obscureRegConfirmPassword,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _primaryBtn(
            'Créer le compte',
            Icons.check_circle_rounded,
            themeColor,
            _handlePharmacyRegistration,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // WIDGETS HELPERS
  // ══════════════════════════════════════════
  Widget _loginField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color themeColor,
    bool obscure = false,
    bool isPin = false,
    Widget? suffixIcon,
    void Function(String)? onSubmit,
    bool forceLowerCase = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          textCapitalization: forceLowerCase
              ? TextCapitalization.none
              : TextCapitalization.none,
          inputFormatters: isPin
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ]
              : (forceLowerCase ? [LowerCaseTextFormatter()] : null),
          keyboardType: isPin ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: isPin ? 20 : 14,
            letterSpacing: isPin && !obscure ? 8 : 0,
            fontWeight: isPin && !obscure ? FontWeight.bold : FontWeight.normal,
          ),
          onFieldSubmitted: onSubmit,
          onChanged: onChanged,
          decoration: _glassDeco(
            hint,
            icon,
            themeColor,
            suffixIcon: suffixIcon,
          ),
          validator:
              validator ??
              (v) {
                if (v == null || v.trim().isEmpty) return 'Champ requis';
                if (isPin && v.trim().length != 4) return '4 chiffres requis';
                return null;
              },
        ),
      ],
    );
  }

  Widget _regField(
    String label,
    TextEditingController ctrl,
    IconData icon,
    Color themeColor, {
    bool required = false,
    bool obscure = false,
    bool isEmail = false,
    bool isPhone = false,
    bool isPinCode = false,
    int? minLength,
    Widget? suffixIcon,
    // Utiliser une fonction getter pour lire la valeur en temps réel lors de la validation
    String? Function()? confirmGetter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: isPhone
              ? TextInputType.phone
              : (isEmail
                    ? TextInputType.emailAddress
                    : (isPinCode ? TextInputType.number : TextInputType.text)),
          inputFormatters: isPhone
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ]
              : (isPinCode
                    ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ]
                    : null),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
          decoration: _glassDeco(
            isPhone
                ? 'Ex: 620000000 (9 chiffres)'
                : (isPinCode ? 'Code PIN à 4 chiffres (Ex: 1234)' : label),
            icon,
            themeColor,
            suffixIcon: suffixIcon,
          ),
          validator: (v) {
            if (required && (v == null || v.trim().isEmpty))
              return 'Champ requis';
            if (isEmail &&
                v != null &&
                v.isNotEmpty &&
                (!v.contains('@') || !v.contains('.')))
              return 'Email invalide';
            if (isPhone && v != null && v.isNotEmpty && v.length != 9)
              return '9 chiffres requis';
            if (isPinCode && v != null && v.isNotEmpty && v.length != 4)
              return '4 chiffres requis';
            if (minLength != null && v != null && v.length < minLength)
              return 'Min $minLength caractères';
            // Lire la valeur à confirmer au moment de la validation (pas au moment du build)
            if (confirmGetter != null && v != confirmGetter())
              return 'Les mots de passe ne correspondent pas';
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _glassDeco(
    String hint,
    IconData prefix,
    Color themeColor, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      prefixIcon: Icon(prefix, color: Colors.white38, size: 18),
      suffixIcon: suffixIcon,
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11),
    );
  }

  Widget _primaryBtn(
    String label,
    IconData icon,
    Color themeColor,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        shadowColor: themeColor.withOpacity(0.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertBox(String message, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPinCodeDialog(Color themeColor) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final phoneCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final newPinConfirmCtrl = TextEditingController();

    final formKeyPhone = GlobalKey<FormState>();
    final formKeyCode = GlobalKey<FormState>();
    final formKeyPin = GlobalKey<FormState>();

    int currentStep = 1;
    String generatedCode = '';
    String? localError;
    String? localSuccess;
    bool obscureNewPin = true;
    bool obscureNewPinConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              title: Row(
                children: [
                  Icon(Icons.pin_rounded, color: Colors.orangeAccent, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Récupération Code PIN',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (localError != null) ...[
                      _alertBox(
                        localError!,
                        Colors.redAccent,
                        Icons.error_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (localSuccess != null) ...[
                      _alertBox(
                        localSuccess!,
                        Colors.orangeAccent,
                        Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (currentStep == 1)
                      Form(
                        key: formKeyPhone,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entrez le numéro de téléphone associé à votre pharmacie (l\'administrateur) pour recevoir le code de récupération.',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Numéro de téléphone',
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(9),
                              ],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: _glassDeco(
                                'Ex: 620000000',
                                Icons.phone_rounded,
                                Colors.orangeAccent,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Veuillez saisir votre numéro';
                                if (v.trim().length != 9)
                                  return '9 chiffres requis';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                    if (currentStep == 2)
                      Form(
                        key: formKeyCode,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saisissez le code à 4 chiffres reçu sur le numéro de téléphone ${phoneCtrl.text}.',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Code de validation',
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: codeCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                letterSpacing: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: _glassDeco(
                                'Code',
                                Icons.message_rounded,
                                Colors.orangeAccent,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Code requis';
                                if (v.trim() != generatedCode)
                                  return 'Code de validation incorrect';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                    if (currentStep == 3)
                      Form(
                        key: formKeyPin,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Définissez votre nouveau Code PIN administrateur (exactement 4 chiffres).',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nouveau Code PIN (4 chiffres)',
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: newPinCtrl,
                              obscureText: obscureNewPin,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                letterSpacing: obscureNewPin ? 0 : 8,
                                fontWeight: obscureNewPin
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                              decoration: _glassDeco(
                                'Nouveau Code PIN',
                                Icons.lock_outline_rounded,
                                Colors.orangeAccent,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureNewPin
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white38,
                                    size: 18,
                                  ),
                                  onPressed: () => setLocalState(
                                    () => obscureNewPin = !obscureNewPin,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Code PIN requis';
                                if (v.length != 4)
                                  return 'Exactement 4 chiffres requis';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Confirmer le nouveau Code PIN',
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: newPinConfirmCtrl,
                              obscureText: obscureNewPinConfirm,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                letterSpacing: obscureNewPinConfirm ? 0 : 8,
                                fontWeight: obscureNewPinConfirm
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                              decoration: _glassDeco(
                                'Confirmer le Code PIN',
                                Icons.lock_outline_rounded,
                                Colors.orangeAccent,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureNewPinConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white38,
                                    size: 18,
                                  ),
                                  onPressed: () => setLocalState(
                                    () => obscureNewPinConfirm =
                                        !obscureNewPinConfirm,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Confirmation requise';
                                if (v != newPinCtrl.text)
                                  return 'Les Codes PIN ne correspondent pas';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    phoneCtrl.dispose();
                    codeCtrl.dispose();
                    newPinCtrl.dispose();
                    newPinConfirmCtrl.dispose();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.inter(color: Colors.white38),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setLocalState(() {
                      localError = null;
                      localSuccess = null;
                    });

                    if (currentStep == 1) {
                      if (formKeyPhone.currentState!.validate()) {
                        final phone = phoneCtrl.text.trim();
                        if (phone == state.pharmacyContact1.trim()) {
                          final randomVal =
                              (1000 + Random.secure().nextInt(9000)).toString();
                          generatedCode = randomVal;

                          setLocalState(() {
                            currentStep = 2;
                            localSuccess =
                                'Le message de confirmation a été envoyé sur son numéro de téléphone.';
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF1E293B),
                              duration: const Duration(seconds: 12),
                              content: Text(
                                '📲 SMS : Le message de confirmation a été envoyé sur son numéro de téléphone ($phone) : $generatedCode',
                                style: GoogleFonts.inter(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              action: SnackBarAction(
                                label: 'Copier',
                                textColor: Colors.orangeAccent,
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: generatedCode),
                                  );
                                },
                              ),
                            ),
                          );
                        } else {
                          setLocalState(() {
                            localError =
                                'Ce numéro de téléphone ne correspond à aucun compte administrateur.';
                          });
                        }
                      }
                    } else if (currentStep == 2) {
                      if (formKeyCode.currentState!.validate()) {
                        setLocalState(() {
                          currentStep = 3;
                          localSuccess =
                              'Code validé ! Définissez le nouveau Code PIN administrateur.';
                        });
                      }
                    } else if (currentStep == 3) {
                      if (formKeyPin.currentState!.validate()) {
                        final phone = phoneCtrl.text.trim();
                        final newPinCode = newPinCtrl.text;
                        final success = state.resetPinCodeByPhone(
                          phone,
                          newPinCode,
                        );
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.orangeAccent,
                              content: Text(
                                'Code PIN administrateur réinitialisé avec succès ! Connectez-vous.',
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                          phoneCtrl.dispose();
                          codeCtrl.dispose();
                          newPinCtrl.dispose();
                          newPinConfirmCtrl.dispose();
                          Navigator.pop(context);
                        } else {
                          setLocalState(() {
                            localError =
                                'Erreur lors de la réinitialisation du Code PIN.';
                          });
                        }
                      }
                    }
                  },
                  child: Text(
                    currentStep == 3 ? 'Confirmer' : 'Suivant',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordDialog(Color themeColor) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final phoneCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final newPassConfirmCtrl = TextEditingController();

    final formKeyPhone = GlobalKey<FormState>();
    final formKeyCode = GlobalKey<FormState>();
    final formKeyPass = GlobalKey<FormState>();

    int currentStep = 1;
    String generatedCode = '';
    String? localError;
    String? localSuccess;
    bool obscureNewPass = true;
    bool obscureNewPassConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              title: Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: themeColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Récupération de compte',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (localError != null) ...[
                      _alertBox(
                        localError!,
                        Colors.redAccent,
                        Icons.error_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (localSuccess != null) ...[
                      _alertBox(
                        localSuccess!,
                        themeColor,
                        Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (currentStep == 1)
                      Form(
                        key: formKeyPhone,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entrez le numéro de téléphone associé à votre pharmacie (l\'administrateur) pour recevoir le code de récupération.',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Numéro de téléphone',
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(9),
                              ],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: _glassDeco(
                                'Ex: 620000000',
                                Icons.phone_rounded,
                                themeColor,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Veuillez saisir votre numéro';
                                if (v.trim().length != 9)
                                  return '9 chiffres requis';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                    if (currentStep == 2)
                      Form(
                        key: formKeyCode,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saisissez le code à 4 chiffres reçu sur le numéro ${phoneCtrl.text}.',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Code de validation',
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: codeCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                letterSpacing: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: _glassDeco(
                                'Code',
                                Icons.message_rounded,
                                themeColor,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Code requis';
                                if (v.trim() != generatedCode)
                                  return 'Code de validation incorrect';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                    if (currentStep == 3)
                      Form(
                        key: formKeyPass,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Définissez votre nouveau mot de passe administrateur.',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nouveau mot de passe',
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: newPassCtrl,
                              obscureText: obscureNewPass,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: _glassDeco(
                                'Nouveau mot de passe',
                                Icons.lock_outline_rounded,
                                themeColor,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureNewPass
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white38,
                                    size: 18,
                                  ),
                                  onPressed: () => setLocalState(
                                    () => obscureNewPass = !obscureNewPass,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Mot de passe requis';
                                if (v.length < 4) return 'Min 4 caractères';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Confirmer le nouveau mot de passe',
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: newPassConfirmCtrl,
                              obscureText: obscureNewPassConfirm,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: _glassDeco(
                                'Confirmer le mot de passe',
                                Icons.lock_outline_rounded,
                                themeColor,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureNewPassConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white38,
                                    size: 18,
                                  ),
                                  onPressed: () => setLocalState(
                                    () => obscureNewPassConfirm =
                                        !obscureNewPassConfirm,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Confirmation requise';
                                if (v != newPassCtrl.text)
                                  return 'Les mots de passe ne correspondent pas';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    phoneCtrl.dispose();
                    codeCtrl.dispose();
                    newPassCtrl.dispose();
                    newPassConfirmCtrl.dispose();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.inter(color: Colors.white38),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setLocalState(() {
                      localError = null;
                      localSuccess = null;
                    });

                    if (currentStep == 1) {
                      if (formKeyPhone.currentState!.validate()) {
                        final phone = phoneCtrl.text.trim();
                        if (phone == state.pharmacyContact1.trim()) {
                          final randomVal =
                              (1000 + Random.secure().nextInt(9000)).toString();
                          generatedCode = randomVal;

                          setLocalState(() {
                            currentStep = 2;
                            localSuccess =
                                'Le message de confirmation a été envoyé sur son numéro de téléphone.';
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF1E293B),
                              duration: const Duration(seconds: 12),
                              content: Text(
                                '📲 SMS : Le message de confirmation a été envoyé sur son numéro de téléphone ($phone) : $generatedCode',
                                style: GoogleFonts.inter(
                                  color: themeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              action: SnackBarAction(
                                label: 'Copier',
                                textColor: themeColor,
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: generatedCode),
                                  );
                                },
                              ),
                            ),
                          );
                        } else {
                          setLocalState(() {
                            localError =
                                'Ce numéro de téléphone ne correspond à aucun compte administrateur.';
                          });
                        }
                      }
                    } else if (currentStep == 2) {
                      if (formKeyCode.currentState!.validate()) {
                        setLocalState(() {
                          currentStep = 3;
                          localSuccess =
                              'Code validé avec succès ! Définissez le nouveau mot de passe.';
                        });
                      }
                    } else if (currentStep == 3) {
                      if (formKeyPass.currentState!.validate()) {
                        final phone = phoneCtrl.text.trim();
                        final newPassword = newPassCtrl.text;
                        final success = state.resetPasswordByPhone(
                          phone,
                          newPassword,
                        );
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: themeColor,
                              content: Text(
                                'Mot de passe administrateur réinitialisé avec succès ! Connectez-vous.',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                          phoneCtrl.dispose();
                          codeCtrl.dispose();
                          newPassCtrl.dispose();
                          newPassConfirmCtrl.dispose();
                          Navigator.pop(context);
                        } else {
                          setLocalState(() {
                            localError =
                                'Erreur lors de la réinitialisation du mot de passe.';
                          });
                        }
                      }
                    }
                  },
                  child: Text(
                    currentStep == 3 ? 'Confirmer' : 'Suivant',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}
