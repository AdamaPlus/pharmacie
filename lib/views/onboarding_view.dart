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
    ),
    const _SlideData(
      imagePath: 'assets/images/intro_2.jpg',
      buttonColor: Color(0xFF3B82F6),
      buttonText: 'Commencer',
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond plein écran
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Image.asset(
              slide.imagePath,
              key: ValueKey<String>(slide.imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
          // Contrôles en bas de l'écran
          Positioned(
            bottom: 48,
            left: 48,
            right: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicateurs de page (Dots)
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

                // Bouton Suivant / Commencer
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
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final String imagePath;
  final Color buttonColor;
  final String buttonText;

  const _SlideData({
    required this.imagePath,
    required this.buttonColor,
    required this.buttonText,
  });
}
