import 'package:flutter_test/flutter_test.dart';
import 'package:pharmaguinee/models/pharmacy_models.dart';
import 'package:pharmaguinee/providers/app_state_provider.dart';

void main() {
  test('seller with new_medicines permission can add products but cannot edit product details', () async {
    final state = AppStateProvider();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    state.users.add(
      UserAccount(
        username: 'seller1',
        passwordHash: 'secret',
        role: 'VENDEUR',
        fullName: 'Vendeur Test',
        permissions: ['new_medicines'],
      ),
    );

    expect(state.login('seller1', 'secret', ''), isTrue);
    expect(state.canCreateNewMedicines(), isTrue);
    expect(state.canEditProductDetails(), isFalse);
  });
}
