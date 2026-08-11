import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaguinee/providers/app_state_provider.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/intro_1.jpg',
      'title': 'Gestion de Stock',
      'desc': 'Suivez vos médicaments en temps réel, gérez les entrées et sorties de stock facilement.',
    },
    {
      'image': 'assets/images/intro_2.jpg',
      'title': 'Ventes & Facturation',
      'desc': 'Enregistrez vos ventes, générez des factures et suivez votre chiffre d\'affaires.',
    },
    {
      'image': 'assets/images/intro_3.jpg',
      'title': 'Rapports & Analyses',
      'desc': 'Consultez vos rapports détaillés et prenez les meilleures décisions pour votre pharmacie.',
    },
  ];

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Provider.of<AppStateProvider>(context, listen: false).markOnboardingSeen();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _pages[index]['image']!,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black87,
                        ],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pages[index]['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _pages[index]['desc']!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Indicateurs de page
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? const Color(0xFF10B981)
                        : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          // Bouton Suivant / Commencer
          Positioned(
            bottom: 20,
            right: 24,
            child: ElevatedButton(
              onPressed: _goNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _currentPage < _pages.length - 1 ? 'Suivant' : 'Commencer',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // Bouton Passer (skip)
          if (_currentPage < _pages.length - 1)
            Positioned(
              bottom: 28,
              left: 24,
              child: TextButton(
                onPressed: () {
                  Provider.of<AppStateProvider>(context, listen: false).markOnboardingSeen();
                },
                child: const Text(
                  'Passer',
                  style: TextStyle(color: Colors.white60, fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
