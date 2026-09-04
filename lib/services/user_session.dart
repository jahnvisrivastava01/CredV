class UserSession {
  UserSession._();

  static final UserSession instance = UserSession._();

  int? userId;
  String? name;
  String? email;

  bool get isLoggedIn => userId != null;

  void login({
    required int id,
    required String userName,
    required String userEmail,
  }) {
    userId = id;
    name = userName;
    email = userEmail;
  }

  void logout() {
    userId = null;
    name = null;
    email = null;
  }
}