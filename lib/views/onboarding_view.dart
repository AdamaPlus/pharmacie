import 'package:flutter/material.dart';
import 'package:pharmaguinee/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  static const _green = Color(0xFF10B981);
  static const _ink = Color(0xFF17212B);
  static const _muted = Color(0xFF5F6B78);

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      image: 'assets/images/onboarding_pharmacy.png',
      eyebrow: 'UNE PHARMACIE BIEN ORGANISÉE',
      title: 'Gérez votre pharmacie avec simplicité',
      description:
          'Centralisez vos produits, vos lots et vos mouvements de stock dans un seul espace clair. Vous connaissez à tout moment les quantités disponibles et les médicaments qui nécessitent votre attention.',
      detail:
          'Moins de tâches répétitives, moins d’erreurs et davantage de temps pour accueillir et conseiller vos patients.',
    ),
    _OnboardingPage(
      image: 'assets/images/onboarding_team.png',
      eyebrow: 'UN TRAVAIL D’ÉQUIPE PLUS EFFICACE',
      title: 'Toute votre équipe avance ensemble',
      description:
          'Chaque membre du personnel accède rapidement aux informations utiles pour servir les patients. Les ventes, les opérations quotidiennes et les responsabilités de chacun restent faciles à suivre.',
      detail:
          'Votre équipe travaille avec des données fiables et une vision commune, de l’ouverture jusqu’à la clôture de la journée.',
    ),
    _OnboardingPage(
      image: 'assets/images/onboarding_medicines.png',
      eyebrow: 'DES DÉCISIONS FONDÉES SUR VOS DONNÉES',
      title: 'Pilotez vos ventes et vos médicaments',
      description:
          'Consultez vos performances, identifiez les produits les plus demandés et anticipez les besoins de réapprovisionnement. Les indicateurs essentiels sont réunis pour vous aider à décider rapidement.',
      detail:
          'Gardez le contrôle sur votre activité et développez votre pharmacie avec une information lisible, précise et toujours disponible.',
    ),
  ];

  void _finish() => context.read<AppStateProvider>().markOnboardingSeen();

  void _goNext() {
    if (_currentPage == _pages.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) =>
                  _PageContent(page: _pages[index]),
            ),
            Positioned(
              top: 18,
              right: 24,
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(foregroundColor: _muted),
                child: const Text('Passer',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 22,
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: index == _currentPage ? 30 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 7),
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? _green
                              : const Color(0xFFD8DEE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _goNext,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(150, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1
                              ? 'Commencer'
                              : 'Suivant',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, size: 19),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final image = Container(
          color: const Color(0xFFF2F7F5),
          child: Image.asset(
            page.image,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.local_pharmacy_outlined,
                  size: 90, color: _OnboardingViewState._green),
            ),
          ),
        );
        final copy = Padding(
          padding: EdgeInsets.fromLTRB(compact ? 24 : 58, compact ? 22 : 76,
              compact ? 24 : 58, compact ? 92 : 96),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                page.eyebrow,
                style: const TextStyle(
                  color: _OnboardingViewState._green,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: compact ? 12 : 20),
              Text(
                page.title,
                style: TextStyle(
                  color: _OnboardingViewState._ink,
                  fontSize: compact ? 30 : 46,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: compact ? 14 : 24),
              Text(
                page.description,
                style: TextStyle(
                  color: _OnboardingViewState._muted,
                  fontSize: compact ? 15 : 18,
                  height: 1.65,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: compact ? 12 : 18),
              Container(
                padding: const EdgeInsets.only(left: 16),
                decoration: const BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: _OnboardingViewState._green, width: 3)),
                ),
                child: Text(
                  page.detail,
                  style: TextStyle(
                    color: _OnboardingViewState._ink,
                    fontSize: compact ? 13 : 15,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        );

        if (compact) {
          return Column(
            children: [
              Expanded(flex: 4, child: image),
              Expanded(flex: 6, child: SingleChildScrollView(child: copy)),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 52, child: image),
            Expanded(flex: 48, child: copy),
          ],
        );
      },
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.detail,
  });

  final String image;
  final String eyebrow;
  final String title;
  final String description;
  final String detail;
}
