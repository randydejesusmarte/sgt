import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Retorna una máscara de texto para formatear números de teléfono con ###-###-####
MaskTextInputFormatter createPhoneMaskFormatter({String? initialText}) {
  return MaskTextInputFormatter(
    mask: '###-###-####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
    initialText: initialText,
  );
}

/// Formatea una cadena de teléfono al formato ###-###-####
String formatTelefono(String? phone) {
  if (phone == null || phone.trim().isEmpty) return '';
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
  } else if (digits.length == 11 && digits.startsWith('1')) {
    return '${digits.substring(1, 4)}-${digits.substring(4, 7)}-${digits.substring(7)}';
  }
  return phone;
}

/// Convierte un texto a Title Case (primera letra de cada palabra en mayúscula)
String toTitleCase(String text) {
  if (text.trim().isEmpty) return text;
  return text.replaceAll(RegExp(r'\s+'), ' ').split(' ').map((word) {
    if (word.isEmpty) return '';
    if (word.length == 1) return word.toUpperCase();
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}
