import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class CustomDashboardView extends StatelessWidget {
  const CustomDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final textPrimary = Colors.black87;
    final accent = Color(0xFF0F9D58);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'TABLEAU DE BORD',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text('Mai 2024', style: GoogleFonts.inter(color: Colors.black87)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_drop_down, color: Colors.black54),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // KPI cards
            SizedBox(
              height: 120,
              child: Row(
                children: [
                  _kpiCard('CHIFFRE D\'AFFAIRES', '12 450 000', 'FCFA', Colors.green.shade50, accent),
                  const SizedBox(width: 12),
                  _kpiCard('COÛTS TOTAUX', '7 350 000', 'FCFA', Colors.red.shade50, Colors.redAccent),
                  const SizedBox(width: 12),
                  _kpiCard('PROFIT NET', '5 100 000', 'FCFA', Colors.green.shade50, Colors.green),
                  const SizedBox(width: 12),
                  _kpiCard('MARGE NETTE', '40,9%', '', Colors.green.shade50, Colors.teal),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Charts and summary
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: line chart and summary
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ÉVOLUTION DU PROFIT NET', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 180,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: false),
                                  titlesData: FlTitlesData(show: true, leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true))),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: const [
                                        FlSpot(0, 2.1),
                                        FlSpot(1, 2.8),
                                        FlSpot(2, 3.6),
                                        FlSpot(3, 3.9),
                                        FlSpot(4, 5.1),
                                      ],
                                      isCurved: true,
                                      color: accent,
                                      barWidth: 3,
                                      dotData: FlDotData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('RÉSUMÉ FINANCIER', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Text('Total des ventes 12 450 000 FCFA', style: GoogleFonts.inter(color: Colors.black87)),
                                  Text('Total des charges 7 350 000 FCFA', style: GoogleFonts.inter(color: Colors.black54)),
                                  Text('Profit net 5 100 000 FCFA', style: GoogleFonts.inter(color: Colors.green)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('TOP PRODUITS / SERVICES', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                _miniListItem('Prestation A', '4 250 000'),
                                _miniListItem('Produit B', '3 150 000'),
                                _miniListItem('Prestation C', '2 300 000'),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right column: pie and performance
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Container(
                        height: 260,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text('RÉPARTITION DES CHARGES', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: PieChart(
                                      PieChartData(
                                        sections: [
                                          PieChartSectionData(value: 35, color: Colors.blueGrey, radius: 40, title: ''),
                                          PieChartSectionData(value: 25, color: Colors.redAccent, radius: 40, title: ''),
                                          PieChartSectionData(value: 20, color: Colors.green, radius: 40, title: ''),
                                          PieChartSectionData(value: 10, color: Colors.orange, radius: 40, title: ''),
                                          PieChartSectionData(value: 10, color: Colors.grey, radius: 40, title: ''),
                                        ],
                                        sectionsSpace: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _legendItem(Colors.blueGrey, 'Achats', '35%'),
                                      _legendItem(Colors.redAccent, 'Charges externes', '25%'),
                                      _legendItem(Colors.green, 'Salaires', '20%'),
                                      _legendItem(Colors.orange, 'Transport', '10%'),
                                      _legendItem(Colors.grey, 'Autres', '10%'),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PERFORMANCE GLOBALE', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('40,9%', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.green)),
                                    const SizedBox(height: 8),
                                    Text('Marge nette', style: GoogleFonts.inter(color: Colors.black54)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, [bool selected = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 36,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: GoogleFonts.inter(color: Colors.white70)),
          )
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, String unit, Color bg, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: GoogleFonts.inter(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(value + (unit.isNotEmpty ? ' $unit' : ''), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                ],
              ),
            ),
            Container(width: 48, height: 48, decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.show_chart, color: accent)),
          ],
        ),
      ),
    );
  }

  Widget _miniListItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12))),
          const SizedBox(width: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12))),
          Text(value, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
