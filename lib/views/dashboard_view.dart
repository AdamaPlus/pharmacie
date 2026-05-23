import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state_provider.dart';
import '../models/pharmacy_models.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // Formatting utility
  String _formatCurrency(double amount, {bool isMasked = false}) {
    if (isMasked) return '*** GNF';
    final format = NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);
    return format.format(amount).replaceAll('GNF', 'GNF ');
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    
    // 1. Calculate Metrics
    final totalProductsCount = state.products.length;
    final totalSalesCount = state.sales.length;
    final totalSuppliersCount = state.suppliers.length;
    
    // Expired or expiring soon lots (quantity > 0)
    final expiringLots = state.lots.where((l) {
      if (l.quantity <= 0) return false;
      final diff = l.expirationDate.difference(DateTime.now()).inDays;
      return diff <= 30; // already expired (negative diff) or expiring in <= 30 days
    }).toList();
    expiringLots.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
    final expiringCount = expiringLots.length;
    
    // Low stock count
    final lowStockCount = state.products.where((p) => p.totalQuantity <= p.minStock && !state.isProductOrdered(p.id)).length;
    
    // Total Revenue (let's sum the sales)
    final totalRevenue = state.sales.fold(0.0, (sum, s) => sum + s.netAmount);
    
    // Recent sales (sorted by date descending)
    final recentSales = List<Sale>.from(state.sales)..sort((a, b) => b.date.compareTo(a.date));
    final displayRecentSales = recentSales.take(5).toList();

    return Scaffold(
      backgroundColor: state.bgPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row for metrics grid (3 cards in first row, 3 cards in second row)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _buildSleekMetricCard(
                  title: 'Médicaments',
                  value: '$totalProductsCount',
                  valueColor: const Color(0xFF3B82F6), // Vibrant Blue
                  icon: Icons.inventory_2_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  state: state,
                ),
                _buildSleekMetricCard(
                  title: 'Ventes Totales',
                  value: '$totalSalesCount',
                  valueColor: const Color(0xFF10B981), // Green
                  icon: Icons.shopping_cart_rounded,
                  iconColor: const Color(0xFF10B981),
                  state: state,
                ),
                _buildSleekMetricCard(
                  title: 'Fournisseurs',
                  value: totalSuppliersCount == 0 ? '0' : '$totalSuppliersCount',
                  valueColor: const Color(0xFF8B5CF6), // Purple
                  icon: Icons.local_shipping_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  state: state,
                ),
                _buildSleekMetricCard(
                  title: "Alerte d'expiration",
                  value: '$expiringCount',
                  valueColor: const Color(0xFFF59E0B), // Orange
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  state: state,
                ),
                _buildSleekMetricCard(
                  title: 'Stock Faible',
                  value: '$lowStockCount',
                  valueColor: const Color(0xFFEF4444), // Red
                  icon: Icons.inventory_rounded,
                  iconColor: const Color(0xFFEF4444),
                  state: state,
                ),
                _buildSleekMetricCard(
                  title: 'Revenue',
                  value: _formatCurrency(totalRevenue, isMasked: state.maskRevenues),
                  valueColor: const Color(0xFF10B981), // Teal/Green
                  icon: Icons.attach_money_rounded,
                  iconColor: const Color(0xFF10B981),
                  state: state,
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Bottom columns layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1000;
                final content = [
                  // Left Column: Recent Sales
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _buildGlassPanel(
                      title: 'Ventes Récentes',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      child: displayRecentSales.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'Aucune vente récente',
                                  style: GoogleFonts.inter(color: state.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayRecentSales.length,
                              separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.04), height: 24),
                              itemBuilder: (context, index) {
                                final sale = displayRecentSales[index];
                                return Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white.withOpacity(0.04),
                                      radius: 18,
                                      child: Icon(Icons.receipt_long_rounded, color: state.textSecondary, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Vente #${sale.id.substring(0, min(8, sale.id.length))}',
                                            style: GoogleFonts.inter(color: state.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('dd/MM/yyyy').format(sale.date),
                                            style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(sale.netAmount, isMasked: state.maskRevenues),
                                      style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                );
                              },
                            ),
                      state: state,
                    ),
                  ),
                  
                  if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),
                  
                  // Right Column: Médicaments périmés ou expirant bientôt
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _buildGlassPanel(
                      title: 'Médicaments périmés ou expirant bientôt',
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      child: expiringLots.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'Aucun lot périmé ou expirant bientôt',
                                  style: GoogleFonts.inter(color: state.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: expiringLots.length,
                              separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.04), height: 24),
                              itemBuilder: (context, index) {
                                final lot = expiringLots[index];
                                final daysLeft = lot.expirationDate.difference(DateTime.now()).inDays;
                                final isExpired = daysLeft < 0;
                                final displayColor = isExpired || daysLeft <= 10 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
                                return Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: displayColor.withOpacity(0.08),
                                      radius: 18,
                                      child: Icon(
                                        isExpired ? Icons.dangerous_rounded : Icons.hourglass_empty_rounded,
                                        color: displayColor,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lot.productName,
                                            style: GoogleFonts.inter(color: state.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'N° de lot : ${lot.lotNumber}',
                                            style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          isExpired ? 'PÉRIMÉ' : '$daysLeft jours',
                                          style: GoogleFonts.inter(
                                            color: displayColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Quantité: ${lot.quantity}',
                                          style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                      state: state,
                    ),
                  ),
                ];
                
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: content,
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: content.map((w) => w is Expanded ? w.child : w).toList(),
                  );
                }
              },
            ),
            const SizedBox(height: 32),
            _buildMonthlyChartSection(state),
          ],
        ),
      ),
    );
  }

  Widget _buildSleekMetricCard({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
    required AppStateProvider state,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: state.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: state.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: valueColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPanel({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    required AppStateProvider state,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: state.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: state.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: state.borderTheme, height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMonthlyChartSection(AppStateProvider state) {
    final now = DateTime.now();
    final year = now.year;
    
    // Calculate sales per month for the current year
    final List<double> monthlySales = List.generate(12, (index) {
      final month = index + 1;
      final salesInMonth = state.sales.where((s) => s.date.year == year && s.date.month == month);
      return salesInMonth.fold(0.0, (sum, s) => sum + s.netAmount);
    });

    final maxY = monthlySales.isEmpty ? 1000.0 : monthlySales.reduce(max);
    final chartMaxY = maxY == 0 ? 1000.0 : maxY * 1.2;

    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: state.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Croissance des Activités ($year)',
                style: GoogleFonts.outfit(
                  color: state.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(Icons.bar_chart_rounded, color: const Color(0xFF3B82F6), size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: state.borderTheme, height: 1),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMaxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${months[group.x.toInt()]}\n${_formatCurrency(rod.toY, isMasked: state.maskRevenues)}',
                        GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final style = GoogleFonts.inter(
                          color: state.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        );
                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(months[value.toInt()], style: style),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value == chartMaxY || value == 0) return Container();
                        if (state.maskRevenues) {
                          return Text('***', style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11));
                        }
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: GoogleFonts.inter(
                            color: state.textSecondary,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: state.borderTheme.withOpacity(0.5),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(12, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: monthlySales[i],
                        color: const Color(0xFF3B82F6),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: chartMaxY,
                          color: state.borderTheme.withOpacity(0.2),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
