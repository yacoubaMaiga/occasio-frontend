import 'package:flutter/material.dart';
import 'package:occasio/screen/profil/public_profil_screen.dart';
import 'package:occasio/theme/app_colors.dart';
import 'package:occasio/screen/conversation/chat_screen.dart';
import 'package:occasio/service/annonce_service.dart';
import 'package:occasio/service/messagerie_service.dart';
import 'package:occasio/service/signalement_service.dart';

class AnnonceDetailScreen extends StatefulWidget {
  final dynamic item; // Map JSON issu de AnnonceResponse

  const AnnonceDetailScreen({super.key, required this.item});

  @override
  State<AnnonceDetailScreen> createState() => _AnnonceDetailScreenState();
}

class _AnnonceDetailScreenState extends State<AnnonceDetailScreen> {
  final AnnonceService _annonceService = AnnonceService();

  int _currentImageIndex = 0;
  bool _isFavori = false;
  bool _descriptionExpanded = false;

  // Données extraites du DTO AnnonceResponse
  late String vendeurId;
  late int categorieId;
  late String titre;
  late String prix;
  late String description;
  late String etat;
  late String statut;
  late String categorie;
  late String vendeur;
  late String vendeurPhoto;
  late bool estVendu;
  late List<String> images;
  late int nombreVues;
  late String datePublication;

  // Gestion des recommandations dynamiques
  List<dynamic> _recommandations = [];
  bool _loadingRecommendations = true;

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    categorieId = item['categorieId'] ?? 0;
    vendeurId = item['vendeurId']?.toString() ?? '';
    titre = item['titre'] ?? 'Sans titre';
    prix = item['prix']?.toString() ?? '0';
    description = item['description'] ?? '';
    etat = _formatEtat(item['etat'] ?? '');
    statut = item['statut'] ?? 'ACTIVE';
    categorie = item['categorieNom'] ?? 'Autre';
    vendeur = item['vendeurUsername'] ?? 'Vendeur';
    vendeurPhoto = item['vendeurPhoto'] ?? '';
    estVendu = statut == 'VENDUE';
    _isFavori = item['estEnFavori'] ?? false;
    nombreVues = item['nombreVues'] ?? 0;
    datePublication = _formatDate(item['createdAt']);

    images = List<String>.from(item['images'] ?? []);
    if (images.isEmpty && item['imagePrincipale'] != null) {
      images = [item['imagePrincipale']];
    }

