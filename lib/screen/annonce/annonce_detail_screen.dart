import 'package:flutter/material.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/screen/conversation/chat_screen.dart';
import 'package:occasio/screen/profil/public_profil_screen.dart';
import 'package:occasio/service/annonce_service.dart';
import 'package:occasio/service/messagerie_service.dart';
import 'package:occasio/data/models/annonce_model.dart'; 
import 'package:occasio/service/favori_service.dart';
import 'package:occasio/service/signalement_service.dart'; // <-- Nouvel import

class AnnonceDetailScreen extends StatefulWidget {
  final AnnonceModel item;

  const AnnonceDetailScreen({super.key, required this.item});

  @override
  State<AnnonceDetailScreen> createState() => _AnnonceDetailScreenState();
}

class _AnnonceDetailScreenState extends State<AnnonceDetailScreen> {
  final AnnonceService _annonceService = AnnonceService();
  final FavoriService _favoriService = FavoriService(); // <-- Instanciation du service
  
  int _currentImageIndex = 0;
  bool _descriptionExpanded = false;

  // Gestion des favoris
  bool _isFavori = false;
  bool _isLoadingFavori = false;

  // Gestion des recommandations dynamiques
  List<AnnonceModel> _recommandations = [];
  bool _loadingRecommendations = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _verifierStatutFavori(); // <-- Appel au chargement
  }

  Future<void> _verifierStatutFavori() async {
    final estFavori = await _favoriService.estFavori(widget.item.id);
    if (mounted) {
      setState(() {
        _isFavori = estFavori;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final allAnnonces = await _annonceService.getAnnonces();
      if (mounted) {
        setState(() {
          _recommandations = allAnnonces.where((a) => 
            a.categorieNom == widget.item.categorieNom && a.id != widget.item.id
          ).toList();
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
      case 'NEUF': return 'Neuf';
      case 'TRES_BON_ETAT': return 'Très bon état';
      case 'BON_ETAT': return 'Bon état';
      case 'ETAT_CORRECT': return 'État correct';
      default: return etat;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Récemment';
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

  // <-- Méthode mise à jour pour gérer la BDD
  Future<void> _toggleFavori() async {
    if (_isLoadingFavori) return;

    setState(() => _isLoadingFavori = true);

    try {
      if (_isFavori) {
        await _favoriService.supprimerDesFavoris(widget.item.id);
        setState(() => _isFavori = false);
      } else {
        await _favoriService.ajouterAuxFavoris(widget.item.id);
        setState(() => _isFavori = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavori = false);
      }
    }
  }

  void _contacterVendeur() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
    );

    try {
      final MessagerieService messagerieService = MessagerieService();
      final conv = await messagerieService.ouvrirConversation(widget.item.id);
      
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conv['id'],
              interlocuteurName: conv['username'] ?? widget.item.vendeurPseudo,
              interlocuteurId: conv['userId'] ?? widget.item.vendeurId, 
              produitInfo: {
                'titre': widget.item.titre,
                'prix': '${widget.item.prix} FCFA',
                'image': widget.item.imagePrincipale,
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir la discussion pour le moment.")),
        );
      }
    }
  }
  
  void _signalerAnnonce() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.report_problem_outlined, color: AppColors.terracotta, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Signaler cette annonce',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pourquoi souhaitez-vous signaler cette annonce ? Votre signalement restera anonyme et sera examiné par notre équipe.',
                style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.6), fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              
              // Les 3 motifs demandés
              _buildMotifTile(context, 'Contenu inapproprié'),
              const Divider(height: 1, color: AppColors.sable),
              _buildMotifTile(context, 'Douteux (Arnaque, prix anormalement bas...)'),
              const Divider(height: 1, color: AppColors.sable),
              _buildMotifTile(context, 'Termes déplacés (dans le chat ou la description)'),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Widget interne pour dessiner les boutons de motifs
  Widget _buildMotifTile(BuildContext ctx, String motif) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        motif, 
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.terracotta),
      onTap: () {
        Navigator.pop(ctx); // On ferme le BottomSheet
        _envoyerSignalement(motif); // On déclenche l'envoi
      },
    );
  }

  // Fonction qui appelle le service Supabase et gère l'affichage des messages
  Future<void> _envoyerSignalement(String motif) async {
    // Affiche un loader temporaire
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
    );

    try {
      await SignalementService().signalerAnnonce(
        annonceId: widget.item.id,
        motif: motif,
      );
      
      if (mounted) {
        Navigator.pop(context); // Retire le loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signalement envoyé avec succès. Merci !'),
            backgroundColor: AppColors.menthe, // Vert pour le succès
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Retire le loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: AppColors.terracotta,
          ),
        );
      }
    }
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
                  images: widget.item.images,
                  currentIndex: _currentImageIndex,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PrixTitreSection(
                      titre: widget.item.titre,
                      prix: widget.item.prix.toString(),
                      categorie: widget.item.categorieNom,
                      etat: _formatEtat(widget.item.etat),
                      estVendu: widget.item.estVendue,
                      datePublication: _formatDate(widget.item.createdAt),
                      nombreVues: 0,
                    ),
                    _DescriptionSection(
                      description: widget.item.description,
                      expanded: _descriptionExpanded,
                      onToggle: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
                    ),
                    _DetailsSection(etat: _formatEtat(widget.item.etat), categorie: widget.item.categorieNom),
                    _VendeurSection(
                      vendeurId: widget.item.vendeurId,
                      vendeur: widget.item.vendeurPseudo,
                      vendeurPhoto: '',
                      onContact: _contacterVendeur,
                    ),
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
            isLoadingFavori: _isLoadingFavori, // <-- On passe l'état de chargement
            onBack: () => Navigator.of(context).pop(),
            onFavori: _toggleFavori,
            onSignaler: _signalerAnnonce,
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _BottomCta(
              estVendu: widget.item.estVendue,
              onContact: _contacterVendeur,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingAppBar extends StatelessWidget {
  const _FloatingAppBar({
    required this.isFavori, 
    required this.isLoadingFavori, 
    required this.onBack, 
    required this.onFavori, 
    required this.onSignaler
  });

  final bool isFavori;
  final bool isLoadingFavori;
  final VoidCallback onBack;
  final VoidCallback onFavori;
  final VoidCallback onSignaler;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8, left: 12, right: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _AppBarButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          Row(
            children: [
              _AppBarButton(
                icon: isFavori ? Icons.favorite : Icons.favorite_border, 
                iconColor: isFavori ? AppColors.terracotta : AppColors.nuit, 
                isLoading: isLoadingFavori, // <-- Utilisation du chargement
                onTap: onFavori
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
  const _AppBarButton({required this.icon, required this.onTap, this.iconColor = AppColors.nuit, this.isLoading = false});
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final bool isLoading; // <-- Ajout de la variable isLoading

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.blanc, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.nuit.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))]),
        child: isLoading 
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracotta),
              )
            : Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({required this.images, required this.currentIndex, required this.onPageChanged});
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
              return Image.network(images[index], fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, _, _) => _PhotoPlaceholder());
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 14, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 3), height: 6, width: currentIndex == i ? 20 : 6, decoration: BoxDecoration(color: currentIndex == i ? AppColors.terracotta : AppColors.blanc.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(3)))),
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: 14, right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.nuit.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(12)),
                child: Text('${currentIndex + 1}/${images.length}', style: const TextStyle(color: AppColors.blanc, fontSize: 12, fontWeight: FontWeight.w600)),
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
    return Container(color: AppColors.sable, child: Center(child: Icon(Icons.image_outlined, size: 48, color: AppColors.nuit.withValues(alpha: 0.2))));
  }
}

