import 'package:flutter/services.dart';

class MaliPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    
    // Gère le cas où l'utilisateur efface tout d'un coup
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '+223 ',
        selection: TextSelection.collapsed(offset: 5),
      );
    }

    final text = newValue.text;

    // Empêche d'effacer le préfixe "+223 "
    if (text.length < 5) {
      return const TextEditingValue(
        text: '+223 ',
        selection: TextSelection.collapsed(offset: 5),
      );
    }

    // Force le début avec "+223 "
    if (!text.startsWith('+223 ')) {
      return oldValue;
    }

    // Extrait uniquement les chiffres tapés APRÈS le préfixe "+223 "
    final digitsOnly = text.substring(5).replaceAll(RegExp(r'\D'), '');
    
    // Limite stricte à 8 chiffres (réseau malien)
    final truncatedDigits = digitsOnly.length > 8 ? digitsOnly.substring(0, 8) : digitsOnly;

    final buffer = StringBuffer('+223 ');
    for (int i = 0; i < truncatedDigits.length; i++) {
      if (i > 0 && i % 2 == 0) {
        buffer.write(' '); // Ajoute un espace tous les 2 chiffres
      }
      buffer.write(truncatedDigits[i]);
    }

    final formattedString = buffer.toString();
    
    return TextEditingValue(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length),
    );
  }

  static String formatInitial(String? phone) {
    if (phone == null || phone.trim().isEmpty || phone.trim() == '+223') {
      return '+223 ';
    }
    final clean = phone.replaceAll(' ', '');
    if (clean.startsWith('+223') && clean.length == 12) {
      return '+223 ${clean.substring(4, 6)} ${clean.substring(6, 8)} ${clean.substring(8, 10)} ${clean.substring(10, 12)}';
    }
    return '+223 ';
  }
}