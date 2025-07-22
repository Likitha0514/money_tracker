import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class WeeklyAnalysisPage extends StatefulWidget {
  const WeeklyAnalysisPage({Key? key}) : super(key: key);

  @override
  State<WeeklyAnalysisPage> createState() => _WeeklyAnalysisPageState();
}

class _WeeklyAnalysisPageState extends State<WeeklyAnalysisPage> {
  DateTime? _selectedDate;
  bool _loading = false;
  String? _error;
  double _lend = 0, _inflow = 0, _outflow = 0;
  List<double> _lendWeek = List.filled(7, 0);
  List<double> _inflowWeek = List.filled(7, 0);
  List<double> _outflowWeek = List.filled(7, 0);

  Future<void> _fetchSummary() async {
    if (_selectedDate == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final start = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final end = DateFormat(
      'yyyy-MM-dd',
    ).format(_selectedDate!.add(Duration(days: 6)));
    final uri = Uri.parse(
      'http://localhost:5000/api/transactions/weekly-summary'
      '?email=$email&start=$start&end=$end',
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('Server ${res.statusCode}');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _lend = (data['lend'] ?? 0).toDouble();
        _inflow = (data['in'] ?? 0).toDouble();
        _outflow = (data['out'] ?? 0).toDouble();
        // Simulate daily breakdown for now
        for (int i = 0; i < 7; i++) {
          _lendWeek[i] = _lend / 7;
          _inflowWeek[i] = _inflow / 7;
          _outflowWeek[i] = _outflow / 7;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color(0xFF7CFC00)),
        title: const Text(
          'Weekly Analysis',
          style: TextStyle(color: Color(0xFF7CFC00)),
        ),
        backgroundColor: Colors.black54,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Color(0xFF7CFC00),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(DateTime.now().year - 5),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                                _fetchSummary();
                              }
                            },
                            child: Text(
                              _selectedDate == null
                                  ? 'Select Start Date'
                                  : 'Week: ${DateFormat('dd MMM').format(_selectedDate!)} - ${DateFormat('dd MMM').format(_selectedDate!.add(Duration(days: 6)))}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_loading)
                        const Center(child: CircularProgressIndicator()),
                      if (!_loading && _error != null)
                        Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (!_loading &&
                          _error == null &&
                          (_lend + _inflow + _outflow) == 0)
                        const Center(
                          child: Text(
                            'No transactions',
                            style: TextStyle(color: Color(0xFF7CFC00)),
                          ),
                        ),
                      if (!_loading &&
                          _error == null &&
                          (_lend + _inflow + _outflow) > 0)
                        Column(
                          children: [
                            Card(
                              color: Colors.black,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: _InfoTile(
                                  label: 'Total Income',
                                  value: _inflow,
                                  color: Colors.purpleAccent,
                                  icon: Icons.arrow_downward,
                                  labelColor: Color(0xFF81D4FA),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.black,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: _InfoTile(
                                  label: 'Total Spent',
                                  value: _outflow,
                                  color: Colors.purpleAccent,
                                  icon: Icons.arrow_upward,
                                  labelColor: Color(0xFF81D4FA),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.black,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: _InfoTile(
                                  label: 'Amount Lent',
                                  value: _lend,
                                  color: Colors.purpleAccent,
                                  icon: Icons.handshake,
                                  labelColor: Color(0xFF81D4FA),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final Color labelColor;
  const _InfoTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.labelColor = const Color(0xFF81D4FA),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: labelColor, fontWeight: FontWeight.bold),
        ),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Color(0xFF7CFC00),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendDot({required this.color, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Color(0xFF7CFC00))),
      ],
    );
  }
}
