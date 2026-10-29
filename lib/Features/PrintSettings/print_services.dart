import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_selector/file_selector.dart';
import 'package:shipping/Features/PrintSettings/report_model.dart';

abstract class PrintServices {
  // ── Fonts ────────────────────────────────────────────────
  static late pw.Font _englishRegular;
  static late pw.Font _englishBold;
  static late pw.Font _persianRegular;
  static late pw.Font _persianBold;

  // ── Translations (JSON asset) ────────────────────────────
  static Map<String, Map<String, String>>? _printTranslations;
  static Future<void>? _translationsLoadFuture;

  // ── Init ─────────────────────────────────────────────────

  static Future<void> initializeFonts() async {
    await Future.wait([
      _loadEnglishFonts(),
      _loadPersianFonts(),
      initializeTranslations(),
    ]);
  }

  static Future<void> initializeTranslations() async {
    if (_printTranslations != null) return;
    _translationsLoadFuture ??= _loadTranslationsInternal();
    await _translationsLoadFuture;
  }

  static Future<void> _loadTranslationsInternal() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/l10n/print_translations.json',
      );
      final decoded = json.decode(raw) as Map<String, dynamic>;
      _printTranslations = decoded.map<String, Map<String, String>>(
            (key, value) => MapEntry(
          key,
          Map<String, String>.from(value as Map),
        ),
      );
      debugPrint(
          '✅ Print translations loaded (${_printTranslations!.length} keys)');
    } catch (e) {
      debugPrint('❌ Print translations load failed: $e');
      _printTranslations = const {};
    }
  }

  // ── English fonts ────────────────────────────────────────
  static Future<void> _loadEnglishFonts() async {
    try {
      final regular = await rootBundle.load(
        'assets/fonts/OpenSans/OpenSans-Regular.ttf',
      );
      _englishRegular = pw.Font.ttf(regular);

      final bold = await rootBundle.load(
        'assets/fonts/OpenSans/OpenSans-Bold.ttf',
      );
      _englishBold = pw.Font.ttf(bold);
    } catch (e) {
      debugPrint('❌ English font loading failed: $e');
      _englishRegular = _englishBold = pw.Font.courier();
    }
  }

  // ── Persian fonts ────────────────────────────────────────
  static Future<void> _loadPersianFonts() async {
    try {
      if (kIsWeb) {
        await _loadWebPersianFonts();
      } else {
        await _loadNativePersianFonts();
      }
    } catch (e) {
      debugPrint('❌ Persian font loading failed: $e');
      _persianRegular = _persianBold = pw.Font.courier();
    }
  }

  static Future<void> _loadWebPersianFonts() async {
    try {
      final regular = await rootBundle.load(
        'assets/fonts/NotoNaskh/NotoNaskhArabic-Regular.ttf',
      );
      _persianRegular = pw.Font.ttf(regular);

      final bold = await rootBundle.load(
        'assets/fonts/NotoNaskh/NotoNaskhArabic-Bold.ttf',
      );
      _persianBold = pw.Font.ttf(bold);
    } catch (e) {
      await _loadNativePersianFonts();
    }
  }

  static Future<void> _loadNativePersianFonts() async {
    final regular = await rootBundle.load(
      'assets/fonts/Amiri/Amiri-Regular.ttf',
    );
    _persianRegular = pw.Font.ttf(regular);

    final bold = await rootBundle.load(
      'assets/fonts/Amiri/Amiri-Bold.ttf',
    );
    _persianBold = pw.Font.ttf(bold);
  }

  // ── Font selection ───────────────────────────────────────
  static pw.Font _getFont({
    required String text,
    required pw.FontWeight? fontWeight,
  }) {
    final isPersian = _isPersian(text);
    try {
      if (fontWeight != null && fontWeight.index >= pw.FontWeight.bold.index) {
        return isPersian ? _persianBold : _englishBold;
      }
      return isPersian ? _persianRegular : _englishRegular;
    } catch (_) {
      return pw.Font.courier();
    }
  }

  static bool _isPersian(String text) {
    final persianRegex = RegExp(r'[\u0600-\u06FF]');
    return persianRegex.hasMatch(text);
  }

  static pw.TextDirection _textDirection({required String text}) {
    return _isPersian(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  }

  static pw.TextStyle _textStyle({
    required String text,
    double? fontSize,
    PdfColor? color,
    pw.FontWeight? fontWeight,
    pw.FontStyle? fontStyle,
  }) {
    return pw.TextStyle(
      color: color,
      font: _getFont(text: text, fontWeight: fontWeight),
      fontWeight: fontWeight,
      fontSize: fontSize,
      fontStyle: fontStyle,
    );
  }

  // ── Header ───────────────────────────────────────────────
  Future<pw.Widget> header({required ReportModel report}) async {
    final phoneIcon = pw.MemoryImage(
      (await rootBundle.load('assets/images/phone.png')).buffer.asUint8List(),
    );
    final whatsappIcon = pw.MemoryImage(
      (await rootBundle.load('assets/images/whatsapp.png')).buffer.asUint8List(),
    );
    final emailIcon = pw.MemoryImage(
      (await rootBundle.load('assets/images/email.png')).buffer.asUint8List(),
    );
    final websiteIcon = pw.MemoryImage(
      (await rootBundle.load('assets/images/internet.png')).buffer.asUint8List(),
    );
    final instagramIcon = pw.MemoryImage(
      (await rootBundle.load('assets/images/instagram.png'))
          .buffer
          .asUint8List(),
    );
    final facebookIcon = pw.MemoryImage(
      (await rootBundle.load('assets/images/facebook.png')).buffer.asUint8List(),
    );
    final addressIcon = pw.MemoryImage(
      (await rootBundle.load('assets/images/location.png')).buffer.asUint8List(),
    );

    final bool hasCompanyLogo = report.comLogo != null &&
        report.comLogo is Uint8List &&
        report.comLogo!.isNotEmpty;

    pw.ImageProvider? logoImage;
    if (hasCompanyLogo) {
      logoImage = pw.MemoryImage(report.comLogo!);
    }

    // ── Colors (PdfColor / PdfColors live in pdf.dart, no `pw.`) ──
    final primaryColor = PdfColor.fromHex('#1E407C');
    final accentColor = PdfColor.fromHex('#00A8E8');
    final softBg = PdfColor.fromHex('#EFF4FA');
    final iconBg = PdfColor.fromHex('#E6F0FA');

    pw.Widget contactRow({
      required pw.ImageProvider icon,
      required String text,
      pw.FontWeight weight = pw.FontWeight.normal,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 0.5),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            zText(
              text: text,
              fontSize: 8.5,
              fontWeight: weight,
              color: PdfColors.grey900,
            ),
            pw.SizedBox(width: 3),
            pw.Container(
              width: 11,
              height: 11,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: iconBg,
                borderRadius: pw.BorderRadius.circular(5.5),
              ),
              child: pw.Image(icon, width: 6.5, height: 6.5),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Stack(
          children: [
            pw.Positioned(
              top: -50,
              right: -50,
              child: pw.Container(
                width: 125,
                height: 128,
                decoration: pw.BoxDecoration(
                  color: softBg,
                  shape: pw.BoxShape.circle,
                ),
              ),
            ),
            pw.Positioned(
              bottom: -55,
              left: -55,
              child: pw.Container(
                width: 125,
                height: 135,
                decoration: pw.BoxDecoration(
                  color: softBg,
                  shape: pw.BoxShape.circle,
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoImage != null)
                          pw.Container(
                            width: 50,
                            height: 50,
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                        zText(
                          text: report.comName ?? "",
                          fontSize: 17,
                          tightBounds: true,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                        if (report.slogan != null &&
                            report.slogan!.isNotEmpty) ...[
                          pw.SizedBox(height: 1),
                          zText(
                            text: report.slogan!,
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ],
                        if (report.comAddress != null &&
                            report.comAddress!.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: 17,
                                height: 17,
                                alignment: pw.Alignment.center,
                                decoration: pw.BoxDecoration(
                                  color: iconBg,
                                  borderRadius: pw.BorderRadius.circular(2),
                                ),
                                child: pw.Image(addressIcon,
                                    width: 12, height: 12),
                              ),
                              pw.SizedBox(width: 4),
                              zText(
                                text: report.comAddress!,
                                fontSize: 9.5,
                                color: PdfColors.grey900,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 1, right: 2),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          if (report.compPhone != null &&
                              report.compPhone!.isNotEmpty)
                            contactRow(
                              icon: phoneIcon,
                              text: report.compPhone!,
                              weight: pw.FontWeight.bold,
                            ),
                          if (report.comWhatsApp != null &&
                              report.comWhatsApp!.isNotEmpty)
                            contactRow(
                              icon: whatsappIcon,
                              text: report.comWhatsApp!,
                            ),
                          if (report.comEmail != null &&
                              report.comEmail!.isNotEmpty)
                            contactRow(
                                icon: emailIcon, text: report.comEmail!),
                          if (report.comWebsite != null &&
                              report.comWebsite!.isNotEmpty)
                            contactRow(
                              icon: websiteIcon,
                              text: report.comWebsite!,
                            ),
                          if (report.comFacebook != null &&
                              report.comFacebook!.isNotEmpty)
                            contactRow(
                              icon: facebookIcon,
                              text: report.comFacebook!,
                            ),
                          if (report.comInstagram != null &&
                              report.comInstagram!.isNotEmpty)
                            contactRow(
                              icon: instagramIcon,
                              text: report.comInstagram!,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.Container(
          height: 3,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [primaryColor, accentColor],
            ),
          ),
        ),
      ],
    );
  }

  // ── Footer ───────────────────────────────────────────────
  pw.Widget pageNumber({
    required pw.Context context,
    required String language,
  }) {
    return buildPage(context.pageNumber, context.pagesCount, language);
  }

  pw.Widget footer({
    required ReportModel report,
    required pw.Context context,
    required String language,
    required pw.MemoryImage logoImage,
  }) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            buildPage(context.pageNumber, context.pagesCount, language),
            pw.Row(
              children: [
                zText(
                  text: tr(text: 'printedBy', tr: language),
                  color: PdfColors.grey700,
                  fontSize: 9,
                ),
                pw.SizedBox(width: 5),
                zText(text: report.usrPrintedBy ?? '', fontSize: 9),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Save dialog ──────────────────────────────────────────
  Future<File?> saveDocument({
    required String suggestedName,
    required pw.Document pdf,
  }) async {
    try {
      final FileSaveLocation? fileSaveLocation = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'PDF Files',
            extensions: ['pdf'],
          ),
        ],
      );

      if (fileSaveLocation == null) return null;

      String filePath = fileSaveLocation.path;
      if (!filePath.toLowerCase().endsWith('.pdf')) {
        filePath += '.pdf';
      }

      final bytes = await pdf.save();
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  // ── Text helpers ─────────────────────────────────────────
  pw.Widget zText({
    required String text,
    double? fontSize,
    pw.FontWeight? fontWeight,
    bool? tightBounds,
    PdfColor? color,
    pw.TextAlign? textAlign,
    pw.FontStyle? fontStyle,
  }) {
    if (text.isEmpty) return pw.SizedBox();

    return pw.Text(
      text,
      textAlign: textAlign,
      style: _textStyle(
        text: text,
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
      ),
      textDirection: _textDirection(text: text),
    );
  }

  pw.Widget buildPage(int currentPage, int totalPages, String language) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 1),
      child: zText(
        text:
        '${tr(text: 'page', tr: language)} $currentPage ${tr(text: 'of', tr: language)} $totalPages',
        fontSize: 8,
      ),
    );
  }

  Future<pw.ImageProvider?> loadNetworkImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http
          .get(Uri.parse('https://www.zaitoonsoft.com/rapi/uploads/$url'));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  pw.Widget verticalDivider({
    required double height,
    required double width,
  }) {
    return pw.Container(
      height: height,
      width: width,
      color: PdfColors.grey500,
      margin: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    );
  }

  pw.Widget horizontalDivider({double? width}) {
    return pw.Container(
      height: 0.5,
      width: width ?? double.infinity,
      color: PdfColors.grey300,
      margin: const pw.EdgeInsets.symmetric(vertical: 1, horizontal: 0),
    );
  }

  pw.Widget buildSummary({
    required String label,
    required String value,
    double? fontSize,
    PdfColor? color,
    double distance = 100,
    bool isEmphasized = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: distance,
            child: zText(
              color: color,
              text: label,
              fontWeight:
              isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: fontSize ?? 9,
            ),
          ),
          zText(
            text: value,
            fontSize: fontSize ?? 9,
            fontWeight:
            isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
            textAlign: pw.TextAlign.right,
          ),
        ],
      ),
    );
  }

  PdfColor hexToPdfColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    } else if (hexColor.length == 8) {
      hexColor = '${hexColor.substring(6, 8)}${hexColor.substring(0, 6)}';
    }

    try {
      return PdfColor.fromInt(int.parse(hexColor, radix: 16));
    } catch (e) {
      return PdfColors.black;
    }
  }

  pw.Widget buildTotalSummary({
    required String label,
    required String value,
    double? width,
    double? space,
    PdfColor? color,
    String? ccySymbol,
    pw.TextAlign? align,
    bool isEmphasized = false,
    bool applyBalanceColor = false,
    double? balanceValue,
  }) {
    PdfColor? finalColor = color;
    if (applyBalanceColor && balanceValue != null) {
      if (balanceValue < 0) {
        finalColor = PdfColors.red;
      } else if (balanceValue > 0) {
        finalColor = PdfColors.green;
      } else {
        finalColor = PdfColors.black;
      }
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: width ?? 100,
            child: zText(
              color: finalColor,
              text: label,
              fontWeight:
              isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 9,
            ),
          ),
          pw.SizedBox(width: space ?? 30),
          pw.Row(
            children: [
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight:
                  isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
                  font: _englishBold,
                  color: finalColor,
                ),
                textAlign: align ?? pw.TextAlign.center,
              ),
              if (ccySymbol != null && ccySymbol.isNotEmpty) ...[
                pw.SizedBox(width: 3),
                zText(
                  text: ccySymbol,
                  tightBounds: true,
                  fontSize: 8,
                  fontWeight: isEmphasized
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  color: finalColor,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  pw.TextDirection documentLanguage({required String language}) {
    return language == 'en' ? pw.TextDirection.ltr : pw.TextDirection.rtl;
  }

  // ── Translations (JSON-backed) ───────────────────────────
  String tr({required String text, required String tr}) {
    final table = _printTranslations;
    if (table == null) {
      debugPrint(
          '⚠️ PrintServices.tr called before translations loaded — call initializeFonts() first');
      return text;
    }
    final entry = table[text];
    if (entry == null) return text;
    return entry[tr] ?? entry['en'] ?? text;
  }
}