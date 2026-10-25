import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../l10n/app_localizations.dart';
import 'bloc/currencies_bloc.dart';
import 'model/ccy_model.dart';

class AddEditCurrencyView extends StatefulWidget {
  final CurrenciesModel? currency;
  const AddEditCurrencyView({super.key, this.currency});

  @override
  State<AddEditCurrencyView> createState() => _AddEditCurrencyViewState();
}

class _AddEditCurrencyViewState extends State<AddEditCurrencyView> {
  final TextEditingController ccyCode = TextEditingController();
  final TextEditingController country = TextEditingController();
  final TextEditingController ccySymbol = TextEditingController();
  final TextEditingController ccyLocalName = TextEditingController();
  final TextEditingController ccyCountryCode = TextEditingController();
  final TextEditingController ccyName = TextEditingController();

  final formKey = GlobalKey<FormState>();
  bool _hasChanges = false;
  Map<String, String> _originalValues = {};

  @override
  void initState() {
    super.initState();
    if (widget.currency != null) {
      ccyCode.text = widget.currency!.ccyCode ?? '';
      ccySymbol.text = widget.currency!.ccySymbol ?? '';
      ccyLocalName.text = widget.currency!.ccyLocalName ?? '';
      country.text = widget.currency?.ccyCountry ?? '';
      ccyCountryCode.text = widget.currency!.ccyCountryCode ?? '';
      ccyName.text = widget.currency!.ccyName ?? '';

      _originalValues = {
        'ccyCode': widget.currency?.ccyCode ?? '',
        'ccySymbol': widget.currency?.ccySymbol ?? '',
        'ccyLocalName': widget.currency?.ccyLocalName ?? '',
        'ccyCountry': widget.currency?.ccyCountry ?? '',
        'ccyCountryCode': widget.currency?.ccyCountryCode ?? '',
        'ccyName': widget.currency?.ccyName ?? '',
      };
    }

    _setupChangeListeners();
  }

  void _setupChangeListeners() {
    void checkForChanges() {
      final currentValues = {
        'ccyCode': ccyCode.text,
        'ccySymbol': ccySymbol.text,
        'ccyLocalName': ccyLocalName.text,
        'ccyCountry': country.text,
        'ccyCountryCode': ccyCountryCode.text,
        'ccyName': ccyName.text,
      };

      final hasChanges = currentValues.entries.any(
            (entry) => entry.value != _originalValues[entry.key],
      );

      if (hasChanges != _hasChanges) {
        setState(() {
          _hasChanges = hasChanges;
        });
      }
    }

    ccyCode.addListener(checkForChanges);
    ccySymbol.addListener(checkForChanges);
    ccyLocalName.addListener(checkForChanges);
    ccyCountryCode.addListener(checkForChanges);
    ccyName.addListener(checkForChanges);
    country.addListener(checkForChanges);   // ← was missing
  }

  @override
  void dispose() {
    ccyCode.dispose();
    ccySymbol.dispose();
    ccyLocalName.dispose();
    ccyCountryCode.dispose();
    ccyName.dispose();
    country.dispose();                       // ← was missing
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final isUpdate = widget.currency != null;

    return BlocListener<CurrenciesBloc, CurrenciesState>(
      listener: (context, state) {
        if (state is CurrenciesErrorState) {
          if (!state.message.contains('No changes detected')) {
            // TODO: show SnackBar / error
          }
        } else if (state is CurrenciesSuccessState) {
          Navigator.of(context).pop();
        }
      },
      child: BlocBuilder<CurrenciesBloc, CurrenciesState>(
        builder: (context, state) {
          final isLoading = state is CurrenciesLoadingState;

          return ZFormDialog(
            width: 450,
            isButtonEnabled: _hasChanges || !isUpdate,
            onAction: _hasChanges || !isUpdate
                ? () => onSubmit(isUpdate)
                : null,
            title: isUpdate ? locale.update : 'New',
            actionLabel: isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.surface,
              ),
            )
                : Text(isUpdate ? locale.update : locale.create),
            padding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  ZTextFieldEntitled(
                    title: 'CCY Name',
                    controller: ccyName,
                    isRequired: true,
                    onFieldSubmitted: (_) => onSubmit(isUpdate),
                    validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? locale.required('ccy name')
                        : null,
                  ),
                  Row(
                    spacing: 5,
                    children: [
                      Expanded(
                        child: ZTextFieldEntitled(
                          title: 'Currency Code',
                          controller: ccyCode,
                          isRequired: true,
                          onFieldSubmitted: (_) => onSubmit(isUpdate),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return locale.required('ccy code');
                            }
                            if (value.length > 4) {
                              return 'Code cannot exceed 4 characters.';
                            }
                            return null;
                          },
                          inputFormat: [
                            LengthLimitingTextInputFormatter(4),
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z]')),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ZTextFieldEntitled(
                          title: 'Symbol',
                          controller: ccySymbol,
                          isRequired: true,
                          onFieldSubmitted: (_) => onSubmit(isUpdate),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return locale.required('symbol');
                            }
                            if (value.length > 3) {
                              return 'Symbol cannot exceed 3 characters.';
                            }
                            return null;
                          },
                          inputFormat: [
                            LengthLimitingTextInputFormatter(3),
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z]')),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ZTextFieldEntitled(
                          title: 'Country Code',
                          controller: ccyCountryCode,
                          isRequired: true,
                          onFieldSubmitted: (_) => onSubmit(isUpdate),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return locale.required('country code');
                            }
                            if (value.length > 4) {
                              return 'Country code cannot exceed 4 characters.';
                            }
                            return null;
                          },
                          inputFormat: [
                            LengthLimitingTextInputFormatter(4),
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z]')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ZTextFieldEntitled(
                    title: 'Country',
                    controller: country,
                    isRequired: true,
                    onFieldSubmitted: (_) => onSubmit(isUpdate),
                    validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? locale.required('country')
                        : null,
                  ),
                  ZTextFieldEntitled(
                    title: 'Local Name',
                    controller: ccyLocalName,
                    isRequired: true,
                    onFieldSubmitted: (_) => onSubmit(isUpdate),
                    validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? locale.required('local name')
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void onSubmit(bool isUpdate) {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (isUpdate && !_hasChanges) return;

    final model = CurrenciesModel(
      ccyCode: ccyCode.text.trim(),
      ccyCountry: country.text.trim(),
      ccyLocalName: ccyLocalName.text.trim(),
      ccyName: ccyName.text.trim(),
      ccySymbol: ccySymbol.text.trim(),
      ccyCountryCode: ccyCountryCode.text.trim(),
    );

    final bloc = context.read<CurrenciesBloc>();
    if (isUpdate) {
      bloc.add(UpdateCcyEvent(ccy: model));
    } else {
      bloc.add(AddCcyEvent(ccy: model));
    }
  }
}