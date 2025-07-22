import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class TrackSpendPage extends StatefulWidget {
  const TrackSpendPage({super.key});

  @override
  State<TrackSpendPage> createState() => _TrackSpendPageState();
}

class _TrackSpendPageState extends State<TrackSpendPage> {
  double _balance = 0;
  final TextEditingController _amountInController = TextEditingController();
  final TextEditingController _spendAmountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _error;
  List<Map<String, dynamic>> _transactions = [];

  void _addAmountIn() {
    final amt = double.tryParse(_amountInController.text);
    if (amt == null || amt <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    setState(() {
      _balance += amt;
      _transactions.insert(0, {
        'amount': amt,
        'note': 'Amount In',
        'date': DateTime.now(),
        'type': 'in',
      });
      _amountInController.clear();
      _error = null;
    });
  }

  void _addTransaction() {
    final amt = double.tryParse(_spendAmountController.text);
    final note = _noteController.text.trim();
    if (amt == null || amt <= 0) {
      setState(() => _error = 'Enter a valid spend amount');
      return;
    }
    if (amt > _balance) {
      setState(() => _error = 'Spend amount exceeds balance');
      return;
    }
    setState(() {
      _balance -= amt;
      _transactions.insert(0, {
        'amount': amt,
        'note': note,
        'date': DateTime.now(),
        'type': 'spend',
      });
      _spendAmountController.clear();
      _noteController.clear();
      _error = null;
    });
  }

  Future<void> _downloadTransactionsAsPdf(BuildContext context) async {
    final pdf = pw.Document();
    final totalIn = _transactions
        .where((tx) => tx['type'] == 'in')
        .fold<double>(0, (sum, tx) => sum + (tx['amount'] as double));
    final totalSpend = _transactions
        .where((tx) => tx['type'] == 'spend')
        .fold<double>(0, (sum, tx) => sum + (tx['amount'] as double));

    pdf.addPage(
      pw.MultiPage(
        build:
            (pw.Context ctx) => [
              pw.Text(
                'Transaction Details',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF000000),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['Type', 'Amount', 'Note', 'Date'],
                data:
                    _transactions.reversed
                        .map(
                          (tx) => [
                            tx['type'] == 'in' ? 'Amount In' : 'Spend',
                            '${tx['amount'].toStringAsFixed(0)}',
                            tx['note'],
                            (tx['date'] as DateTime).toString(),
                          ],
                        )
                        .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF000000),
                ),
                cellStyle: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromInt(0xFF000000),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF000000),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Total In: ${totalIn.toStringAsFixed(0)}',
                style: pw.TextStyle(
                  color: PdfColor.fromInt(0xFF000000),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Total Spend: ${totalSpend.toStringAsFixed(0)}',
                style: pw.TextStyle(
                  color: PdfColor.fromInt(0xFF000000),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Balance: ${_balance.toStringAsFixed(0)}',
                style: pw.TextStyle(
                  color: PdfColor.fromInt(0xFF000000),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFF7CFC00)),
        title: const Text(
          'Track Spend',
          style: TextStyle(color: Color(0xFF7CFC00)),
        ),
        backgroundColor: Colors.black54,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Balance',
                  style: TextStyle(color: Color(0xFF7CFC00), fontSize: 12),
                ),
                Text(
                  '₹${_balance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF7CFC00),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.black,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add Amount In',
                        style: TextStyle(
                          color: Color(0xFF7CFC00),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountInController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Enter amount',
                                hintStyle: TextStyle(color: Color(0xFF7CFC00)),
                                filled: true,
                                fillColor: Color(0xFF222222),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(color: Color(0xFF7CFC00)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7CFC00),
                              foregroundColor: Colors.black,
                            ),
                            onPressed: _addAmountIn,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.black,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add Spend Transaction',
                        style: TextStyle(
                          color: Color(0xFF7CFC00),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _spendAmountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Enter spend amount',
                                hintStyle: TextStyle(color: Color(0xFF7CFC00)),
                                filled: true,
                                fillColor: Color(0xFF222222),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(color: Color(0xFF7CFC00)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                hintText: 'Enter note',
                                hintStyle: TextStyle(color: Color(0xFF7CFC00)),
                                filled: true,
                                fillColor: Color(0xFF222222),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(color: Color(0xFF7CFC00)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7CFC00),
                              foregroundColor: Colors.black,
                            ),
                            onPressed: _addTransaction,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_transactions.isNotEmpty)
                Card(
                  color: Colors.black,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transactions',
                              style: TextStyle(
                                color: Color(0xFF7CFC00),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF7CFC00),
                                foregroundColor: Colors.black,
                              ),
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                              onPressed:
                                  () => _downloadTransactionsAsPdf(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._transactions.map(
                          (tx) => Card(
                            color: Color(0xFF222222),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Icon(
                                tx['type'] == 'in'
                                    ? Icons.add_circle
                                    : Icons.remove_circle,
                                color:
                                    tx['type'] == 'spend'
                                        ? Colors.redAccent
                                        : Color(0xFF7CFC00),
                              ),
                              title: Text(
                                '₹${tx['amount'].toStringAsFixed(0)}',
                                style: TextStyle(
                                  /// The above code is setting the color based on the condition that if
                                  /// the value of `tx['type']` is equal to 'spend', then it will use
                                  /// the color `Colors.redAccent`, otherwise it will use the color
                                  /// `Color(0xFF7CFC00)`.
                                  color:
                                      tx['type'] == 'spend'
                                          ? Colors.redAccent
                                          : Color(0xFF7CFC00),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                tx['note'].isEmpty
                                    ? (tx['type'] == 'in'
                                        ? 'Amount In'
                                        : 'No note')
                                    : tx['note'],
                                style: const TextStyle(
                                  color: Color(0xFF7CFC00),
                                ),
                              ),
                              trailing: Text(
                                '${(tx['date'] as DateTime).hour.toString().padLeft(2, '0')}:${(tx['date'] as DateTime).minute.toString().padLeft(2, '0')} ${(tx['date'] as DateTime).day}/${(tx['date'] as DateTime).month}',
                                style: TextStyle(
                                  color:
                                      tx['type'] == 'spend'
                                          ? Colors.redAccent
                                          : Color(0xFF7CFC00),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF222222),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total In: ₹${_transactions.where((tx) => tx['type'] == 'in').fold<double>(0, (sum, tx) => sum + (tx['amount'] as double)).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFF7CFC00),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Total Spend: ₹${_transactions.where((tx) => tx['type'] == 'spend').fold<double>(0, (sum, tx) => sum + (tx['amount'] as double)).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Balance: ₹${_balance.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFF7CFC00),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountInController.dispose();
    _spendAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
