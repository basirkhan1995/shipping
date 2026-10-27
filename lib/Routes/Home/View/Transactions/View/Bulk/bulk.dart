// features/journal/bulk/view/bulk_transfer_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/model/stk_model.dart';
import 'package:shipping/l10n/app_localizations.dart';

import '../../../../../../../../Features/Widgets/z_dialog.dart';
import '../../../../../../../../Features/Widgets/toast.dart';
import '../../../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../../../Services/repository.dart';
import '../../../Finance/View/Currencies/features/currency_drop.dart';
import '../../../Finance/View/Currencies/model/ccy_model.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import 'bloc/bulk_transfer_bloc.dart';
import 'bloc/bulk_transfer_event.dart';
import 'bloc/bulk_transfer_state.dart';
import 'model/bulk_model.dart';

Future<bool?> showBulkTransferDialog(
    BuildContext context, {
      required String usrName,
      required String baseCurrency,
    }) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider(
      create: (ctx) => BulkTransferBloc(ctx.read<Repositories>()),
      child: _BulkTransferDialog(
        usrName: usrName,
        baseCurrency: baseCurrency,
      ),
    ),
  );
}

class _BulkTransferDialog extends StatefulWidget {
  final String usrName;
  final String baseCurrency;
  const _BulkTransferDialog({
    required this.usrName,
    required this.baseCurrency,
  });

  @override
  State<_BulkTransferDialog> createState() => _BulkTransferDialogState();
}

class _BulkTransferDialogState extends State<_BulkTransferDialog> {
  late String _headerCurrency;
  final Map<int, _RowControllers> _controllers = {};

  /// API error — rendered as the top banner inside the form, cleared on
  /// any edit or on the next submit.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _headerCurrency = widget.baseCurrency;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  _RowControllers _ctrlFor(BulkTransferRow row) =>
      _controllers.putIfAbsent(row.rowId, () => _RowControllers(row));

  void _dispatch(BulkTransferEvent event) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
    context.read<BulkTransferBloc>().add(event);
  }

  void _changeHeaderCurrency(String ccy) {
    setState(() {
      _headerCurrency = ccy;
      _errorMessage = null;
    });
    final cur = context.read<BulkTransferBloc>().state;
    if (cur is BulkTransferEditing) {
      for (final row in cur.rows) {
        context.read<BulkTransferBloc>().add(BulkTransferUpdateRow(
          rowId: row.rowId,
          currency: ccy,
        ));
      }
    }
  }

  void _onRowComplete() => _dispatch(const BulkTransferAddRow());

  void _onSubmit() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
    context.read<BulkTransferBloc>().add(
      BulkTransferSubmitted(userName: widget.usrName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BulkTransferBloc, BulkTransferState>(
      listener: (context, state) {
        if (state is BulkTransferSuccess) {
          ToastManager.show(
            context: context,
            title: 'Bulk transfer',
            message: state.message,
            type: ToastType.success,
          );
          Navigator.of(context).pop(true);
        } else if (state is BulkTransferFailure) {
          // ✅ Show the failure as an inline top banner — no toast.
          setState(() => _errorMessage = state.message);
        }
      },
      builder: (context, state) {
        final editing = _toEditing(state);
        final busy = state is BulkTransferSubmitting;

        return ZFormDialog(
          width: MediaQuery.of(context).size.width * 0.7,
          icon: Icons.dynamic_feed_outlined,
          title: 'Bulk transfer',
          isActionTrue: false,
          onAction: null,
          child: _buildBody(context, editing, busy),
        );
      },
    );
  }

  BulkTransferEditing _toEditing(BulkTransferState state) {
    if (state is BulkTransferEditing) return state;
    if (state is BulkTransferFailure) {
      final rows = state.rows;
      final debit = rows.fold<double>(0, (a, r) => a + r.debit);
      final credit = rows.fold<double>(0, (a, r) => a + r.credit);
      return BulkTransferEditing(
        rows: rows,
        totalDebit: debit,
        totalCredit: credit,
      );
    }
    return const BulkTransferEditing(rows: [], totalDebit: 0, totalCredit: 0);
  }

  Widget _buildBody(
      BuildContext context,
      BulkTransferEditing state,
      bool busy,
      ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 140,
                child: CurrencyDropdown(
                  title: AppLocalizations.of(context)!.currencyTitle,
                  isMulti: false,
                  height: 35,
                  disableAction: busy,
                  initiallySelectedSingle:
                  CurrenciesModel(ccyCode: _headerCurrency),
                  onSingleChanged: (ccy) {
                    if (ccy?.ccyCode == null) return;
                    _changeHeaderCurrency(ccy!.ccyCode!);
                  },
                ),
              ),
              const SizedBox(width: 8),
              ZOutlineButton(
                height: 42,
                isActive: true,
                onPressed: busy
                    ? null
                    : () => _dispatch(const BulkTransferAddRow()),
                icon: Icons.add,
                label: Text('Add Row'),
              ),
              const Spacer(),
              if (!state.isEmpty) ...[
                _pill(
                  '${AppLocalizations.of(context)!.debit} '
                      '${state.totalDebit.toStringAsFixed(2)}',
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _pill(
                  '${AppLocalizations.of(context)!.credit} '
                      '${state.totalCredit.toStringAsFixed(2)}',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _pill(
                  'Diff ${state.difference.toStringAsFixed(2)}',
                  state.isBalanced ? Colors.green : Colors.red,
                ),
              ],
            ],
          ),
        ),

        // ── Inline warnings ──────────────────────────────────────
        // API error first (top-most), then local validation warnings.
        if (_errorMessage != null && _errorMessage!.isNotEmpty)
          _banner(_errorMessage!, Colors.red),

        if (!state.isEmpty && state.hasCurrencyMix)
          _banner(
            'Rows use different currencies. Pick one currency for all rows.',
            Colors.orange,
          ),

        if (!state.isEmpty && !state.isBalanced)
          _banner('Total debit must equal total credit.', Colors.red),

        // ── Rows ─────────────────────────────────────────────────
        Expanded(
          child: state.isEmpty
              ? _emptyState()
              : ListView.separated(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: state.rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final row = state.rows[i];
              final isLast = i == state.rows.length - 1;
              return _BulkRowWidget(
                key: ValueKey(row.rowId),
                index: i,
                row: row,
                controllers: _ctrlFor(row),
                headerCurrency: _headerCurrency,
                enabled: !busy,
                isLast: isLast,
                onRowComplete: isLast ? _onRowComplete : null,
                onChanged: _dispatch,
              );
            },
          ),
        ),

        // ── Footer ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: Row(
            spacing: 8,
            children: [
              ZOutlineButton(
                onPressed: () => Navigator.of(context).pop(false),
                backgroundHover: Theme.of(context).colorScheme.error,
                label: Text(AppLocalizations.of(context)!.cancel),
              ),
              ZOutlineButton(
                icon: Icons.save_alt_rounded,
                isActive: true,
                onPressed: !state.canSubmit || busy ? null : _onSubmit,
                label: busy
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState() => const Expanded(
    child: Center(
      child: Text(
        'Add at least two rows — one debit and one credit — '
            'with the same total.',
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );

  Widget _banner(String text, Color color) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(color: color, fontSize: 12)),
        ),
      ],
    ),
  );
}

