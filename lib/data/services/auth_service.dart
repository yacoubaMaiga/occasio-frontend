import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- CONNEXION ---
  Future<UserModel> login(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) throw Exception("Erreur d'authentification");

      // Récupération des données du profil dans ta table public.users
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(userData);
    } on AuthException catch (e) {
      throw Exception("Email ou mot de passe invalide.");
    } catch (e) {
      throw Exception("Erreur système: $e");
    }
  }

  // --- INSCRIPTION ---
// --- INSCRIPTION ---
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber ?? '',
        },
      );

      if (response.session == null) {
        throw Exception("Le compte a été créé, mais la session n'a pas pu démarrer. Essayez de vous connecter manuellement via l'écran de connexion.");
      }
      
    } on AuthException catch (e) {
      // On affiche le message EXACT renvoyé par Supabase
      throw Exception("Supabase Auth : ${e.message}");
    } catch (e) {
      // On affiche l'erreur système EXACTE (ex: Timeout, TypeError...)
      throw Exception("Erreur système : $e"); 
    }
  }
  // --- DÉCONNEXION ---
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}