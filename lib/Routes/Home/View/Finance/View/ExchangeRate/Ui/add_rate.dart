import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../../Features/Other/smart_decimal.dart';
import '../../../../../../../Features/Widgets/extensions.dart';
import '../../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../Currencies/features/currency_drop.dart';
import '../../Currencies/model/ccy_model.dart';
import '../bloc/exchange_rate_bloc.dart';
import '../model/ex_rate_model.dart';

class AddRateView extends StatelessWidget {
  final ExchangeRateModel? rate;

  /// Base currency of the dashboard this dialog was opened from.
  /// Used to reload the correct slice after a successful add.
  final String baseCcy;

  const AddRateView({
    super.key,
    this.rate,
    this.baseCcy = '',
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Desktop(rate: rate, baseCcy: baseCcy),
      tablet: _Desktop(rate: rate, baseCcy: baseCcy),
      desktop: _Desktop(rate: rate, baseCcy: baseCcy),
    );
  }
}

class _Desktop extends StatefulWidget {
  final ExchangeRateModel? rate;
  final String baseCcy;
  const _Desktop({this.rate, required this.baseCcy});

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final TextEditingController rate = TextEditingController();
  String crFrom = 'USD';
  String crTo = 'AFN';

  @override
  void initState() {
    super.initState();
    crFrom = widget.rate?.crFrom ?? 'USD';
    crTo = widget.rate?.crTo ?? 'AFN';
    rate.text = widget.rate?.crExchange.toExchangeRate() ?? '';
  }

  @override
  void dispose() {
    rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final isLoading =
    context.watch<ExchangeRateBloc>().state is ExchangeRateLoadingState;

    return ZFormDialog(
      width: 400,
      icon: Icons.currency_yen_rounded,
      padding: const EdgeInsets.all(8),
      onAction: onSubmit,
      title: "New Rate",
      actionLabel: isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          color: Theme.of(context).colorScheme.surface,
        ),
      )
          : Text(locale.create),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: CurrencyDropdown(
                  title: "From",
                  initiallySelectedSingle: CurrenciesModel(ccyCode: crFrom),
                  isMulti: false,
                  onSingleChanged: (e) {
                    setState(() => crFrom = e?.ccyCode ?? 'USD');
                  },
                  onMultiChanged: (_) {},
                ),
              ),
              Expanded(
                child: CurrencyDropdown(
                  title: "toCurrency",
                  initiallySelectedSingle: CurrenciesModel(ccyCode: crTo),
                  isMulti: false,
                  onSingleChanged: (e) {
                    setState(() => crTo = e?.ccyCode ?? 'AFN');
                  },
                  onMultiChanged: (_) {},
                ),
              ),
            ],
          ),
          ZTextFieldEntitled(
            isRequired: true,
            onFieldSubmitted: (_) => onSubmit(),
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            inputFormat: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
              SmartThousandsDecimalFormatter(decimalDigits: 6),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return locale.required("exchangeRate");
              }
              final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
              final amount = double.tryParse(clean);
              if (amount == null || amount <= 0.0) {
                return "amountGreaterZero";
              }
              return null;
            },
            controller: rate,
            title: "Exchange Rate",
          ),
        ],
      ),
    );
  }

  void onSubmit() {
    // Trim and strip separators before sending.
    final clean = rate.text.replaceAll(RegExp(r'[^\d.]'), '');
    final parsed = double.tryParse(clean);
    if (parsed == null || parsed <= 0) return;

    context.read<ExchangeRateBloc>().add(
      AddExchangeRateEvent(
        newRate: ExchangeRateModel(
          crFrom: crFrom,
          crTo: crTo,
          crExchange: parsed.toString(),
        ),
        baseCcy: widget.baseCcy,
      ),
    );
  }
}