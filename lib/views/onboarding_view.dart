import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _bgAnimCtrl;
  late Animation<double> _bgAnim;

  late AnimationController _slideAnimCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  static const _themeGreen = Color(0xFF10B981);
  static const _themeDark = Color(0xFF0F172A);
  static const _themeDark2 = Color(0xFF1E293B);

  // ─── Données des deux slides ───────────────────────────────────────
  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      imagePath: 'assets/images/intro_1.jpg',
      icon: Icons.local_pharmacy_rounded,
      iconColor: Color(0xFF10B981),
      iconBg: Color(0xFF10B981),
      title: 'Bienvenue sur\nPharmaGuinée',
      subtitle:
          'La solution complète pour gérer votre pharmacie : stocks, ventes, fournisseurs et bien plus — tout en un seul endroit.',
      badge1Icon: Icons.inventory_2_rounded,
      badge1Label: 'Gestion des stocks',
      badge2Icon: Icons.point_of_sale_rounded,
      badge2Label: 'Point de vente',
      badge3Icon: Icons.people_alt_rounded,
      badge3Label: 'Gestion des équipes',
      gradient: [Color(0xFF0F172A), Color(0xFF0D2B1A)],
    ),
    _OnboardingSlide(
      imagePath: 'assets/images/intro_2.jpg',
      icon: Icons.shield_rounded,
      iconColor: Color(0xFF3B82F6),
      iconBg: Color(0xFF3B82F6),
      title: 'Sécurisé &\nPerformant',
      subtitle:
          'Sécurité renforcée et contrôle des permissions configurables pour votre équipe.',
      badge1Icon: Icons.lock_rounded,
      badge1Label: 'Données sécurisées',
      badge2Icon: Icons.bar_chart_rounded,
      badge2Label: 'Rapports en temps réel',
      badge3Icon: Icons.local_shipping_rounded,
      badge3Label: 'Suivi fournisseurs',
      gradient: [Color(0xFF0F172A), Color(0xFF0D1B2B)],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _bgAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgAnimCtrl, curve: Curves.easeInOut);

    _slideAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _slideAnimCtrl, curve: Curves.easeOut);
    _slideAnimCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimCtrl.dispose();
    _slideAnimCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _slideAnimCtrl.reset();
      _slideAnimCtrl.forward();
    } else {
      // Dernier slide → marquer comme vu et continuer
      final state = Provider.of<AppStateProvider>(context, listen: false);
      state.markOnboardingSeen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: _themeDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Image de fond plein écran avec transition (Cliquable pour Suivant) ──
          GestureDetector(
            onTap: _goNext,
            behavior: HitTestBehavior.opaque,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: Image.asset(
                slide.imagePath,
                key: ValueKey<String>(slide.imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // ── Overlay sombre pour la lisibilité ───────────────────────
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // ── Fond animé avec particules décoratives ──────────────────
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, _) {
              return CustomPaint(
                painter: _BgParticlesPainter(
                  progress: _bgAnim.value,
                  accentColor: slide.iconBg,
                ),
              );
            },
          ),

          // ── Overlay dégradé radial ──────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.8,
                colors: [
                  slide.iconBg.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ── Contenu principal ───────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) => const SizedBox.shrink(),
          ),

          // ── Corps de la slide ───────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icône principale
                        _buildMainIcon(slide),

                        const SizedBox(height: 48),

                        // Titre
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Sous-titre
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16.5,
                            color: Colors.white.withOpacity(0.55),
                            height: 1.65,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Badges fonctionnalités
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _featureBadge(slide.badge1Icon, slide.badge1Label, slide.iconBg),
                            const SizedBox(width: 16),
                            _featureBadge(slide.badge2Icon, slide.badge2Label, slide.iconBg),
                            const SizedBox(width: 16),
                            _featureBadge(slide.badge3Icon, slide.badge3Label, slide.iconBg),
                          ],
                        ),

                        const SizedBox(height: 60),

                        // Indicateurs de page + bouton
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Dots
                            Row(
                              children: List.generate(
                                _slides.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOut,
                                  margin: const EdgeInsets.only(right: 8),
                                  width: i == _currentPage ? 32 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: i == _currentPage
                                        ? slide.iconBg
                                        : Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),

                            // Bouton Suivant / Commencer
                            _buildNextButton(slide, isLast),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Numéro de slide en haut à droite ────────────────────────
          Positioned(
            top: 28,
            right: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                '${_currentPage + 1} / ${_slides.length}',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // ── Logo en haut à gauche ───────────────────────────────────
          Positioned(
            top: 24,
            left: 36,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _themeGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _themeGreen.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    color: _themeGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'PharmaGuinée',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Icône principale avec anneau lumineux ───────────────────────────
  Widget _buildMainIcon(_OnboardingSlide slide) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Glow effect
        AnimatedBuilder(
          animation: _bgAnim,
          builder: (context, _) {
            return Container(
              width: 140 + 20 * _bgAnim.value,
              height: 140 + 15 * _bgAnim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: slide.iconBg.withOpacity(0.3 + 0.05 * _bgAnim.value),
                    blurRadius: 45,
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
          },
        ),
        // Big floating icon in a beautiful glowing circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(color: slide.iconBg, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            slide.icon,
            color: slide.iconColor,
            size: 44,
          ),
        ),
      ],
    );
  }

  // ── Badge fonctionnalité ────────────────────────────────────────────
  Widget _featureBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bouton Suivant / Commencer ─────────────────────────────────────
  Widget _buildNextButton(_OnboardingSlide slide, bool isLast) {
    return GestureDetector(
      onTap: _goNext,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              slide.iconBg,
              slide.iconBg.withOpacity(0.75),
            ],
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: slide.iconBg.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLast ? 'Commencer' : 'Suivant',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLast
                    ? Icons.login_rounded
                    : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modèle de données pour chaque slide ────────────────────────────────
class _OnboardingSlide {
  final String imagePath;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final IconData badge1Icon;
  final String badge1Label;
  final IconData badge2Icon;
  final String badge2Label;
  final IconData badge3Icon;
  final String badge3Label;
  final List<Color> gradient;

  const _OnboardingSlide({
    required this.imagePath,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.badge1Icon,
    required this.badge1Label,
    required this.badge2Icon,
    required this.badge2Label,
    required this.badge3Icon,
    required this.badge3Label,
    required this.gradient,
  });
}

// ── Peintre de particules en arrière-plan ──────────────────────────────
class _BgParticlesPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _BgParticlesPainter({required this.progress, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final positions = [
      Offset(size.width * 0.12, size.height * 0.18),
      Offset(size.width * 0.88, size.height * 0.12),
      Offset(size.width * 0.05, size.height * 0.72),
      Offset(size.width * 0.92, size.height * 0.68),
      Offset(size.width * 0.5, size.height * 0.05),
      Offset(size.width * 0.72, size.height * 0.88),
      Offset(size.width * 0.22, size.height * 0.95),
    ];

    final radii = [80.0, 120.0, 60.0, 100.0, 90.0, 70.0, 50.0];

    for (int i = 0; i < positions.length; i++) {
      final phase = (progress + i * 0.15) % 1.0;
      paint.color = accentColor.withOpacity(0.03 + 0.025 * phase);
      canvas.drawCircle(
        positions[i] + Offset(0, 20 * phase),
        radii[i],
        paint,
      );
    }

    // Lignes diagonales décoratives
    final linePaint = Paint()
      ..color = accentColor.withOpacity(0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final y = size.height * (i / 5.0);
      canvas.drawLine(
        Offset(0, y + 30 * progress),
        Offset(size.width, y - 30 + 30 * progress),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BgParticlesPainter old) =>
      old.progress != progress || old.accentColor != accentColor;
}
