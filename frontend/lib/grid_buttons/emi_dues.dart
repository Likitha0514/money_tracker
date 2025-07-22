import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EmiDuesPage extends StatefulWidget {
  const EmiDuesPage({super.key});

  @override
  State<EmiDuesPage> createState() => _EmiDuesPageState();
}

class _EmiDuesPageState extends State<EmiDuesPage> {
  double _balance = 0; // Get from user session or parent
  List<Map<String, dynamic>> _transactions = []; // Get from parent or API
  List<Map<String, dynamic>> _emis = [];
  bool _showAddForm = false;
  final _emiNameController = TextEditingController();
  final _emiAmountController = TextEditingController();
  DateTime? _startMonth;
  DateTime? _endMonth;
  String userEmail = "user@email.com"; // Replace with actual user email

  @override
  void initState() {
    super.initState();
    _fetchEmis();
  }

  Future<void> _fetchEmis() async {
    final res = await http.get(
      Uri.parse('http://localhost:5000/api/emi/fetchemi?email=$userEmail'),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        _emis = List<Map<String, dynamic>>.from(data['emis']);
      });
    }
  }

  Future<void> _addEmi() async {
    if (_emiNameController.text.isEmpty ||
        _emiAmountController.text.isEmpty ||
        _startMonth == null ||
        _endMonth == null)
      return;
    final months = <String>[];
    var current = DateTime(_startMonth!.year, _startMonth!.month);
    while (!current.isAfter(_endMonth!)) {
      months.add(DateFormat('yyyy-MM').format(current));
      current = DateTime(current.year, current.month + 1);
    }
    final res = await http.post(
      Uri.parse('http://localhost:5000/api/emi/addemi'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': userEmail,
        'name': _emiNameController.text,
        'amount': double.parse(_emiAmountController.text),
        'months': months,
      }),
    );
    if (res.statusCode == 200) {
      _fetchEmis();
      setState(() => _showAddForm = false);
      _emiNameController.clear();
      _emiAmountController.clear();
      _startMonth = null;
      _endMonth = null;
    }
  }

  Future<void> _payEmiMonth(String emiId, String month, double amount) async {
    // Step 1: Mark EMI month as paid (existing endpoint)
    final res = await http.post(
      Uri.parse('http://localhost:5000/api/emi/updateemi'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'emiId': emiId, 'month': month}),
    );

    if (res.statusCode == 200) {
      // Step 2: Add transaction (use /transactions/out)
      final txnRes = await http.post(
        Uri.parse('http://localhost:5000/api/transactions/out'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': userEmail,
          'amount': amount,
          'notes': 'EMI for $month',
          'date': DateTime.now().toIso8601String(),
        }),
      );

      if (txnRes.statusCode == 201) {
        setState(() {
          _balance -= amount;
          _transactions.insert(0, {
            'amount': amount,
            'note': 'EMI for $month',
            'date': DateTime.now(),
            'type': 'spend',
          });
        });
        _fetchEmis(); // Refresh EMI list
      } else {
        // Handle transaction failure
        print('Transaction failed: ${txnRes.body}');
      }
    } else {
      // Handle EMI update failure
      print('EMI update failed: ${res.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFF7CFC00)),
        title: const Text(
          'EMI Dues',
          style: TextStyle(color: Color(0xFF7CFC00)),
        ),
        backgroundColor: Colors.black54,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7CFC00),
                  foregroundColor: Colors.black,
                ),
                onPressed: () => setState(() => _showAddForm = !_showAddForm),
                child: const Text('Add EMI'),
              ),
              if (_showAddForm)
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
                        TextField(
                          controller: _emiNameController,
                          decoration: const InputDecoration(
                            labelText: 'EMI Name',
                            labelStyle: TextStyle(color: Color(0xFF7CFC00)),
                            filled: true,
                            fillColor: Color(0xFF222222),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(color: Color(0xFF7CFC00)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emiAmountController,
                          decoration: const InputDecoration(
                            labelText: 'EMI Amount',
                            labelStyle: TextStyle(color: Color(0xFF7CFC00)),
                            filled: true,
                            fillColor: Color(0xFF222222),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Color(0xFF7CFC00)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                tileColor: Color(0xFF222222),
                                title: Text(
                                  _startMonth == null
                                      ? 'Start Month'
                                      : DateFormat(
                                        'yyyy-MM',
                                      ).format(_startMonth!),
                                  style: const TextStyle(
                                    color: Color(0xFF7CFC00),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF7CFC00),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(
                                      () =>
                                          _startMonth = DateTime(
                                            picked.year,
                                            picked.month,
                                            1,
                                          ),
                                    );
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                tileColor: Color(0xFF222222),
                                title: Text(
                                  _endMonth == null
                                      ? 'End Month'
                                      : DateFormat(
                                        'yyyy-MM',
                                      ).format(_endMonth!),
                                  style: const TextStyle(
                                    color: Color(0xFF7CFC00),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF7CFC00),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(
                                      () =>
                                          _endMonth = DateTime(
                                            picked.year,
                                            picked.month,
                                            1,
                                          ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7CFC00),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _addEmi,
                          child: const Text('Submit EMI'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              ..._emis.map(
                (emi) => EmiCard(
                  emi: emi,
                  onPay:
                      (month) => _payEmiMonth(emi['_id'], month, emi['amount']),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmiCard extends StatefulWidget {
  final Map<String, dynamic> emi;
  final Function(String month) onPay;
  const EmiCard({required this.emi, required this.onPay, super.key});

  @override
  State<EmiCard> createState() => _EmiCardState();
}

class _EmiCardState extends State<EmiCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              '${widget.emi['name']}',
              style: const TextStyle(
                color: Color(0xFF7CFC00),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Amount: ₹${widget.emi['amount']}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: Color(0xFF7CFC00),
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded)
            Column(
              children: [
                const Text(
                  'Months:',
                  style: TextStyle(
                    color: Color(0xFF7CFC00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Wrap(
                  children: List<Widget>.from(
                    (widget.emi['months'] as List).map(
                      (month) => Padding(
                        padding: const EdgeInsets.all(4),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7CFC00),
                            foregroundColor: Colors.black,
                          ),
                          child: Text(
                            month,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            final pay = await showDialog<bool>(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    backgroundColor: Colors.black,
                                    title: Text(
                                      'Pay EMI for $month?',
                                      style: const TextStyle(
                                        color: Color(0xFF7CFC00),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(ctx, false),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(ctx, true),
                                        child: const Text(
                                          'Pay',
                                          style: TextStyle(
                                            color: Color(0xFF7CFC00),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                            if (pay == true) widget.onPay(month);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
