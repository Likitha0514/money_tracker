import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddTransactionCard extends StatefulWidget {
  final String type;   // lend | in | out
  final String email;
  final void Function()? onSuccess; // ✅ optional callback after successful add

  const AddTransactionCard({
    super.key,
    required this.type,
    required this.email,
    this.onSuccess,
  });

  @override
  State<AddTransactionCard> createState() => _AddTransactionCardState();
}

class _AddTransactionCardState extends State<AddTransactionCard> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDate;

  bool _loading = false;
  String? _message;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      setState(() => _message = "Please select a date.");
      return;
    }

    final url = Uri.parse("http://localhost:5000/api/transactions/add");

    final data = {
      "email": widget.email,
      "type": widget.type,
      "amount": double.parse(_amountController.text),
      "notes": _noteController.text.trim(), // ✅ match model
      "date": _selectedDate!.toIso8601String(),
    };

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (res.statusCode == 201) {
        setState(() {
          _message = "Transaction added successfully!";
          _amountController.clear();
          _noteController.clear();
          _selectedDate = null;
        });

        widget.onSuccess?.call(); // ✅ notify parent
      } else {
        final body = jsonDecode(res.body);
        setState(() => _message = body['message'] ?? 'Failed to add transaction');
      }
    } catch (e) {
      setState(() => _message = 'Network error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Add ${widget.type.toUpperCase()}",
                  style: const TextStyle(
                    color: Color(0xFF7CFC00),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
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
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    style: const TextStyle(color: Color(0xFF7CFC00)),
                    decoration: InputDecoration(
                      labelText: _selectedDate == null
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
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: Color(0xFF7CFC00)),
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  labelStyle: TextStyle(color: Color(0xFF7CFC00)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7CFC00)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7CFC00)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.contains("success") ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7CFC00),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Color(0xFF7CFC00))
                      : const Text("Add", style: TextStyle(color: Colors.black,fontSize: 22)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
