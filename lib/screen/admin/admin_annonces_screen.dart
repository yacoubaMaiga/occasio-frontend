import 'package:flutter/material.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/service/admin/admin_service.dart';

class AdminAnnoncesScreen extends StatefulWidget {
  const AdminAnnoncesScreen({super.key});

  @override
  State<AdminAnnoncesScreen> createState() => _AdminAnnoncesScreenState();
}

class _AdminAnnoncesScreenState extends State<AdminAnnoncesScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _annonces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnonces();
  }

  Future<void> _loadAnnonces() async {
    setState(() => _isLoading = true);
    final data = await _adminService.getAllAnnonces();
    if (mounted) setState(() { _annonces = data; _isLoading = false; });
  }

  Future<void> _supprimer(String id) async {
    await _adminService.supprimerAnnonceAdmin(id);
    _loadAnnonces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.nuit,
        title: const Text('Modération Annonces', style: TextStyle(color: AppColors.blanc, fontSize: 16)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _annonces.length,
            itemBuilder: (context, index) {
              final a = _annonces[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(a['titre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Prix: ${a['prix']} FCFA • Vendeur: ${a['vendeur']?['username'] ?? 'Inconnu'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    onPressed: () => _supprimer(a['id']),
                  ),
                ),
              );
            },
          ),
    );
  }
}