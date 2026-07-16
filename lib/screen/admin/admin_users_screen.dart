import 'package:flutter/material.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/service/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _adminService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Fonction pour suspendre ou réactiver un utilisateur
  Future<void> _toggleStatus(String userId, bool currentStatus) async {
    final newStatus = !currentStatus; // Inverse le statut actuel
    
    try {
      await _adminService.toggleUserStatus(userId, newStatus);
      
      if (mounted) {
        // Mise à jour locale pour éviter de recharger toute la liste
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['enabled'] = newStatus;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Compte réactivé avec succès.' : 'Compte suspendu.'),
            backgroundColor: newStatus ? AppColors.menthe : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.nuit,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.blanc),
        title: const Text(
          'Gestion des Utilisateurs',
          style: TextStyle(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                
                // Récupération sécurisée des données
                final isEnabled = user['enabled'] ?? true;
                final role = user['role'] ?? 'MEMBRE';
                final username = user['username'] ?? 'Inconnu';
                final email = user['email'] ?? '';
                final photo = user['photo_profil'];

                return Card(
                  color: AppColors.blanc,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  shadowColor: AppColors.nuit.withValues(alpha: 0.05),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.sable,
                      backgroundImage: photo != null ? NetworkImage(photo) : null,
                      child: photo == null 
                          ? Text(
                              username.isNotEmpty ? username[0].toUpperCase() : '?', 
                              style: const TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.bold, fontSize: 18)
                            )
                          : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            username,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Badge si l'utilisateur est ADMIN
                        if (role == 'ADMIN')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.nuit,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('ADMIN', style: TextStyle(color: AppColors.blanc, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(email, style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.6), fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          isEnabled ? 'Compte actif' : 'Compte suspendu',
                          style: TextStyle(
                            color: isEnabled ? AppColors.menthe : Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    // Switch d'activation/désactivation (on empêche l'admin de se suspendre lui-même)
                    trailing: role == 'ADMIN' 
                      ? const SizedBox(width: 48) 
                      : Switch(
                          value: isEnabled,
                          activeThumbColor: AppColors.menthe,
                          inactiveThumbColor: Colors.redAccent,
                          inactiveTrackColor: Colors.redAccent.withValues(alpha: 0.3),
                          onChanged: (val) => _toggleStatus(user['id'], isEnabled),
                        ),
                  ),
                );
              },
            ),
    );
  }
}