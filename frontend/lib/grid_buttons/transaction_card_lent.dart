import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';

class AddTransactionCard1 extends StatefulWidget {
  final String type;
  final String email;
  final VoidCallback onSuccess;

  const AddTransactionCard1({
    super.key,
    required this.type,
    required this.email,
    required this.onSuccess,
  });

  @override
  State<AddTransactionCard1> createState() => _AddTransactionCardState();
}

class _AddTransactionCardState extends State<AddTransactionCard1> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String _mode = 'previous'; // previous or new
  double _balance = 0;
  DateTime? _selectedDate;
  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    final res = await http.get(
      Uri.parse(
        'http://localhost:5000/api/transactions/balance?email=${widget.email}',
      ),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _balance = (data['balance'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitTransaction() async {
    final amount = double.tryParse(_amountController.text);
    final notes = _notesController.text.trim();

    // Validate amount
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
      return;
    }

    // Validate “new lend ≤ balance”
    if (_mode == 'new' && amount > _balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amount exceeds current balance (₹$_balance)')),
      );
      return;
    }

    // ** New: check & prompt date selection **
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date.')));
      return;
    }

    setState(() => _isSubmitting = true);

    final body = jsonEncode({
      'type': widget.type,
      'amount': amount,
      'notes': notes,
      'email': widget.email,
      'isPrevious': _mode == 'previous',
      'date': _selectedDate!.toIso8601String(), // include the date
    });

    try {
      final res = await http.post(
        Uri.parse('http://localhost:5000/api/transactions/add'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        widget.onSuccess();
        // clear form
        _amountController.clear();
        _notesController.clear();
        setState(() => _selectedDate = null);
      } else {
        final msg = jsonDecode(res.body)['message'] ?? res.body;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Add failed: $msg')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Is this a Previous or New Lend?",
              style: TextStyle(color: Color(0xFF7CFC00), fontSize: 16),
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'previous',
                  groupValue: _mode,
                  activeColor: const Color(0xFF7CFC00),
                  onChanged: (value) => setState(() => _mode = value!),
                ),
                Text(
                  "Previous",
                  style: TextStyle(
                    fontSize: 16, // ← increase this
                    color:
                        _mode == 'previous'
                            ? const Color(0xFF7CFC00)
                            : Colors.white70,
                  ),
                ),

                const SizedBox(width: 24),

                Radio<String>(
                  value: 'new',
                  groupValue: _mode,
                  activeColor: const Color(0xFF7CFC00),
                  onChanged: (value) => setState(() => _mode = value!),
                ),
                Text(
                  "New",
                  style: TextStyle(
                    fontSize: 16, // ← and this
                    color:
                        _mode == 'new'
                            ? const Color(0xFF7CFC00)
                            : Colors.white70,
                  ),
                ),
              ],
            ),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFF7CFC00)),
              decoration: const InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: Color(0xFF7CFC00)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7CFC00)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7CFC00)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  style: const TextStyle(color: Color(0xFF7CFC00)),
                  decoration: InputDecoration(
                    labelText:
                        _selectedDate == null
                            ? 'Select Date'
                            : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                    labelStyle: const TextStyle(color: Color(0xFF7CFC00)),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF7CFC00)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF7CFC00)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: Color(0xFF7CFC00)),
              decoration: const InputDecoration(
                labelText: 'Notes',
                labelStyle: TextStyle(color: Color(0xFF7CFC00)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7CFC00)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7CFC00)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7CFC00),
              ),
              child:
                  _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                        "Submit",
                        style: TextStyle(color: Colors.black),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
