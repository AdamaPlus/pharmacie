import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/pharmacy_models.dart';
import '../providers/app_state_provider.dart';

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});
  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  String _query = '', _category = 'Toutes';
  final _money = NumberFormat.decimalPattern('fr_FR');
  static const _green = Color(0xFF079447),
      _ink = Color(0xFF17212B),
      _muted = Color(0xFF697586),
      _line = Color(0xFFE7ECF1);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final categories =
        {'Toutes', ...state.expenses.map((e) => e.category)}.toList();
    final items = state.expenses
        .where((e) =>
            (_category == 'Toutes' || e.category == _category) &&
            ('${e.label} ${e.notes}'
                .toLowerCase()
                .contains(_query.toLowerCase())))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final now = state.workingDate;
    final month = state.expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0, (s, e) => s + e.amount);
    final today = state.expenses
        .where((e) => DateUtils.isSameDay(e.date, now))
        .fold<double>(0, (s, e) => s + e.amount);
    return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 12,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dépenses',
                                  style: GoogleFonts.outfit(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w700,
                                      color: _ink)),
                              Text(
                                  'Enregistrez et suivez toutes les charges de la pharmacie.',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: _muted))
                            ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          OutlinedButton.icon(
                              onPressed: items.isEmpty
                                  ? null
                                  : () => _printExpenses(state, items),
                              icon: const Icon(Icons.print_rounded),
                              label: const Text('Imprimer'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: _green,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 15))),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                              onPressed: () => _openForm(state),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Nouvelle dépense'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7))))
                        ])
                      ]),
                  const SizedBox(height: 20),
                  Wrap(spacing: 14, runSpacing: 14, children: [
                    _summary('Dépenses aujourd’hui', today, Icons.today_rounded,
                        const Color(0xFFF59E0B)),
                    _summary('Dépenses ce mois', month,
                        Icons.calendar_month_rounded, _green),
                    _summary('Nombre d’opérations', items.length.toDouble(),
                        Icons.receipt_long_rounded, const Color(0xFF3B82F6),
                        count: true)
                  ]),
                  const SizedBox(height: 18),
                  Container(
                      padding: const EdgeInsets.all(14),
                      decoration: _card(),
                      child: Row(children: [
                        Expanded(
                            child: TextField(
                                onChanged: (v) => setState(() => _query = v),
                                decoration: _input('Rechercher une dépense...',
                                    Icons.search_rounded))),
                        const SizedBox(width: 12),
                        SizedBox(
                            width: 190,
                            child: DropdownButtonFormField<String>(
                                value: categories.contains(_category)
                                    ? _category
                                    : 'Toutes',
                                decoration: _input(
                                    'Catégorie', Icons.filter_list_rounded),
                                items: categories
                                    .map((v) => DropdownMenuItem(
                                        value: v, child: Text(v)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _category = v ?? 'Toutes')))
                      ])),
                  const SizedBox(height: 14),
                  Expanded(
                      child: Container(
                          decoration: _card(),
                          child: items.isEmpty
                              ? Center(
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                      const Icon(Icons.receipt_long_outlined,
                                          size: 50, color: Color(0xFFCBD5E1)),
                                      const SizedBox(height: 10),
                                      Text('Aucune dépense enregistrée',
                                          style:
                                              GoogleFonts.inter(color: _muted))
                                    ]))
                              : ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1, color: _line),
                                  itemBuilder: (_, i) {
                                    final e = items[i];
                                    return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 7),
                                        leading: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFFFF7E8),
                                                borderRadius:
                                                    BorderRadius.circular(7)),
                                            child: const Icon(Icons.payments_outlined,
                                                color: Color(0xFFF59E0B))),
                                        title: Text(e.label,
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                color: _ink)),
                                        subtitle: Text(
                                            '${e.category} • ${DateFormat('dd MMM yyyy', 'fr_FR').format(e.date)} • ${e.paymentMethod}',
                                            style: GoogleFonts.inter(
                                                fontSize: 11, color: _muted)),
                                        trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                  '${_money.format(e.amount.round())} GNF',
                                                  style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: _ink)),
                                              const SizedBox(width: 12),
                                              IconButton(
                                                  tooltip: 'Modifier',
                                                  onPressed: () =>
                                                      _openForm(state, e),
                                                  icon: const Icon(
                                                      Icons.edit_outlined,
                                                      size: 19)),
                                              IconButton(
                                                  tooltip: 'Supprimer',
                                                  onPressed: () =>
                                                      _delete(state, e),
                                                  icon: const Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      size: 19,
                                                      color: Colors.redAccent))
                                            ]));
                                  })))
                ])));
  }

  Future<void> _printExpenses(
      AppStateProvider state, List<Expense> items) async {
    final document = pw.Document();
    final total = items.fold<double>(0, (sum, expense) => sum + expense.amount);
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => [
        pw.Text(
            state.pharmacyName.isEmpty ? 'PharmaGuinée' : state.pharmacyName,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('RAPPORT DES DÉPENSES — ANNÉE ${state.workingYear}',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.Text(
            'Imprimé le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: const [
            'Date',
            'Libellé',
            'Catégorie',
            'Paiement',
            'Montant'
          ],
          data: items
              .map((expense) => [
                    DateFormat('dd/MM/yyyy').format(expense.date),
                    expense.label,
                    expense.category,
                    expense.paymentMethod,
                    '${_money.format(expense.amount.round())} GNF',
                  ])
              .toList(),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
          headerStyle: pw.TextStyle(
              color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignment: pw.Alignment.centerLeft,
        ),
        pw.SizedBox(height: 14),
        pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('TOTAL : ${_money.format(total.round())} GNF',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)))
      ],
    ));
    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }

  Widget _summary(String title, double value, IconData icon, Color color,
          {bool count = false}) =>
      Container(
          width: 260,
          height: 96,
          padding: const EdgeInsets.all(16),
          decoration: _card(),
          child: Row(children: [
            Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color)),
            const SizedBox(width: 13),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: GoogleFonts.inter(fontSize: 11, color: _muted)),
                  const SizedBox(height: 6),
                  FittedBox(
                      child: Text(
                          count
                              ? value.round().toString()
                              : '${_money.format(value.round())} GNF',
                          style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _ink)))
                ]))
          ]));
  BoxDecoration _card() => BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
                color: Color(0x080F172A), blurRadius: 12, offset: Offset(0, 3))
          ]);
  InputDecoration _input(String hint, IconData icon) => InputDecoration(
      isDense: true,
      hintText: hint,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _line)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _line)));

  Future<void> _openForm(AppStateProvider state, [Expense? expense]) async {
    final form = GlobalKey<FormState>(),
        label = TextEditingController(text: expense?.label),
        amount = TextEditingController(
            text: expense == null ? '' : expense.amount.round().toString()),
        notes = TextEditingController(text: expense?.notes);
    var category = expense?.category ?? 'Loyer',
        payment = expense?.paymentMethod ?? 'Espèces',
        date = expense?.date ?? state.workingDate;
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (_, setLocal) => AlertDialog(
                    title: Text(expense == null
                        ? 'Nouvelle dépense'
                        : 'Modifier la dépense'),
                    content: SizedBox(
                        width: 480,
                        child: Form(
                            key: form,
                            child: SingleChildScrollView(
                                child: Column(children: [
                              TextFormField(
                                  controller: label,
                                  decoration: _input(
                                      'Libellé', Icons.description_outlined),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Champ requis'
                                          : null),
                              const SizedBox(height: 12),
                              TextFormField(
                                  controller: amount,
                                  keyboardType: TextInputType.number,
                                  decoration: _input('Montant en GNF',
                                      Icons.payments_outlined),
                                  validator: (v) => (double.tryParse(
                                                  v?.replaceAll(' ', '') ??
                                                      '') ??
                                              0) <=
                                          0
                                      ? 'Montant invalide'
                                      : null),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                  value: category,
                                  decoration: _input(
                                      'Catégorie', Icons.category_outlined),
                                  items: [
                                    'Loyer',
                                    'Salaires',
                                    'Transport',
                                    'Électricité',
                                    'Entretien',
                                    'Fournitures',
                                    'Taxes',
                                    'Autres'
                                  ]
                                      .map((v) => DropdownMenuItem(
                                          value: v, child: Text(v)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setLocal(() => category = v!)),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                  value: payment,
                                  decoration: _input('Paiement',
                                      Icons.account_balance_wallet_outlined),
                                  items: [
                                    'Espèces',
                                    'Orange Money',
                                    'Virement',
                                    'Chèque'
                                  ]
                                      .map((v) => DropdownMenuItem(
                                          value: v, child: Text(v)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setLocal(() => payment = v!)),
                              const SizedBox(height: 12),
                              ListTile(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(color: _line),
                                      borderRadius: BorderRadius.circular(7)),
                                  leading:
                                      const Icon(Icons.calendar_today_outlined),
                                  title: Text(
                                      DateFormat('dd MMMM yyyy', 'fr_FR')
                                          .format(date)),
                                  onTap: () async {
                                    final d = await showDatePicker(
                                        context: dialogContext,
                                        initialDate: date,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(
                                            state.workingYear, 12, 31));
                                    if (d != null) setLocal(() => date = d);
                                  }),
                              const SizedBox(height: 12),
                              TextFormField(
                                  controller: notes,
                                  maxLines: 3,
                                  decoration: _input('Notes facultatives',
                                      Icons.notes_rounded))
                            ])))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Annuler')),
                      ElevatedButton(
                          onPressed: () {
                            if (!(form.currentState?.validate() ?? false))
                              return;
                            final item = Expense(
                                id: expense?.id ??
                                    'DEP-${DateTime.now().millisecondsSinceEpoch}',
                                label: label.text.trim(),
                                category: category,
                                amount: double.parse(
                                    amount.text.replaceAll(' ', '')),
                                date: date,
                                paymentMethod: payment,
                                notes: notes.text.trim());
                            expense == null
                                ? state.addExpense(item)
                                : state.updateExpense(item);
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(expense == null
                                    ? 'Dépense enregistrée avec succès.'
                                    : 'Dépense modifiée avec succès.'),
                                backgroundColor: _green));
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white),
                          child: Text(
                              expense == null ? 'Enregistrer' : 'Modifier'))
                    ])));
  }

  Future<void> _delete(AppStateProvider state, Expense expense) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Supprimer la dépense ?'),
                content:
                    Text('« ${expense.label} » sera supprimée définitivement.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Annuler')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Supprimer',
                          style: TextStyle(color: Colors.red)))
                ]));
    if (ok == true) {
      state.deleteExpense(expense.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dépense supprimée avec succès.'),
            backgroundColor: _green));
      }
    }
  }
}
