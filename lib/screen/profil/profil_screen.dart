import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:occasio/screen/profil/edit_profil_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import ajouté
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/screen/annonce/mes_annonces_screen.dart';
import 'package:occasio/service/profil_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ProfilService _profilService = ProfilService();
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _profilData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
    try {
      final data = await _profilService.getMonProfil();
      if (mounted) {
        setState(() {
          _profilData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changerPhotoProfil() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      await _profilService.modifierPhotoProfil(image.path);
      _chargerProfil(); 
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la mise à jour de la photo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.terracotta),
        ),
      );
    }

    final p = _profilData ?? {};
    final nomComplet = '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim();
    final initiale = nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : '?';
    final photoUrl = p['photoProfil'];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.sable,
        elevation: 0,
        title: const Text(
          'Mon Compte',
          style: TextStyle(
            color: AppColors.nuit,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ── Avatar modifiable ──
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.terracotta,
                    image: photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photoUrl == null
                      ? Center(
                          child: Text(
                            initiale,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _changerPhotoProfil,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.nuit,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              nomComplet.isNotEmpty
                  ? nomComplet
                  : (p['username'] ?? 'Utilisateur'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '@${p['username'] ?? 'username'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // ── Liste des actions ──
            _buildTile(
              icon: Icons.assignment_ind_outlined,
              title: 'Modifier mes informations',
              onTap: () async {
                final aModifie = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilScreen(profilData: p),
                  ),
                );
                if (aModifie == true) _chargerProfil();
              },
            ),
            _buildTile(
              icon: Icons.storefront_outlined,
              title: 'Mes annonces',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MesAnnoncesScreen()),
              ),
            ),
            _buildTile(
              icon: Icons.logout_rounded,
              title: 'Se déconnecter',
              textColor: Colors.redAccent,
              iconColor: Colors.redAccent,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.blanc,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Déconnexion',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.nuit,
                      ),
                    ),
                    content: const Text(
                      'Êtes-vous sûr de vouloir vous déconnecter ?',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            color: AppColors.nuit.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          // 1. Déconnexion native via Supabase (Détruit la session en cache)
                          await Supabase.instance.client.auth.signOut();

                          // 2. Redirection vers le login en détruisant tout l'historique
                          if (mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/connexion',
                              (route) => false,
                            );
                          }
                        },
                        child: const Text(
                          'Me déconnecter',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: AppColors.blanc, 
        leading: Icon(icon, color: iconColor ?? AppColors.terracotta),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}