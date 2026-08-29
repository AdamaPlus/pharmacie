import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/pharmacy_models.dart';
import '../providers/app_state_provider.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});
  static const green = Color(0xFF079447),
      blue = Color(0xFF2F7DF4),
      purple = Color(0xFF9254DE),
      orange = Color(0xFFF59E0B),
      red = Color(0xFFE84D5B),
      ink = Color(0xFF17212B),
      muted = Color(0xFF697586),
      line = Color(0xFFE7ECF1);

  String money(num n) =>
      '${NumberFormat.decimalPattern('fr_FR').format(n.round())} GNF';
  TextStyle text(double size, Color color,
          [FontWeight weight = FontWeight.w400]) =>
      GoogleFonts.inter(
        fontSize: size < 10
            ? size + 2
            : size < 14
                ? size + 1.5
                : size + 1,
        color: color,
        fontWeight: weight,
        height: 1.2,
      );
  BoxDecoration card() => BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
                color: Color(0x070F172A), blurRadius: 12, offset: Offset(0, 3))
          ]);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final systemNow = DateTime.now();
    final now = DateTime(
        state.workingYear,
        systemNow.month,
        min(systemNow.day,
            DateUtils.getDaysInMonth(state.workingYear, systemNow.month)));
    final todaySales =
        state.sales.where((s) => DateUtils.isSameDay(s.date, now)).toList();
    final todayExpenses = state.expenses
        .where((e) => DateUtils.isSameDay(e.date, now))
        .fold<double>(0, (v, e) => v + e.amount);
    final monthExpenses = state.expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0, (v, e) => v + e.amount);
    final todayRevenue =
        todaySales.fold<double>(0, (v, s) => v + s.netAmount) - todayExpenses;
    final monthRevenue = state.sales
            .where((s) => s.date.year == now.year && s.date.month == now.month)
            .fold<double>(0, (v, s) => v + s.netAmount) -
        monthExpenses;
    final pendingOrders = state.suppliers
        .expand((s) => s.orders)
        .where((o) => o.status != 'RECUE' && o.status != 'ANNULEE')
        .length;
    final low = state.products
        .where((p) => p.totalQuantity <= p.minStock)
        .toList()
      ..sort((a, b) => a.totalQuantity.compareTo(b.totalQuantity));
    final recentSales = [...state.sales]
      ..sort((a, b) => b.date.compareTo(a.date));
    final purchases = <_Purchase>[];
    for (final supplier in state.suppliers) {
      for (final order in supplier.orders) {
        if (order.date.year == state.workingYear) {
          purchases.add(_Purchase(supplier.name, order));
        }
      }
    }
    purchases.sort((a, b) => b.order.date.compareTo(a.order.date));
    final categories = <String, double>{},
        products = {for (final p in state.products) p.id: p};
    for (final sale in state.sales
        .where((s) => s.date.year == now.year && s.date.month == now.month)) {
      for (final item in sale.items) {
        final c = products[item.productId]?.category.trim();
        categories.update(
            c == null || c.isEmpty ? 'Autres' : c, (v) => v + item.total,
            ifAbsent: () => item.total);
      }
    }

    return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: LayoutBuilder(
            builder: (_, box) => SingleChildScrollView(
                padding: EdgeInsets.all(box.maxWidth < 700 ? 16 : 22),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 10,
                          children: [
                            Text('Tableau de bord',
                                style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: ink)),
                            Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                      onPressed: () {
                                        state.refreshSystemAlerts();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Tableau de bord actualisé avec succès.'),
                                          backgroundColor: blue,
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                      },
                                      icon: const Icon(Icons.refresh_rounded,
                                          size: 17),
                                      label: const Text('Actualiser'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: blue,
                                          foregroundColor: Colors.white)),
                                  const Icon(Icons.calendar_month_rounded,
                                      color: green, size: 20),
                                  Text('Année de travail',
                                      style: text(12, muted, FontWeight.w600)),
                                  DropdownButton<int>(
                                      value: state.workingYear,
                                      underline: const SizedBox(),
                                      style: text(16, ink, FontWeight.w800),
                                      items: state.availableWorkingYears
                                          .map((year) => DropdownMenuItem(
                                              value: year,
                                              child: Text('$year')))
                                          .toList(),
                                      onChanged: (year) {
                                        if (year != null)
                                          state.setWorkingYear(year);
                                      }),
                                  OutlinedButton.icon(
                                      onPressed: () =>
                                          _confirmNextYear(context, state),
                                      icon: const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16),
                                      label: Text('${state.workingYear + 1}'),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: green,
                                          side: const BorderSide(color: green)))
                                ])
                          ]),
                      const SizedBox(height: 3),
                      Text(
                          'Bienvenue, voici l’activité générale de votre pharmacie.',
                          style: text(12, muted)),
                      if (state.shouldShowPreviousYearDebtReminder) ...[
                        const SizedBox(height: 14),
                        _previousYearDebtReminder(state),
                      ],
                      const SizedBox(height: 18),
                      _metrics(box.maxWidth, [
                        (
                          'Ventes du jour',
                          money(todayRevenue),
                          '${todaySales.length} vente(s), dépenses déduites',
                          Icons.shopping_cart_outlined,
                          green
                        ),
                        (
                          'Produits en stock',
                          '${state.products.length}',
                          '${state.products.fold<int>(0, (v, p) => v + p.totalQuantity)} unités disponibles',
                          Icons.inventory_2_outlined,
                          blue
                        ),
                        (
                          'Commandes en cours',
                          '$pendingOrders',
                          'En attente de réception',
                          Icons.groups_outlined,
                          purple
                        ),
                        (
                          'Montant net',
                          money(monthRevenue),
                          'Ventes moins dépenses du mois',
                          Icons.monetization_on_outlined,
                          orange
                        )
                      ]),
                      const SizedBox(height: 14),
                      _topGrid(box.maxWidth, state, low, categories),
                      const SizedBox(height: 14),
                      _bottomGrid(
                          box.maxWidth, state, recentSales, purchases, low),
                    ]))));
  }

  Widget _previousYearDebtReminder(AppStateProvider state) {
    final unpaidLoans = state.unpaidLoansFromPreviousYears;
    final years = unpaidLoans.map((loan) => loan.loanDate.year).toSet().toList()
      ..sort();
    final yearsText = years.join(', ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D6),
        border: Border.all(color: const Color(0xFFF4C542)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFF9A6700), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${unpaidLoans.length} dette(s) de $yearsText ne sont pas encore payées.',
              style: text(12, const Color(0xFF7A5200), FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Masquer pour aujourd’hui',
            onPressed: state.dismissPreviousYearDebtReminder,
            icon: const Icon(Icons.close_rounded,
                color: Color(0xFF7A5200), size: 19),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmNextYear(
      BuildContext context, AppStateProvider state) async {
    final nextYear = state.workingYear + 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Passer à l’année $nextYear ?'),
        content: Text(
            'L’application utilisera $nextYear comme année de travail. Vous pourrez toujours consulter ${state.workingYear} depuis la liste des années.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed == true) await state.setWorkingYear(nextYear);
  }

  Widget _metrics(
      double width, List<(String, String, String, IconData, Color)> data) {
    final cols = width >= 1000
        ? 4
        : width >= 560
            ? 2
            : 1;
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 126),
        itemBuilder: (_, i) {
          final d = data[i];
          return Container(
              padding: const EdgeInsets.all(16),
              decoration: card(),
              child: Row(children: [
                Container(
                    width: 47,
                    height: 47,
                    decoration: BoxDecoration(
                        color: d.$5, borderRadius: BorderRadius.circular(10)),
                    child: Icon(d.$4, color: Colors.white, size: 24)),
                const SizedBox(width: 13),
                Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(d.$1, style: text(11, muted, FontWeight.w600)),
                      const SizedBox(height: 7),
                      FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(d.$2,
                              style: text(17, ink, FontWeight.w800))),
                      const SizedBox(height: 7),
                      Text(d.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text(9, d.$5, FontWeight.w600))
                    ]))
              ]));
        });
  }

  Widget _topGrid(double width, AppStateProvider state, List<Product> low,
      Map<String, double> categories) {
    final referenceDate = state.workingDate;
    final evolution = _evolution(state.sales, referenceDate);
    final left = _panel(
        'Évolution des ventes', _salesChart(evolution, referenceDate),
        action: '7 derniers jours', onTap: () => state.setActiveTab(10));
    final middle = _panel('Produits à stock faible', _lowStock(state, low),
        action: 'Voir tout', onTap: () => state.setActiveTab(1));
    final right = _panel('Répartition des ventes', _donut(categories),
        action: 'Ce mois', onTap: () => state.setActiveTab(10));
    if (width < 900)
      return Column(children: [
        left,
        const SizedBox(height: 14),
        middle,
        const SizedBox(height: 14),
        right
      ]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 5, child: left),
      const SizedBox(width: 14),
      Expanded(flex: 3, child: middle),
      const SizedBox(width: 14),
      Expanded(flex: 3, child: right)
    ]);
  }

  Widget _bottomGrid(double width, AppStateProvider state, List<Sale> sales,
      List<_Purchase> purchases, List<Product> low) {
    final a = _panel('Ventes récentes', _recentSales(sales),
        action: 'Voir tout', onTap: () => state.setActiveTab(11), height: 245);
    final b = _panel('Derniers achats', _purchases(purchases),
        action: 'Voir tout', onTap: () => state.setActiveTab(6), height: 245);
    final c = _panel('Alertes importantes', _alerts(state, low), height: 245);
    if (width < 900)
      return Column(children: [
        a,
        const SizedBox(height: 14),
        b,
        const SizedBox(height: 14),
        c
      ]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: a),
      const SizedBox(width: 14),
      Expanded(child: b),
      const SizedBox(width: 14),
      Expanded(child: c)
    ]);
  }

  Widget _panel(String title, Widget child,
          {String? action, VoidCallback? onTap, double height = 320}) =>
      Container(
          height: height,
          padding: const EdgeInsets.all(14),
          decoration: card(),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: Text(title, style: text(12, ink, FontWeight.w700))),
              if (action != null)
                TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6)),
                    child: Text(action,
                        style: text(
                            9, onTap == null ? muted : blue, FontWeight.w600)))
            ]),
            const SizedBox(height: 7),
            Expanded(child: child)
          ]));

  List<double> _evolution(List<Sale> sales, DateTime now) {
    final values = List<double>.filled(7, 0);
    for (final sale in sales) {
      final day = DateTime(now.year, now.month, now.day)
          .difference(DateTime(sale.date.year, sale.date.month, sale.date.day))
          .inDays;
      if (day >= 0 && day < 7) values[6 - day] += sale.netAmount;
    }
    return values;
  }

  Widget _salesChart(List<double> values, DateTime now) {
    final top = max(10.0, values.fold<double>(0, max) * 1.2), chartDate = now;
    return LineChart(LineChartData(
        minY: 0,
        maxY: top,
        gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: line, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) =>
                        Text(_compact(v), style: text(8, muted)))),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i > 6) return const SizedBox();
                      return SideTitleWidget(
                          meta: meta,
                          child: Text(
                              DateFormat('dd MMM', 'fr_FR').format(
                                  chartDate.subtract(Duration(days: 6 - i))),
                              style: text(7.5, muted)));
                    }))),
        lineBarsData: [
          LineChartBarData(
              spots: List.generate(7, (i) => FlSpot(i.toDouble(), values[i])),
              isCurved: true,
              color: green,
              barWidth: 2.2,
              dotData: const FlDotData(show: false),
              belowBarData:
                  BarAreaData(show: true, color: green.withOpacity(.10)))
        ]));
  }

  String _compact(double n) => n >= 1000000
      ? '${(n / 1000000).toStringAsFixed(1)}M'
      : n >= 1000
          ? '${(n / 1000).round()}K'
          : n.round().toString();

  Widget _lowStock(AppStateProvider state, List<Product> items) => items.isEmpty
      ? _empty('Aucun stock faible')
      : ListView.separated(
          itemCount: min(4, items.length),
          separatorBuilder: (_, __) => const Divider(height: 1, color: line),
          itemBuilder: (_, i) {
            final p = items[i], danger = p.totalQuantity <= 5;
            return InkWell(
                onTap: () => state.setActiveTab(1),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(children: [
                      Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.medication_outlined,
                              color: blue, size: 19)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text(10, ink, FontWeight.w700)),
                            Text(p.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text(8, muted))
                          ])),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                              color: danger
                                  ? const Color(0xFFFFEEF0)
                                  : const Color(0xFFFFF6E6),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text('${p.totalQuantity} unités',
                              style: text(
                                  8, danger ? red : orange, FontWeight.w700)))
                    ])));
          });

  Widget _donut(Map<String, double> input) {
    final entries = input.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = entries.take(5).toList();
    if (shown.isEmpty) return _empty('Aucune vente ce mois');
    final total = shown.fold<double>(0, (v, e) => v + e.value);
    const colors = [blue, green, orange, red, purple];
    return Column(children: [
      Expanded(
          child: Stack(alignment: Alignment.center, children: [
        PieChart(PieChartData(
            centerSpaceRadius: 45,
            sectionsSpace: 2,
            sections: List.generate(
                shown.length,
                (i) => PieChartSectionData(
                    value: shown[i].value,
                    color: colors[i],
                    radius: 24,
                    showTitle: false)))),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_compact(total), style: text(14, ink, FontWeight.w800)),
          Text('GNF', style: text(8, muted))
        ])
      ])),
      ...List.generate(
          shown.length,
          (i) => Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(children: [
                Container(width: 7, height: 7, color: colors[i]),
                const SizedBox(width: 7),
                Expanded(
                    child: Text(shown[i].key,
                        overflow: TextOverflow.ellipsis,
                        style: text(8, muted))),
                Text('${(shown[i].value / total * 100).round()}%',
                    style: text(8, ink, FontWeight.w700))
              ])))
    ]);
  }

  Widget _recentSales(List<Sale> sales) => sales.isEmpty
      ? _empty('Aucune vente récente')
      : ListView.builder(
          itemCount: min(5, sales.length),
          itemBuilder: (_, i) {
            final s = sales[i];
            return SizedBox(
                height: 40,
                child: Row(children: [
                  Expanded(
                      flex: 3,
                      child: Text(s.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text(8, ink, FontWeight.w700))),
                  Expanded(
                      flex: 3,
                      child: Text(
                          DateFormat('dd MMM, HH:mm', 'fr_FR').format(s.date),
                          style: text(8, muted))),
                  Expanded(
                      flex: 3,
                      child: Text(money(s.netAmount),
                          textAlign: TextAlign.right,
                          style: text(8, ink, FontWeight.w700))),
                  const SizedBox(width: 8),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEAF8F0),
                          borderRadius: BorderRadius.circular(4)),
                      child:
                          Text('Payée', style: text(7, green, FontWeight.w700)))
                ]));
          });
  Widget _purchases(List<_Purchase> items) => items.isEmpty
      ? _empty('Aucun achat récent')
      : ListView.builder(
          itemCount: min(5, items.length),
          itemBuilder: (_, i) {
            final p = items[i];
            return SizedBox(
                height: 40,
                child: Row(children: [
                  Expanded(
                      flex: 3,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(p.order.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text(8, ink, FontWeight.w700)),
                            Text(p.supplier,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text(7, muted))
                          ])),
                  Expanded(
                      flex: 2,
                      child: Text(
                          DateFormat('dd MMM yyyy', 'fr_FR')
                              .format(p.order.date),
                          style: text(7, muted))),
                  Expanded(
                      flex: 2,
                      child: Text(money(p.order.totalAmount),
                          textAlign: TextAlign.right,
                          style: text(8, ink, FontWeight.w700)))
                ]));
          });

  Widget _alerts(AppStateProvider state, List<Product> low) {
    final expiring = state.lots
            .where((l) =>
                l.quantity > 0 &&
                l.expirationDate
                    .isBefore(DateTime.now().add(const Duration(days: 30))))
            .length,
        pending = state.suppliers
            .expand((s) => s.orders)
            .where((o) => o.status != 'RECUE' && o.status != 'ANNULEE')
            .length;
    return Column(children: [
      _alert(
          '${low.length} médicament(s) en rupture ou stock faible',
          'Vérifiez les quantités disponibles',
          red,
          Icons.notifications_none_rounded,
          () => state.setActiveTab(1)),
      const SizedBox(height: 8),
      _alert(
          '$expiring médicament(s) expirent bientôt',
          'Vérifiez les dates de péremption',
          orange,
          Icons.warning_amber_rounded,
          () => state.setActiveTab(1)),
      const SizedBox(height: 8),
      _alert(
          '$pending commande(s) en attente',
          'Confirmez les réceptions fournisseurs',
          blue,
          Icons.local_shipping_outlined,
          () => state.setActiveTab(13))
    ]);
  }

  Widget _alert(String title, String sub, Color color, IconData icon,
          VoidCallback tap) =>
      Expanded(
          child: InkWell(
              onTap: tap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      color: color.withOpacity(.06),
                      borderRadius: BorderRadius.circular(6)),
                  child: Row(children: [
                    Icon(icon, color: color, size: 17),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text(8, color, FontWeight.w700)),
                          Text(sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text(7, muted))
                        ])),
                    const Icon(Icons.chevron_right_rounded,
                        color: muted, size: 17)
                  ]))));
  Widget _empty(String label) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.inbox_outlined, color: Color(0xFFCBD5E1), size: 36),
        const SizedBox(height: 8),
        Text(label, style: text(10, muted))
      ]));
}

class _Purchase {
  const _Purchase(this.supplier, this.order);
  final String supplier;
  final SupplierOrder order;
}
