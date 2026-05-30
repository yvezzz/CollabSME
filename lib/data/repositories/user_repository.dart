import '../../core/network/api_client.dart';
import '../../utils/safe_parser.dart';
import '../models/user_model.dart';

class UserRepository {
  Future<List<UserModel>> getCompanyUsers() async {
    final response = await ApiClient.get('auth/users/');
    if (response.statusCode == 200) {
      final decoded = SafeParser.safeDecodeList(response.body);
      if (decoded == null) return [];
      return decoded.whereType<Map<String, dynamic>>().map((json) => UserModel.fromJson(json)).toList();
    }
    throw Exception("Erreur lors du chargement des utilisateurs (${response.statusCode})");
  }
}
