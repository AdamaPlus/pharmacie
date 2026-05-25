import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/pharmacy_models.dart';
import '../providers/app_state_provider.dart';
import '../utils/invoice_printer.dart';

class ArchivesView extends StatefulWidget {
  const ArchivesView({super.key});

  @override
  State<ArchivesView> createState() => _ArchivesViewState();
}

class _ArchivesViewState extends State<ArchivesView> with SingleTickerProviderStateMixin {
  AppStateProvider get state => Provider.of<AppStateProvider>(context, listen: false);
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _periodFilter = 'day';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _periodFilter = ['day', 'month', 'year'][_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final now = DateTime.now();
    final fmt = NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);

    // Filter sales by period and search
    final periodSales = state.sales.where((s) {
      final matchesPeriod = _periodFilter == 'day'
          ? s.date.year == now.year && s.date.month == now.month && s.date.day == now.day
          : _periodFilter == 'month'
              ? s.date.year == now.year && s.date.month == now.month
              : s.date.year == now.year;

      final query = _searchCtrl.text.toLowerCase();
      final matchesSearch = query.isEmpty ||
          s.id.toLowerCase().contains(query) ||
          (s.patientName ?? '').toLowerCase().contains(query) ||
          s.cashierName.toLowerCase().contains(query);

      return matchesPeriod && matchesSearch;
    }).toList();

    final periodTotal = periodSales.fold<double>(0.0, (sum, s) => sum + s.netAmount);

