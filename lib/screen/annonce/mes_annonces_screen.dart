import 'package:flutter/material.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/service/annonce_service.dart';
import 'package:occasio/widgets/listing_card.dart';

class MesAnnoncesScreen extends StatefulWidget {
  const MesAnnoncesScreen({super.key});

  @override
  State<MesAnnoncesScreen> createState() => _MesAnnoncesScreenState();
}

class _MesAnnoncesScreenState extends State<MesAnnoncesScreen> with SingleTickerProviderStateMixin {
  final AnnonceService _annonceService = AnnonceService();
  late TabController _tabController;

  List<dynamic> _toutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMesAnnonces();
  }

  Future<void> _loadMesAnnonces() async {
    try {
      // Ton backend renvoie un objet Page, on extrait la liste via .data['content'] dans ton annonce_service
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

  List<dynamic> _filtrerParStatut(String? statut) {
    if (statut == null) return _toutes;
    return _toutes.where((a) => a['statut'] == statut).toList();
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

  Widget _buildGrid(List<dynamic> list) {
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