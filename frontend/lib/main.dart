import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/login/loginBloc.dart';
import 'bloc/login/loginEvent.dart';
import 'bloc/login/loginState.dart';
import 'dashBoard.dart';
import 'forgot_password.dart';
import 'grid_buttons/amount_in.dart';
import 'grid_buttons/amount_lent.dart';
import 'grid_buttons/amount_out.dart';
import 'grid_buttons/emi_dues.dart';
import 'grid_buttons/monthly_analysis.dart';
import 'grid_buttons/track_spend.dart';
import 'grid_buttons/transaction.dart';
import 'grid_buttons/weekly_analysis.dart';
import 'register.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: const Color(0xFF121212),
      title: 'Money Tracker',
      debugShowCheckedModeBanner: false,
      home: const InitialScreen(), // <- New wrapper screen
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/dashboard': (_) => const DashboardPage(),
        '/amount-lent': (_) => const AmountLentPage(),
        '/amount-in': (_) => const AmountInPage(),
        '/amount-out': (_) => const AmountOutPage(),
        '/monthly-analysis': (_) => const MonthlyAnalysisPage(),
        '/weekly-analysis': (_) => const WeeklyAnalysisPage(),
        '/transactions': (_) => const TransactionPage(),
        '/emi-dues': (_) => const EmiDuesPage(),
        '/track-spend': (_) => const TrackSpendPage(),
        '/forgot-password': (_) => const ForgotPasswordPage(),
      },
    );
  }
}

/// A startup screen that checks login status
class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final token = prefs.getString('token');
    return email != null && token != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final loggedIn = snapshot.data ?? false;

        // Navigate directly once we know the state
        Future.microtask(() {
          Navigator.of(context).pushReplacementNamed(
            loggedIn ? '/dashboard' : '/login',
          );
        });

        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: const _LoginForm(),
    );
  }
}

/* ───────────────────────── private form widget ──────────────────────── */
class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (prev, curr) => prev.success != curr.success,
      listener: (context, state) {
        if (state.success) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/dashboard', (_) => false);
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Color(0xFF121212),

            appBar: AppBar(
              title: const Text('Welcome to Money Tracker',
                  style: TextStyle(color: Color(0xFF7CFC00))),
              backgroundColor: Color(0xFF121212),

              centerTitle: true,
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CircleAvatar(backgroundImage: AssetImage('assets/logo.jpeg'),maxRadius: 80,),
                      const SizedBox(height: 20),

                      const Text('LOGIN',
                          style:
                          TextStyle(color: Color(0xFF7CFC00), fontSize: 30)),
                      const SizedBox(height: 24),
                      _LoginCard(state: state),
                      const SizedBox(height: 20),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(state.error!,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              context
                                  .read<LoginBloc>()
                                  .add(const LoginSubmitted());
                            }
                          },
                          child: const Text('Login',
                              style: TextStyle(color: Color(0xFF7CFC00),fontSize: 20)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account,",
                              style: TextStyle(fontSize: 18,color: Color(0xFF7CFC00))),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/register'),
                            child: const Text('Register',
                                style: TextStyle(
                                    color: Color(0xFF7CFC00), fontSize: 18)),
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

/* ────────────────── split out the card for readability ───────────────── */
class _LoginCard extends StatefulWidget {
  final LoginState state;
  const _LoginCard({required this.state});

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /* Email */
            TextFormField(
              initialValue: widget.state.email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Color(0xFF7CFC00)),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7CFC00))),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7CFC00))),
              ),
              style: const TextStyle(color: Color(0xFF7CFC00)),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email required';
                final ok = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v);
                return ok ? null : 'Enter a valid email';
              },
              onChanged: (v) =>
                  context.read<LoginBloc>().add(LoginEmailChanged(v)),
            ),
            const SizedBox(height: 20),

            /* Password */
            TextFormField(
              initialValue: widget.state.password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Color(0xFF7CFC00)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: Color(0xFF7CFC00),
                  ),
                  onPressed: () {
                    setState(() => _obscure = !_obscure);
                  },
                ),
                enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7CFC00))),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7CFC00))),
              ),
              style: const TextStyle(color: Color(0xFF7CFC00)),
              validator: (v) =>
              v == null || v.isEmpty ? 'Password required' : null,
              onChanged: (v) =>
                  context.read<LoginBloc>().add(LoginPasswordChanged(v)),
            ),

            /* Forgot Password Button */
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/forgot-password');
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Color(0xFF7CFC00)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
