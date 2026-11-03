import 'package:flutter/material.dart';

enum NumberLanguage { en, fa, ps }

class NumberToWords {
  static String convertDecimal(double number, NumberLanguage lang) {
    if (number == 0) {
      return switch (lang) {
        NumberLanguage.fa => 'صفر',
        NumberLanguage.ps => 'صفر',
        _ => 'zero',
      };
    }

    if (number < 0) {
      return '${_negativePrefix(lang)} ${convertDecimal(-number, lang)}';
    }

    int intPart = number.floor();
    int fractionalPart = ((number - intPart) * 100).round();

    String result = convert(intPart, lang);
    if (fractionalPart > 0) {  // Only convert fractional part if it's not zero
      final units = _getUnits(lang);
      final digits = fractionalPart.toString().padLeft(2, '0').split('').map((d) => units[int.parse(d)]).join(' ');
      final pointWord = switch (lang) {
        NumberLanguage.fa => 'ممیز',
        NumberLanguage.ps => 'اشاریه',
        _ => 'point',
      };
      result += ' $pointWord $digits';
    }

    return result.trim();
  }

  static String convert(int number, NumberLanguage lang) {
    if (number == 0) {
      return switch (lang) {
        NumberLanguage.fa => 'صفر',
        NumberLanguage.ps => 'صفر',
        _ => 'zero',
      };
    }

    if (number < 0) {
      return '${_negativePrefix(lang)} ${convert(-number, lang)}';
    }

    return _convert(number, lang).trim();
  }

  static String _convert(int number, NumberLanguage lang) {
    final units = _getUnits(lang);
    final tens = _getTens(lang);
    final hundreds = _getHundreds(lang);

    if (number < 20) {
      return units[number];
    } else if (number < 100) {
      final ten = number ~/ 10;
      final unit = number % 10;
      final tenStr = tens[ten];
      final unitStr = unit > 0 ? units[unit] : '';
      if (lang == NumberLanguage.fa || lang == NumberLanguage.ps) {
        return unit > 0 ? '$tenStr و $unitStr' : tenStr;
      } else {
        return '$tenStr $unitStr'.trim();
      }
    } else if (number < 1000) {
      final hundred = number ~/ 100;
      final remainder = number % 100;
      final hundredStr = hundreds[hundred];
      final remainderStr = remainder > 0 ? _convert(remainder, lang) : '';
      if (lang == NumberLanguage.fa || lang == NumberLanguage.ps) {
        return remainder > 0 ? '$hundredStr و $remainderStr' : hundredStr;
      } else {
        return '$hundredStr $remainderStr'.trim();
      }
    } else if (number < 1000000) {
      final thousands = number ~/ 1000;
      final remainder = number % 1000;
      final thousandsStr = _convert(thousands, lang);
      final thousandWord = _thousand(lang);
      final remainderStr = remainder > 0 ? _convert(remainder, lang) : '';
      if (lang == NumberLanguage.fa || lang == NumberLanguage.ps) {
        return remainder > 0
            ? '$thousandsStr $thousandWord و $remainderStr'
            : '$thousandsStr $thousandWord';
      } else {
        return '$thousandsStr $thousandWord $remainderStr'.trim();
      }
    } else {
      final millions = number ~/ 1000000;
      final remainder = number % 1000000;
      final millionsStr = _convert(millions, lang);
      final millionWord = _million(lang);
      final remainderStr = remainder > 0 ? _convert(remainder, lang) : '';
      if (lang == NumberLanguage.fa || lang == NumberLanguage.ps) {
        return remainder > 0
            ? '$millionsStr $millionWord و $remainderStr'
            : '$millionsStr $millionWord';
      } else {
        return '$millionsStr $millionWord $remainderStr'.trim();
      }
    }
  }

  static NumberLanguage getLanguageFromLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'fa':
        return NumberLanguage.fa;
      case 'ar':
      case 'ps':
        return NumberLanguage.ps;
      default:
        return NumberLanguage.en;
    }
  }

  static List<String> _getUnits(NumberLanguage lang) => switch (lang) {
    NumberLanguage.fa => _unitsFa,
    NumberLanguage.ps => _unitsPs,
    _ => _unitsEn,
  };

  static List<String> _getTens(NumberLanguage lang) => switch (lang) {
    NumberLanguage.fa => _tensFa,
    NumberLanguage.ps => _tensPs,
    _ => _tensEn,
  };

  static List<String> _getHundreds(NumberLanguage lang) => switch (lang) {
    NumberLanguage.fa => _hundredsFa,
    NumberLanguage.ps => _hundredsPs,
    _ => _hundredsEn,
  };

  static String _thousand(NumberLanguage lang) => switch (lang) {
    NumberLanguage.fa => 'هزار',
    NumberLanguage.ps => 'زره',
    _ => 'thousand',
  };

  static String _million(NumberLanguage lang) => switch (lang) {
    NumberLanguage.fa => 'میلیون',
    NumberLanguage.ps => 'ملیون',
    _ => 'million',
  };

  static String _negativePrefix(NumberLanguage lang) => switch (lang) {
    NumberLanguage.fa => 'منفی',
    NumberLanguage.ps => 'منفي',
    _ => 'minus',
  };

  static const _unitsEn = [
    'zero', 'one', 'two', 'three', 'four', 'five',
    'six', 'seven', 'eight', 'nine', 'ten', 'eleven',
    'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen',
    'seventeen', 'eighteen', 'nineteen'
  ];

  static const _tensEn = [
    '', '', 'twenty', 'thirty', 'forty', 'fifty',
    'sixty', 'seventy', 'eighty', 'ninety'
  ];

  static const _hundredsEn = [
    '', 'one hundred', 'two hundred', 'three hundred', 'four hundred',
    'five hundred', 'six hundred', 'seven hundred', 'eight hundred', 'nine hundred'
  ];

  static const _unitsFa = [
    'صفر', 'یک', 'دو', 'سه', 'چهار', 'پنج',
    'شش', 'هفت', 'هشت', 'نه', 'ده', 'یازده',
    'دوازده', 'سیزده', 'چهارده', 'پانزده', 'شانزده',
    'هفده', 'هجده', 'نوزده'
  ];

  static const _tensFa = [
    '', '', 'بیست', 'سی', 'چهل', 'پنجاه',
    'شصت', 'هفتاد', 'هشتاد', 'نود'
  ];

  static const _hundredsFa = [
    '', 'صد', 'دوصد', 'سیصد', 'چهارصد', 'پانصد',
    'ششصد', 'هفتصد', 'هشتصد', 'نهصد'
  ];

  static const _unitsPs = [
    'صفر', 'یو', 'دوه', 'درې', 'څلور', 'پنځه',
    'شپږ', 'اووه', 'اته', 'نهه', 'لس', 'یولس',
    'دولس', 'دیارلس', 'څوارلس', 'پنځلس', 'شپاړلس',
    'اوولس', 'اتلس', 'نولس'
  ];

  static const _tensPs = [
    '', '', 'شل', 'دیرش', 'څلوېښت', 'پنځوس',
    'شپیته', 'اویا', 'اتیا', 'نوي'
  ];

  static const _hundredsPs = [
    '', 'سل', 'دوه سوه', 'درې سوه', 'څلور سوه',
    'پنځه سوه', 'شپږ سوه', 'اووه سوه', 'اته سوه', 'نهه سوه'
  ];
}