class _PrixTitreSection extends StatelessWidget {
  const _PrixTitreSection({required this.titre, required this.prix, required this.categorie, required this.etat, required this.estVendu, required this.datePublication, required this.nombreVues});
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
              _Badge(label: etat, color: AppColors.menthe.withValues(alpha: 0.15), textColor: AppColors.menthe),
              if (estVendu) ...[const SizedBox(width: 8), _Badge(label: 'Vendu', color: AppColors.menthe, textColor: AppColors.blanc)],
            ],
          ),
          const SizedBox(height: 12),
          Text(titre, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, height: 1.25)),
          const SizedBox(height: 10),
          Text('$prix FCFA', style: const TextStyle(color: AppColors.terracotta, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule_outlined, size: 13, color: AppColors.nuit.withValues(alpha: 0.4)), const SizedBox(width: 4), Text(datePublication, style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.45), fontSize: 12)),
              const SizedBox(width: 14),
              Icon(Icons.remove_red_eye_outlined, size: 13, color: AppColors.nuit.withValues(alpha: 0.4)), const SizedBox(width: 4), Text('$nombreVues vues', style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.45), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.textColor = AppColors.textPrimary});
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)));
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.description, required this.expanded, required this.onToggle});
  final String description;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final text = description.isNotEmpty ? description : 'Aucune description fournie par le vendeur.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Description', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            firstChild: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.75), fontSize: 14, height: 1.6)),
            secondChild: Text(text, style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.75), fontSize: 14, height: 1.6)),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
          const SizedBox(height: 8),
          GestureDetector(onTap: onToggle, child: Text(expanded ? 'Voir moins' : 'Voir plus', style: const TextStyle(color: AppColors.terracotta, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.etat, required this.categorie});
  final String etat;
  final String categorie;

  @override
  Widget build(BuildContext context) {
    final details = [
      _DetailItem(icon: Icons.inventory_2_outlined, label: 'État', value: etat),
      _DetailItem(icon: Icons.category_outlined, label: 'Catégorie', value: categorie),
      _DetailItem(icon: Icons.location_on_outlined, label: 'Lieu', value: 'Bamako, Mali'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Détails', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: AppColors.sable.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: details.asMap().entries.map((entry) {
                return Column(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), child: Row(children: [Icon(entry.value.icon, size: 18, color: AppColors.terracotta), const SizedBox(width: 12), Text(entry.value.label, style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.5), fontSize: 13)), const Spacer(), Text(entry.value.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))])),
                    if (entry.key < details.length - 1) Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.sable),
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
  const _DetailItem({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
}
class _VendeurSection extends StatelessWidget {
  const _VendeurSection({
    required this.vendeurId, // <-- Ajout du paramètre
    required this.vendeur, 
    required this.vendeurPhoto, 
    required this.onContact
  });
  
  final String vendeurId; // <-- Ajout de la variable
  final String vendeur;
  final String vendeurPhoto;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Le vendeur', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.sable, image: vendeurPhoto.isNotEmpty ? DecorationImage(image: NetworkImage(vendeurPhoto), fit: BoxFit.cover) : null), child: vendeurPhoto.isEmpty ? Center(child: Text(vendeur.isNotEmpty ? vendeur[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.terracotta, fontSize: 20, fontWeight: FontWeight.w700))) : null),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(vendeur, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Row(children: [Icon(Icons.star_rounded, color: AppColors.terracotta, size: 14), const SizedBox(width: 3), Text('Nouveau', style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.5), fontSize: 12))])])),
              GestureDetector(
                // 💡 MAGIE ICI : Redirection vers le profil public
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfilScreen(userId: vendeurId),
                    ),
                  );
                }, 
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: AppColors.sable, borderRadius: BorderRadius.circular(20)), child: const Text('Voir profil', style: TextStyle(color: AppColors.nuit, fontSize: 12, fontWeight: FontWeight.w600)))),
            ],
          ),
          const SizedBox(height: 14),
          // Idem ici, le TextButton peut aussi rediriger vers le profil
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicProfilScreen(userId: vendeurId),
                ),
              );
            }, 
            icon: const Icon(Icons.storefront_outlined, size: 16, color: AppColors.terracotta), 
            label: const Text('Voir toutes ses annonces', style: TextStyle(color: AppColors.terracotta, fontSize: 13, fontWeight: FontWeight.w600)), 
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap)
          ),
        ],
      ),
    );
  }
}
class _RecommandationsSection extends StatelessWidget {
  final List<AnnonceModel> items; // Utilisation de AnnonceModel
  final bool isLoading;

