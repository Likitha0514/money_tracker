import 'package:MoneyTracker/grid_buttons/transaction_card_lent.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AmountLentPage extends StatefulWidget {
  const AmountLentPage({super.key});

  @override
  State<AmountLentPage> createState() => _AmountLentPageState();
}

class _AmountLentPageState extends State<AmountLentPage> {
  List<Map<String, dynamic>> _transactions = [];
  String? _email;
  bool _loading = true;
  String? _error;
  bool _showAddCard = false;
  double _balance = 0.0;

  Future<void> _fetchBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    if (email == null) return;

    final res = await http.get(
      Uri.parse('http://localhost:5000/api/transactions/balance?email=$email'),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _balance = (data['balance'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _loadEmailAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    if (email != null) {
      setState(() => _email = email);
      await Future.wait([
        _fetchTransactions(email),
        _fetchBalance(), // 👈 fetch balance
      ]);
    } else {
      setState(() {
        _error = 'Email not found';
        _loading = false;
      });
    }
  }

  Future<void> _fetchTransactions(String email) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.get(
        Uri.parse(
          'http://localhost:5000/api/transactions?type=lend&email=$email',
        ),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _transactions = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load transactions';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _clearTransaction(String transactionId, num amount) async {
    final uri = Uri.parse('http://localhost:5000/api/transactions/clear-full');
    final body = jsonEncode({
      'transactionId': transactionId,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
    });

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Transaction cleared")));
      if (_email != null) _fetchTransactions(_email!);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Clear failed: ${res.body}")));
    }
  }

  void _showPartialClearDialog({
    required String transactionId,
    required num currentAmount,
    required String? currentNote,
  }) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Partial Clear"),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter amount to clear",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  final entered = num.tryParse(controller.text);
                  if (entered == null || entered <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Enter valid amount")),
                    );
                    return;
                  }
                  if (entered > currentAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Cannot clear more than ₹$currentAmount"),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  await _partialClearTransaction(
                    transactionId: transactionId,
                    clearAmount: entered,
                    remainingAmount: currentAmount - entered,
                    originalNote: currentNote,
                  );
                },
                child: const Text("Clear"),
              ),
            ],
          ),
    );
  }

  Future<void> _partialClearTransaction({
    required String transactionId,
    required num clearAmount,
    required num remainingAmount,
    required String? originalNote,
  }) async {
    final uri = Uri.parse(
      'http://localhost:5000/api/transactions/clear-partial',
    );
    final body = jsonEncode({
      'transactionId': transactionId,
      'clearAmount': clearAmount,
      'remainingAmount': remainingAmount,
      'date': DateTime.now().toIso8601String(),
      'note': originalNote ?? '',
    });

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Partial amount cleared")));
      if (_email != null) _fetchTransactions(_email!);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Clear failed: ${res.body}")));
    }
  }

  void _onTransactionAdded() async {
    if (_email != null) {
      await _fetchTransactions(_email!);
      await _fetchBalance(); // 👈 update balance
      setState(() => _showAddCard = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEmailAndFetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "Amount Lent",
          style: TextStyle(color: Color(0xFF7CFC00)),
        ),
        backgroundColor: Colors.black54,
        iconTheme: const IconThemeData(color: Color(0xFF7CFC00)),
        actions: [
          const Text('ADD', style: TextStyle(color: Color(0xFF7CFC00))),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF7CFC00), size: 25),
            onPressed: () => setState(() => _showAddCard = !_showAddCard),
          ),
        ],
      ),
      body:
          _email == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_showAddCard)
                        AddTransactionCard1(
                          type: 'lend',
                          email: _email!,
                          onSuccess: _onTransactionAdded,
                        ),
                      const SizedBox(height: 16),
                      _loading
                          ? const CircularProgressIndicator()
                          : _error != null
                          ? Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          )
                          : _transactions.isEmpty
                          ? const Text(
                            "",
                            style: TextStyle(color: Color(0xFF7CFC00)),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _transactions.length,
                            itemBuilder:
                                (_, i) => Card(
                                  color: Colors.black,
                                  child: ListTile(
                                    title: Text(
                                      "₹ ${_transactions[i]['amount']}",
                                      style: const TextStyle(
                                        color: Color(0xFF7CFC00),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _transactions[i]['notes'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _transactions[i]['date'] != null
                                              ? _transactions[i]['date']
                                                  .toString()
                                                  .substring(0, 10)
                                              : '',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'clear') {
                                              _clearTransaction(
                                                _transactions[i]['_id'],
                                                _transactions[i]['amount'],
                                              );
                                            } else if (value == 'partial') {
                                              _showPartialClearDialog(
                                                transactionId:
                                                    _transactions[i]['_id'],
                                                currentAmount:
                                                    _transactions[i]['amount'],
                                                currentNote:
                                                    _transactions[i]['notes'],
                                              );
                                            }
                                          },
                                          itemBuilder:
                                              (context) => [
                                                const PopupMenuItem(
                                                  value: 'clear',
                                                  child: Text('Clear'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'partial',
                                                  child: Text('Partial Clear'),
                                                ),
                                              ],
                                          icon: const Icon(
                                            Icons.more_vert,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ),
                    ],
                  ),
                ),
              ),
    );
  }
}
