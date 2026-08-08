import 'package:flutter_test/flutter_test.dart';
import 'package:pharmaguinee/providers/app_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a successful activation keeps the app permanently unlocked', () async {
    final provider = AppStateProvider();

    final isActivated = await provider.validateLicense('M@riame@@##Ad@m!a62380//');

    expect(isActivated, isTrue);
    expect(provider.isTrialExpired, isFalse);
    expect(provider.isLicensed, isTrue);
  });
}
