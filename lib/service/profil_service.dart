import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getMonProfil() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Non connecté');
    
    // On mappe "first_name" en "firstName" pour que ton UI n'ait pas besoin de changer
    final data = await _supabase.from('users').select().eq('id', userId).single();
    return _mapToUi(data);
  }

  Future<Map<String, dynamic>> modifierProfil({
    required String nom,
    required String prenom,
    required String telephone,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    final response = await _supabase.from('users').update({
      'last_name': nom,
      'first_name': prenom,
      'phone_number': telephone,
    }).eq('id', userId!).select().single();
    
    return _mapToUi(response);
  }

  Future<void> modifierPhotoProfil(String cheminLocalPhoto) async {
    final userId = _supabase.auth.currentUser?.id;
    final fileExt = cheminLocalPhoto.split('.').last;
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    // Upload vers le bucket "profils"
    await _supabase.storage.from('profils').upload(fileName, File(cheminLocalPhoto));
    final publicUrl = _supabase.storage.from('profils').getPublicUrl(fileName);

    await _supabase.from('users').update({'photo_profil': publicUrl}).eq('id', userId!);
  }

  Future<Map<String, dynamic>> getProfilPublic(String userId) async {
    final user = await _supabase.from('users').select().eq('id', userId).single();
    final annonces = await _supabase.from('annonces').select().eq('vendeur_id', userId).eq('statut', 'ACTIVE');
    
    final formattedUser = _mapToUi(user);
    formattedUser['annonces'] = annonces;
    return formattedUser;
  }

  // Utilitaire pour adapter les données PostgreSQL à ton écran existant
  Map<String, dynamic> _mapToUi(Map<String, dynamic> dbData) {
    return {
      'id': dbData['id'],
      'username': dbData['username'],
      'email': dbData['email'],
      'firstName': dbData['first_name'],
      'lastName': dbData['last_name'],
      'phoneNumber': dbData['phone_number'],
      'photoProfil': dbData['photo_profil'],
    };
  }
}