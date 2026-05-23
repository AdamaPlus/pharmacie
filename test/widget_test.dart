import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmaguinee/main.dart';
import 'package:pharmaguinee/providers/app_state_provider.dart';

void main() {
  setUpAll(() {
    // Disable dynamic runtime font downloading in tests
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('PharmaGuinee App Startup Smoke Test', (WidgetTester tester) async {
    // Set screen size to a desktop dimension to prevent RenderFlex overflow in testing
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    final state = AppStateProvider();
    // Force role to GUEST to render the Login View
    state.logout();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const PharmaGuineeApp(),
      ),
    );

    // Verify that the login screen header is displayed.
    expect(find.text('PharmaGuinée'), findsWidgets);
    expect(find.text('COMPTES DE TEST RAPIDE'), findsOneWidget);

    // Verify the presence of fast demo profiles
    expect(find.text('Administrateur'), findsOneWidget);
    expect(find.text('Pharmacien'), findsOneWidget);
  });
}
