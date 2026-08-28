import 'package:flutter/services.dart';

class LicenseKey {
  static const int payloadLength = 12;
  static const int checksumLength = 4;
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const String _namespace = 'PHARMAGUINE-LICENCE-V1';

  static String normalize(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  static String format(String value) {
    final normalized = normalize(value);
    final limited = normalized.substring(0, normalized.length.clamp(0, 16));
    final groups = <String>[];
    for (var index = 0; index < limited.length; index += 4) {
      groups
          .add(limited.substring(index, (index + 4).clamp(0, limited.length)));
    }
    return groups.join('-');
  }

  static bool hasValidFormat(String value) {
    final formatted = format(value);
    final normalized = normalize(value);
    return RegExp(r'^[A-Z0-9]{4}(?:-[A-Z0-9]{4}){3}$').hasMatch(formatted) &&
        RegExp(r'[A-Z]').hasMatch(normalized) &&
        RegExp(r'[0-9]').hasMatch(normalized);
  }

  static bool isValid(String value) {
    if (!hasValidFormat(value)) return false;
    final normalized = normalize(value);
    final payload = normalized.substring(0, payloadLength);
    return normalized.substring(payloadLength) == _checksum(payload);
  }

  // La future application génératrice peut utiliser cette même méthode.
  static String generateFromPayload(String payload) {
    final normalized = normalize(payload);
    if (normalized.length != payloadLength ||
        !RegExp(r'[A-Z]').hasMatch(normalized) ||
        !RegExp(r'[0-9]').hasMatch(normalized)) {
      throw const FormatException(
          'Le payload doit contenir 12 lettres/chiffres avec au moins une lettre et un chiffre.');
    }
    return format('$normalized${_checksum(normalized)}');
  }

  static String _checksum(String payload) {
    var hash = 0x811C9DC5;
    for (final code in '$_namespace:$payload'.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    final result = StringBuffer();
    for (var index = 0; index < checksumLength; index++) {
      result.write(_alphabet[hash & 31]);
      hash = ((hash >> 5) ^ (hash * 1103515245)) & 0xFFFFFFFF;
    }
    return result.toString();
  }
}

class LicenseKeyFormatter extends TextInputFormatter {
  const LicenseKeyFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final formatted = LicenseKey.format(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
