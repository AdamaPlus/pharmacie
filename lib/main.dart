import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/app_state_provider.dart';
import 'views/login_view.dart';
import 'views/main_layout.dart';
import 'views/onboarding_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: const PharmaGuineeApp(),
    ),
  );
}

class PharmaGuineeApp extends StatelessWidget {
  const PharmaGuineeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = state.isDarkMode;

    return MaterialApp(
      title: 'PharmaGuinée - Gestion de Pharmacie & RH',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: state.bgPrimary,
        colorScheme: isDark
            ? const ColorScheme.dark(
                primary: Color(0xFF10B981),
                secondary: Color(0xFF06B6D4),
                background: Color(0xFF0F172A),
                surface: Color(0xFF1E293B),
                onPrimary: Colors.white,
              )
            : const ColorScheme.light(
                primary: Color(0xFF10B981),
                secondary: Color(0xFF06B6D4),
                background: Color(0xFFF1F5F9),
                surface: Colors.white,
                onPrimary: Colors.white,
              ),
        textTheme: GoogleFonts.interTextTheme(
          isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
        ).apply(
          bodyColor: state.textPrimary,
          displayColor: state.textPrimary,
        ),
        cardTheme: CardThemeData(
          color: state.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dividerTheme: DividerThemeData(
          color: state.borderTheme,
          thickness: 1,
        ),
        useMaterial3: true,
      ),
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    // Attendre l'initialisation de la base de données
    if (!state.initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    // Premier lancement : afficher l'écran d'onboarding
    if (!state.hasSeenOnboarding) {
      return const OnboardingView();
    }

    // Si non authentifié → écran de connexion
    if (state.currentUserRole == 'GUEST') {
      return const LoginView();
    }

    // Sinon → interface principale
    return const MainLayout();
  }
}
