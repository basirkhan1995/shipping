import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class SmartThousandsDecimalFormatter extends TextInputFormatter {
  final int decimalDigits;
  final NumberFormat _formatter = NumberFormat("#,##0");

  SmartThousandsDecimalFormatter({this.decimalDigits = 4});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final raw = newValue.text.replaceAll(',', '');

    // Allow empty or just decimal point
    if (raw.isEmpty || raw == '.') {
      return newValue;
    }

    // Dynamic decimal validation
    final valid = RegExp(r'^\d*\.?\d{0,' + decimalDigits.toString() + r'}$');
    if (!valid.hasMatch(raw)) {
      return oldValue;
    }

    final parts = raw.split('.');
    final intPartRaw = parts[0];
    final decPart = parts.length > 1 ? parts[1] : null;

    String formattedInt = '';
    if (intPartRaw.isNotEmpty) {
      try {
        formattedInt = _formatter.format(int.parse(intPartRaw));
      } catch (_) {
        return oldValue;
      }
    }

    final newText = decPart != null
        ? '$formattedInt.$decPart'
        : formattedInt;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
