import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/service/annonce_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final AnnonceService _annonceService = AnnonceService();

  static const double _heroHeight = 220.0;
  static const double _searchBarTotalHeight = 68.0;

  double _scrollOffset = 0.0;
  
  List<dynamic> _annonces = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset.clamp(0.0, _heroHeight);
      });
    });
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final responses = await Future.wait([
        _annonceService.getCategories(),
        _annonceService.getAnnonces(),
      ]);

      if (mounted) {
        setState(() {
          _categories = responses[0];
          _annonces = responses[1];
          _isLoading = false; // Tout est chargé en même temps
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger les données. Vérifiez votre connexion.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const _HomeAppBar(),
      
      // ── MODIFICATION ICI : Un seul loading sur toute la page ──
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.terracotta,
              ),
            )
          : Stack(
              children: [
                // Contenu principal (Affiché uniquement quand le chargement est fini)
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(height: _heroHeight + _searchBarTotalHeight),
                    ),

                    const SliverToBoxAdapter(
                      child: _SectionTitle(title: 'Parcourir les catégories'),
                    ),
                    
                    SliverToBoxAdapter(
                      child: _CategoriesRow(categoriesData: _categories),
                    ),

                    const SliverToBoxAdapter(
                      child: _SectionTitle(title: 'Annonces récentes'),
                    ),
                    
                    // Gestion de l'affichage des annonces sans double loading
                    if (_annonces.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'Aucune annonce disponible pour le moment.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
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
                            (context, index) => _ListingCard(item: _annonces[index]),
                            childCount: _annonces.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),

                // Hero + Barre de recherche persistante
                _HeroWithSearchBar(
                  scrollOffset: _scrollOffset,
                  heroHeight: _heroHeight,
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.sable,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleSpacing: 16,
      title: Image.asset(
        'assets/logo_light.png',
        height: 24,
        fit: BoxFit.contain,
      ),
      actions: [
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.nuit.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.nuit,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  HERO + SEARCH BAR
// ─────────────────────────────────────────────
class _HeroWithSearchBar extends StatelessWidget {
  const _HeroWithSearchBar({
    required this.scrollOffset,
    required this.heroHeight,
  });

  final double scrollOffset;
  final double heroHeight;

  @override
  Widget build(BuildContext context) {
    final visibleHeroHeight = (heroHeight - scrollOffset).clamp(0.0, heroHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(
          child: SizedBox(
            height: visibleHeroHeight,
            width: double.infinity,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: heroHeight,
              maxHeight: heroHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/hero_caroussel/img2.jpeg',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.nuit.withValues(alpha: 0.10),
                          AppColors.nuit.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Opacity(
                      opacity: (1 - scrollOffset / heroHeight * 2).clamp(0.0, 1.0),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trouvez votre\nperle rare 🌿',
                            style: TextStyle(
                              color: AppColors.blanc,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Des millions d\'annonces d\'occasion',
                            style: TextStyle(
                              color: AppColors.sable,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          color: AppColors.blanc,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: const _SearchBar(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SEARCH BAR
// ─────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.sable.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sable),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: AppColors.nuit, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Vêtements, meubles, électronique…',
                hintStyle: TextStyle(
                  color: AppColors.nuit.withValues(alpha: 0.45),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.terracotta,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Filtres',
              style: TextStyle(
                color: AppColors.blanc,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CATEGORIES ROW
// ─────────────────────────────────────────────
class _CategoriesRow extends StatelessWidget {
  final List<dynamic> categoriesData;

  const _CategoriesRow({required this.categoriesData});

  @override
  Widget build(BuildContext context) {
    if (categoriesData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('Aucune catégorie.', style: TextStyle(color: Colors.grey)),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoriesData.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categoriesData[index];
          return _CategoryCard(
            label: cat['nom'] ?? 'Inconnu',
            icon: Icons.category_outlined, 
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CategoryCard({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.sable,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.terracotta, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  LISTING CARD
// ─────────────────────────────────────────────
class _ListingCard extends StatelessWidget {
  final dynamic item;

  const _ListingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final titre = item['titre'] ?? 'Sans titre';
    final prix = item['prix']?.toString() ?? '0';
    final imagePrincipale = item['imagePrincipale'];
    final estVendu = item['statut'] == 'VENDUE';
    final estFavori = item['estEnFavori'] ?? false;
    final vendeur = item['vendeurUsername'] ?? 'Vendeur'; 

    return Container(
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
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: imagePrincipale != null
                      ? Image.network(
                          imagePrincipale,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.sable,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: AppColors.sable,
                          child: Icon(Icons.image_outlined, color: AppColors.terracotta.withValues(alpha: 0.3), size: 40),
                        ),
                ),
                if (estVendu)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.menthe,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Vendu',
                        style: TextStyle(
                          color: AppColors.blanc,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.blanc,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
                      ],
                    ),
                    child: Icon(
                      estFavori ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: estFavori ? AppColors.terracotta : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$prix FCFA',
                  style: const TextStyle(
                    color: AppColors.terracotta,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 11, color: AppColors.nuit.withValues(alpha: 0.45)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        vendeur,
                        style: TextStyle(
                          color: AppColors.nuit.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}