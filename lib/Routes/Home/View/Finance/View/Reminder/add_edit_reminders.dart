import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/model/stk_model.dart';
import '../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../Features/Other/smart_decimal.dart';
import '../../../../../../Features/Widgets/extensions.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import 'bloc/reminder_bloc.dart';
import 'features/due_drop.dart';
import 'model/reminder_model.dart';

class AddEditReminderView extends StatelessWidget {
  final String? dueParameter;
  final int? accNumber;
  final bool? isEnable;
  final ReminderModel? r;
  final double? autoFillAmount; // NEW: Optional auto-fill amount

  const AddEditReminderView({
    super.key,
    this.r,
    this.dueParameter,
    this.accNumber,
    this.isEnable = false,
    this.autoFillAmount, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Desktop(r, accNumber, dueParameter, isEnable, autoFillAmount),
      desktop: _Desktop(r, accNumber, dueParameter, isEnable, autoFillAmount),
      tablet: _Desktop(r, accNumber, dueParameter, isEnable, autoFillAmount),
    );
  }
}

class _Desktop extends StatefulWidget {
  final ReminderModel? reminder;
  final int? accNumber;
  final String? dueParameter;
  final bool? isEnable;
  final double? autoFillAmount; // NEW

  const _Desktop(
      this.reminder,
      this.accNumber,
      this.dueParameter,
      this.isEnable,
      this.autoFillAmount, // NEW
      );

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final TextEditingController account = TextEditingController();
  final TextEditingController amount = TextEditingController();
  final TextEditingController details = TextEditingController();
  int? accNumber;
  String? usrName;
  String? dueType;
  String dueDate = DateTime.now().add(Duration(days: 1)).toFormattedDate();

  @override
  void initState() {
    super.initState();

    final r = widget.reminder;

    if (widget.accNumber != null) {
      accNumber = widget.accNumber;
      account.text = widget.accNumber.toString();
    }

    if (widget.dueParameter != null && widget.dueParameter!.isNotEmpty) {
      dueType = widget.dueParameter;
    }

    if (r != null) {
      // Edit mode - populate from existing reminder
      account.text = r.rmdAccount?.toString() ?? widget.accNumber.toString();
      accNumber = r.rmdAccount ?? widget.accNumber;
      amount.text = r.rmdAmount.toAmount();
      details.text = r.rmdDetails ?? "";
      dueDate = r.rmdAlertDate?.toFormattedDate() ?? "";
      dueType = r.rmdName;
    } else {
      // Create mode - auto-fill amount if provided
      if (widget.autoFillAmount != null && widget.autoFillAmount! > 0) {
        amount.text = widget.autoFillAmount!.toAmount();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;
    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    usrName = login.usrName ?? "";
    final isLoading = context.watch<ReminderBloc>().state.loading;

    return BlocListener<ReminderBloc, ReminderState>(
      listener: (context, state) {
        if (state.error != null && !state.loading) {
          ToastManager.show(context: context, message: state.error??"", type: ToastType.error);
        }
        if (state.successMsg != null && !state.loading) {
          Navigator.of(context).pop();
        }
      },
      child: ZFormDialog(
        width: 450,
        padding: const EdgeInsets.all(12),
        icon: Icons.notifications,
        title: tr.reminders,
        actionLabel: isLoading
            ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator())
            : Text(widget.reminder == null ? tr.create : tr.update),
        onAction: onSubmit,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              /// DATE PICKER
              Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ZDatePicker(
                      disablePastDate: true,
                      label: tr.dueDate,
                      value: dueDate,
                      onDateChanged: (v) {
                        setState(() {
                          dueDate = v;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: DueTypeDropdown(
                      isEnable: widget.isEnable ?? false,
                      selectedDueType: dueType ?? widget.dueParameter ??"",
                      onDueTypeSelected: (selectedType) {
                        setState(() {
                          dueType = selectedType.toDatabaseValue();
                        });
                      },
                    ),
                  ),
                ],
              ),

              /// Account
              if(widget.isEnable == false)...[
                GenericTextField<StakeholderAccount, StkAccountsBloc, StkAccountsState>(
                  showAllOnFocus: true,
                  controller: account,
                  title: tr.accounts,
                  hintText: tr.accNameOrNumber,
                  isRequired: true,
                  bloc: context.read<StkAccountsBloc>(),
                  fetchAllFunction: (bloc) => bloc.add(LoadStkAccountsEvent()),
                  searchFunction: (bloc, query) => bloc.add(LoadStkAccountsEvent(query: query)),
                  validator: (value) {
                    if (value == null && value!.isEmpty) {
                      return tr.required(tr.accounts);
                    }
                    if (accNumber == null) {
                      return tr.required(tr.accounts);
                    }
                    return null;
                  },
                  itemBuilder: (context, account) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${account.accNumber} | ${account.accName}",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                  stateToLoading: (state) => state is StkAccountsLoadingState,
                  loadingBuilder: (context) => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  ),
                  stateToItems: (state) {
                    if (state is StkAccountsLoadedState) {
                      return state.accounts;
                    }
                    return [];
                  },
                  onSelected: (value) {
                    setState(() {
                      accNumber = value.accNumber;
                    });
                  },
                  noResultsText: tr.noDataFound,
                  showClearButton: true,
                ),
              ],

              /// Amount
              ZTextFieldEntitled(
                controller: amount,
                title: tr.amount,
                hint: widget.autoFillAmount != null && widget.autoFillAmount! > 0
                    ? null
                    : null,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                isRequired: true,
                inputFormat: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                  SmartThousandsDecimalFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr.required(tr.amount);
                  }

                  final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
                  final amountValue = double.tryParse(clean);

                  if (amountValue == null || amountValue <= 0.0) {
                    return tr.amountGreaterZero;
                  }

                  return null;
                },
              ),

              /// Details
              ZTextFieldEntitled(
                controller: details,
                title: tr.details,
                keyboardType: TextInputType.multiline,
                maxLength: 100,
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void onSubmit() {
    final tr = AppLocalizations.of(context)!;
    // Validate due type
    if (dueType == null || dueType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.required("Reminder type")),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate account
    if (accNumber == null && widget.accNumber == null) {
      ToastManager.show(context: context, message: tr.required(tr.account), type: ToastType.warning);
      return;
    }

    final model = ReminderModel(
      rmdId: widget.reminder?.rmdId,
      usrName: usrName,
      rmdName: dueType ?? widget.dueParameter,
      rmdAccount: accNumber ?? widget.accNumber,
      rmdAmount: amount.text.cleanAmount,
      rmdDetails: details.text,
      rmdAlertDate: DateTime.tryParse(dueDate),
      rmdStatus: widget.reminder?.rmdStatus ?? 0,
    );

    if (widget.reminder == null) {
      context.read<ReminderBloc>().add(AddReminderEvent(model));
    } else {
      context.read<ReminderBloc>().add(UpdateReminderEvent(model));
    }
  }
}