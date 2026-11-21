import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Date/shamsi_converter.dart';
import 'package:shipping/Features/Widgets/cover.dart';
import 'package:shipping/Features/Widgets/extensions.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Routes/Home/View/Stock/Orders/features/status_method.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../Features/Widgets/ztextfield.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import 'bloc/shipment_bloc.dart';
import 'bloc/shipment_event.dart';
import 'bloc/shipment_state.dart';
import 'model/shp_model.dart';

class ShipmentContainerDialog extends StatefulWidget {
  final ShipmentModel? shipment;

  const ShipmentContainerDialog({
    super.key,
    this.shipment,
  });

  static Future<void> show(
      BuildContext context, {
        ShipmentModel? shipment,
      }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ShipmentContainerDialog(
        shipment: shipment,
      ),
    );
  }

  @override
  State<ShipmentContainerDialog> createState() =>
      _ShipmentContainerDialogState();
}

class _ShipmentContainerDialogState
    extends State<ShipmentContainerDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _portNameCtrl;
  late final TextEditingController _containerNoCtrl;
  late final TextEditingController _sequenceNoCtrl;
  late final TextEditingController _loadingDateCtrl;
  late final TextEditingController _unloadingDateCtrl;
  late final TextEditingController _descriptionCtrl;

  // Focus nodes — one per field
  late final FocusNode _portNameFocus;
  late final FocusNode _containerNoFocus;
  late final FocusNode _sequenceNoFocus;
  late final FocusNode _loadingDateFocus;
  late final FocusNode _unloadingDateFocus;
  late final FocusNode _descriptionFocus;

  bool _isBusy = false;

  bool get _isEditing => widget.shipment != null;

  @override
  void initState() {
    super.initState();

    final shipment = widget.shipment;

    _portNameCtrl = TextEditingController(
      text: shipment?.portName ?? '',
    );

    _containerNoCtrl = TextEditingController(
      text: shipment?.containerNo ?? '',
    );

    _sequenceNoCtrl = TextEditingController(
      text: shipment?.sequenceNo ?? '',
    );

    _loadingDateCtrl = TextEditingController(
      text: _dateOnly(shipment?.loadingDate),
    );

    _unloadingDateCtrl = TextEditingController(
      text: _dateOnly(shipment?.unloadingDate),
    );

    _descriptionCtrl = TextEditingController(
      text: shipment?.description ?? '',
    );

    _portNameFocus = FocusNode();
    _containerNoFocus = FocusNode();
    _sequenceNoFocus = FocusNode();
    _loadingDateFocus = FocusNode();
    _unloadingDateFocus = FocusNode();
    _descriptionFocus = FocusNode();

    // Autofocus the first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _portNameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _portNameCtrl.dispose();
    _containerNoCtrl.dispose();
    _sequenceNoCtrl.dispose();
    _loadingDateCtrl.dispose();
    _unloadingDateCtrl.dispose();
    _descriptionCtrl.dispose();

    _portNameFocus.dispose();
    _containerNoFocus.dispose();
    _sequenceNoFocus.dispose();
    _loadingDateFocus.dispose();
    _unloadingDateFocus.dispose();
    _descriptionFocus.dispose();

    super.dispose();
  }

  String _dateOnly(String? value) {
    if (value == null || value.isEmpty) return '';

    // Supports API dates such as 2026-11-19
    // and date-time strings.
    return value.length >= 10 ? value.substring(0, 10) : value;
  }

  String? _loginName() {
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthenticatedState) {
      return authState.loginData.usrName;
    }

    return null;
  }

  Future<void> _pickDate(
      TextEditingController controller,
      FocusNode focusNode,
      ) async {
    // Move focus to this field first (keeps visual selection consistent)
    focusNode.requestFocus();

    final initialDate =
        DateTime.tryParse(controller.text) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    controller.text =
    '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final usrName = _loginName();

    if (usrName == null || usrName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify the logged-in user.'),
        ),
      );
      return;
    }

    setState(() => _isBusy = true);

    final bloc = context.read<ShipmentBloc>();

    if (_isEditing) {
      bloc.add(
        UpdateShipment(
          usrName: usrName,
          shpId: widget.shipment!.shpId,
          portName: _portNameCtrl.text.trim(),
          containerNo: _containerNoCtrl.text.trim(),
          sequenceNo: _optionalValue(_sequenceNoCtrl.text),
          loadingDate: _loadingDateCtrl.text.trim(),
          unloadingDate: _optionalValue(_unloadingDateCtrl.text),
          description: _optionalValue(_descriptionCtrl.text),
        ),
      );
    } else {
      bloc.add(
        CreateShipment(
          usrName: usrName,
          portName: _portNameCtrl.text.trim(),
          containerNo: _containerNoCtrl.text.trim(),
          loadingDate: _loadingDateCtrl.text.trim(),
          sequenceNo: _optionalValue(_sequenceNoCtrl.text),
          unloadingDate: _optionalValue(_unloadingDateCtrl.text),
          description: _optionalValue(_descriptionCtrl.text),
        ),
      );
    }
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _delete() async {
    final shipment = widget.shipment;
    if (shipment == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Container'),
          content: Text(
            'Are you sure you want to delete '
                'container ${shipment.containerNo ?? ''}?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final usrName = _loginName();

    if (usrName == null || usrName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify the logged-in user.'),
        ),
      );
      return;
    }

    setState(() => _isBusy = true);

    context.read<ShipmentBloc>().add(
      DeleteShipment(
        usrName: usrName,
        shpId: shipment.shpId,
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _dateValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    if (DateTime.tryParse(value.trim()) == null) {
      return 'Enter a valid date';
    }

    return null;
  }

  Widget _dateField({
    required String title,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool required = false,
    FocusNode? nextFocus,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: _isBusy
          ? null
          : () => _pickDate(controller, focusNode),
      child: AbsorbPointer(
        child: ZTextFieldEntitled(
          controller: controller,
          focusNode: focusNode,
          title: title,
          isRequired: required,
          isEnabled: !_isBusy,
          readOnly: true,
          keyboardType: TextInputType.datetime,
          textInputAction:
          isLast ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: (_) {
            if (isLast) {
              _submit();
            } else {
              nextFocus?.requestFocus();
            }
          },
          validator: required ? _dateValidator : null,
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Container Info in edit mode
          if(widget.shipment !=null)...[
            _buildInfoCard(context),
            const SizedBox(height: 12),

          ],


          ZTextFieldEntitled(
            controller: _portNameCtrl,
            focusNode: _portNameFocus,
            title: AppLocalizations.of(context)!.port,
            isRequired: true,
            isEnabled: !_isBusy,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                _containerNoFocus.requestFocus(),
            validator: _requiredValidator,
          ),

          const SizedBox(height: 12),

          ZTextFieldEntitled(
            controller: _containerNoCtrl,
            focusNode: _containerNoFocus,
            title: AppLocalizations.of(context)!.containerNo,
            isRequired: true,
            isEnabled: !_isBusy,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                _sequenceNoFocus.requestFocus(),
            validator: _requiredValidator,
          ),

          const SizedBox(height: 12),

          ZTextFieldEntitled(
            controller: _sequenceNoCtrl,
            focusNode: _sequenceNoFocus,
            title: AppLocalizations.of(context)!.sequence,
            isEnabled: !_isBusy,
            keyboardType: TextInputType.number,
            // ── digits only ────────────────────────────────────────
            inputFormat: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                _loadingDateFocus.requestFocus(),
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _dateField(
                  title: AppLocalizations.of(context)!.loadingDate,
                  controller: _loadingDateCtrl,
                  focusNode: _loadingDateFocus,
                  required: true,
                  nextFocus: _unloadingDateFocus,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _dateField(
                  title: AppLocalizations.of(context)!.unloadingDate,
                  controller: _unloadingDateCtrl,
                  focusNode: _unloadingDateFocus,
                  nextFocus: _descriptionFocus,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ZTextFieldEntitled(
            controller: _descriptionCtrl,
            focusNode: _descriptionFocus,
            keyboardType: TextInputType.multiline,
            title: AppLocalizations.of(context)!.description,
            isEnabled: !_isBusy,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Row(
        children: [
          ZOutlineButton(
            onPressed: _isBusy
                ? null
                : () => Navigator.of(context).pop(),
            label: Text(AppLocalizations.of(context)!.cancel),
          ),

          const SizedBox(width: 8),

          ZOutlineButton(
            isActive: true,
            onPressed: _isBusy ? null : _submit,
            label: _isBusy
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : Text(_isEditing
                ? AppLocalizations.of(context)!.update
                : AppLocalizations.of(context)!.save),
          ),

          if (_isEditing) ...[
            const SizedBox(width: 8),
            ZOutlineButton(
              backgroundHover: Theme.of(context).colorScheme.error,
              onPressed: _isBusy ? null : _delete,
              isActive: true,
              icon: Icons.delete_outline,
              label: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildInfoCard(BuildContext context) {
    final shipment = widget.shipment!;

    final status = shipment.status.toUpperCase();
    final tr = AppLocalizations.of(context)!;
    return ZCover(
      margin: const EdgeInsets.only(bottom: 16),
      radius: 8,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Date + Status badge ─────────────────────────────
          Row(
            children: [
              _InfoItem(
                icon: Icons.timelapse_rounded,
                label: AppLocalizations.of(context)!.entryDate,
                value: shipment.entryDate?.toFormattedDateTime() ?? "—",
                expanded: true,
              ),

              const SizedBox(width: 6),
              StatusDotIndicator(status: status,size: 13,showText: true),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 3: Items + Total rent ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.verified_user_outlined,
                  label: tr.maker,
                  value: shipment.createdByName??"",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoItem(
                  icon: Icons.shopping_basket_outlined,
                  label: tr.noItems,
                  value: shipment.totalItems.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoItem(
                  icon: Icons.payments_outlined,
                  label: tr.rent,
                  value: shipment.totalRent.toAmount(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return BlocListener<ShipmentBloc, ShipmentState>(
      listener: (context, state) {
        if (state is ShipmentOperationLoading) {
          if (mounted) {
            setState(() => _isBusy = true);
          }
        }

        if (state is ShipmentOperationSuccess) {
          final message = state.message;

          Navigator.of(context).pop();

          ToastManager.show(
              context: context,
              message: message,
              type: ToastType.success);
        }

        if (state is ShipmentOperationError) {
          if (mounted) {
            setState(() => _isBusy = false);
          }

          ToastManager.show(
              context: context,
              message: "Failed operation",
              type: ToastType.error);
        }
      },
      child: ZFormDialog(
        width: 460,
        padding: EdgeInsets.all(10),
        icon: _isEditing ? Icons.edit : Icons.add_box_outlined,
        title: _isEditing
            ? '${tr.editContainer} - ${widget.shipment?.containerNo}'
            : tr.addContainer,
        isActionTrue: false,
        onAction: null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 650),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildForm(),
                const SizedBox(height: 20),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool expanded;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                value.isEmpty ? "—" : value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
    return expanded ? Expanded(child: content) : content;
  }
}