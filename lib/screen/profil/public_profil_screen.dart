import 'package:flutter/material.dart';
import 'package:occasio/theme/app_colors.dart';
import 'package:occasio/service/profil_service.dart';
import 'package:occasio/widgets/listing_card.dart';

class PublicProfilScreen extends StatefulWidget {
  final String userId;

  const PublicProfilScreen({super.key, required this.userId});

  @override
  State<PublicProfilScreen> createState() => _PublicProfilScreenState();
}

class _PublicProfilScreenState extends State<PublicProfilScreen> {
  final ProfilService _profilService = ProfilService();

  Map<String, dynamic>? _publicData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPublicProfil();
  }

  Future<void> _loadPublicProfil() async {
    try {
      final data = await _profilService.getProfilPublic(widget.userId);
      if (mounted) {
        setState(() {
          _publicData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
      );
    }

    final p = _publicData ?? {};
    final username = p['username'] ?? 'Vendeur';
    final photoUrl = p['photoProfil'];
    final listeAnnonces = p['annonces'] as List<dynamic>? ?? []; // Adapté selon la structure de ta PubliProfilResponse

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.blanc,
        elevation: 0,
        leading: const BackButton(color: AppColors.nuit),
        title: Text(username, style: const TextStyle(color: AppColors.nuit, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bandeau Profil d'en-haut
            Container(
              color: AppColors.blanc,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.sable,
                      image: photoUrl != null ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                    ),
                    child: photoUrl == null
                        ? Center(child: Text(username[0].toUpperCase(), style: const TextStyle(color: AppColors.terracotta, fontSize: 28, fontWeight: FontWeight.bold)))
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text('@$username', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  
                  // Étoiles & Note moyenne
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.terracotta, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '4.8 · 12 avis', // Tu pourras connecter la vraie note moyenne et taille des évaluations ici
                        style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text('Ses articles en vente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),

            // Grille d'annonces du vendeur
            if (listeAnnonces.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text('Ce vendeur n\'a aucune autre annonce active.', style: TextStyle(color: Colors.grey))),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemCount: listeAnnonces.length,
                itemBuilder: (context, index) => ListingCard(item: listeAnnonces[index]),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}