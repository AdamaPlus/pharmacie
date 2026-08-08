import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/pharmacy_models.dart';
import '../providers/app_state_provider.dart';

class ReplenishmentView extends StatelessWidget {
  const ReplenishmentView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final lowStockItems = state.products.where((p) => p.totalQuantity <= p.minStock && !state.isProductOrdered(p.id)).toList();
    
    // Check if there are any active orders
    bool hasActiveOrders = false;
    for (var sup in state.suppliers) {
      if (sup.orders.any((o) => o.status == 'COMMANDE')) {
        hasActiveOrders = true;
        break;
      }
    }

    return Scaffold(
      backgroundColor: state.bgPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Purchase Order Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Réapprovisionnement',
                      style: GoogleFonts.outfit(
                        color: state.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gérer les stocks faibles et émettre des bons de commande',
                      style: GoogleFonts.inter(
                        color: state.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: state.products.isEmpty
                      ? null
                      : () => _showCreateOrderDialog(context, state),
                  icon: const Icon(Icons.shopping_bag_rounded, size: 18),
                  label: const Text('Bonne commande'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: state.bgSecondary,
                    disabledForegroundColor: state.textSecondaryLight,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Articles en stock faible
            Container(
              decoration: BoxDecoration(
                color: state.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Articles en stock faible (${lowStockItems.length})',
                          style: GoogleFonts.outfit(color: state.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.black12),
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: lowStockItems.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                                ),
                                child: const Icon(Icons.check, color: Color(0xFF10B981), size: 32),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tous les médicaments ont un stock suffisant',
                                style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 14),
                              ),
                            ],
                          )
                        : Column(
                            children: lowStockItems.map((p) {
                              final isRupture = p.totalQuantity <= 0;
                              return ListTile(
                                leading: Icon(
                                  isRupture ? Icons.error_outline : Icons.warning_amber_rounded, 
                                  color: isRupture ? Colors.redAccent : Colors.orangeAccent
                                ),
                                title: Row(
                                  children: [
                                    Text(p.name, style: GoogleFonts.inter(color: state.textPrimary)),
                                    if (isRupture) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('RUPTURE', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text('En stock : ${p.totalQuantity} (Min: ${p.minStock})', style: GoogleFonts.inter(color: state.textSecondary)),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Commandes de réapprovisionnement
            Container(
              decoration: BoxDecoration(
                color: state.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, color: Color(0xFF3B82F6), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Commandes de réapprovisionnement',
                          style: GoogleFonts.outfit(color: state.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.black12),
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: !hasActiveOrders
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_shipping_rounded, color: state.textSecondaryLight.withOpacity(0.3), size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune commande de réapprovisionnement',
                                style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 14),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Text(
                                'Des commandes sont en cours.',
                                style: GoogleFonts.inter(color: state.textPrimary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  state.setActiveTab(6);
                                },
                                child: const Text('Voir les commandes'),
                              ),
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

  // Create Supplier Order Dialog (exactly like the premium one in SupplierView)
  void _showCreateOrderDialog(BuildContext context, AppStateProvider state) {
    if (state.products.isEmpty) return;

    final formKey = GlobalKey<FormState>();
    final qtyCtrl = TextEditingController(text: "50");
    final customSupNameCtrl = TextEditingController();

    // If no suppliers exist yet, start directly in "custom supplier" mode
    final bool noSuppliers = state.suppliers.isEmpty;
    // Build a virtual "Autre" supplier for the case where list is empty
    final Supplier autreSup = Supplier(
      id: 'sup_autre',
      name: 'Autre fournisseur',
      contactPerson: '',
      phone: '',
      email: '',
      address: '',
      paymentTerms: 'A_LA_RECEPTION',
      orders: [],
      invoices: [],
    );
    Supplier selSup = noSuppliers
        ? autreSup
        : state.suppliers.firstWhere((s) => s.id != 'sup_autre', orElse: () => state.suppliers[0]);
    Product selProd = state.products[0];
    final priceCtrl = TextEditingController(text: selProd.purchasePrice.toStringAsFixed(0));
    List<OrderItem> orderItems = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double totalOrderAmount = orderItems.fold(0.0, (sum, item) => sum + (item.quantityOrdered * item.unitPrice));
            // Always show custom name field if no suppliers exist OR if "Autre" is selected
            bool showCustomSup = noSuppliers || selSup.id == 'sup_autre';

            final sortedSuppliers = List<Supplier>.from(state.suppliers);
            sortedSuppliers.removeWhere((s) => s.id == 'sup_autre');
            sortedSuppliers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            if (sortedSuppliers.isNotEmpty && !sortedSuppliers.any((s) => s.id == selSup.id)) {
              selSup = sortedSuppliers.first;
            }

            final sortedProducts = List<Product>.from(state.products);
            sortedProducts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            if (sortedProducts.isNotEmpty && !sortedProducts.any((p) => p.id == selProd.id)) {
              selProd = sortedProducts.first;
            }

            return AlertDialog(
              backgroundColor: state.bgSecondary,
              title: Row(
                children: [
                  const Icon(Icons.shopping_cart_checkout_rounded, color: Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  Text(
                    "Émettre une Bonne commande Fournisseur", 
                    style: GoogleFonts.outfit(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)
                  ),
                ],
              ),
              content: SizedBox(
                width: 700,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Select Supplier
                        Text("Fournisseur", style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        if (noSuppliers)
                          // No suppliers at all: show info message instead of dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: state.bgPrimary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Aucun fournisseur enregistré. Saisissez le nom ci-dessous.',
                                    style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: state.bgPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Supplier>(
                                value: selSup,
                                isExpanded: true,
                                dropdownColor: state.bgSecondary,
                                style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                                items: (() {
                                  final sorted = List<Supplier>.from(sortedSuppliers);
                                  sorted.add(autreSup);
                                  return sorted.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList();
                                })(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() {
                                      selSup = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        if (showCustomSup) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: customSupNameCtrl,
                            style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13.5),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: state.bgPrimary,
                              hintText: 'Saisir le nom du nouveau fournisseur',
                              hintStyle: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 12.5),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: state.borderTheme)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: state.borderTheme)),
                            ),
                            validator: (value) {
                              if (showCustomSup && (value == null || value.trim().isEmpty)) {
                                return 'Veuillez saisir le nom du fournisseur';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Section header: Ajouter des articles
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: state.bgPrimary.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_shopping_cart_rounded, color: Colors.blueAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Ajouter des produits à la bonne commande",
                                style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Selector and Qty Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Product dropdown
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Produit à commander", style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: state.bgPrimary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<Product>(
                                        value: selProd,
                                        isExpanded: true,
                                        dropdownColor: state.bgSecondary,
                                        style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13),
                                        items: (() {
                                          return sortedProducts.map((p) {
                                            final isRupture = p.totalQuantity <= 0;
                                            return DropdownMenuItem(
                                              value: p, 
                                              child: Text(
                                                "${p.name} (Catégorie: ${p.category})",
                                                style: GoogleFonts.inter(
                                                  color: isRupture ? Colors.redAccent : state.textPrimary,
                                                  fontWeight: isRupture ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              )
                                            );
                                          }).toList();
                                        })(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setDialogState(() {
                                              selProd = val;
                                              priceCtrl.text = val.purchasePrice.toStringAsFixed(0);
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Prix d'achat
                            Expanded(
                              flex: 2,
                              child: _dialogField(
                                context: context,
                                label: "Prix d'achat (GNF)", 
                                controller: priceCtrl, 
                                isNumber: true, 
                                required: true,
                                hintText: "10000"
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Quantity
                            Expanded(
                              flex: 1,
                              child: _dialogField(
                                context: context,
                                label: "Quantité", 
                                controller: qtyCtrl, 
                                isNumber: true, 
                                required: true,
                                hintText: "50"
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Add Button
                            ElevatedButton.icon(
                              onPressed: () {
                                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                                final unitPrice = double.tryParse(priceCtrl.text) ?? selProd.purchasePrice;
                                if (qty <= 0) return;

                                setDialogState(() {
                                  // Check if item is already added to update quantity instead of duplicating
                                  final existingIdx = orderItems.indexWhere((item) => item.productId == selProd.id);
                                  if (existingIdx != -1) {
                                    final currentItem = orderItems[existingIdx];
                                    orderItems[existingIdx] = OrderItem(
                                      productId: currentItem.productId,
                                      productName: currentItem.productName,
                                      quantityOrdered: currentItem.quantityOrdered + qty,
                                      unitPrice: unitPrice,
                                    );
                                  } else {
                                    orderItems.add(OrderItem(
                                      productId: selProd.id,
                                      productName: selProd.name,
                                      quantityOrdered: qty,
                                      unitPrice: unitPrice,
                                    ));
                                  }
                                  // Reset quantity input
                                  qtyCtrl.text = "50";
                                });
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text("Ajouter"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section header: Liste des articles ajoutés
                        Text(
                          "Articles dans la commande (${orderItems.length})",
                          style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // List container
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: state.bgPrimary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: orderItems.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_basket_outlined, color: state.textSecondaryLight, size: 36),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Aucun produit ajouté pour le moment.",
                                        style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: orderItems.length,
                                  separatorBuilder: (context, idx) => Divider(color: Colors.white.withOpacity(0.04), height: 12),
                                  itemBuilder: (context, index) {
                                    final item = orderItems[index];
                                    final totalItemPrice = item.quantityOrdered * item.unitPrice;

                                    return Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: GoogleFonts.inter(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "${NumberFormat.decimalPattern('fr').format(item.unitPrice)} GNF / unité",
                                                style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 11.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          "Quantité: ${item.quantityOrdered}",
                                          style: GoogleFonts.inter(color: state.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 24),
                                        Text(
                                          "${NumberFormat.decimalPattern('fr').format(totalItemPrice)} GNF",
                                          style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13.5),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                          onPressed: () {
                                            setDialogState(() {
                                              orderItems.removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Grand total row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Montant Total Estimé :",
                              style: GoogleFonts.inter(color: state.textSecondary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              "${NumberFormat.decimalPattern('fr').format(totalOrderAmount)} GNF",
                              style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Annuler", style: GoogleFonts.inter(color: state.textSecondaryLight)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton.icon(
                  onPressed: orderItems.isEmpty
                      ? null
                      : () {
                          if (formKey.currentState!.validate()) {
                            String finalSupId = selSup.id;
                            String finalSupName = selSup.name;
                            if (showCustomSup) {
                              final newSupName = customSupNameCtrl.text.trim();
                              final newSupId = 'SUP-${DateTime.now().millisecondsSinceEpoch}';
                              final newSup = Supplier(
                                id: newSupId,
                                name: newSupName,
                                contactPerson: 'Autre',
                                phone: '',
                                email: '',
                                address: '',
                                paymentTerms: 'A_LA_RECEPTION',
                                orders: [],
                                invoices: [],
                              );
                              state.addSupplier(newSup);
                              finalSupId = newSupId;
                              finalSupName = newSupName;
                            }
                            state.createSupplierOrder(finalSupId, orderItems);
                            Navigator.pop(context);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Bonne commande émise pour $finalSupName avec ${orderItems.length} article(s) !"),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    "Créer la Bonne commande", 
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: state.bgPrimary,
                    disabledForegroundColor: state.textSecondaryLight,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    bool required = false,
    bool isNumber = false,
    bool isPhone = false,
    String? hintText,
  }) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13.5),
          keyboardType: isPhone
              ? TextInputType.phone
              : (isNumber ? TextInputType.number : TextInputType.text),
          inputFormatters: isPhone
              ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)]
              : (isNumber ? [FilteringTextInputFormatter.digitsOnly] : null),
          decoration: InputDecoration(
            filled: true,
            fillColor: state.bgPrimary,
            hintText: hintText,
            hintStyle: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 12.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'Ce champ est requis';
            }
            if (isPhone && value != null && value.isNotEmpty && value.length != 9) {
              return 'Le numéro doit comporter exactement 9 chiffres';
            }
            return null;
          },
        ),
      ],
    );
  }
}
