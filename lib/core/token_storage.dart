import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _rolesKey = 'user_roles';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // --- Rôles (nécessaires pour la redirection intelligente au démarrage) ---

  static Future<void> saveRoles(List<String> roles) async {
    await _storage.write(key: _rolesKey, value: roles.join(','));
  }

  static Future<List<String>> getRoles() async {
    final raw = await _storage.read(key: _rolesKey);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',');
  }

  static Future<bool> isAdmin() async {
    final roles = await getRoles();
    return roles.contains('ROLE_ADMIN');
  }

  // --- Nettoyage centralisé (utilisé par AuthService.logout()) ---

  static Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _rolesKey);
  }
}