import 'dart:convert';
import 'package:moneytracker/pdf/pdf_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';

// Import conditional helper

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  String? _email;
  bool _loading = true;
  String? _error;
  DateTime? _startDate;
  DateTime? _endDate;

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
      await _fetchTransactions(email);
      _filterTransactions();
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
          'https://money-tracker-ofsn.onrender.com/api/transactions/all?email=$email',
        ),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        data.sort((a, b) => b['date'].compareTo(a['date']));
        setState(() {
          _allTransactions = data.cast<Map<String, dynamic>>();
          _filteredTransactions = List.from(_allTransactions);
          _loading = false;
        });
      } else {
        setState(() => _error = 'Failed to load transactions');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
  }

  void _filterTransactions() {
    setState(() {
      _filteredTransactions = _allTransactions.where((txn) {
        final date = DateTime.parse(txn['date']);
        final afterStart = _startDate == null ||
            date.isAfter(_startDate!.subtract(const Duration(days: 1)));
        final beforeEnd = _endDate == null ||
            date.isBefore(_endDate!.add(const Duration(days: 1)));
        return afterStart && beforeEnd;
      }).toList();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _filterTransactions();
    }
  }

  Future<pw.Document> _buildPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Transaction Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            "Date Range: ${_startDate?.toString().substring(0, 10) ?? ''}"
            " to ${_endDate?.toString().substring(0, 10) ?? ''}",
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Date', 'Type', 'Amount', 'Note'],
            data: _filteredTransactions.map((txn) {
              return [
                txn['date']?.toString().substring(0, 10) ?? '',
                txn['type'],
                "₹ ${txn['amount']}",
                txn['notes'] ?? '',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf;
  }

  Future<void> _exportToPdf() async {
    final pdf = await _buildPdf();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export Options'),
        content: const Text(
          'Would you like to save the PDF or preview it before printing?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                if (kIsWeb) {
                  await savePdfFileWeb(pdf);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF download started')),
                  );
                } else {
                  final savedPath = await savePdfFileMobile(pdf);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF saved at $savedPath')),
                  );
                  await OpenFile.open(savedPath);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save PDF: $e')),
                );
              }
            },
            child: const Text('Save as PDF'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Printing.layoutPdf(onLayout: (format) => pdf.save());
            },
            child: const Text('Print Preview'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransactionsByDateRange() async {
    if (_email == null || _startDate == null || _endDate == null) return;

    final uri = Uri.parse(
      'https://money-tracker-ofsn.onrender.com/api/transactions/delete-range',
    );
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _email,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
      }),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Transactions deleted")));
      setState(() {
        _startDate = null;
        _endDate = null;
      });
      await _fetchTransactions(_email!);
      _filterTransactions(); // show all after reset
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: ${res.body}")));
    }
  }

  void _confirmDelete() {
    final countToDelete = _filteredTransactions.length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text(
          "Are you sure you want to delete $countToDelete transactions from "
          "${_startDate?.toString().substring(0, 10) ?? 'start'} to "
          "${_endDate?.toString().substring(0, 10) ?? 'end'}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTransactionsByDateRange();
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFF7CFC00)),
        title: const Text(
          "Transactions",
          style: TextStyle(color: Color(0xFF7CFC00)),
        ),
        backgroundColor: Colors.black54,
      ),
      body: _email == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _pickDateRange,
                          child: Text(
                            (_startDate != null && _endDate != null)
                                ? "Filtered: ${DateFormat('dd MMM yyyy').format(_startDate!)} → ${DateFormat('dd MMM yyyy').format(_endDate!)}"
                                : "Filter by Date Range",
                            overflow:
                                TextOverflow.ellipsis, // Optional for safety
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _filteredTransactions.isEmpty
                                ? null
                                : _exportToPdf,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Export'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: (_startDate == null ||
                                    _endDate == null ||
                                    _filteredTransactions.isEmpty)
                                ? null
                                : _confirmDelete,
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey,
                              disabledForegroundColor: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _loading
                      ? const CircularProgressIndicator()
                      : _error != null
                          ? Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            )
                          : Expanded(
                              child: ListView.builder(
                                itemCount: _filteredTransactions.length,
                                itemBuilder: (_, i) => Card(
                                  color: Colors.black,
                                  child: ListTile(
                                    title: Text(
                                      "\u20B9 ${_filteredTransactions[i]['amount']}",
                                      style: const TextStyle(
                                        color: Color(0xFF7CFC00),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "${_filteredTransactions[i]['type'].toString().toUpperCase()} - ${_filteredTransactions[i]['notes'] ?? 'No note'}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    trailing: Text(
                                      _filteredTransactions[i]['date']
                                              ?.toString()
                                              ?.substring(0, 10) ??
                                          '',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                ],
              ),
            ),
    );
  }
}
