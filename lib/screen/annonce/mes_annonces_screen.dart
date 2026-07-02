import 'package:flutter/material.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/service/annonce_service.dart';
import 'package:occasio/widgets/listing_card.dart';
import 'package:occasio/data/models/annonce_model.dart'; // <-- Nouvel import

class MesAnnoncesScreen extends StatefulWidget {
  const MesAnnoncesScreen({super.key});

  @override
  State<MesAnnoncesScreen> createState() => _MesAnnoncesScreenState();
}

class _MesAnnoncesScreenState extends State<MesAnnoncesScreen> with SingleTickerProviderStateMixin {
  final AnnonceService _annonceService = AnnonceService();
  late TabController _tabController;

  // On utilise le modèle fortement typé au lieu de dynamic
  List<AnnonceModel> _toutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMesAnnonces();
  }

  Future<void> _loadMesAnnonces() async {
    try {
      // On récupère directement la liste d'AnnonceModel depuis Supabase
      final data = await _annonceService.getMesAnnonces(); 
      if (mounted) {
        setState(() {
          _toutes = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // La liste filtrée renvoie également des AnnonceModel
  List<AnnonceModel> _filtrerParStatut(String? statut) {
    if (statut == null) return _toutes;
    // On utilise la notation objet ".statut" au lieu de "['statut']"
    return _toutes.where((a) => a.statut == statut).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.sable,
        elevation: 0,
        title: const Text('Mes Annonces', style: TextStyle(color: AppColors.nuit, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: const BackButton(color: AppColors.nuit),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.terracotta,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.terracotta,
          tabs: const [Tab(text: 'Toutes'), Tab(text: 'Actives'), Tab(text: 'Vendues')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(_filtrerParStatut(null)),
                _buildGrid(_filtrerParStatut('ACTIVE')),
                _buildGrid(_filtrerParStatut('VENDUE')),
              ],
            ),
    );
  }

  // Le Grid attend désormais une liste d'AnnonceModel
  Widget _buildGrid(List<AnnonceModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Aucune annonce dans cette catégorie.', style: TextStyle(color: Colors.grey, fontSize: 13)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) => ListingCard(item: list[index]),
    );
  }
}