  const _RecommandationsSection({required this.items, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 14), child: Text('Dans la même catégorie', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
        SizedBox(
          height: 210,
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
              : items.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Aucun autre article disponible pour le moment.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: items.length, separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => _RecoCard(item: items[index]),
                    ),
        ),
      ],
    );
  }
}

class _RecoCard extends StatelessWidget {
  final AnnonceModel item; // Remplacé par AnnonceModel
  const _RecoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AnnonceDetailScreen(item: item))),
      child: Container(
        width: 145,
        decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.nuit.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(color: AppColors.sable, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: item.imagePrincipale != null ? Image.network(item.imagePrincipale!, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, _, _) => _fallbackIcon()) : _fallbackIcon(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.titre, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${item.prix} FCFA', style: const TextStyle(color: AppColors.terracotta, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.vendeurPseudo, style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.45), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _fallbackIcon() {
    return Center(child: Icon(Icons.image_outlined, color: AppColors.terracotta.withValues(alpha: 0.3), size: 32));
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.estVendu, required this.onContact});
  final bool estVendu;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(color: AppColors.blanc, boxShadow: [BoxShadow(color: AppColors.nuit.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))]),
      child: estVendu
          ? Container(height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)), child: Text('Cette annonce est vendue', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 15)))
          : GestureDetector(
              onTap: onContact,
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(color: AppColors.terracotta, borderRadius: BorderRadius.circular(14)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.chat_bubble_outline, color: AppColors.blanc, size: 18), SizedBox(width: 8), Text('Contacter le vendeur', style: TextStyle(color: AppColors.blanc, fontSize: 15, fontWeight: FontWeight.w700))]),
              ),
            ),
    );
  }
}