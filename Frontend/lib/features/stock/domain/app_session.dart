import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  static const _token = 'token';
  static const _userId = 'userId';
  static const _name = 'name';
  static const _email = 'email';
  static const _role = 'role';

  static String? token;
  static int? userId;
  static String? name;
  static String? email;
  static String? role;

  static bool get isLoggedIn => token != null && token!.isNotEmpty;
  static bool get isAdmin => role == 'ADMIN';

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString(_token);
    userId = p.getInt(_userId);
    name = p.getString(_name);
    email = p.getString(_email);
    role = p.getString(_role);
  }

  static Future<void> save({
    required String token,
    required int userId,
    required String name,
    required String email,
    required String role,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_token, token);
    await p.setInt(_userId, userId);
    await p.setString(_name, name);
    await p.setString(_email, email);
    await p.setString(_role, role);
    AppSession.token = token;
    AppSession.userId = userId;
    AppSession.name = name;
    AppSession.email = email;
    AppSession.role = role;
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_token);
    await p.remove(_userId);
    await p.remove(_name);
    await p.remove(_email);
    await p.remove(_role);
    token = null; userId = null; name = null; email = null; role = null;
  }
}
