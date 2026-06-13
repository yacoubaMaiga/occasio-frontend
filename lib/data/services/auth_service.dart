import 'package:dio/dio.dart';
import 'package:occasio/core/api/api_client.dart';
import 'package:occasio/core/constants/api_constants.dart';
import 'package:occasio/data/models/user_model.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.registerEndpoint,
        data: userData,
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      return e.response?.data['message'] ?? 'Une erreur est survenue';
    }
    return 'Problème de connexion au serveur';
  }
}
