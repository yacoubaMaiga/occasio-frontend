import 'package:flutter/material.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/screen/auth/services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Tous les contrôleurs requis par ton backend
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Optionnel
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // États de l'UI
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isButtonEnabled = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // On écoute uniquement les champs OBLIGATOIRES pour activer le bouton
    _firstNameController.addListener(_checkFieldsNotEmpty);
    _lastNameController.addListener(_checkFieldsNotEmpty);
    _usernameController.addListener(_checkFieldsNotEmpty);
    _emailController.addListener(_checkFieldsNotEmpty);
    _passwordController.addListener(_checkFieldsNotEmpty);
    _confirmPasswordController.addListener(_checkFieldsNotEmpty);
  }

  void _checkFieldsNotEmpty() {
    setState(() {
      _isButtonEnabled = _firstNameController.text.trim().isNotEmpty &&
                         _lastNameController.text.trim().isNotEmpty &&
                         _usernameController.text.trim().isNotEmpty &&
                         _emailController.text.trim().isNotEmpty &&
                         _passwordController.text.isNotEmpty &&
                         _confirmPasswordController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validation du formulaire (regex, mots de passe identiques, etc.)
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; });

    try {
      // Appel de la méthode register que nous avons créée dans AuthService
      final message = await _authService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(), // Peut être vide
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        // Message de succès du backend (ex: "Inscription réussie, veuillez vérifier votre email.")
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.menthe),
        );
        
        Navigator.of(context).pushReplacementNamed(
          '/verification',
          arguments: _emailController.text.trim(), // On transmet l'email pour le Timer/Renvoi
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.sable,
        elevation: 0,
        title: const Text(
          'Inscription',
          style: TextStyle(color: AppColors.nuit, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: AppColors.nuit),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Rejoignez Occasio !',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.nuit, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Créez votre compte pour commencer à acheter et vendre.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // --- LIGNE PRÉNOM & NOM ---
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Prénom',
                            prefixIcon: const Icon(Icons.person_outline, color: AppColors.nuit),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
                            ),
                          ),
                          validator: (value) => value!.isEmpty ? 'Requis' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
                            ),
                          ),
                          validator: (value) => value!.isEmpty ? 'Requis' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- CHAMP USERNAME ---
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Nom d\'utilisateur (Pseudo)',
                      prefixIcon: const Icon(Icons.alternate_email, color: AppColors.nuit),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Veuillez choisir un pseudo';
                      if (value.length < 3) return 'Le pseudo doit contenir au moins 3 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- CHAMP EMAIL ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Adresse e-mail',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.nuit),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Veuillez renseigner votre e-mail';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'E-mail invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- CHAMP TÉLÉPHONE (Optionnel) ---
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone (Optionnel)',
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.nuit),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- CHAMP MOT DE PASSE ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.nuit),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Veuillez créer un mot de passe';
                      // Validation "Strong Password" similaire à ton backend
                      if (value.length < 8) return 'Minimum 8 caractères';
                      if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) return 'Au moins une majuscule';
                      if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) return 'Au moins un chiffre';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- CHAMP CONFIRMATION MOT DE PASSE ---
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(),
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.nuit),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Veuillez confirmer le mot de passe';
                      if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // --- BOUTON D'INSCRIPTION ---
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_isButtonEnabled) ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.callToAction,
                        foregroundColor: AppColors.blanc,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.blanc, strokeWidth: 3))
                          : const Text('S\'inscrire', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- LIEN VERS CONNEXION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Vous avez déjà un compte ?", style: TextStyle(color: AppColors.nuit)),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/connexion'),
                        child: const Text("Se connecter", style: TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}