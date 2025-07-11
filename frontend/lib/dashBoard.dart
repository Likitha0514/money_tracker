import 'dart:convert';
import 'package:MoneyTracker/user_session.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _baseUrl = 'http://localhost:5000'; // change to your IP
  bool _loading = true;
  String? _error;
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final token = prefs.getString('token');

    if (email != null && token != null) {
      UserSession().email = email;
      UserSession().token = token;

      // 👇 ADD THIS
      await _fetchBalance();

      await _fetchUser(email, token);
    } else {
      _redirectToLogin();
    }
  }

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
        _balance = (data['balance'] ?? 0).toDouble();      });
    }
  }

  Future<void> _fetchUser(String email, String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/users/by-email/$email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        UserSession().name = data['name'];
        setState(() => _loading = false);
      } else {
        _error = data['message'] ?? 'Failed to fetch user';
        _loading = false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _loading = false;
    }
    setState(() {});
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    UserSession().clear();
    _redirectToLogin();
  }

  Widget _tile(String label, IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: const Color(0xFF7CFC00)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF7CFC00),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final buttons = [
      {
        'label': 'Amount Lent',
        'icon': Icons.attach_money,
        'route': '/amount-lent',
      },
      {
        'label': 'Amount In',
        'icon': Icons.account_balance_wallet,
        'route': '/amount-in',
      },
      {'label': 'Amount Out', 'icon': Icons.money_off, 'route': '/amount-out'},
      {
        'label': 'Monthly Analysis',
        'icon': Icons.pie_chart,
        'route': '/monthly-analysis',
      },
      {
        'label': 'Weekly Analysis',
        'icon': Icons.bar_chart,
        'route': '/weekly-analysis',
      },
      {
        'label': 'Transactions',
        'icon': Icons.receipt_long,
        'route': '/transactions',
      },
      {'label': 'EMI Dues', 'icon': Icons.payments, 'route': '/emi-dues'},
      {
        'label': 'Track Spend',
        'icon': Icons.track_changes,
        'route': '/track-spend',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Center(
          child: Text('Money Tracker', style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.black54,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hello, ${UserSession().name ?? 'User'}!',
                          style: const TextStyle(
                            color: Color(0xFF7CFC00),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          "Balance: ₹$_balance",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Card(
                        color: const Color(0xFF121212),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final cols = constraints.maxWidth < 600 ? 2 : 4;
                              final rows = (buttons.length / cols).ceil();
                              const spacing = 12.0;
                              final cellW =
                                  (constraints.maxWidth -
                                      spacing * (cols - 1)) /
                                  cols;
                              final cellH =
                                  (constraints.maxHeight -
                                      spacing * (rows - 1)) /
                                  rows;
                              final aspectRatio = cellW / cellH;

                              return GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: buttons.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      crossAxisSpacing: spacing,
                                      mainAxisSpacing: spacing,
                                      childAspectRatio: aspectRatio,
                                    ),
                                itemBuilder:
                                    (_, i) => _tile(
                                      buttons[i]['label'] as String,
                                      buttons[i]['icon'] as IconData,
                                          () async {
                                        final result = await Navigator.pushNamed(
                                          context,
                                          buttons[i]['route'] as String,
                                        );
                                        if (result == true) {
                                          await _fetchBalance(); // 👈 refresh balance when child page returns true
                                        }
                                      },

                                    ),
                              );
                            },
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