// ── Row controllers ─────────────────────────────────────────────

class _RowControllers {
  final TextEditingController account;
  final TextEditingController debit;
  final TextEditingController credit;
  final TextEditingController narration;

  final FocusNode accountFocus = FocusNode();
  final FocusNode debitFocus = FocusNode();
  final FocusNode creditFocus = FocusNode();
  final FocusNode narrationFocus = FocusNode();

  _RowControllers(BulkTransferRow row)
      : account = TextEditingController(text: row.accountName ?? ''),
        debit = TextEditingController(
          text: row.debit > 0 ? row.debit.toStringAsFixed(2) : '',
        ),
        credit = TextEditingController(
          text: row.credit > 0 ? row.credit.toStringAsFixed(2) : '',
        ),
        narration = TextEditingController(text: row.narration);

  void dispose() {
    account.dispose();
    debit.dispose();
    credit.dispose();
    narration.dispose();
    accountFocus.dispose();
    debitFocus.dispose();
    creditFocus.dispose();
    narrationFocus.dispose();
  }
}

// ── Row widget ──────────────────────────────────────────────────

class _BulkRowWidget extends StatefulWidget {
  final int index;
  final BulkTransferRow row;
  final _RowControllers controllers;
  final String headerCurrency;
  final bool enabled;
  final bool isLast;
  final VoidCallback? onRowComplete;
  final void Function(BulkTransferUpdateRow) onChanged;

  const _BulkRowWidget({
    super.key,
    required this.index,
    required this.row,
    required this.controllers,
    required this.headerCurrency,
    required this.enabled,
    required this.isLast,
    required this.onChanged,
    this.onRowComplete,
  });

  @override
  State<_BulkRowWidget> createState() => _BulkRowWidgetState();
}

