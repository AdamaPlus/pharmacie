import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/app_state_provider.dart';
import '../models/pharmacy_models.dart';

class StockView extends StatefulWidget {
  const StockView({super.key});

  @override
  State<StockView> createState() => _StockViewState();
}

class _StockViewState extends State<StockView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _selectedCategory = 'Tous';
  bool _filterOnlyAlerts =
      false; // For Lots tab: show only expired/expiring soon

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat.decimalPattern('fr').format(amount)} GNF';
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final themeColor = Color(0xFF10B981);

    // Categories list
    final List<String> categories = ['Tous'];
    final List<String> defaultCats = [];
    final dynamicCatsList = state.products
        .map((p) => p.category)
        .toSet()
        .toList();
    for (var c in defaultCats) {
      if (!dynamicCatsList.contains(c)) dynamicCatsList.add(c);
    }
    dynamicCatsList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    categories.addAll(dynamicCatsList);

    return Scaffold(
      backgroundColor: state.bgPrimary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sub-Header Navigation
          Container(
            color: state.bgSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: themeColor,
                  labelColor: state.textPrimary,
                  unselectedLabelColor: state.textSecondary,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Médicaments'),
                    Tab(text: 'Suivi expiration et lots'),
                  ],
                ),
                const SizedBox(width: 16),

                // Add Buttons
                if (state.currentUserRole == 'ADMIN' ||
                    state.currentUserRole == 'PHARMACIEN' ||
                    state.canCreateNewMedicines())
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          PopupMenuButton<String>(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF1E293B),
                                border: Border.all(color: state.borderTheme),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.import_export_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Import / Export',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onSelected: (value) async {
                              if (value == 'pdf')
                                _exportStockPdf(state);
                              else if (value == 'export_csv')
                                _exportStockCSV(state);
                              else if (value == 'import_csv')
                                _importStockCSV(state);
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'pdf',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf_rounded,
                                      color: Colors.redAccent,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Exporter PDF'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'export_csv',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.download_rounded,
                                      color: Colors.blueAccent,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Exporter CSV'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'import_csv',
                                child: Row(
                                  children: [
                                    Icon(Icons.upload_rounded, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Importer CSV'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: state.canCreateNewMedicines()
                                ? () => _showAddLotDialog(context, state)
                                : null,
                            icon: Icon(Icons.add_box_rounded, size: 18),
                            label: Text('Ajouter un produit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: state.canCreateNewMedicines()
                                ? () => _showAddProductDialog(context, state)
                                : null,
                            icon: Icon(Icons.add_circle_outline_rounded, size: 18),
                            label: Text('Nouveau médicament'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Main Search & Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            color: state.bgPrimary,
            child: Row(
              children: [
                // Search Input
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      color: state.textPrimary,
                      fontSize: 14,
                    ),
                    onChanged: (val) {
                      setState(() {
                        state.productSearchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: state.bgSecondary,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: state.textSecondaryLight,
                      ),
                      hintText:
                          'Rechercher par nom, description ou code-barres...',
                      hintStyle: GoogleFonts.inter(
                        color: state.textSecondaryLight,
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.02),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // Category Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: state.bgSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.02)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: state.bgSecondary,
                      style: GoogleFonts.inter(
                        color: state.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildProductsTab(state), _buildLotsTab(state)],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: PRODUCTS LIST
  // ==========================================
  Widget _buildProductsTab(AppStateProvider state) {
    // Filter products
    final filtered = state.products.where((p) {
      final matchesQuery =
          p.name.toLowerCase().contains(
            state.productSearchQuery.toLowerCase(),
          ) ||
          p.description.toLowerCase().contains(
            state.productSearchQuery.toLowerCase(),
          ) ||
          p.barcode.contains(state.productSearchQuery);
      final matchesCat =
          _selectedCategory == 'Tous' || p.category == _selectedCategory;
      return matchesQuery && matchesCat;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: state.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.0), // ID
            1: FlexColumnWidth(2.6), // Name
            2: FlexColumnWidth(1.8), // Category
            3: FlexColumnWidth(1.3), // Sell Price
            4: FlexColumnWidth(1.1), // Qty
            5: FlexColumnWidth(1.6), // Status badge
            6: FlexColumnWidth(1.5), // Actions
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Table Header
            TableRow(
              decoration: BoxDecoration(
                color: state.bgPrimary.withOpacity(0.5),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
              ),
              children: [
                _tableHeaderCell('Code ID'),
                _tableHeaderCell('Nom du Produit'),
                _tableHeaderCell('Catégorie'),
                _tableHeaderCell('Prix Vente'),
                _tableHeaderCell('Quantité en Stock'),
                _tableHeaderCell('Statut'),
                _tableHeaderCell('Actions'),
              ],
            ),
            // Table Body Rows
            ...filtered.map((prod) {
              final isOrdered = state.isProductOrdered(prod.id);
              final isOutOfStock = prod.totalQuantity <= 0;
              final isLowStock =
                  prod.totalQuantity <= prod.minStock && !isOutOfStock;

              return TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.02)),
                  ),
                ),
                children: [
                  _tableCellText(
                    prod.id,
                    bold: true,
                    color: state.textSecondary,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Miniature product image
                        Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: state.textPrimary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child:
                              prod.image.isNotEmpty &&
                                  !prod.image.startsWith('generic_pill') &&
                                  prod.image.length > 50
                              ? Image.memory(
                                  base64Decode(
                                    prod.image.contains(',')
                                        ? prod.image.split(',').last
                                        : prod.image,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Transform.rotate(
                                    angle: -0.5,
                                    child: Icon(
                                      Icons.medication,
                                      size: 26,
                                      color: state.bgSecondary,
                                    ),
                                  ),
                                ),
                        ),
                        // Product details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prod.name,
                                style: GoogleFonts.inter(
                                  color: state.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'C.B: ${prod.barcode} • Fourn: ${prod.supplierName}',
                                style: GoogleFonts.inter(
                                  color: state.textSecondaryLight,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _tableCellText(prod.category),
                  _tableCellText(_formatCurrency(prod.sellingPrice)),
                  _tableCellText('${prod.totalQuantity}', bold: true),

                  // Status Badge
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOrdered
                              ? Colors.blueAccent.withOpacity(0.12)
                              : isOutOfStock
                              ? Colors.redAccent.withOpacity(0.12)
                              : isLowStock
                              ? Colors.orangeAccent.withOpacity(0.12)
                              : Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          isOrdered
                              ? 'En Commande'
                              : isOutOfStock
                              ? 'Rupture'
                              : isLowStock
                              ? 'Stock Faible'
                              : 'Suffisant',
                          style: GoogleFonts.inter(
                            color: isOrdered
                                ? Colors.blueAccent
                                : isOutOfStock
                                ? Colors.redAccent
                                : isLowStock
                                ? Colors.orangeAccent
                                : Color(0xFF10B981),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Actions Column
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: Colors.blueAccent,
                            size: 18,
                          ),
                          onPressed: state.canEditProductDetails()
                              ? () => _showAddProductDialog(context, state, prod)
                              : null,
                          tooltip: state.canEditProductDetails() ? 'Modifier' : 'Accès restreint',
                        ),
                        if (state.currentUserRole == 'ADMIN')
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            onPressed: () {
                              _confirmDeleteProduct(context, state, prod);
                            },
                            tooltip: 'Supprimer',
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: BATCHES & EXSPIRATION DATES
  // ==========================================
  Widget _buildLotsTab(AppStateProvider state) {
    // Filter lots
    final filteredLots = state.lots.where((l) {
      final matchesQuery =
          l.productName.toLowerCase().contains(
            state.productSearchQuery.toLowerCase(),
          ) ||
          l.lotNumber.toLowerCase().contains(
            state.productSearchQuery.toLowerCase(),
          );

      bool matchesAlert = true;
      if (_filterOnlyAlerts) {
        matchesAlert = l.isExpired || l.isNearExpiration;
      }
      return matchesQuery && matchesAlert;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter checkbox
          Row(
            children: [
              Checkbox(
                value: _filterOnlyAlerts,
                activeColor: Color(0xFF10B981),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _filterOnlyAlerts = val;
                    });
                  }
                },
              ),
              Text(
                'Afficher uniquement les alertes',
                style: GoogleFonts.inter(
                  color: state.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: state.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3.0), // Product
                1: FlexColumnWidth(1.5), // Lot number
                2: FlexColumnWidth(2.0), // Expiration Date
                3: FlexColumnWidth(1.2), // Quantity
                4: FlexColumnWidth(1.8), // Status
                5: FlexColumnWidth(1.5), // Adjust actions
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(
                    color: state.bgPrimary.withOpacity(0.5),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  children: [
                    _tableHeaderCell('Produit'),
                    _tableHeaderCell('N° de lot'),
                    _tableHeaderCell('Date d\'expiration'),
                    _tableHeaderCell('Quantité'),
                    _tableHeaderCell('État du lot'),
                    _tableHeaderCell('Inventaire'),
                  ],
                ),
                // Rows
                ...filteredLots.map((lot) {
                  return TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.02),
                        ),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          lot.productName,
                          style: GoogleFonts.inter(
                            color: state.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      _tableCellText(
                        lot.lotNumber,
                        bold: true,
                        color: Color(0xFF3B82F6),
                      ),
                      _tableCellText(
                        DateFormat('dd / MM / yyyy').format(lot.expirationDate),
                      ),
                      _tableCellText('${lot.quantity}', bold: true),

                      // Status
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: lot.isExpired
                                  ? Colors.redAccent.withOpacity(0.12)
                                  : lot.isNearExpiration
                                  ? Colors.orangeAccent.withOpacity(0.12)
                                  : Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              lot.isExpired
                                  ? 'PÉRIMÉ'
                                  : lot.isNearExpiration
                                  ? 'EXPIRE BIENTÔT'
                                  : 'VALIDE',
                              style: GoogleFonts.inter(
                                color: lot.isExpired
                                    ? Colors.redAccent
                                    : lot.isNearExpiration
                                    ? Colors.orangeAccent
                                    : Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Inventaire physique button
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showAdjustLotDialog(context, state, lot),
                          icon: Icon(Icons.edit_note_rounded, size: 14),
                          label: Text(
                            'Corriger Quantité',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3B82F6).withOpacity(0.1),
                            foregroundColor: Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPERS & DIALOGS
  // ==========================================
  Widget _tableHeaderCell(String text) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: state.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _tableCellText(String text, {bool bold = false, Color? color}) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color ?? state.textPrimary,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 13.5,
        ),
      ),
    );
  }

  // Confirm delete product
  void _confirmDeleteProduct(
    BuildContext context,
    AppStateProvider state,
    Product prod,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: state.bgSecondary,
        title: Text(
          'Supprimer le produit ?',
          style: GoogleFonts.outfit(color: state.textPrimary),
        ),
        content: Text(
          'Voulez-vous supprimer définitivement ${prod.name} et effacer tous les lots associés dans le système ? Cette action est irréversible.',
          style: GoogleFonts.inter(color: state.textSecondary),
        ),
        actions: [
          TextButton(
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: state.textSecondaryLight),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              'Confirmer la suppression',
              style: GoogleFonts.inter(
                color: state.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              state.deleteProduct(prod.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Add Product Dialog
  void _showAddProductDialog(
    BuildContext context,
    AppStateProvider state, [
    Product? original,
  ]) {
    final isEdit = original != null;
    final formKey = GlobalKey<FormState>();
    final idCtrl = TextEditingController(
      text: isEdit ? original.id : 'P00${state.products.length + 1}',
    );
    final nameCtrl = TextEditingController(text: isEdit ? original.name : '');
    final purchaseCtrl = TextEditingController(
      text: isEdit ? original.purchasePrice.toString() : '',
    );
    final sellCtrl = TextEditingController(
      text: isEdit ? original.sellingPrice.toString() : '',
    );

    String catVal = isEdit ? original.category : 'Autre';
    final customCatCtrl = TextEditingController();
    String prodImage = isEdit ? original.image : 'generic_pill';

    List<String> dynamicCategories = state.products
        .map((p) => p.category)
        .toSet()
        .toList();
    dynamicCategories.remove('Autre');
    if (!dynamicCategories.contains(catVal) && catVal != 'Autre') {
      dynamicCategories.add(catVal);
    }
    dynamicCategories.sort(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    if (catVal != 'Autre') {
      dynamicCategories.remove(catVal);
      dynamicCategories.insert(0, catVal);
    }
    if (!dynamicCategories.contains('Autre')) {
      dynamicCategories.add('Autre');
    }

    // Lots data
    Lot? firstLot;
    if (isEdit) {
      final lots = state.lots.where((l) => l.productId == original.id).toList();
      if (lots.isNotEmpty) firstLot = lots.first;
    }

    final lotCtrl = TextEditingController(
      text: firstLot?.lotNumber ?? _generateUniqueLotNumber(state.lots),
    );
    final qtyCtrl = TextEditingController(
      text:
          firstLot?.quantity.toString() ??
          (isEdit ? original.totalQuantity.toString() : ''),
    );
    final expCtrl = TextEditingController(
      text: firstLot != null
          ? DateFormat('dd/MM/yyyy').format(firstLot.expirationDate)
          : DateFormat(
              'dd/MM/yyyy',
            ).format(DateTime.now().add(const Duration(days: 365))),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: state.bgSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              titlePadding: const EdgeInsets.only(
                left: 24,
                right: 16,
                top: 20,
                bottom: 16,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Modifier le médicament' : 'Ajouter un médicament',
                    style: GoogleFonts.inter(
                      color: state.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: state.textSecondaryLight,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SizedBox(
                width: 580,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _dialogField(
                                label: 'Nom du médicament *',
                                controller: nameCtrl,
                                required: true,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Catégorie *',
                                    style: GoogleFonts.inter(
                                      color: state.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: state.bgPrimary,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: state.borderTheme,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: catVal,
                                        isExpanded: true,
                                        dropdownColor: state.bgSecondary,
                                        style: GoogleFonts.inter(
                                          color: state.textPrimary,
                                          fontSize: 13.5,
                                        ),
                                        items: dynamicCategories.map((cat) {
                                          return DropdownMenuItem(
                                            value: cat,
                                            child: Text(cat),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setDialogState(() {
                                              catVal = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  if (catVal == 'Autre') ...[
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: customCatCtrl,
                                      style: GoogleFonts.inter(
                                        color: state.textPrimary,
                                        fontSize: 13.5,
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: state.bgPrimary,
                                        hintText:
                                            'Saisir la nouvelle catégorie',
                                        hintStyle: GoogleFonts.inter(
                                          color: state.textSecondaryLight,
                                          fontSize: 12.5,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: state.borderTheme,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: state.borderTheme,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (catVal == 'Autre' &&
                                            (value == null ||
                                                value.trim().isEmpty)) {
                                          return 'Veuillez saisir la catégorie';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _dialogField(
                                label: 'N° de Lot (auto-généré)',
                                controller: lotCtrl,
                                readOnly: true,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _dialogField(
                                label: 'Quantité en stock *',
                                controller: qtyCtrl,
                                isNumber: true,
                                required: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date d\'expiration *',
                                    style: GoogleFonts.inter(
                                      color: state.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  TextFormField(
                                    controller: expCtrl,
                                    readOnly: true,
                                    style: GoogleFonts.inter(
                                      color: state.textPrimary,
                                      fontSize: 13.5,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: state.bgPrimary,
                                      suffixIcon: Icon(
                                        Icons.calendar_today_outlined,
                                        size: 18,
                                        color: state.textSecondaryLight,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: state.borderTheme,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: state.borderTheme,
                                        ),
                                      ),
                                    ),
                                    onTap: () async {
                                      DateTime? picked = await showDatePicker(
                                        context: context,
                                        locale: const Locale('fr', 'FR'),
                                        initialDate:
                                            firstLot?.expirationDate ??
                                            DateTime.now().add(
                                              const Duration(days: 365),
                                            ),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(9999, 12, 31),
                                      );
                                      if (picked != null) {
                                        expCtrl.text = DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(picked);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _dialogField(
                                label: 'Prix d\'achat *',
                                controller: purchaseCtrl,
                                isNumber: true,
                                required: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _dialogField(
                                label: 'Prix unitaire (Vente) *',
                                controller: sellCtrl,
                                isNumber: true,
                                required: true,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(child: SizedBox()),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Image du produit (optionnel)',
                          style: GoogleFonts.inter(
                            color: state.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: state.bgPrimary,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: state.borderTheme),
                                ),
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        FilePickerResult? result =
                                            await FilePicker.pickFiles(
                                              type: FileType.image,
                                              withData: true,
                                            );
                                        if (result != null &&
                                            result.files.single.bytes != null) {
                                          final base64Str = base64Encode(
                                            result.files.single.bytes!,
                                          );
                                          setDialogState(() {
                                            prodImage = base64Str;
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: state.bgSecondary,
                                        foregroundColor: state.textPrimary,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        side: BorderSide(
                                          color: state.borderTheme,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Choisir un fichier',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        prodImage.length > 50
                                            ? 'Image sélectionnée'
                                            : 'Aucun fichier choisi',
                                        style: GoogleFonts.inter(
                                          color: state.textSecondaryLight,
                                          fontSize: 12.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (prodImage.length > 50)
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.redAccent,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => setDialogState(
                                          () => prodImage = 'generic_pill',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (prodImage.length > 50) ...[
                              SizedBox(width: 12),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: state.borderTheme),
                                  image: DecorationImage(
                                    image: MemoryImage(
                                      base64Decode(
                                        prodImage.contains(',')
                                            ? prodImage.split(',').last
                                            : prodImage,
                                      ),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isEdit
                        ? 'Valider les modifications'
                        : '+ Ajouter un médicament',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      // Process date
                      DateTime parsedDate;
                      try {
                        final parts = expCtrl.text.split('/');
                        parsedDate = DateTime(
                          int.parse(parts[2]),
                          int.parse(parts[1]),
                          int.parse(parts[0]),
                        );
                      } catch (e) {
                        parsedDate = DateTime.now().add(
                          const Duration(days: 365),
                        );
                      }

                      final finalQty = int.tryParse(qtyCtrl.text) ?? 0;

                      final newProd = Product(
                        id: idCtrl.text.trim(),
                        name: nameCtrl.text.trim(),
                        description: isEdit ? original.description : '',
                        barcode: isEdit ? original.barcode : '',
                        purchasePrice:
                            double.tryParse(purchaseCtrl.text) ?? 0.0,
                        sellingPrice: double.tryParse(sellCtrl.text) ?? 0.0,
                        vat: isEdit ? original.vat : 0.0,
                        category: catVal == 'Autre'
                            ? customCatCtrl.text.trim()
                            : catVal,
                        supplierName: isEdit
                            ? original.supplierName
                            : 'Inconnu',
                        image: prodImage,
                        minStock: isEdit ? original.minStock : 10,
                        totalQuantity: isEdit
                            ? (original.totalQuantity -
                                  (firstLot?.quantity ?? 0) +
                                  finalQty)
                            : 0,
                      );

                      if (isEdit) {
                        if (firstLot != null) {
                          final newLot = Lot(
                            id: firstLot!.id,
                            productId: firstLot!.productId,
                            productName: newProd.name,
                            lotNumber: lotCtrl.text.isNotEmpty
                                ? lotCtrl.text
                                : firstLot!.lotNumber,
                            expirationDate: parsedDate,
                            quantity: finalQty,
                          );
                          final lotIdx = state.lots.indexWhere(
                            (l) => l.id == firstLot!.id,
                          );
                          if (lotIdx != -1) {
                            state.lots[lotIdx] = newLot;
                          }
                        } else {
                          final newLot = Lot(
                            id: 'LOT-${DateTime.now().millisecondsSinceEpoch}',
                            productId: newProd.id,
                            productName: newProd.name,
                            lotNumber: lotCtrl.text.isNotEmpty
                                ? lotCtrl.text
                                : _generateUniqueLotNumber(state.lots),
                            expirationDate: parsedDate,
                            quantity: finalQty,
                          );
                          state.lots.add(newLot);
                        }
                        state.editProduct(newProd); // saves _db and notifies
                      } else {
                        state.addProduct(newProd);
                        final newLot = Lot(
                          id: 'LOT-${DateTime.now().millisecondsSinceEpoch}',
                          productId: newProd.id,
                          productName: newProd.name,
                          lotNumber: lotCtrl.text.isNotEmpty
                              ? lotCtrl.text
                              : _generateUniqueLotNumber(state.lots),
                          expirationDate: parsedDate,
                          quantity: finalQty,
                        );
                        state.addLot(
                          newLot,
                        ); // this increments newProd.totalQuantity and saves
                      }
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Génère un numéro de lot séquentiel unique : 1, 2, 3...
  String _generateUniqueLotNumber(List<dynamic> existingLots) {
    int next = 1;
    final existing = existingLots
        .map((l) => int.tryParse(l.lotNumber) ?? 0)
        .toSet();
    while (existing.contains(next)) {
      next++;
    }
    return '$next';
  }

  // Add Lot Dialog
  void _showAddLotDialog(BuildContext context, AppStateProvider state) {
    if (state.products.isEmpty) return;

    final formKey = GlobalKey<FormState>();
    final numCtrl = TextEditingController(
      text: _generateUniqueLotNumber(state.lots),
    );
    final qtyCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().add(const Duration(days: 365))),
    );

    Product selProd = state.products[0];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: state.bgSecondary,
              title: Text(
                'Réception de Marchandise / Ajouter un produit',
                style: GoogleFonts.outfit(color: state.textPrimary),
              ),
              content: SizedBox(
                width: 460,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Select Product
                      Text(
                        'Sélectionner le produit',
                        style: GoogleFonts.inter(
                          color: state.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: state.bgPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Product>(
                            value: selProd,
                            isExpanded: true,
                            dropdownColor: state.bgSecondary,
                            style: GoogleFonts.inter(
                              color: state.textPrimary,
                              fontSize: 13.5,
                            ),
                            items: (() {
                              final sorted = List<Product>.from(state.products);
                              sorted.sort(
                                (a, b) => a.name.toLowerCase().compareTo(
                                  b.name.toLowerCase(),
                                ),
                              );
                              return sorted
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p.name),
                                    ),
                                  )
                                  .toList();
                            })(),
                            onChanged: (val) {
                              if (val != null)
                                setDialogState(() => selProd = val);
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Photo et détails du médicament sélectionné
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: state.bgPrimary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: state.bgPrimary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child:
                                  selProd.image.isNotEmpty &&
                                      !selProd.image.startsWith(
                                        'generic_pill',
                                      ) &&
                                      selProd.image.length > 50
                                  ? Image.memory(
                                      base64Decode(
                                        selProd.image.contains(',')
                                            ? selProd.image.split(',').last
                                            : selProd.image,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Transform.rotate(
                                        angle: -0.5,
                                        child: Icon(
                                          Icons.medication_rounded,
                                          size: 28,
                                          color: const Color(
                                            0xFF10B981,
                                          ).withOpacity(0.4),
                                        ),
                                      ),
                                    ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selProd.name,
                                    style: GoogleFonts.inter(
                                      color: state.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Catégorie : ${selProd.category}',
                                    style: GoogleFonts.inter(
                                      color: state.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Stock actuel : ${selProd.totalQuantity} unités',
                                    style: GoogleFonts.inter(
                                      color: Color(0xFF10B981),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Lot number & quantity
                      Row(
                        children: [
                          Expanded(
                            child: _dialogField(
                              label: 'Numéro de lot *',
                              controller: numCtrl,
                              required: true,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _dialogField(
                              label: 'Quantité reçue',
                              controller: qtyCtrl,
                              isNumber: true,
                              required: true,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Expiration date
                      _dialogField(
                        label: 'Date d\'Expiration (AAAA-MM-JJ)',
                        controller: dateCtrl,
                        required: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
                TextButton(
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.inter(color: state.textSecondaryLight),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                  ),
                  child: Text(
                    'Ajouter le produit',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final date =
                          DateTime.tryParse(dateCtrl.text) ??
                          DateTime.now().add(const Duration(days: 365));
                      final newLot = Lot(
                        id: 'LOT-${DateTime.now().millisecondsSinceEpoch}',
                        productId: selProd.id,
                        productName: selProd.name,
                        lotNumber: numCtrl.text.trim(),
                        expirationDate: date,
                        quantity: int.tryParse(qtyCtrl.text) ?? 0,
                      );

                      state.addLot(newLot);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Adjust Lot Quantity Dialog
  void _showAdjustLotDialog(
    BuildContext context,
    AppStateProvider state,
    Lot lot,
  ) {
    final formKey = GlobalKey<FormState>();
    final qtyCtrl = TextEditingController(text: lot.quantity.toString());
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: state.bgSecondary,
          title: Text(
            'Inventaire Physique - ${lot.productName}',
            style: GoogleFonts.outfit(color: state.textPrimary),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'N° de lot : ${lot.lotNumber} • Expiration : ${DateFormat('dd/MM/yyyy').format(lot.expirationDate)}',
                  style: GoogleFonts.inter(
                    color: state.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                SizedBox(height: 16),
                _dialogField(
                  label: 'Nouvelle Quantité Physique Comptée',
                  controller: qtyCtrl,
                  isNumber: true,
                  required: true,
                ),
                SizedBox(height: 12),
                _dialogField(
                  label: 'Motif de la Correction',
                  controller: reasonCtrl,
                  required: true,
                  maxLines: 2,
                  hintText:
                      'ex: Casse de flacon, Correction comptage inventaire trimestriel, vol, périmé',
                ),
              ],
            ),
          ),
        ),
        actions: [
            TextButton(
              child: Text(
                'Annuler',
                style: GoogleFonts.inter(color: state.textSecondaryLight),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3B82F6),
              ),
              child: Text(
                'Appliquer Correction',
                style: GoogleFonts.inter(
                  color: state.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newQty = int.tryParse(qtyCtrl.text) ?? lot.quantity;
                  state.adjustLotQuantity(
                    lot.id,
                    newQty,
                    reasonCtrl.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _dialogField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    bool isNumber = false,
    bool readOnly = false,
    int maxLines = 1,
    String? hintText,
    ValueChanged<String>? onChanged,
  }) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: state.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          style: GoogleFonts.inter(color: state.textPrimary, fontSize: 14),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly
                ? Color(0xFF334155).withOpacity(0.3)
                : state.bgPrimary,
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              color: state.textSecondaryLight,
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.02)),
            ),
          ),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'Ce champ est requis';
            }
            if (isNumber &&
                value != null &&
                value.trim().isNotEmpty &&
                double.tryParse(value) == null) {
              return 'Saisie numérique invalide';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ==========================================
  // PDF EXPORT: STOCK DETAILS
  // ==========================================
  Future<void> _exportStockPdf(AppStateProvider state) async {
    final filtered = state.products.where((p) {
      final matchesQuery =
          p.name.toLowerCase().contains(
            state.productSearchQuery.toLowerCase(),
          ) ||
          p.description.toLowerCase().contains(
            state.productSearchQuery.toLowerCase(),
          ) ||
          p.barcode.contains(state.productSearchQuery);
      final matchesCat =
          _selectedCategory == 'Tous' || p.category == _selectedCategory;
      return matchesQuery && matchesCat;
    }).toList();

    final doc = pw.Document();
    final fmt = NumberFormat.decimalPattern('fr');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final now = DateTime.now();

    double totalStockValue = 0;
    for (var p in filtered)
      totalStockValue += (p.purchasePrice * p.totalQuantity);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Text(
              'PHARMACIE GUINÉE',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal700,
              ),
            ),
            pw.Text(
              'Détail de Stock',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              'Catégorie : $_selectedCategory',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.Text(
              'Généré le : ${dateFmt.format(now)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Nombre d\'articles: ${filtered.length}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Valeur du Stock (Achat): ${fmt.format(totalStockValue)} GNF',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal700,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.teal700),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.5),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
                4: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal700),
                  children: [
                    _pdfCell('Produit', bold: true, isHeader: true),
                    _pdfCell('Catégorie', bold: true, isHeader: true),
                    _pdfCell('Prix Achat', bold: true, isHeader: true),
                    _pdfCell('Prix Vente', bold: true, isHeader: true),
                    _pdfCell('Quantité', bold: true, isHeader: true),
                  ],
                ),
                ...filtered.map((p) {
                  return pw.TableRow(
                    children: [
                      _pdfCell('${p.name}\n(CB: ${p.barcode})'),
                      _pdfCell(p.category),
                      _pdfCell('${fmt.format(p.purchasePrice)}'),
                      _pdfCell('${fmt.format(p.sellingPrice)}'),
                      _pdfCell(
                        '${p.totalQuantity}',
                        bold: true,
                        color: p.totalQuantity <= p.minStock
                            ? PdfColors.red700
                            : PdfColors.black,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  pw.Widget _pdfCell(
    String text, {
    bool bold = false,
    bool isHeader = false,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : color,
        ),
      ),
    );
  }

  Future<void> _exportStockCSV(AppStateProvider state) async {
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Exporter le stock en CSV',
      fileName: 'stock_${DateTime.now().millisecondsSinceEpoch}.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (outputFile != null) {
      final buffer = StringBuffer();
      buffer.writeln(
        "ID;Nom;Categorie;Prix Achat;Prix Vente;Quantite Actuelle;Stock Minimum;Fournisseur;Code-Barres",
      );
      for (var p in state.products) {
        buffer.writeln(
          "${p.id};${p.name};${p.category};${p.purchasePrice};${p.sellingPrice};${p.totalQuantity};${p.minStock};${p.supplierName};${p.barcode}",
        );
      }
      await File(outputFile).writeAsString(buffer.toString());
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export CSV réussi'),
            backgroundColor: Colors.green,
          ),
        );
    }
  }

  Future<void> _importStockCSV(AppStateProvider state) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      try {
        final file = File(result.files.single.path!);
        final lines = await file.readAsLines();
        int count = 0;
        for (int i = 1; i < lines.length; i++) {
          final parts = lines[i].split(';');
          if (parts.length >= 7) {
            final id = parts[0];
            final name = parts[1];
            final category = parts[2];
            final pPrice = double.tryParse(parts[3]) ?? 0.0;
            final sPrice = double.tryParse(parts[4]) ?? 0.0;
            final qty = int.tryParse(parts[5]) ?? 0;
            final minStock = int.tryParse(parts[6]) ?? 10;
            final supplierName = parts.length > 7 ? parts[7] : 'Inconnu';
            final barcode = parts.length > 8 ? parts[8] : '';

            final existing = state.products.where((p) => p.id == id).toList();
            if (existing.isNotEmpty) {
              final newP = Product(
                id: existing.first.id,
                name: name,
                description: existing.first.description,
                barcode: barcode,
                purchasePrice: pPrice,
                sellingPrice: sPrice,
                vat: existing.first.vat,
                category: category,
                supplierName: supplierName,
                image: existing.first.image,
                minStock: minStock,
                totalQuantity: qty,
              );
              state.editProduct(newP);
            } else {
              final newP = Product(
                id: id,
                name: name,
                description: '',
                barcode: barcode,
                purchasePrice: pPrice,
                sellingPrice: sPrice,
                vat: 0.0,
                category: category,
                supplierName: supplierName,
                image: '',
                minStock: minStock,
                totalQuantity: qty,
              );
              state.addProduct(newP);
            }
            count++;
          }
        }
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count produits importés !'),
              backgroundColor: Colors.green,
            ),
          );
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'importation'),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }
}
