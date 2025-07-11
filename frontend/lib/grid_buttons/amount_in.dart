import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'add_transaction.dart';

class AmountInPage extends StatefulWidget {
  const AmountInPage({super.key});

  @override
  State<AmountInPage> createState() => _AmountInPageState();
}

class _AmountInPageState extends State<AmountInPage> {
  List<Map<String, dynamic>> _transactions = [];
  String? _email;
  bool _loading = true;
  String? _error;
  bool _showAddCard = false;
  double _balance = 0;



  Future<void> _fetchBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    if (email == null) return;

    final res = await http.get(Uri.parse('http://localhost:5000/api/transactions/balance?email=$email'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _balance = (data['balance'] ?? 0).toDouble();      });
    }
  }

  Future<void> _fetchTransactions(String email) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('http://localhost:5000/api/transactions?type=in&email=$email'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _transactions = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() => _error = 'Failed to load transactions');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
  }


  @override
  @override
  void initState() {
    super.initState();
    _loadEmailAndFetch();
  }

  Future<void> _loadEmailAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    if (email != null) {
      setState(() => _email = email);
      await Future.wait([
        _fetchTransactions(email),
        _fetchBalance(),
      ]);
    } else {
      setState(() {
        _error = 'Email not found';
        _loading = false;
      });
    }
  }

  void _onTransactionAdded() async {
    if (_email != null) {
      await _fetchTransactions(_email!);
      await _fetchBalance();
      setState(() => _showAddCard = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
      Navigator.pop(context, true); // <- this sends true to previous screen
      return false; // don't pop automatically
    },
    child: Scaffold(
      backgroundColor: const Color(0xFF121212),

      appBar: AppBar(
    title: const Text("Amount In", style: TextStyle(color: Color(0xFF7CFC00))),
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
      body: _email == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [Text(
            "Balance: ₹$_balance",
            style: const TextStyle(
              color: Color(0xFF7CFC00),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
            const SizedBox(height: 8),

            if (_showAddCard)
              AddTransactionCard(
                type: 'in',
                email: _email!,
                onSuccess: _onTransactionAdded,
              ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.red))
                : Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (_, i) => Card(
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
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Text(
                      _transactions[i]['date']?.toString()?.substring(0, 10) ?? '',
                      style: const TextStyle(color: Colors.white54),
                    ),
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
