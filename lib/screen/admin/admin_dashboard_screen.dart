import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:occasio/screen/admin/admin_annonces_screen.dart';
import 'package:occasio/screen/admin/admin_categories_screen.dart';
import 'package:occasio/screen/admin/admin_signalements_screen.dart';
import 'package:occasio/service/admin/admin_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:occasio/screen/app_colors.dart';

// 1. AJOUT DE LA CLASSE PRINCIPALE (StatefulWidget) MANQUANTE
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

// 2. CORRECTION DE LA SIGNATURE DU STATE
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  Map<String, int> _stats = {
    'signalements': 0,
    'users': 0,
    'annonces': 0,
    'categories': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _adminService.getGlobalStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _deconnexion(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/connexion', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight, // Ajout de la couleur de fond
      appBar: AppBar(
        backgroundColor: AppColors.nuit,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Console d\'Administration',
          style: TextStyle(
            color: AppColors.blanc,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.blanc),
            onPressed: () => _deconnexion(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vue d\'ensemble',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildAdminCard(
                        context,
                        title: 'Signalements',
                        icon: Icons.report_problem_outlined,
                        color: AppColors.terracotta,
                        count: _stats['signalements'].toString(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminSignalementsScreen(),
                            ),
                          ).then((_) {
                            // Recharge les stats en revenant sur le dashboard au cas où un signalement a été traité
                            _loadStats();
                          });
                        },
                      ),
                      _buildAdminCard(
                        context,
                        title: 'Utilisateurs',
                        icon: Icons.people_outline,
                        color: AppColors.menthe,
                        count: _stats['users'].toString(),
                        onTap: () {},
                      ),
                      _buildAdminCard(
                        context,
                        title: 'Annonces Actives',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF6B7DB3),
                        count: _stats['annonces'].toString(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminAnnoncesScreen(),
                            ),
                          );
                        },
                      ),
                      _buildAdminCard(
                        context,
                        title: 'Catégories',
                        icon: Icons.category_outlined,
                        color: const Color(0xFF8B6B9E),
                        count: _stats['categories'].toString(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminCategoriesScreen(),
                            ),
                          ).then((_) {
                            // Recharge les stats en revenant sur le dashboard au cas où un signalement a été traité
                            _loadStats();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blanc,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.nuit.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.nuit.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
