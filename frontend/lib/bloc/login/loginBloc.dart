import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../user_session.dart';
import 'loginEvent.dart';
import 'loginState.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  static const String _baseUrl =
      'https://money-tracker-ofsn.onrender.com'; // change to your IP on device

  LoginBloc() : super(const LoginState()) {
    on<LoginEmailChanged>(
      (e, emit) => emit(state.copyWith(email: e.email, error: null)),
    );
    on<LoginPasswordChanged>(
      (e, emit) => emit(state.copyWith(password: e.password, error: null)),
    );
    on<LoginSubmitted>(_onSubmit);
  }

  Future<void> _onSubmit(LoginSubmitted event, Emitter<LoginState> emit) async {
    if (state.email.isEmpty || state.password.isEmpty) {
      emit(state.copyWith(error: 'Email & password required'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': state.email.trim(),
          'password': state.password,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final user = data['user'];
        final email = user['email'];
        final name = user['name'];
        final token = data['token'];

        // Save in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setString('name', name);
        await prefs.setString('token', token);

        // Save in UserSession singleton
        final session = UserSession();
        session.email = email;
        session.name = name;
        session.token = token;

        emit(state.copyWith(isLoading: false, success: true));
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            error: data['message'] ?? 'Login failed',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Network error: $e'));
    }
  }
}
