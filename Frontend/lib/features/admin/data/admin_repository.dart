import '../../stock/data/api_base.dart';

class AdminRepository {
  Future<Map<String, dynamic>> fetchDashboard() async => await apiGet('/api/admin/dashboard');
  Future<List<dynamic>> fetchUsers() async => await apiGet('/api/admin/users');
  Future<void> updateUserRole(int id, String role) async => await apiPut('/api/admin/users/$id/role', {'role': role});
  Future<List<dynamic>> fetchStocks() async => await apiGet('/api/admin/stocks');
  Future<List<dynamic>> fetchCompanyProfiles() async => await apiGet('/api/admin/company-profiles');
  Future<Map<String, dynamic>> fetchCompanyProfile(String code) async => await apiGet('/api/admin/company-profiles/$code');
  Future<void> saveCompanyProfile(String code, Map<String, dynamic> data) async => await apiPut('/api/admin/company-profiles/$code', data);
}
