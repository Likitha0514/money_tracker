import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MonthlyAnalysisPage extends StatefulWidget {
  const MonthlyAnalysisPage({Key? key}) : super(key: key);

  @override
  State<MonthlyAnalysisPage> createState() => _MonthlyAnalysisPageState();
}

class _MonthlyAnalysisPageState extends State<MonthlyAnalysisPage> {
  final List<int> _years = List.generate(5, (i) => DateTime.now().year - i);
  final List<String> _months = const [
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12',
  ];

  String? _selMonth;
  int? _selYear;
  bool _loading = false;
  String? _error;
  double _lend = 0, _inflow = 0, _outflow = 0;

  Future<void> _fetchSummary() async {
    if (_selYear == null || _selMonth == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final uri = Uri.parse(
      'https://money-tracker-ofsn.onrender.com/api/transactions/monthly-summary'
      '?email=$email&year=$_selYear&month=$_selMonth',
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('Server ${res.statusCode}');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _lend = (data['lend'] ?? 0).toDouble();
        _inflow = (data['in'] ?? 0).toDouble();
        _outflow = (data['out'] ?? 0).toDouble();
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
    final total = _lend + _inflow + _outflow;
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color(0xFF7CFC00)),
        title: const Text(
          'Monthly Analysis',
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
                      // Month/Year selectors
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DropdownButton<String>(
                            dropdownColor: Colors.black54,
                            hint: const Text(
                              'Month',
                              style: TextStyle(color: Color(0xFF7CFC00)),
                            ),
                            value: _selMonth,
                            items:
                                _months.map((m) {
                                  return DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      m,
                                      style: const TextStyle(
                                        color: Color(0xFF7CFC00),
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              setState(() => _selMonth = val);
                              _fetchSummary();
                            },
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<int>(
                            dropdownColor: Colors.black54,
                            hint: const Text(
                              'Year',
                              style: TextStyle(color: Color(0xFF7CFC00)),
                            ),
                            value: _selYear,
                            items:
                                _years.map((y) {
                                  return DropdownMenuItem(
                                    value: y,
                                    child: Text(
                                      '$y',
                                      style: const TextStyle(
                                        color: Color(0xFF7CFC00),
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              setState(() => _selYear = val);
                              _fetchSummary();
                            },
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
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: _lend,
                                      title:
                                          'Lent\n₹${_lend.toStringAsFixed(0)}',
                                      color: const Color.fromARGB(
                                        255,
                                        243,
                                        143,
                                        136,
                                      ),
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                        color: Color(0xFF7CFC00),
                                        fontSize: 12,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: _inflow,
                                      title:
                                          'In\n₹${_inflow.toStringAsFixed(0)}',
                                      color: Color(0xFF7A5FFF),
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        color: Color(0xFF7CFC00),
                                        fontSize: 12,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: _outflow,
                                      title:
                                          'Out\n₹${_outflow.toStringAsFixed(0)}',
                                      color: Color.fromARGB(255, 110, 218, 245),
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        color: Color(0xFF7CFC00),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 50,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Spend vs Income',
                              style: TextStyle(
                                color: Color(0xFF7CFC00).withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value:
                                  _inflow > 0
                                      ? (_outflow / _inflow).clamp(0.0, 1.0)
                                      : 0,
                              backgroundColor: Color(0xFF7A5FFF),

                              valueColor: AlwaysStoppedAnimation(
                                Color.fromARGB(255, 110, 218, 245),
                              ),
                              minHeight: 12,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You spent ₹${_outflow.toStringAsFixed(0)} of ₹${_inflow.toStringAsFixed(0)}',
                              style: const TextStyle(color: Color(0xFF7CFC00)),
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

/// little badge for slice labels
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

/// small colored dot + text
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
