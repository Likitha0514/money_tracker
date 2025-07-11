// user_session.dart
class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? email;
  String? token;
  String? name;

  bool get isLoggedIn => email != null && token != null;

  void clear() {
    email = null;
    token = null;
    name = null;
  }
}
