import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/service/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  // L'email est requis pour permettre le renvoi du code en cas de perte
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isButtonEnabled = false;
  
  // Gestion du compte à rebours pour le renvoi de code
  Timer? _timer;
  int _startSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _codeController.addListener(_checkCodeLength);
  }

  // Active le bouton de validation uniquement si les 6 chiffres sont saisis
  void _checkCodeLength() {
    setState(() {
      _isButtonEnabled = _codeController.text.trim().length == 6;
    });
  }

  // Démarre un compte à rebours de 60 secondes (Concept UX d'anti-spam)
  void _startCountdown() {
    setState(() {
      _startSeconds = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startSeconds == 0) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _startSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _codeController.removeListener(_checkCodeLength);
    _codeController.dispose();
    _timer?.cancel(); // Très important : annuler le timer pour éviter les fuites de mémoire
    super.dispose();
  }

  // Envoi du code à 6 chiffres à ton endpoint /auth/verify
  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; });

    try {
      final messageResponse = await _authService.verifyEmail(_codeController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageResponse), backgroundColor: AppColors.menthe),
        );
        // Le compte est activé ! On redirige vers la connexion
        Navigator.of(context).pushNamedAndRemoveUntil('/connexion', (route) => false);
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

  // Demande d'un nouveau code à ton endpoint /auth/renvoyer-code
  Future<void> _resendCode() async {
    setState(() { _isLoading = true; });

    try {
      final messageResponse = await _authService.resendCode(widget.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageResponse), backgroundColor: AppColors.menthe),
        );
        _startCountdown(); // On relance le blocage de 60 secondes
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
      backgroundColor: AppColors.blanc,
      appBar: AppBar(
        backgroundColor: AppColors.sable,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Vérification',
          style: TextStyle(color: AppColors.nuit, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: AppColors.nuit),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Code de validation',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.nuit),
                ),
                const SizedBox(height: 12),
                Text(
                  'Saisissez le code à 6 chiffres envoyé à l\'adresse :\n${widget.email}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 48),

                // Champ de saisie stylisé pour l'OTP
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 12),
                  // Contraintes de saisie : uniquement des chiffres et 6 caractères max
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.3), letterSpacing: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.callToAction, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez entrer le code';
                    if (value.length < 6) return 'Le code doit contenir 6 chiffres';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Bouton de validation dynamique
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_isButtonEnabled) ? null : _submitVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.callToAction,
                      foregroundColor: AppColors.blanc,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: AppColors.blanc)
                        : const Text('Vérifier mon compte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),

                // Gestion du renvoi de code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pas reçu de code ? ', style: TextStyle(color: AppColors.nuit)),
                    _canResend
                        ? TextButton(
                            onPressed: _isLoading ? null : _resendCode,
                            child: const Text(
                              'Renvoyer',
                              style: TextStyle(color: AppColors.callToAction, fontWeight: FontWeight.bold),
                            ),
                          )
                        : Text(
                            'Renvoyer dans ${_startSeconds}s',
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}