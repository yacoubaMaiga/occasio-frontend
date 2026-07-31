import 'package:flutter/material.dart';
import 'package:occasio/theme/app_colors.dart';
import 'package:occasio/service/admin_service.dart';
import 'package:occasio/utils/icon_helper.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final data = await _adminService.getCategories();
      if (mounted) {
        setState(() {
          _categories = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCategorieDialog({Map<String, dynamic>? categorieExistante}) {
    final bool isEdit = categorieExistante != null;
    final nomController = TextEditingController(text: isEdit ? categorieExistante['nom'] : '');
    final descController = TextEditingController(text: isEdit ? categorieExistante['description'] : '');
    String selectedIcon = isEdit ? (categorieExistante['icone'] ?? 'defaut') : 'defaut';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.blanc,
              title: Text(isEdit ? 'Modifier catégorie' : 'Nouvelle catégorie', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.nuit)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomController,
                      decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 20),
                    const Align(alignment: Alignment.centerLeft, child: Text('Icône associée :', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: IconHelper.icons.containsKey(selectedIcon) ? selectedIcon : 'defaut',
                      items: IconHelper.icons.keys.map((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Row(
                            children: [
                              Icon(IconHelper.icons[key], color: AppColors.terracotta),
                              const SizedBox(width: 12),
                              Text(key),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedIcon = val!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
                  onPressed: () async {
                    if (nomController.text.isEmpty) return;
                    Navigator.pop(context);
                    
                    try {
                      if (isEdit) {
                        await _adminService.modifierCategorie(categorieExistante['id'], nomController.text, descController.text, selectedIcon);
                      } else {
                        await _adminService.creerCategorie(nomController.text, descController.text, selectedIcon);
                      }
                      _loadCategories();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                    }
                  },
                  child: const Text('Enregistrer', style: TextStyle(color: AppColors.blanc)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _supprimer(int id) async {
    try {
      await _adminService.supprimerCategorie(id);
      _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de supprimer: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.nuit,
        title: const Text('Catégories', style: TextStyle(color: AppColors.blanc, fontSize: 16)),
        iconTheme: const IconThemeData(color: AppColors.blanc),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.terracotta,
        child: const Icon(Icons.add, color: AppColors.blanc),
        onPressed: () => _showCategorieDialog(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Card(
                  color: AppColors.blanc,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.sable,
                      child: Icon(IconHelper.getIcon(cat['icone']), color: AppColors.terracotta),
                    ),
                    title: Text(cat['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(cat['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.nuit), onPressed: () => _showCategorieDialog(categorieExistante: cat)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _supprimer(cat['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}