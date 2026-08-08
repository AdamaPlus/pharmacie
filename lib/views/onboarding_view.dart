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
      highlightText: 'Bienvenue sur PharmaGuinée',
      highlightIcon: Icons.verified_rounded,
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF059669),
      buttonText: 'Suivant',
      bottom: 24,
      left: 24,
    ),
    const _SlideData(
      imagePath: 'assets/images/intro_2.jpg',
      title: 'Gestion de Stock Intelligente',
      subtitle: 'Suivi en temps réel & contrôle des péremptions',
      caption:
          'Suivez vos stocks en temps réel, soyez alerté des produits en seuil critique et facilitez les réapprovisionnements.',
      highlightText: 'Gestion de stock en temps réel',
      highlightIcon: Icons.inventory_2_rounded,
      primaryColor: Color(0xFF06B6D4),
      secondaryColor: Color(0xFF0284C7),
      buttonText: 'Suivant',
      bottom: 24,
      left: 24,
    ),
    const _SlideData(
      imagePath: 'assets/images/intro_3.jpg',
      title: 'Ventes Fluides & Reçus Rapides',
      subtitle: 'Encaissement instantané & bilans clairs',
      caption:
          'Enregistrez vos ventes en quelques clics, imprimez des reçus instantanés et obtenez une synthèse quotidienne de votre activité.',
      highlightText: 'Ventes fluides & Reçus rapides',
      highlightIcon: Icons.point_of_sale_rounded,
      primaryColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFF6D28D9),
      buttonText: 'Accéder à l\'inscription',
      top: 24,
      right: 24,
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
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _goPrevious() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
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
          // ── Ambient background glows ──
          Positioned(
            top: -120,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: slide.primaryColor.withOpacity(0.12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: slide.secondaryColor.withOpacity(0.14),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                children: [
                  // ── Top Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Branding Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  slide.primaryColor.withOpacity(0.25),
                                  slide.secondaryColor.withOpacity(0.25),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: slide.primaryColor.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.local_pharmacy_rounded,
                              color: slide.primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PharmaGuinée',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Gestion Médicale & Officine',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Step Counter & Skip Button
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
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
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: _finishOnboarding,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white60,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
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
                  const SizedBox(height: 20),

                  // ── Main PageView Carousel ──
                  Expanded(
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
                        return _buildSlideCard(item);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Slide Title & Caption Box ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      key: ValueKey<int>(_currentPage),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: slide.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
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
                                itemIcon(index: _currentPage),
                                color: slide.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                slide.title,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slide.subtitle,
                            style: GoogleFonts.inter(
                              color: slide.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            slide.caption,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── Bottom Action & Pagination Bar ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Button
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _currentPage > 0 ? 1.0 : 0.0,
                        child: OutlinedButton.icon(
                          onPressed: _currentPage > 0 ? _goPrevious : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text(
                            'Précédent',
                            style: GoogleFonts.inter(
                              fontSize: 14,
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
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == _currentPage ? 28 : 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: i == _currentPage
                                    ? slide.primaryColor
                                    : Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  if (i == _currentPage)
                                    BoxShadow(
                                      color:
                                          slide.primaryColor.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Next / Registration Button
                      GestureDetector(
                        onTap: _goNext,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 14),
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
                                  color: slide.primaryColor.withOpacity(0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
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
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isLast
                                      ? Icons.how_to_reg_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData itemIcon({required int index}) {
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

  Widget _buildSlideCard(_SlideData slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: slide.primaryColor.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with cover fit
            Image.asset(
              slide.imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF060C17).withOpacity(0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Floating highlight badge
            Positioned(
              top: slide.top,
              left: slide.left,
              right: slide.right,
              bottom: slide.bottom,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: slide.primaryColor.withOpacity(0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: slide.primaryColor.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: slide.primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        slide.highlightIcon,
                        color: slide.primaryColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      slide.highlightText,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
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
  final String highlightText;
  final IconData highlightIcon;
  final Color primaryColor;
  final Color secondaryColor;
  final String buttonText;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  const _SlideData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.caption,
    required this.highlightText,
    required this.highlightIcon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.buttonText,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });
}

