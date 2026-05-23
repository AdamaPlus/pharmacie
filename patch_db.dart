import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('pharmaguinee_db.json');
  if (await file.exists()) {
    final content = await file.readAsString();
    final data = jsonDecode(content);
    
    final products = data['products'] as List;
    for (var p in products) {
      if (p['name'] == 'Huile Cosmétique' && p['id'] == 'P005') {
        p['id'] = 'P009';
      } else if (p['name'] == 'Savon 100 points' && p['id'] == 'P006') {
        p['id'] = 'P010';
      } else if (p['name'] == 'Dentifrice Signal' && p['id'] == 'P007') {
        p['id'] = 'P011';
      }
    }
    
    await file.writeAsString(jsonEncode(data));
    print('Database patched successfully.');
  } else {
    print('No database file found, mock data will be used.');
  }
}
