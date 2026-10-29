import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterCubit extends Cubit<Printer?> {
  static const String _printerKey = "default_printer_url";

  PrinterCubit() : super(null);

  Future<void> loadSavedPrinter(List<Printer> availablePrinters) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_printerKey);

    if (savedUrl == null) return;

    try {
      final printer = availablePrinters.firstWhere(
            (p) => p.url == savedUrl,
      );

      emit(printer);
    } catch (_) {
      // Printer not found
    }
  }

  Future<void> setPrinter(Printer printer) async {
    emit(printer);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerKey, printer.url);
  }
}
