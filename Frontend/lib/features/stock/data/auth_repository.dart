import 'api_base.dart';

class AuthRepository {
  Future<Map<String, dynamic>> register(String userName, String email, String password, bool twoFa) async {
    return await apiPost('/api/auth/register', {'userName': userName, 'email': email, 'password': password, 'twoFactorEnabled': twoFa});
  }
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await apiPost('/api/auth/login', {'email': email, 'password': password});
  }
  Future<Map<String, dynamic>> verifyTwoFactor(String challengeId, String code) async {
    return await apiPost('/api/auth/2fa/verify', {'challengeId': challengeId, 'code': code});
  }
  Future<void> resendTwoFactor(String challengeId) async {
    await apiPost('/api/auth/2fa/resend', {'challengeId': challengeId});
  }
}
