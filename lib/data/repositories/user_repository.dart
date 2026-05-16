import 'dart:convert';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';

class UserRepository {
  Future<List<UserModel>> getCompanyUsers() async {
    final response = await ApiClient.get('auth/users/');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    }
    throw Exception("Erreur lors du chargement des utilisateurs");
  }
}