class _BulkRowWidgetState extends State<_BulkRowWidget> {
  bool _focusedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _focusedOnce) return;
      if (widget.isLast) {
        _focusedOnce = true;
        widget.controllers.accountFocus.requestFocus();
      }
    });
  }

  void _onNarrationDone() {
    if (!widget.isLast) return;
    widget.onRowComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final c = widget.controllers;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${widget.index + 1}',
              style: TextStyle(
                color: color.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: GenericTextField<StakeholderAccount, StkAccountsBloc,
                StkAccountsState>(
              controller: c.account,
              title: '',
              hintText: AppLocalizations.of(context)!.accNameOrNumber,
              isRequired: true,
              bloc: context.read<StkAccountsBloc>(),
              focusNode: c.accountFocus,
              textInputAction: TextInputAction.none,
              showAllOnFocus: false,
              fetchAllFunction: null,
              searchFunction: (bloc, q) {
                if (q.trim().isEmpty) return;
                bloc.add(LoadStkAccountsEvent(query: q));
              },
              itemBuilder: (context, account) => Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${account.accName ?? ''} · ${account.accNumber}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      account.accCurrency ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: account.accCurrency == widget.headerCurrency
                            ? color.primary
                            : color.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              itemToString: (a) => '${a.accNumber} | ${a.accName}',
              stateToItems: (s) {
                if (s is! StkAccountsLoadedState) {
                  return const <StakeholderAccount>[];
                }
                return s.accounts
                    .where((a) => a.accCategory == 8)
                    .toList();
              },
              stateToLoading: (s) => s is StkAccountsLoadingState,
              onSelected: (a) {
                c.account.text = '${a.accNumber} | ${a.accName ?? ''}';
                widget.onChanged(BulkTransferUpdateRow(
                  rowId: widget.row.rowId,
                  accountNumber: a.accNumber,
                  accountName: a.accName,
                  currency: widget.headerCurrency,
                ));
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) c.debitFocus.requestFocus();
                });
              },
              validator: (v) =>
              (widget.row.accountNumber == null) ? 'Required' : null,
            ),
          ),

          SizedBox(
            width: 130,
            child: ZTextFieldEntitled(
              controller: c.debit,
              title: '',
              isRequired: false,
              focusNode: c.debitFocus,
              textInputAction: TextInputAction.none,
              hint: AppLocalizations.of(context)!.debit,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormat: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onFieldSubmitted: (_) => c.creditFocus.requestFocus(),
              onChanged: (v) {
                final d = double.tryParse(v) ?? 0;
                if (d > 0) c.credit.clear();
                widget.onChanged(BulkTransferUpdateRow(
                  rowId: widget.row.rowId,
                  debit: d,
                  credit: d > 0 ? 0 : widget.row.credit,
                ));
              },
            ),
          ),

          SizedBox(
            width: 130,
            child: ZTextFieldEntitled(
              controller: c.credit,
              title: '',
              hint: AppLocalizations.of(context)!.credit,
              isRequired: false,
              focusNode: c.creditFocus,
              textInputAction: TextInputAction.none,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormat: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onFieldSubmitted: (_) => c.narrationFocus.requestFocus(),
              onChanged: (v) {
                final cr = double.tryParse(v) ?? 0;
                if (cr > 0) c.debit.clear();
                widget.onChanged(BulkTransferUpdateRow(
                  rowId: widget.row.rowId,
                  credit: cr,
                  debit: cr > 0 ? 0 : widget.row.debit,
                ));
              },
            ),
          ),

          Expanded(
            flex: 2,
            child: ZTextFieldEntitled(
              controller: c.narration,
              hint: AppLocalizations.of(context)!.narration,
              title: '',
              isRequired: false,
              focusNode: c.narrationFocus,
              textInputAction: TextInputAction.none,
              onFieldSubmitted: (_) {
                widget.onChanged(BulkTransferUpdateRow(
                  rowId: widget.row.rowId,
                  narration: c.narration.text,
                ));
                _onNarrationDone();
              },
              onChanged: (v) => widget.onChanged(BulkTransferUpdateRow(
                rowId: widget.row.rowId,
                narration: v,
              )),
            ),
          ),

          Builder(
            builder: (context) {
              final enabled = widget.enabled;
              bool hovering = false;
              return StatefulBuilder(
                builder: (context, setLocal) {
                  final bg = !enabled
                      ? color.error.withValues(alpha: .04)
                      : hovering
                      ? color.error.withValues(alpha: .20)
                      : color.error.withValues(alpha: .08);

                  final borderColor = enabled
                      ? color.error
                      .withValues(alpha: hovering ? .45 : .20)
                      : color.error.withValues(alpha: .08);

                  final fg = !enabled
                      ? color.error.withValues(alpha: .4)
                      : color.error;

                  return Tooltip(
                    message: 'Remove row',
                    child: MouseRegion(
                      cursor: enabled
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      onEnter: (_) {
                        if (enabled) setLocal(() => hovering = true);
                      },
                      onExit: (_) {
                        if (enabled) setLocal(() => hovering = false);
                      },
                      child: GestureDetector(
                        onTap: enabled
                            ? () => context
                            .read<BulkTransferBloc>()
                            .add(BulkTransferRemoveRow(widget.row.rowId))
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: bg,
                            shape: BoxShape.circle,
                            border:
                            Border.all(color: borderColor, width: 1),
                            boxShadow: enabled && hovering
                                ? [
                              BoxShadow(
                                color: color.error
                                    .withValues(alpha: .18),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                                : null,
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: fg,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}