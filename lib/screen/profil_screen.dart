import 'package:flutter/material.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/core/token_storage.dart';
import 'package:occasio/service/profil_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ProfilService _profilService = ProfilService();
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _email = '';
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfilData();
  }

  Future<void> _fetchProfilData() async {
    try {
      final data = await _profilService.getMonProfil();
      setState(() {
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _email = data['email'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack(e.toString(), Colors.redAccent);
    }
  }

  Future<void> _saveProfilChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _profilService.modifierProfil(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      _showSnack('Profil mis à jour avec succès !', AppColors.menthe);
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack(e.toString(), Colors.redAccent);
    }
  }

  Future<void> _handleLogout() async {
    await TokenStorage.deleteToken();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (route) => false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.sable,
        elevation: 0,
        title: const Text('Mon Profil', style: TextStyle(color: AppColors.nuit, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: AppColors.nuit),
            onPressed: () {
              setState(() {
                if (_isEditing) _fetchProfilData(); // Annuler remet les anciennes valeurs
                _isEditing = !_isEditing;
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar d'en-tête
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.sable,
                      child: Text(
                        _firstNameController.text.isNotEmpty ? _firstNameController.text[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.terracotta),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '@${_usernameController.text}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.nuit),
                ),
              ),
              Center(
                child: Text(
                  _email,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),

              // Formulaire ou affichage des détails
              _buildProfileField('Prénom', _firstNameController, Icons.person_outline),
              const SizedBox(height: 16),
              _buildProfileField('Nom', _lastNameController, Icons.person_outline),
              const SizedBox(height: 16),
              _buildProfileField('Nom d\'utilisateur', _usernameController, Icons.alternate_email),
              const SizedBox(height: 16),
              _buildProfileField('Téléphone', _phoneController, Icons.phone_outlined, isRequired: false),
              const SizedBox(height: 32),

              // Bouton conditionnel (Enregistrer ou Déconnexion)
              if (_isEditing)
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfilChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Enregistrer les modifications', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _handleLogout,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Se déconnecter', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller, IconData icon, {bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      validator: (v) => (isRequired && (v == null || v.trim().isEmpty)) ? 'Ce champ est requis' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.terracotta),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: !_isEditing,
        fillColor: Colors.grey.shade100,
      ),
    );
  }
}