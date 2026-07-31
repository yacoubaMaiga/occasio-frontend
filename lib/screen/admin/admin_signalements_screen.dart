import 'package:flutter/material.dart';
import 'package:occasio/theme/app_colors.dart';
import 'package:occasio/service/admin_service.dart';

class AdminSignalementsScreen extends StatefulWidget {
  const AdminSignalementsScreen({super.key});

  @override
  State<AdminSignalementsScreen> createState() => _AdminSignalementsScreenState();
}

class _AdminSignalementsScreenState extends State<AdminSignalementsScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _signalements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSignalements();
  }

  Future<void> _loadSignalements() async {
    setState(() => _isLoading = true);
    try {
      final data = await _adminService.getSignalementsEnAttente();
      if (mounted) {
        setState(() {
          _signalements = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _traiter(String id, String action, String? annonceId, String? vendeurId) async {
    // Afficher un loader pendant le traitement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
    );

    try {
      await _adminService.traiterSignalement(
        signalementId: id,
        action: action,
        annonceId: annonceId,
        vendeurId: vendeurId,
      );
      
      if (mounted) {
        Navigator.pop(context); // Fermer le loader
        _loadSignalements(); // Recharger la liste
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action effectuée avec succès.'), backgroundColor: AppColors.menthe),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.nuit,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.blanc),
        title: const Text(
          'Signalements en attente',
          style: TextStyle(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : _signalements.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _signalements.length,
                  itemBuilder: (context, index) {
                    final sig = _signalements[index];
                    final annonce = sig['annonce'] ?? {};
                    final signaleur = sig['signaleur'] ?? {};
                    
                    return _buildSignalementCard(sig, annonce, signaleur);
                  },
                ),
    );
  }

  Widget _buildSignalementCard(Map<String, dynamic> sig, Map<String, dynamic> annonce, Map<String, dynamic> signaleur) {
    return Card(
      color: AppColors.blanc,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: AppColors.nuit.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Motif
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sig['motif'] ?? 'Motif inconnu',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Détails du signalement
            if (sig['description'] != null && sig['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Message : "${sig['description']}"',
                  style: TextStyle(color: AppColors.nuit.withValues(alpha: 0.7), fontStyle: FontStyle.italic),
                ),
              ),
              
            // Info Annonce
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sable.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Annonce : ${annonce['titre'] ?? 'Inconnue'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Signalé par : @${signaleur['username'] ?? 'Inconnu'}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Boutons d'action
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Ignorer'),
                  backgroundColor: Colors.grey.shade200,
                  onPressed: () => _traiter(sig['id'], 'REJETER', null, null),
                ),
                ActionChip(
                  label: const Text('Supprimer l\'annonce', style: TextStyle(color: AppColors.blanc)),
                  backgroundColor: AppColors.terracotta,
                  onPressed: () => _traiter(sig['id'], 'SUPPRIMER_ANNONCE', annonce['id'], null),
                ),
                ActionChip(
                  label: const Text('Bannir Vendeur', style: TextStyle(color: AppColors.blanc)),
                  backgroundColor: Colors.redAccent,
                  onPressed: () => _traiter(sig['id'], 'BANNIR_USER', annonce['id'], annonce['vendeur_id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: AppColors.menthe.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('Aucun signalement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tout est calme sur la plateforme.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}