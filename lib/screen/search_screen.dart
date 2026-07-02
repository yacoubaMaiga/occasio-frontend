import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/service/annonce_service.dart';
import 'package:occasio/widgets/listing_card.dart';
import 'package:occasio/data/models/annonce_model.dart';
import 'package:occasio/data/models/categorie_model.dart';

class SearchScreen extends StatefulWidget {
  final bool autoFocus; // Permet d'ouvrir le clavier direct si on vient du Home
  final bool showBackButton; // Gère le bouton retour

  const SearchScreen({
    super.key,
    this.autoFocus = false,
    this.showBackButton = false,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final AnnonceService _annonceService = AnnonceService();
  final TextEditingController _searchController = TextEditingController();
  
  // Utilisation des modèles typés
  List<AnnonceModel> _resultats = [];
  List<CategorieModel> _categories = [];
  bool _isLoading = false;

  // Valeurs des filtres
  int? _selectedCategorieId;
  String? _selectedEtat;
  int? _prixMin;
  int? _prixMax;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // Lance une recherche vide au démarrage pour afficher les annonces récentes
    _lancerRecherche();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _annonceService.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (e) {
      print("Erreur catégories: $e");
    }
  }

  Future<void> _lancerRecherche() async {
    setState(() => _isLoading = true);
    try {
      final data = await _annonceService.rechercher(
        q: _searchController.text,
        categorieId: _selectedCategorieId,
        etat: _selectedEtat,
        prixMin: _prixMin,
        prixMax: _prixMax,
      );
      if (mounted) {
        setState(() {
          _resultats = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _ouvrirFiltres() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blanc,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _FilterBottomSheet(
          categories: _categories,
          initialCategorieId: _selectedCategorieId,
          initialEtat: _selectedEtat,
          initialPrixMin: _prixMin,
          initialPrixMax: _prixMax,
          onApply: (catId, etat, min, max) {
            setState(() {
              _selectedCategorieId = catId;
              _selectedEtat = etat;
              _prixMin = min;
              _prixMax = max;
            });
            _lancerRecherche();
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.blanc,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        automaticallyImplyLeading: widget.showBackButton,
        iconTheme: const IconThemeData(color: AppColors.nuit),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.sable.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: widget.autoFocus,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _lancerRecherche(),
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              hintStyle: TextStyle(color: AppColors.nuit.withValues(alpha: 0.4), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.nuit, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16, color: AppColors.nuit),
                      onPressed: () {
                        _searchController.clear();
                        _lancerRecherche();
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() {}),
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.terracotta),
                if (_selectedCategorieId != null || _selectedEtat != null || _prixMin != null || _prixMax != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.menthe,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
              ],
            ),
            onPressed: _ouvrirFiltres,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : _resultats.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: _resultats.length,
                  itemBuilder: (context, index) {
                    return ListingCard(item: _resultats[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.nuit.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text(
            'Aucun résultat',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres\nou de chercher autre chose.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM SHEET POUR LES FILTRES
// ─────────────────────────────────────────────
class _FilterBottomSheet extends StatefulWidget {
  final List<CategorieModel> categories; // Typé avec CategorieModel
  final int? initialCategorieId;
  final String? initialEtat;
  final int? initialPrixMin;
  final int? initialPrixMax;
  final Function(int?, String?, int?, int?) onApply;

  const _FilterBottomSheet({
    required this.categories,
    this.initialCategorieId,
    this.initialEtat,
    this.initialPrixMin,
    this.initialPrixMax,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  int? _catId;
  String? _etat;
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  final Map<String, String> _etatsPossibles = {
    'NEUF': 'Neuf',
    'TRES_BON_ETAT': 'Très bon état',
    'BON_ETAT': 'Bon état',
    'ETAT_CORRECT': 'État correct',
  };

  @override
  void initState() {
    super.initState();
    _catId = widget.initialCategorieId;
    _etat = widget.initialEtat;
    if (widget.initialPrixMin != null) _minController.text = widget.initialPrixMin.toString();
    if (widget.initialPrixMax != null) _maxController.text = widget.initialPrixMax.toString();
  }

  void _reinitialiser() {
    setState(() {
      _catId = null;
      _etat = null;
      _minController.clear();
      _maxController.clear();
    });
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filtres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.nuit)),
              TextButton(
                onPressed: _reinitialiser,
                child: const Text('Réinitialiser', style: TextStyle(color: AppColors.terracotta)),
              )
            ],
          ),
          const SizedBox(height: 16),
          
          // Catégories
          const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.categories.map((cat) {
              final isSelected = _catId == cat.id; // .id au lieu de ['id']
              return ChoiceChip(
                label: Text(cat.nom), // .nom au lieu de ['nom']
                selected: isSelected,
                selectedColor: AppColors.terracotta,
                labelStyle: TextStyle(color: isSelected ? AppColors.blanc : AppColors.nuit),
                onSelected: (selected) {
                  setState(() => _catId = selected ? cat.id : null); // .id au lieu de ['id']
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // État
          const Text('État de l\'article', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _etatsPossibles.entries.map((entry) {
              final isSelected = _etat == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                selectedColor: AppColors.menthe,
                labelStyle: TextStyle(color: isSelected ? AppColors.blanc : AppColors.nuit),
                onSelected: (selected) {
                  setState(() => _etat = selected ? entry.key : null);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Prix
          const Text('Prix (FCFA)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Min',
                    filled: true,
                    fillColor: AppColors.sable.withValues(alpha: 0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text('-', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Max',
                    filled: true,
                    fillColor: AppColors.sable.withValues(alpha: 0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Bouton Appliquer
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final min = int.tryParse(_minController.text);
                final max = int.tryParse(_maxController.text);
                widget.onApply(_catId, _etat, min, max);
                Navigator.pop(context);
              },
              child: const Text('Appliquer les filtres', style: TextStyle(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}