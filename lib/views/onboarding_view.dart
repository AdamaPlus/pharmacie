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
  int _currentPage = 0;

  final List<_SlideData> _slides = [
    const _SlideData(
      imagePath: 'assets/images/intro_1.jpg',
      buttonColor: Color(0xFF10B981),
      buttonText: 'Suivant',
      caption: 'Bienvenue sur PharmaGuinée : la solution moderne et intuitive pour la gestion complète de votre pharmacie.',
      highlightText: 'Bienvenue sur PharmaGuinée',
      bottom: 24,
      left: 24,
    ),
    const _SlideData(
      imagePath: 'assets/images/intro_2.jpg',
      buttonColor: Color(0xFF06B6D4),
      buttonText: 'Suivant',
      caption: 'Suivez vos stocks en temps réel et contrôlez les entrées et sorties de médicaments en toute simplicité.',
      highlightText: 'Gestion de stock intelligente',
      bottom: 24,
      left: 24,
    ),
    const _SlideData(
      imagePath: 'assets/images/intro_3.jpg',
      buttonColor: Color(0xFF8B5CF6),
      buttonText: 'Commencer',
      caption: 'Enregistrez vos ventes rapidement, gérez les ordonnances et délivrez des reçus imprimables instantanés.',
      highlightText: 'Ventes fluides & Reçus rapides',
      top: 24,
      right: 24,
    ),
  ];

  void _goNext() {
    if (_currentPage < _slides.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      final state = Provider.of<AppStateProvider>(context, listen: false);
      state.markOnboardingSeen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF07111F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Text(
                'PharmaGuinée',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    key: ValueKey<String>(slide.imagePath),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            slide.imagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          if (slide.highlightText != null)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                              top: slide.top,
                              left: slide.left,
                              right: slide.right,
                              bottom: slide.bottom,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Text(
                                  slide.highlightText!,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  slide.caption,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(right: 8),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? slide.buttonColor
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            if (i == _currentPage)
                              BoxShadow(
                                color: slide.buttonColor.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _goNext,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: slide.buttonColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: slide.buttonColor.withOpacity(0.4),
                              blurRadius: 15,
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
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
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
    );
  }
}

class _SlideData {
  final String imagePath;
  final Color buttonColor;
  final String buttonText;
  final String caption;
  final String? highlightText;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  const _SlideData({
    required this.imagePath,
    required this.buttonColor,
    required this.buttonText,
    required this.caption,
    this.highlightText,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });
}
