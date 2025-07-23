import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  bool _emailVerified = false;
  bool _isLoading = false;
  String? _error;

  final _baseUrl =
      'https://money-tracker-ofsn.onrender.com'; // Replace with your actual API

  Future<void> _verifyEmail() async {
    final email = _emailController.text.trim();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/users/check-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['exists'] == true) {
        setState(() {
          _emailVerified = true;
        });
      } else {
        setState(() {
          _error = 'Email not found in our system.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Server error. Try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    final newPass = _passController.text.trim();
    if (newPass.length < 8) {
      setState(() {
        _error = 'Password must be at least 8 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/users/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': newPass,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        Navigator.of(context).pop(); // go back to login
      } else {
        setState(() {
          _error = data['message'] ?? 'Failed to reset password';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: Color(0xFF7CFC00)),
        ),
        backgroundColor: Color(0xFF121212),
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF7CFC00)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Card(
            color: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!_emailVerified) ...[
                      const Text(
                        'Enter your email',
                        style: TextStyle(
                          fontSize: 22,
                          color: Color(0xFF7CFC00),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Color(0xFF7CFC00)),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Color(0xFF7CFC00)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF7CFC00)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF7CFC00)),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Email required';
                          final ok = RegExp(
                            r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(v);
                          return ok ? null : 'Enter a valid email';
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                          ),
                          onPressed: _isLoading ? null : _verifyEmail,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Color(0xFF7CFC00),
                                  )
                                  : const Text(
                                    'Verify',
                                    style: TextStyle(color: Color(0xFF7CFC00)),
                                  ),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Set New Password',
                        style: TextStyle(
                          fontSize: 22,
                          color: Color(0xFF7CFC00),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passController,
                        obscureText: true,
                        style: const TextStyle(color: Color(0xFF7CFC00)),
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          labelStyle: TextStyle(color: Color(0xFF7CFC00)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF7CFC00)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF7CFC00)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                          ),
                          onPressed: _isLoading ? null : _updatePassword,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Color(0xFF7CFC00),
                                  )
                                  : const Text(
                                    'Set Password',
                                    style: TextStyle(color: Color(0xFF7CFC00)),
                                  ),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
