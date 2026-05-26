import 'api_base.dart';

class UserRepository {
  Future<Map<String, dynamic>> getProfile() async => await apiGet('/api/users/me');
  Future<Map<String, dynamic>> updateProfile(String userName) async => await apiPut('/api/users/me', {'userName': userName});
  Future<void> updatePassword(String current, String next) async => await apiPut('/api/users/me/password', {'currentPassword': current, 'newPassword': next});
  Future<Map<String, dynamic>> setTwoFactor(bool enabled) async => await apiPut('/api/users/me/2fa', {'twoFactorEnabled': enabled});
}
