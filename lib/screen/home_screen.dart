import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:occasio/screen/annonce/publish_screen.dart';
import 'package:occasio/theme/app_colors.dart';
import 'package:occasio/screen/conversation/conversations_screen.dart';
import 'package:occasio/screen/search_screen.dart';
import 'package:occasio/service/annonce_service.dart';
import 'package:occasio/service/messagerie_service.dart';
import 'package:occasio/widgets/listing_card.dart';
import 'package:occasio/utils/icon_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final AnnonceService _annonceService = AnnonceService();
  final MessagerieService _messagerieService = MessagerieService();

  static const double _heroHeight = 220.0;
  static const double _searchBarTotalHeight = 68.0;

  double _scrollOffset = 0.0;
  
  List<dynamic> _annonces = [];
  List<dynamic> _categories = [];
  int _unreadMessagesCount = 0;
  bool _isLoading = true;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset.clamp(0.0, _heroHeight);
      });
    });
    _loadData();

    // Rafraîchit les données toutes les 3 secondes, en arrière-plan,
    // sans réafficher le loader plein écran (pour ne pas gêner le scroll).
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadData(silent: true);
    });
  }

  Future<void> _loadData({bool silent = false}) async {
    // En mode silencieux (rafraîchissement périodique), on ne montre pas
    // le spinner plein écran ni les erreurs, pour ne pas gêner l'utilisateur.
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final responses = await Future.wait([
        _annonceService.getCategories(),
        _annonceService.getAnnonces(),
      ]);

      int unread = 0;
      try {
        final conversations = await _messagerieService.getMesConversations();
        for (var conv in conversations) {
          unread += (conv['nonLus'] as int? ?? 0);
        }
      } catch (_) {
        // Ignoré si l'utilisateur n'est pas connecté
      }

      if (mounted) {
        setState(() {
          _categories = responses[0];
          _annonces = responses[1];
          _unreadMessagesCount = unread;
          _isLoading = false; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de charger les données. Vérifiez votre connexion.')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _HomeAppBar(unreadCount: _unreadMessagesCount),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta),
            )
          : Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: _heroHeight + _searchBarTotalHeight,
                      ),
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
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.65,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                ListingCard(item: _annonces[index]),
                            childCount: _annonces.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),

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
  final int unreadCount;

  const _HomeAppBar({required this.unreadCount});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading:
          false, // Désactive la flèche de retour automatique
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
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConversationsScreen()),
            );
          },
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 16),
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.nuit,
                  size: 26,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
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
class _HeroWithSearchBar extends StatefulWidget {
  final double scrollOffset;
  final double heroHeight;

  const _HeroWithSearchBar({
    required this.scrollOffset,
    required this.heroHeight,
  });

  @override
  State<_HeroWithSearchBar> createState() => _HeroWithSearchBarState();
}

class _HeroWithSearchBarState extends State<_HeroWithSearchBar> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startOrRestartTimer(0);
  }

  void _startOrRestartTimer(int pageIndex) {
    _timer?.cancel();
    final duration = pageIndex == 0 ? 5 : 3;
    _timer = Timer(Duration(seconds: duration), () {
      if (mounted) {
        _pageController.animateToPage(
          pageIndex == 0 ? 1 : 0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleHeroHeight = (widget.heroHeight - widget.scrollOffset).clamp(
      0.0,
      widget.heroHeight,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(
          child: SizedBox(
            height: visibleHeroHeight,
            width: double.infinity,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: widget.heroHeight,
              maxHeight: widget.heroHeight,
              child: SizedBox(
                height: widget.heroHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        _startOrRestartTimer(index);
                      },
                      children: [
                        _buildSlide(
                          imagePath: 'assets/hero_caroussel/img1.jpg',
                          title: 'Gagnez de l\'argent\nfacilement',
                          subtitle:
                              'Vendez les objets que vous n\'utilisez plus en 3 clics.',
                          showCta: true,
                        ),
                        _buildSlide(
                          imagePath: 'assets/hero_caroussel/img2.jpeg',
                          title:
                              'Choisissez les produits\nqui vous conviennent',
                          subtitle:
                              'Des millions d\'annonces d\'occasion près de chez vous.',
                          showCta: false,
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity:
                            (1 - widget.scrollOffset / widget.heroHeight * 2)
                                .clamp(0.0, 1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDot(0),
                            const SizedBox(width: 6),
                            _buildDot(1),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildSlide({
    required String imagePath,
    required String title,
    required String subtitle,
    required bool showCta,
  }) {
    final textOpacity = (1 - widget.scrollOffset / widget.heroHeight * 2).clamp(
      0.0,
      1.0,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.sable,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.nuit.withValues(alpha: 0.2),
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Image non trouvée',
                    style: TextStyle(
                      color: AppColors.nuit.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.nuit.withValues(alpha: 0.05),
                AppColors.nuit.withValues(alpha: 0.72),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 30,
          left: 16,
          right: 16,
          child: Opacity(
            opacity: textOpacity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.sable,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (showCta) ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PublishScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.add_circle_outline,
                            color: AppColors.blanc,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Publier une annonce',
                            style: TextStyle(
                              color: AppColors.blanc,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 6,
      width: _currentPage == index ? 20 : 6,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.terracotta
            : AppColors.blanc.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
      ),
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
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                const SearchScreen(autoFocus: true, showBackButton: true),
          ),
        );
      },
      child: Container(
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
              child: Text(
                'Vêtements, meubles, électronique…',
                style: TextStyle(
                  color: AppColors.nuit.withValues(alpha: 0.45),
                  fontSize: 14,
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
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categoriesData[index];
          return _CategoryCard(
            label: cat['nom'] ?? 'Inconnu',
            icon: IconHelper.getIcon(cat['icone']),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SearchScreen(
                    initialCategorieId: cat['id'],
                    initialCategorieName: cat['nom'],
                    showBackButton: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }
}