    _loadRecommendations();
  }

  // Fonction pour charger les annonces de la même catégorie
  Future<void> _loadRecommendations() async {
    if (categorieId == 0) {
      setState(() => _loadingRecommendations = false);
      return;
    }

    try {
      final list = await _annonceService.getAnnoncesParCategorie(categorieId);
      if (mounted) {
        setState(() {
          // Exclut l'annonce actuelle des recommandations
          _recommandations = list
              .where((element) => element['id'] != widget.item['id'])
              .toList();
          _loadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRecommendations = false);
      }
    }
  }

  String _formatEtat(String etat) {
    switch (etat) {
      case 'NEUF':
        return 'Neuf';
      case 'TRES_BON_ETAT':
        return 'Très bon état';
      case 'BON_ETAT':
        return 'Bon état';
      case 'ETAT_CORRECT':
        return 'État correct';
      default:
        return etat;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Récemment';
    try {
      final date = DateTime.parse(dateStr);
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 0) {
        return 'Publié il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'Publié il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
      } else if (difference.inMinutes > 0) {
        return 'Publié il y a ${difference.inMinutes} min';
      } else {
        return 'Publié à l\'instant';
      }
    } catch (e) {
      return 'Récemment';
    }
  }

  Future<void> _toggleFavori() async {
    final previousState = _isFavori;
    setState(() => _isFavori = !_isFavori); // Optimistic UI

    try {
      if (_isFavori) {
        await _annonceService.ajouterFavoris(widget.item['id'].toString());
      } else {
        await _annonceService.retirerFavoris(widget.item['id'].toString());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavori = previousState); // Rollback si échec
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible de mettre à jour les favoris."),
          ),
        );
      }
    }
  }

  void _contacterVendeur() async {
    // Évite que l'utilisateur clique plusieurs fois pendant le chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.terracotta),
      ),
    );

    try {
      final MessagerieService messagerieService = MessagerieService();

      // 1. Ouvre ou récupère la conversation depuis le backend
      final conv = await messagerieService.ouvrirConversation(
        widget.item['id'].toString(),
      );

      if (mounted) {
        Navigator.pop(context); // Ferme le loader de chargement

        // 2. Navigue directement vers la page de Chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conv['id'],
              interlocuteurName: conv['username'] ?? 'Vendeur',
              interlocuteurId: conv['userId'], // 🎯 ON PASSE L'ID ICI
              produitInfo: {
                'titre': titre,
                'prix': '$prix FCFA',
                'image': images.isNotEmpty ? images[0] : null,
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Ferme le loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'ouvrir la discussion pour le moment."),
          ),
        );
      }
    }
  }

  void _signalerAnnonce() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blanc,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SignalementBottomSheet(annonceId: widget.item['id'].toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _PhotoGallery(
                  images: images,
                  currentIndex: _currentImageIndex,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PrixTitreSection(
                      titre: titre,
                      prix: prix,
                      categorie: categorie,
                      etat: etat,
                      estVendu: estVendu,
                      datePublication: datePublication,
                      nombreVues: nombreVues,
                    ),
                    _DescriptionSection(
                      description: description,
                      expanded: _descriptionExpanded,
                      onToggle: () => setState(
                        () => _descriptionExpanded = !_descriptionExpanded,
                      ),
                    ),
                    _DetailsSection(etat: etat, categorie: categorie),
                    _VendeurSection(
                      vendeur: vendeur,
                      vendeurPhoto: vendeurPhoto,
                      onContact: _contacterVendeur,
                      onVoirProfil: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PublicProfilScreen(userId: vendeurId),
                          ),
                        );
                      },
                    ),

                    // ── Appel de la section recommandation DYNAMIQUE ──
                    _RecommandationsSection(
                      items: _recommandations,
                      isLoading: _loadingRecommendations,
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          _FloatingAppBar(
            isFavori: _isFavori,
            onBack: () => Navigator.of(context).pop(),
            onFavori: _toggleFavori,
            onSignaler: _signalerAnnonce,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomCta(estVendu: estVendu, onContact: _contacterVendeur),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  APPBAR FLOTTANTE
// ─────────────────────────────────────────────
class _FloatingAppBar extends StatelessWidget {
  const _FloatingAppBar({
    required this.isFavori,
    required this.onBack,
    required this.onFavori,
    required this.onSignaler,
  });

  final bool isFavori;
  final VoidCallback onBack;
  final VoidCallback onFavori;
  final VoidCallback onSignaler;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _AppBarButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          Row(
            children: [
              _AppBarButton(
                icon: isFavori ? Icons.favorite : Icons.favorite_border,
                iconColor: isFavori ? AppColors.terracotta : AppColors.nuit,
                onTap: onFavori,
              ),
              const SizedBox(width: 8),
              _AppBarButton(icon: Icons.more_vert, onTap: onSignaler),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  const _AppBarButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.nuit,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.blanc,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.nuit.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  GALERIE PHOTOS
// ─────────────────────────────────────────────
class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<String> images;
  final int currentIndex;
  final void Function(int) onPageChanged;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.width * 0.9;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              if (images.isEmpty) return _PhotoPlaceholder();
              return Image.network(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => _PhotoPlaceholder(),
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: currentIndex == i ? 20 : 6,
                    decoration: BoxDecoration(
                      color: currentIndex == i
                          ? AppColors.terracotta
                          : AppColors.blanc.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.nuit.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sable,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.nuit.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION PRIX + TITRE
// ─────────────────────────────────────────────
class _PrixTitreSection extends StatelessWidget {
  const _PrixTitreSection({
    required this.titre,
    required this.prix,
    required this.categorie,
    required this.etat,
    required this.estVendu,
    required this.datePublication,
    required this.nombreVues,
  });

  final String titre;
  final String prix;
  final String categorie;
  final String etat;
  final bool estVendu;
  final String datePublication;
  final int nombreVues;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(label: categorie, color: AppColors.sable),
              const SizedBox(width: 8),
              _Badge(
                label: etat,
                color: AppColors.menthe.withValues(alpha: 0.15),
                textColor: AppColors.menthe,
              ),
              if (estVendu) ...[
                const SizedBox(width: 8),
                _Badge(
                  label: 'Vendu',
                  color: AppColors.menthe,
                  textColor: AppColors.blanc,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            titre,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$prix FCFA',
            style: const TextStyle(
              color: AppColors.terracotta,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 13,
                color: AppColors.nuit.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
              Text(
                datePublication,
                style: TextStyle(
                  color: AppColors.nuit.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 14),
              Icon(
                Icons.remove_red_eye_outlined,
                size: 13,
                color: AppColors.nuit.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
              Text(
                '$nombreVues vues',
                style: TextStyle(
                  color: AppColors.nuit.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.textColor = AppColors.textPrimary,
  });
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION DESCRIPTION
// ─────────────────────────────────────────────
class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({
    required this.description,
    required this.expanded,
    required this.onToggle,
  });
  final String description;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final text = description.isNotEmpty
        ? description
        : 'Aucune description fournie par le vendeur.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            firstChild: Text(
              text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.nuit.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            secondChild: Text(
              text,
              style: TextStyle(
                color: AppColors.nuit.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onToggle,
            child: Text(
              expanded ? 'Voir moins' : 'Voir plus',
              style: const TextStyle(
                color: AppColors.terracotta,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION DÉTAILS
// ─────────────────────────────────────────────
class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.etat, required this.categorie});
  final String etat;
  final String categorie;

  @override
  Widget build(BuildContext context) {
    final details = [
      _DetailItem(icon: Icons.inventory_2_outlined, label: 'État', value: etat),
      _DetailItem(
        icon: Icons.category_outlined,
        label: 'Catégorie',
        value: categorie,
      ),
      _DetailItem(
        icon: Icons.location_on_outlined,
        label: 'Lieu',
        value: 'Bamako, Mali',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.sable.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: details.asMap().entries.map((entry) {
                final i = entry.key;
                final detail = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            detail.icon,
                            size: 18,
                            color: AppColors.terracotta,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            detail.label,
                            style: TextStyle(
                              color: AppColors.nuit.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            detail.value,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < details.length - 1)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppColors.sable,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
}

// ─────────────────────────────────────────────
//  SECTION VENDEUR
// ─────────────────────────────────────────────
class _VendeurSection extends StatelessWidget {
  const _VendeurSection({
    required this.vendeur,
    required this.vendeurPhoto,
    required this.onContact,
    required this.onVoirProfil,
  });
  final String vendeur;
  final String vendeurPhoto;
  final VoidCallback onContact;
  final VoidCallback onVoirProfil;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Le vendeur',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sable,
                  image: vendeurPhoto.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(vendeurPhoto),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: vendeurPhoto.isEmpty
                    ? Center(
                        child: Text(
                          vendeur.isNotEmpty ? vendeur[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.terracotta,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendeur,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: AppColors.terracotta,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Nouveau',
                          style: TextStyle(
                            color: AppColors.nuit.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onVoirProfil,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sable,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Voir profil',
                    style: TextStyle(
                      color: AppColors.nuit,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onVoirProfil,
            icon: const Icon(
              Icons.storefront_outlined,
              size: 16,
              color: AppColors.terracotta,
            ),
            label: const Text(
              'Voir toutes ses annonces',
              style: TextStyle(
                color: AppColors.terracotta,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION RECOMMANDATIONS DYNAMIQUE
// ─────────────────────────────────────────────
class _RecommandationsSection extends StatelessWidget {
  final List<dynamic> items;
  final bool isLoading;

  const _RecommandationsSection({required this.items, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Text(
            'Dans la même catégorie',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 225,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.terracotta),
                )
              : items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Aucun autre article disponible pour le moment.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _RecoCard(item: items[index]),
                ),
        ),
      ],
    );
  }
}

class _RecoCard extends StatelessWidget {
  final dynamic item; // Remplacé de _RecoItem à dynamic

  const _RecoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    // Extraction des données du JSON
    final t = item['titre'] ?? 'Sans titre';
    final p = item['prix']?.toString() ?? '0';
    final img = item['imagePrincipale'];
    final v = item['vendeurUsername'] ?? 'Vendeur';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AnnonceDetailScreen(item: item)),
        );
      },
      child: Container(
        width: 145,
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.nuit.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 105,
              decoration: BoxDecoration(
                color: AppColors.sable,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: img != null
                    ? Image.network(
                        img,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, _, _) => _fallbackIcon(),
                      )
                    : _fallbackIcon(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$p FCFA',
                    style: const TextStyle(
                      color: AppColors.terracotta,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    v,
                    style: TextStyle(
                      color: AppColors.nuit.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        color: AppColors.terracotta.withValues(alpha: 0.3),
        size: 32,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BARRE CTA FIXE EN BAS
// ─────────────────────────────────────────────
class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.estVendu, required this.onContact});
  final bool estVendu;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        boxShadow: [
          BoxShadow(
            color: AppColors.nuit.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: estVendu
          ? Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Cette annonce est vendue',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            )
          : GestureDetector(
              onTap: onContact,
              child: Container(
                width: double.infinity, // Bouton prend toute la largeur
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.blanc,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Contacter le vendeur',
                      style: TextStyle(
                        color: AppColors.blanc,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM SHEET DE SIGNALEMENT
// ─────────────────────────────────────────────
class _SignalementBottomSheet extends StatefulWidget {
  final String annonceId;
  const _SignalementBottomSheet({required this.annonceId});

  @override
  State<_SignalementBottomSheet> createState() => _SignalementBottomSheetState();
}

class _SignalementBottomSheetState extends State<_SignalementBottomSheet> {
  final SignalementService _signalementService = SignalementService();
  final TextEditingController _descriptionController = TextEditingController();

  String? _motifSelectionne;
  bool _isLoading = false;

  final Map<String, String> _motifs = {
    'CONTENU_INAPPROPRIE': 'Contenu inapproprié',
    'ARNAQUE': 'Arnaque suspectée',
    'SPAM': 'Spam',
    'AUTRE': 'Autre',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _envoyerSignalement() async {
    debugPrint('🔍 _envoyerSignalement appelée, motif = $_motifSelectionne');
    if (_motifSelectionne == null) {
      debugPrint('🔍 Motif null, sortie anticipée');
      return;
    }

    debugPrint('🔍 Avant setState isLoading=true');
    setState(() => _isLoading = true);
    debugPrint('🔍 Avant appel réseau');

    try {
      await _signalementService.signalerAnnonce(
        annonceId: widget.annonceId,
        motifSignalement: _motifSelectionne!,
        description: _descriptionController.text.trim(),
      );
      debugPrint('🔍 Appel réseau réussi');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signalement envoyé. Merci de nous aider à garder la communauté sûre.'),
            backgroundColor: AppColors.menthe,
          ),
        );
      }
    } catch (e) {
      debugPrint('🔍 Erreur capturée: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signaler cette annonce',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.nuit),
          ),
          const SizedBox(height: 16),
          const Text('Motif', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _motifs.entries.map((entry) {
              final isSelected = _motifSelectionne == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                selectedColor: AppColors.terracotta,
                labelStyle: TextStyle(color: isSelected ? AppColors.blanc : AppColors.nuit),
                onSelected: (selected) {
                  setState(() => _motifSelectionne = selected ? entry.key : null);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Description (optionnel)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ajoutez des précisions...',
              filled: true,
              fillColor: AppColors.sable.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (_motifSelectionne == null || _isLoading) 
                  ? () => debugPrint('🔍 Bouton DÉSACTIVÉ tapé (motif=$_motifSelectionne, loading=$_isLoading)') 
                  : _envoyerSignalement,
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: AppColors.blanc, strokeWidth: 2),
                    )
                  : const Text('Envoyer le signalement', style: TextStyle(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}