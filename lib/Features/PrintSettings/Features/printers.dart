import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import '../../../l10n/app_localizations.dart';
import '../../zdropdown.dart';
import '../bloc/Printer/printer_cubit.dart';

class PrinterDropdown extends StatefulWidget {
  final Function(Printer) onPrinterSelected;

  const PrinterDropdown({super.key, required this.onPrinterSelected});

  @override
  State<PrinterDropdown> createState() => _PrinterDropdownState();
}

class _PrinterDropdownState extends State<PrinterDropdown> {
  List<Printer> _printers = [];
  bool _isLoading = true;
  bool _noPrinters = false;

  @override
  void initState() {
    super.initState();
    _fetchPrinters();
  }

  Future<void> _fetchPrinters() async {
    try {
      final printers = await Printing.listPrinters();

      if (!mounted) return;

      if (printers.isEmpty) {
        setState(() {
          _isLoading = false;
          _noPrinters = true;
        });
        return;
      }

      final cubit = context.read<PrinterCubit>();

      setState(() {
        _printers = printers;
        _isLoading = false;
        _noPrinters = false;
      });

      await cubit.loadSavedPrinter(printers);

      if (cubit.state == null) {
        await cubit.setPrinter(printers.first);
      }

      widget.onPrinterSelected(cubit.state!);

    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _noPrinters = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPrinter = context.watch<PrinterCubit>().state;

    // 🔄 Loading State
    if (_isLoading) {
      return ZDropdown<Printer>(
        title: AppLocalizations.of(context)!.printers,
        isLoading: true,
        items: const [],
        initialValue: "",
        itemLabel: (printer) => "",
        onItemSelected: (_) {},
      );
    }

    // ❌ No Printers State
    if (_noPrinters) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: .4),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.print_disabled,
                size: 18,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(
              "No printers found",
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Normal Dropdown
    return ZDropdown<Printer>(
      itemStyle: const TextStyle(fontSize: 11),
      title: AppLocalizations.of(context)!.printers,
      isLoading: false,
      initialValue: selectedPrinter?.name ?? "",
      items: _printers,
      itemLabel: (printer) => printer.name,
      onItemSelected: (printer) async {
        await context.read<PrinterCubit>().setPrinter(printer);
        widget.onPrinterSelected(printer);
      },
    );
  }
}