    return Container(
      color: state.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================
          // HEADER
          // ==========================================
          Container(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
            color: state.bgPrimary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.archive_rounded, color: Color(0xFF10B981), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Archives & Historique des Reçus',
                          style: GoogleFonts.outfit(
                            color: state.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.sales.length} facture(s) enregistrée(s) au total',
                          style: GoogleFonts.inter(color: state.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SEARCH BAR + TAB BAR
                // ==========================================
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Rechercher par N° facture, patient, caissier...',
                          hintStyle: GoogleFonts.inter(color: state.textSecondaryLight),
                          prefixIcon: Icon(Icons.search_rounded, color: state.textSecondaryLight, size: 20),
                          filled: true,
                          fillColor: state.bgSecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: "Aujourd'hui"),
                    Tab(text: 'Ce Mois'),
                    Tab(text: 'Cette Année'),
                  ],
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 13.5),
                  labelColor: const Color(0xFF10B981),
                  unselectedLabelColor: state.textSecondary,
                  indicatorColor: const Color(0xFF10B981),
                  indicatorSize: TabBarIndicatorSize.label,
                ),
              ],
            ),
          ),

          // ==========================================
          // SALES LIST
          // ==========================================
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(32, 12, 32, 24),
              decoration: BoxDecoration(
                color: state.bgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: state.borderTheme),
              ),
              child: periodSales.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, color: state.textSecondaryLight.withOpacity(0.2), size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune vente trouvée',
                            style: GoogleFonts.outfit(
                              color: state.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Aucun reçu ne correspond à votre recherche.',
                            style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Summary bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF064E3B).withOpacity(0.4),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.list_alt_rounded, color: const Color(0xFF10B981), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${periodSales.length} vente(s) pour la période',
                                    style: GoogleFonts.inter(color: state.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                              Text(
                                state.maskRevenues ? 'Total: **** GNF' : 'Total: ${fmt.format(periodTotal)}',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // List
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: periodSales.length,
                            separatorBuilder: (_, __) => Divider(color: state.borderTheme, height: 1),
                            itemBuilder: (context, i) {
                              final sale = periodSales[i];
                              return _buildSaleRow(sale, state, fmt, context);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11)),
          Text('$value GNF', style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11)),
        ],
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, Sale sale, AppStateProvider state) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: state.bgSecondary,
          content: Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo in virtual receipt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      state.pharmacyLogo != null
                          ? Image.memory(
                              state.pharmacyLogo!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D9488),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 14,
                                      color: Colors.white,
                                    ),
                                    Container(
                                      width: 14,
                                      height: 4,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(width: 8),
                      Text(
                        state.pharmacyName.toUpperCase(),
                        style: GoogleFonts.courierPrime(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${state.pharmacyQuartier}\nTel: ${state.pharmacyContact2.isNotEmpty ? "${state.pharmacyContact1} / ${state.pharmacyContact2}" : state.pharmacyContact1}\nNIF: 998274-A',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),
                  Text(
                    'REÇU DE PAIEMENT\nN°: ${sale.id}\nDate: ${DateFormat("dd/MM/yyyy HH:mm").format(sale.date)}\n${(sale.cashierName.toLowerCase().contains("admin") || sale.cashierName.toLowerCase().contains("responsable") || state.users.any((u) => u.role == "ADMIN" && (u.username.toLowerCase() == sale.cashierName.toLowerCase() || u.fullName.toLowerCase() == sale.cashierName.toLowerCase()))) ? "Admin" : "Caissier"}: ${sale.cashierName}\nClient: ${sale.patientName ?? "Passage"}',
                    style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11),
                  ),
                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),
                  
                  // Items lines
                  ...sale.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '   ${item.quantity} x ${NumberFormat.decimalPattern('fr').format(item.unitPrice)} GNF',
                                style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11),
                              ),
                              Text(
                                '${NumberFormat.decimalPattern('fr').format(item.total)} GNF',
                                style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),

                  // Calculations
                  if (sale.discountAmount > 0)
                    _receiptRow('REMISE APPLIQUÉE', '- ${NumberFormat.decimalPattern('fr').format(sale.discountAmount)}'),
                  
                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),

                  // Net Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL NET PAYÉ', style: GoogleFonts.courierPrime(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${NumberFormat.decimalPattern('fr').format(sale.netAmount)} GNF', style: GoogleFonts.courierPrime(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  _receiptRow('MODE DE PAIEMENT', sale.paymentMethod),
                  
                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Signature',
                            style: GoogleFonts.courierPrime(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 35),
                          Text(
                            '........................',
                            style: GoogleFonts.courierPrime(color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Merci de votre confiance !\nOn vous souhaite prompt rétablissement.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Fermer', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                InvoicePrinter.printInvoice(
                  sale,
                  state.pharmacyLogo,
                  pharmacyName: state.pharmacyName,
                  quartier: state.pharmacyQuartier,
                  contact1: state.pharmacyContact1,
                  contact2: state.pharmacyContact2,
                );
              },
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text('Imprimer Facture', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSaleRow(Sale sale, AppStateProvider state, NumberFormat fmt, BuildContext ctx) {
    final isToday = sale.date.year == DateTime.now().year &&
        sale.date.month == DateTime.now().month &&
        sale.date.day == DateTime.now().day;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          // Receipt icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_rounded, color: Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sale.id,
                      style: GoogleFonts.inter(
                        color: state.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Aujourd'hui",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF10B981),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormat('dd/MM/yyyy HH:mm').format(sale.date)}  •  ${sale.items.length} article(s)  •  ${sale.paymentMethod}  •  Caissier: ${sale.cashierName}',
                  style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11),
                ),
                if (sale.patientName != null)
                  Text(
                    'Client: ${sale.patientName}',
                    style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 10),
                  ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                state.maskRevenues ? '**** GNF' : fmt.format(sale.netAmount),
                style: GoogleFonts.outfit(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (sale.discountAmount > 0)
                Text(
                  'Remise: ${fmt.format(sale.discountAmount)}',
                  style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Refund / Return
              Tooltip(
                message: 'Retour en stock / Remboursement',
                child: IconButton(
                  icon: const Icon(Icons.keyboard_return_rounded, color: Colors.orangeAccent, size: 18),
                  onPressed: () => _showReturnDialog(ctx, sale, state),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 10),
              // Print
              Tooltip(
                message: 'Imprimer le reçu',
                child: IconButton(
                  icon: const Icon(Icons.print_rounded, color: Color(0xFF10B981), size: 18),
                  onPressed: () => _showReceiptDialog(ctx, sale, state),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Supprimer',
                child: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                  onPressed: () {
                    showDialog(
                      context: ctx,
                      builder: (dCtx) => AlertDialog(
                        backgroundColor: state.bgSecondary,
                        title: Text('Confirmer', style: GoogleFonts.inter(color: state.textPrimary)),
                        content: Text('Voulez-vous vraiment supprimer cette vente ?', style: GoogleFonts.inter(color: state.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              state.deleteSale(sale.id);
                              Navigator.pop(dCtx);
                            },
                            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(BuildContext ctx, Sale sale, AppStateProvider state) {
    final fmt = NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);
    final Map<String, Map<String, dynamic>> returnData = {};
    for (var item in sale.items) {
      returnData[item.productId] = {
        'selected': true,
        'quantity': item.quantity,
        'maxQuantity': item.quantity,
        'unitPrice': item.unitPrice,
        'name': item.productName,
      };
    }

    showDialog(
      context: ctx,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setD) {
            double totalRefund = 0.0;
            returnData.forEach((key, val) {
              if (val['selected'] == true) {
                totalRefund += (val['quantity'] as int) * (val['unitPrice'] as double);
              }
            });

            return AlertDialog(
              backgroundColor: state.bgSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.keyboard_return_rounded, color: Colors.orangeAccent, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Retour & Remboursement',
                    style: GoogleFonts.inter(
                      color: state.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.5,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sélectionnez les produits à retourner pour la facture ${sale.id} :',
                      style: GoogleFonts.inter(color: state.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: sale.items.map((item) {
                          final data = returnData[item.productId]!;
                          final isSelected = data['selected'] as bool;
                          final currentQty = data['quantity'] as int;
                          final maxQty = data['maxQuantity'] as int;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: state.bgPrimary.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orangeAccent.withOpacity(0.4)
                                    : state.borderTheme,
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  activeColor: Colors.orangeAccent,
                                  value: isSelected,
                                  onChanged: (val) => setD(() => data['selected'] = val ?? false),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: GoogleFonts.inter(
                                          color: state.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        'Acheté: ${item.quantity}  •  ${fmt.format(item.unitPrice)} l\'un',
                                        style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.orangeAccent, size: 20),
                                        onPressed: () => setD(() {
                                          if (currentQty > 1) {
                                            data['quantity'] = currentQty - 1;
                                          } else {
                                            data['selected'] = false;
                                            data['quantity'] = 1;
                                          }
                                        }),
                                      ),
                                      Text(
                                        '$currentQty',
                                        style: GoogleFonts.inter(
                                          color: state.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: Colors.orangeAccent, size: 20),
                                        onPressed: currentQty < maxQty
                                            ? () => setD(() => data['quantity'] = currentQty + 1)
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        tooltip: 'Supprimer du retour',
                                        onPressed: () => setD(() {
                                          data['selected'] = false;
                                          data['quantity'] = 1;
                                        }),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: state.borderTheme),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL À REMBOURSER :',
                          style: GoogleFonts.inter(
                            color: state.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          fmt.format(totalRefund),
                          style: GoogleFonts.outfit(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Info note
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Les produits retournés seront automatiquement réintégrés dans le stock et une trace sera conservée dans l\'historique.',
                              style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Annuler', style: GoogleFonts.inter(color: state.textSecondary)),
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text('Confirmer le Retour', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onPressed: totalRefund <= 0
                      ? null
                      : () {
                          final List<Map<String, dynamic>> itemsToReturn = [];
                          returnData.forEach((productId, value) {
                            if (value['selected'] == true) {
                              itemsToReturn.add({
                                'productId': productId,
                                'quantity': value['quantity'],
                              });
                            }
                          });

                          final success = state.processItemsRefund(
                            saleId: sale.id,
                            itemsToReturn: itemsToReturn,
                          );

                          Navigator.pop(dialogCtx);
                          if (success) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Retour confirmé ! Les produits ont été réintégrés en stock.',
                                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.orangeAccent,
                                duration: const Duration(seconds: 4),
                              ),
                            );
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
}
