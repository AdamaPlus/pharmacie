import 'package:flutter_test/flutter_test.dart';
import 'package:pharmaguinee/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Windows crée AppData depuis USERPROFILE si APPDATA est absent', () {
    final candidates = DatabaseService.windowsDataDirectoryCandidates({
      'USERPROFILE': r'C:\Users\pharmacie',
    });

    expect(
      candidates.first,
      p.join(r'C:\Users\pharmacie', 'AppData', 'Roaming', 'PharmaGuinee'),
    );
    expect(
      candidates,
      contains(p.join(r'C:\Users\pharmacie', 'Documents', 'PharmaGuinee')),
    );
  });

  test('Windows privilégie APPDATA quand il est disponible', () {
    final candidates = DatabaseService.windowsDataDirectoryCandidates({
      'APPDATA': r'D:\Data\Roaming',
      'USERPROFILE': r'C:\Users\pharmacie',
    });

    expect(candidates.first, p.join(r'D:\Data\Roaming', 'PharmaGuinee'));
  });
}
