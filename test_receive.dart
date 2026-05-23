import 'dart:convert';
import 'lib/models/pharmacy_models.dart';
import 'lib/services/database_service.dart';
import 'lib/providers/app_state_provider.dart';

void main() async {
  final provider = AppStateProvider();
  await Future.delayed(Duration(seconds: 1)); // Wait for init
  
  final prod = provider.products.firstWhere((p) => p.id == 'P007');
  print('Before receiving: ${prod.name}, qty: ${prod.totalQuantity}');
  
  provider.receiveSupplierOrder('SUP001', 'O002');
  
  print('After receiving: ${prod.name}, qty: ${prod.totalQuantity}');
}
