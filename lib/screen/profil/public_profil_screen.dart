import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/service/profil_service.dart';
import 'package:occasio/widgets/listing_card.dart';
import 'package:occasio/data/models/annonce_model.dart';

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
    final firstName = p['firstName'] ?? '';
    final lastName = p['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final photoUrl = p['photoProfil'];
    
    // On convertit la liste brute en List<AnnonceModel>
    final annoncesBrutes = p['annonces'] as List<dynamic>? ?? [];
    final List<AnnonceModel> listeAnnonces = annoncesBrutes
        .map((json) => AnnonceModel.fromJson(json))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.blanc,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: const BackButton(color: AppColors.nuit),
        title: Text(
          username, 
          style: const TextStyle(color: AppColors.nuit, fontSize: 16, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. En-tête du profil
          SliverToBoxAdapter(
            child: _buildHeader(
              username: username, 
              fullName: fullName, 
              photoUrl: photoUrl
            ),
          ),
          
          // 2. Titre de la section Annonces
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'Ses articles en vente', 
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w800, 
                  color: AppColors.textPrimary
                )
              ),
            ),
          ),

          // 3. Grille des annonces (Optimisée avec SliverGrid)
          if (listeAnnonces.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ListingCard(item: listeAnnonces[index]),
                  childCount: listeAnnonces.length,
                ),
              ),
            ),
            
          // Marge en bas
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader({required String username, required String fullName, String? photoUrl}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanc,
        boxShadow: [
          BoxShadow(
            color: AppColors.nuit.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          // Avatar premium
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sable,
              border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.2), width: 3),
              image: photoUrl != null 
                ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) 
                : null,
            ),
            child: photoUrl == null
                ? Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?', 
                      style: const TextStyle(color: AppColors.terracotta, fontSize: 32, fontWeight: FontWeight.bold)
                    )
                  )
                : null,
          ),
          const SizedBox(height: 16),
          
          // Noms
          if (fullName.isNotEmpty)
            Text(
              fullName, 
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)
            ),
          Text(
            '@$username', 
            style: TextStyle(
              fontSize: 15, 
              fontWeight: fullName.isNotEmpty ? FontWeight.w500 : FontWeight.w800, 
              color: fullName.isNotEmpty ? AppColors.nuit.withValues(alpha: 0.5) : AppColors.textPrimary
            )
          ),
          const SizedBox(height: 16),
          
          // Badges (Note et Membre)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.sable.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.terracotta, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '4.8 (12 avis)',
                      style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.sable.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: AppColors.menthe, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Membre vérifié',
                      style: TextStyle(color: AppColors.menthe, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sable,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.terracotta),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune annonce',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce vendeur n\'a aucune annonce active pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }
}