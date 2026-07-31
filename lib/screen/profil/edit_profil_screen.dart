import 'package:flutter/material.dart';
import 'package:occasio/theme/app_colors.dart';
import 'package:occasio/service/profil_service.dart';

class EditProfilScreen extends StatefulWidget {
  final Map<String, dynamic> profilData;

  const EditProfilScreen({super.key, required this.profilData});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final ProfilService _profilService = ProfilService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _prenomController;
  late TextEditingController _nomController;
  late TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _prenomController = TextEditingController(
      text: widget.profilData['firstName'],
    );
    _nomController = TextEditingController(text: widget.profilData['lastName']);
    _phoneController = TextEditingController(
      text: widget.profilData['phoneNumber'],
    );
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    // Masquer le clavier
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);
    try {
      await _profilService.modifierProfil(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _phoneController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès !'),
            backgroundColor: AppColors.menthe,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la sauvegarde.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.blanc,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Mes informations',
          style: TextStyle(
            color: AppColors.nuit,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: const BackButton(color: AppColors.nuit),
      ),
      body: _isSaving
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Petit texte d'introduction
                          Text(
                            'Gérez vos données personnelles.',
                            style: TextStyle(
                              color: AppColors.nuit.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Formulaire
                          _buildPremiumField(
                            label: 'Prénom',
                            hint: 'Entrez votre prénom',
                            icon: Icons.person_outline_rounded,
                            controller: _prenomController,
                          ),
                          const SizedBox(height: 20),
                          _buildPremiumField(
                            label: 'Nom de famille',
                            hint: 'Entrez votre nom',
                            icon: Icons.badge_outlined,
                            controller: _nomController,
                          ),
                          const SizedBox(height: 20),
                          _buildPremiumField(
                            label: 'Numéro de téléphone',
                            hint: 'Ex: +223 70 00 00 00',
                            icon: Icons.phone_outlined,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bouton de sauvegarde fixe en bas
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blanc,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.nuit.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _sauvegarder,
                      child: const Text(
                        'Sauvegarder les modifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPremiumField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.nuit,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.nuit.withValues(alpha: 0.3),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.terracotta.withValues(alpha: 0.8),
              size: 22,
            ),
            filled: true,
            fillColor: AppColors.blanc,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.sable.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.terracotta,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Ce champ est obligatoire' : null,
        ),
      ],
    );
  }
}
