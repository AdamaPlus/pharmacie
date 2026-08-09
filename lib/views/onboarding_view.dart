import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<_SlideData> _slides = [
    const _SlideData(
      imagePath: 'assets/images/intro_1.jpg',
      title: 'Solution Médicale Complète',
      subtitle: 'Une plateforme moderne pour votre officine',
      caption:
          'Bienvenue sur PharmaGuinée : la solution intégrée pour gérer vos ventes, vos stocks et votre officine avec précision.',
      comment:
          '🏥 Votre officine mérite le meilleur outil.\nPharmaGuinée — la gestion qui sauve du temps, et des vies.',
      highlightText: 'Bienvenue sur PharmaGuinée',
      highlightIcon: Icons.verified_rounded,
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF059669),
      buttonText: 'Suivant',
      badgeAlignment: Alignment.bottomLeft,
    ),
    const _SlideData(
      imagePath: 'assets/images/intro_2.jpg',
      title: 'Gestion de Stock Intelligente',
      subtitle: 'Suivi en temps réel & contrôle des péremptions',
      caption:
          'Suivez vos stocks en temps réel, soyez alerté des produits en seuil critique et facilitez les réapprovisionnements.',
      comment:
          '📦 Zéro rupture. Zéro perte. Zéro stress.\nAnticipez chaque besoin avant qu\'il ne devienne urgent.',
      highlightText: 'Gestion de stock en temps réel',
      highlightIcon: Icons.inventory_2_rounded,
      primaryColor: Color(0xFF06B6D4),
      secondaryColor: Color(0xFF0284C7),
      buttonText: 'Suivant',
      badgeAlignment: Alignment.bottomLeft,
    ),
    const _SlideData(
      imagePath: 'assets/images/intro_3.jpg',
      title: 'Ventes Fluides & Reçus Rapides',
      subtitle: 'Encaissement instantané & bilans clairs',
      caption:
          'Enregistrez vos ventes en quelques clics, imprimez des reçus instantanés et obtenez une synthèse quotidienne de votre activité.',
      comment:
          '💊 Chaque ordonnance traitée est une vie protégée.\nAvec PharmaGuinée, transformez votre officine en pilier\nde santé pour toute la communauté.',
      highlightText: 'Ventes fluides & Reçus rapides',
      highlightIcon: Icons.point_of_sale_rounded,
      primaryColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFF6D28D9),
      buttonText: 'Accéder à l\'inscription',
      badgeAlignment: Alignment.topRight,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    state.markOnboardingSeen();
  }

  void _goNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _goPrevious() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF060C17),
      body: Stack(
        children: [
          // ── Background Ambient Glow Effects ──
          Positioned(
            top: -120,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: slide.primaryColor.withOpacity(0.15),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: slide.secondaryColor.withOpacity(0.15),
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Column(
                          children: [
                            // ── Header Bar ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // App Branding with Icon
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          colors: [
                                            slide.primaryColor.withOpacity(0.4),
                                            slide.secondaryColor.withOpacity(0.4),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: slide.primaryColor.withOpacity(0.5),
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
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'PharmaGuinée',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 21,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          'Gestion Médicale & Officine',
                                          style: GoogleFonts.inter(
                                            color: Colors.white.withOpacity(0.55),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // Step Badge & Skip Button
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.12),
                                        ),
                                      ),
                                      child: Text(
                                        'Étape 0${_currentPage + 1} / 0${_slides.length}',
                                        style: GoogleFonts.inter(
                                          color: slide.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    TextButton.icon(
                                      onPressed: _finishOnboarding,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white70,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.skip_next_rounded, size: 18),
                                      label: Text(
                                        'Passer',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ── PageView Carousel Container ──
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 280),
                                child: PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (idx) {
                                    setState(() {
                                      _currentPage = idx;
                                    });
                                  },
                                  itemCount: _slides.length,
                                  itemBuilder: (context, index) {
                                    final item = _slides[index];
                                    final isLastSlide = index == _slides.length - 1;
                                    return _buildSlideCard(
                                      item,
                                      showNextButton: !isLastSlide,
                                      onNext: _goNext,
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Slide Title & Description Box ──
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              child: Container(
                                key: ValueKey<int>(_currentPage),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withOpacity(0.82),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: slide.primaryColor.withOpacity(0.25),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _itemIcon(_currentPage),
                                          color: slide.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            slide.title,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      slide.subtitle,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: slide.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      slide.caption,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // ── Bottom Action & Indicator Bar ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Previous Button
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  opacity: _currentPage > 0 ? 1.0 : 0.0,
                                  child: OutlinedButton.icon(
                                    onPressed: _currentPage > 0 ? _goPrevious : null,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                    label: Text(
                                      'Précédent',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                // Indicators
                                Row(
                                  children: List.generate(
                                    _slides.length,
                                    (i) => GestureDetector(
                                      onTap: () {
                                        _pageController.animateToPage(
                                          i,
                                          duration: const Duration(milliseconds: 350),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: i == _currentPage ? 26 : 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: i == _currentPage
                                              ? slide.primaryColor
                                              : Colors.white.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(5),
                                          boxShadow: [
                                            if (i == _currentPage)
                                              BoxShadow(
                                                color: slide.primaryColor.withOpacity(0.5),
                                                blurRadius: 8,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Next / Action Button
                                if (isLast)
                                  InkWell(
                                    onTap: _finishOnboarding,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 22, vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            slide.primaryColor,
                                            slide.secondaryColor,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: slide.primaryColor.withOpacity(0.4),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Accéder",
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.how_to_reg_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 80),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _itemIcon(int index) {
    switch (index) {
      case 0:
        return Icons.health_and_safety_rounded;
      case 1:
        return Icons.inventory_rounded;
      case 2:
        return Icons.point_of_sale_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Widget _buildSlideCard(
    _SlideData slide, {
    bool showNextButton = false,
    VoidCallback? onNext,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: slide.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image plein cadre
            Image.asset(
              slide.imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            // Gradient haut + bas pour la profondeur visuelle
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.72),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Badge highlight en haut ou bas selon slide
            Align(
              alignment: slide.badgeAlignment,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: slide.primaryColor.withOpacity(0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: slide.primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: slide.primaryColor.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          slide.highlightIcon,
                          color: slide.primaryColor,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        slide.highlightText,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Commentaire sur l'image (slides 0 et 1 seulement) ──
            if (slide.comment != null)
              Positioned(
                bottom: showNextButton ? 72 : 16,
                left: 16,
                right: showNextButton ? 150 : 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: slide.primaryColor.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        slide.comment!,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Bouton Suivant intégré dans l'image (slides 0 et 1 seulement) ──
            if (showNextButton)
              Positioned(
                bottom: 18,
                right: 18,
                child: GestureDetector(
                  onTap: onNext,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              slide.primaryColor.withOpacity(0.85),
                              slide.secondaryColor.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: slide.primaryColor.withOpacity(0.55),
                              blurRadius: 18,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              slide.buttonText,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String imagePath;
  final String title;
  final String subtitle;
  final String caption;
  final String? comment;
  final String highlightText;
  final IconData highlightIcon;
  final Color primaryColor;
  final Color secondaryColor;
  final String buttonText;
  final Alignment badgeAlignment;

  const _SlideData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.caption,
    this.comment,
    required this.highlightText,
    required this.highlightIcon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.buttonText,
    required this.badgeAlignment,
  });
}
