// lib/Routes/Home/View/Finance/View/Currencies/features/currency_drop.dart
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../../../Features/zdropdown.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../bloc/currencies_bloc.dart';
import '../model/ccy_model.dart';

class CurrencyDropdown extends StatefulWidget {
  final String? title;
  final bool isMulti;
  final double height;
  final bool disableAction;
  final bool flag;
  final ValueChanged<List<CurrenciesModel>>? onMultiChanged;
  final ValueChanged<CurrenciesModel?>? onSingleChanged;
  final List<CurrenciesModel>? initiallySelected;
  final CurrenciesModel? initiallySelectedSingle;

  /// 👇 NEW: when true, the list gains an "All currencies" entry
  /// whose `ccyCode` is `''`. The widget also defaults to that entry
  /// when `initiallySelectedSingle` is null.
  final bool allowAll;

  const CurrencyDropdown({
    super.key,
    this.isMulti = false,
    this.onMultiChanged,
    this.onSingleChanged,
    this.height = 40,
    this.flag = true,
    this.disableAction = false,
    this.title,
    this.initiallySelected,
    this.initiallySelectedSingle,
    this.allowAll = false,
  })  : assert(!isMulti || onMultiChanged != null,
  'onMultiChanged must be provided when isMulti is true'),
        assert(isMulti || onSingleChanged != null,
        'onSingleChanged must be provided when isMulti is false');

  @override
  State<CurrencyDropdown> createState() => _CurrencyDropdownState();
}

class _CurrencyDropdownState extends State<CurrencyDropdown> {
  List<CurrenciesModel> _selectedMulti = [];
  CurrenciesModel? _selectedSingle;
  String? defaultCcy;

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      defaultCcy = authState.loginData.company?.comLocalCcy ?? "";
    }

    context.read<CurrenciesBloc>().add(LoadCurrenciesEvent(status: 1));

    if (widget.isMulti) {
      _selectedMulti = widget.initiallySelected ?? [];
    } else {
      if (widget.allowAll) {
        // Default to "All currencies".
        _selectedSingle =
            widget.initiallySelectedSingle ?? CurrenciesModel(ccyCode: '');
      } else {
        _selectedSingle = CurrenciesModel(ccyCode: defaultCcy);
        _selectedSingle =
            widget.initiallySelectedSingle ?? _selectedSingle;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrenciesBloc, CurrenciesState>(
      builder: (context, state) {
        final bool isLoading = state is CurrenciesLoadingState;

        if (state is CurrenciesErrorState) {
          return Text('Error: ${state.message}');
        }

        List<CurrenciesModel> currencies = [];
        if (state is CurrenciesLoadedState) {
          currencies = state.active.cast<CurrenciesModel>();
        }

        // ── NEW: prepend "All currencies" when allowed ────────
        final items = widget.allowAll
            ? [CurrenciesModel(ccyCode: ''), ...currencies]
            : currencies;

        // ── NEW: safe value — never pass a ccy the list doesn't have ──
        CurrenciesModel? safeSelected = _selectedSingle;
        if (!widget.isMulti) {
          if (safeSelected == null) {
            safeSelected =
            widget.allowAll ? CurrenciesModel(ccyCode: '') : null;
          } else if (!items.any((c) => c.ccyCode == safeSelected!.ccyCode)) {
            safeSelected =
            widget.allowAll ? CurrenciesModel(ccyCode: '') : null;
          }
        }

        return ZDropdown<CurrenciesModel>(
          disableAction: widget.disableAction,
          title: widget.title,
          height: widget.height,
          leadingBuilder: (CurrenciesModel ccy) {
            // "All currencies" gets a globe icon instead of a flag.
            if (ccy.ccyCode == '' && widget.allowAll) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 30,
                alignment: Alignment.center,
                child: const Icon(Icons.public, size: 18),
              );
            }
            if (widget.flag) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 30,
                child: Flag.fromString(
                  ccy.ccyCountryCode ?? "",
                  height: 20,
                  width: 30,
                  borderRadius: 2,
                  fit: BoxFit.fill,
                ),
              );
            }
            return const SizedBox.shrink();
          },
          items: items,
          multiSelect: widget.isMulti,
          selectedItems: widget.isMulti ? _selectedMulti : [],
          selectedItem: widget.isMulti ? null : safeSelected,
          itemLabel: (item) =>
          item.ccyCode == '' && widget.allowAll
              ? 'All currencies'
              : (item.ccyCode ?? ""),
          initialValue: widget.allowAll
              ? 'All currencies'
              : (defaultCcy ?? AppLocalizations.of(context)!.currencyTitle),
          onMultiSelectChanged: widget.isMulti
              ? (selected) {
            setState(() => _selectedMulti = selected);
            widget.onMultiChanged?.call(selected);
          }
              : null,
          onItemSelected: widget.isMulti
              ? (_) {}
              : (item) {
            setState(() => _selectedSingle = item);
            widget.onSingleChanged?.call(item);
          },
          isLoading: isLoading,
        );
      },
    );
  }
}