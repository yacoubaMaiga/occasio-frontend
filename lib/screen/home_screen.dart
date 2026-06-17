import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:occasio/screen/app_colors.dart';

// ─────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  // Hauteur du hero photo (en-dessous de l'AppBar)
  static const double _heroHeight = 220.0;
  // Hauteur de la search bar + ses paddings
  static const double _searchBarTotalHeight = 68.0;

  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset =
            _scrollController.offset.clamp(0.0, _heroHeight);
      });
    });
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

      // ── AppBar fixe et opaque — rien ne passe derrière ──
      appBar: _HomeAppBar(),

      // ── Body : hero + search bar (sticky) + contenu ──
      body: Stack(
        children: [
          // Contenu scrollable
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Espace réservé au hero + search bar
              SliverToBoxAdapter(
                child: SizedBox(
                    height: _heroHeight + _searchBarTotalHeight),
              ),

              SliverToBoxAdapter(
                child: _SectionTitle(title: 'Parcourir les catégories'),
              ),
              SliverToBoxAdapter(child: _CategoriesRow()),

              SliverToBoxAdapter(
                child: _SectionTitle(title: 'Annonces récentes'),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _ListingCard(item: _demoListings[index]),
                    childCount: _demoListings.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),

          // Hero + search bar collés en haut du body, en overlay
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
//  APP BAR  (logo + cloche, fond sable, fixe)
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
//  HERO + SEARCH BAR  (hero rétrécit, search bar se pin)
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
    final visibleHeroHeight =
        (heroHeight - scrollOffset).clamp(0.0, heroHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Hero photo (se cache progressivement) ──
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
                    'assets/hero_section.jpeg',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  // Gradient bas → lisibilité du tagline
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
                  // Tagline (s'estompe vite)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Opacity(
                      opacity:
                          (1 - scrollOffset / heroHeight * 2).clamp(0.0, 1.0),
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
                            'Des milliers d\'annonces près de chez vous',
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

        // ── Search bar (toujours visible, se pin au bord de l'AppBar) ──
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

// ─────────────────────────────────────────────
//  SECTION TITLE
// ─────────────────────────────────────────────

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
//  CATEGORIES ROW  (horizontal scroll)
// ─────────────────────────────────────────────

class _CategoriesRow extends StatelessWidget {
  _CategoriesRow();

  final List<_Category> categories = [
    _Category(icon: Icons.checkroom_outlined, label: 'Mode'),
    _Category(icon: Icons.phone_android_outlined, label: 'Tech'),
    _Category(icon: Icons.chair_outlined, label: 'Maison'),
    _Category(icon: Icons.sports_soccer_outlined, label: 'Sport'),
    _Category(icon: Icons.directions_car_outlined, label: 'Auto'),
    _Category(icon: Icons.child_friendly_outlined, label: 'Enfants'),
    _Category(icon: Icons.menu_book_outlined, label: 'Livres'),
    _Category(icon: Icons.music_note_outlined, label: 'Loisirs'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _CategoryCard(category: categories[index]),
      ),
    );
  }
}

class _Category {
  const _Category({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final _Category category;

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
          child: Icon(category.icon, color: AppColors.terracotta, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          category.label,
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

class _ListingItem {
  const _ListingItem({
    required this.title,
    required this.price,
    required this.location,
    required this.category,
    this.isFavorite = false,
    this.isSold = false,
  });

  final String title;
  final String price;
  final String location;
  final String category;
  final bool isFavorite;
  final bool isSold;
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.item});

  final _ListingItem item;

  @override
  Widget build(BuildContext context) {
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
          // Photo placeholder
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.sable,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: AppColors.terracotta.withValues(alpha: 0.3),
                      size: 40,
                    ),
                  ),
                ),
                // Badge Vendu
                if (item.isSold)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
                // Bouton favori
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
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      item.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 16,
                      color: item.isFavorite
                          ? AppColors.terracotta
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Infos
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
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
                  item.price,
                  style: const TextStyle(
                    color: AppColors.terracotta,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 11,
                        color: AppColors.nuit.withValues(alpha: 0.45)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        item.location,
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

// ─────────────────────────────────────────────
//  DEMO DATA
// ─────────────────────────────────────────────

const List<_ListingItem> _demoListings = [
  _ListingItem(
    title: 'Canapé 3 places en tissu gris',
    price: '150 €',
    location: 'Paris 11e',
    category: 'Maison',
  ),
  _ListingItem(
    title: 'iPhone 13 – 128 Go – Minuit',
    price: '380 €',
    location: 'Lyon 2e',
    category: 'Tech',
    isFavorite: true,
  ),
  _ListingItem(
    title: 'Veste en jean Levi\'s – Taille M',
    price: '35 €',
    location: 'Bordeaux',
    category: 'Mode',
    isSold: true,
  ),
  _ListingItem(
    title: 'Vélo de ville 7 vitesses',
    price: '90 €',
    location: 'Nantes',
    category: 'Sport',
  ),
  _ListingItem(
    title: 'Table basse bois massif',
    price: '65 €',
    location: 'Toulouse',
    category: 'Maison',
  ),
  _ListingItem(
    title: 'Console PS5 + 2 manettes',
    price: '420 €',
    location: 'Marseille 6e',
    category: 'Tech',
    isFavorite: true,
  ),
];