import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ---- helpers --------------------------------------------------------------

InputDecoration _darkUnderline(
    String label, {
      Widget? suffix,
    }) =>
    InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF7CFC00)),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF7CFC00)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF7CFC00)),
      ),
      suffixIcon: suffix,
    );

final _emailRegex =
RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$', caseSensitive: false);

/// ---- Register Page --------------------------------------------------------

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePwd = true;
  bool _isLoading = false;

  final String apiUrl = "http://localhost:5000/api/users/register";
  // ⬆ Replace with your server URL (use IP instead of localhost on mobile)

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _nameCtrl.text.trim(),
          "email": _emailCtrl.text.trim(),
          "password": _passwordCtrl.text.trim(),
        }),
      );

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful"))
        );
        
        _formKey.currentState?.reset();
        Navigator.pop(context);
      } else {
        final body = jsonDecode(res.body);
        final msg = body['message'] ?? "Registration failed";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFF7CFC00)),
        title: const Center(
          child: Text('Register', style: TextStyle(color: Color(0xFF7CFC00))),
        ),
        backgroundColor: Color(0xFF121212),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            color: Colors.black12,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _darkUnderline('Name'),
                      style: const TextStyle(color: Color(0xFF7CFC00)),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: _darkUnderline('Email'),
                      style: const TextStyle(color: Color(0xFF7CFC00)),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter an e‑mail address';
                        }
                        if (!_emailRegex.hasMatch(v.trim())) {
                          return 'Invalid e‑mail format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: _darkUnderline(
                        'Password',
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePwd
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Color(0xFF7CFC00),
                          ),
                          onPressed: () =>
                              setState(() => _obscurePwd = !_obscurePwd),
                        ),
                      ),
                      obscureText: _obscurePwd,
                      style: const TextStyle(color: Color(0xFF7CFC00)),
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Min. 8 characters'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        final ok =
                            _formKey.currentState?.validate() ?? false;
                        if (ok) _registerUser();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black12,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                        color: Color(0xFF7CFC00),
                      )
                          : const Text(
                        'Register',
                        style:
                        TextStyle(color: Color(0xFF7CFC00), fontSize: 18),
                      ),
                    ),
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
