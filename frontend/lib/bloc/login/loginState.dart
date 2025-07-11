class LoginState {
  final String email;
  final String password;
  final bool isLoading;
  final String? error;
  final bool success;

  const LoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  LoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is LoginState &&
              runtimeType == other.runtimeType &&
              email == other.email &&
              password == other.password &&
              isLoading == other.isLoading &&
              error == other.error &&
              success == other.success;

  @override
  int get hashCode =>
      email.hashCode ^
      password.hashCode ^
      isLoading.hashCode ^
      error.hashCode ^
      success.hashCode;
}
