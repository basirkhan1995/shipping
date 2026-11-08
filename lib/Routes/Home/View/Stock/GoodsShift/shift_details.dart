
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import '../../../../../Features/Widgets/alert_dialog.dart';
import '../../../../../Features/Widgets/cover.dart';
import '../../../../../Features/Widgets/extensions.dart';
import '../../../../../Features/Widgets/noData_widget.dart';
import '../../../../../Features/Widgets/zbutton.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../Auth/bloc/auth_bloc.dart';
import '../../Settings/View/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'bloc/goods_shift_bloc.dart';
import 'model/shift_model.dart';

class GoodsShiftDetailView extends StatefulWidget {
  final int shiftId;

  const GoodsShiftDetailView({super.key, required this.shiftId});

  @override
  State<GoodsShiftDetailView> createState() => _GoodsShiftDetailViewState();
}

class _GoodsShiftDetailViewState extends State<GoodsShiftDetailView> {
  late String? usrName;
  String? baseCurrency;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      usrName = authState.loginData.usrName;
    }

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is CompanyProfileLoadedState) {
      baseCurrency = companyState.company.comLocalCcy ?? "";
    }

    // Load shift details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoodsShiftBloc>().add(LoadGoodsShiftByIdEvent(widget.shiftId));
    });
  }

  void _onBackPressed() {
    // Trigger return to list before navigating back
    context.read<GoodsShiftBloc>().add(ReturnToShiftsListEvent());
    Navigator.of(context).pop();
  }

  void _onDelete() {
    if (usrName == null) {
      ToastManager.show(context: context, message: 'User not authenticated', type: ToastType.error);
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return ZAlertDialog(
          title: AppLocalizations.of(context)!.delete,
          content: AppLocalizations.of(context)!.areYouSure,
          onYes: () {
            setState(() {
              _isDeleting = true;
            });
            context.read<GoodsShiftBloc>().add(DeleteGoodsShiftEvent(
              orderId: widget.shiftId,
              usrName: usrName!,
            ));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return BlocListener<GoodsShiftBloc, GoodsShiftState>(
      listener: (context, state) {
        if (state is GoodsShiftDeletingState) {
          setState(() {
            _isDeleting = true;
          });
        }

        if (state is GoodsShiftDeletedState) {
          // Show success message
          ToastManager.show(context: context, message: state.message, type: ToastType.success);
          // Trigger return to list before popping
          context.read<GoodsShiftBloc>().add(ReturnToShiftsListEvent());
          Navigator.of(context).pop();
        }

        if (state is GoodsShiftErrorState) {
          setState(() {
            _isDeleting = false;
          });
          ToastManager.show(context: context, message: state.error, type: ToastType.error);
        }
      },
      child: Scaffold(
        backgroundColor: color.surface,
        appBar: AppBar(
          backgroundColor: color.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBackPressed,
          ),
          title: Text('${tr.goodShift} #${widget.shiftId}'),
          titleSpacing: 0,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 15),
          actions: [
            ZOutlineButton(
              icon: Icons.print,
              label: Text(tr.print),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            ZOutlineButton(
              isActive: true,
              backgroundHover: Theme.of(context).colorScheme.error,
              icon: Icons.delete,
              label: _isDeleting
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color.surface),
                ),
              )
                  : Text(tr.delete),
              onPressed: _onDelete,
            ),
          ],
        ),
        body: BlocBuilder<GoodsShiftBloc, GoodsShiftState>(
          builder: (context, state) {
            if (state is GoodsShiftDetailLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is GoodsShiftDetailLoadedState) {
              return _buildShiftDetail(state.shift, tr);
            }

            if (state is GoodsShiftErrorState) {
              return Center(
                child: NoDataWidget(
                  imageName: 'error.png',
                  message: state.error,
                  onRefresh: () {
                    context.read<GoodsShiftBloc>().add(
                      LoadGoodsShiftByIdEvent(widget.shiftId),
                    );
                  },
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  // ... rest of the _buildShiftDetail method remains the same
  Widget _buildShiftDetail(GoodShiftModel shift, AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expense Information Card (if exists)
          if (shift.hasExpense)
            ZCover(
              radius: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.money, color: color.primary),
                        const SizedBox(width: 8),
                        Text(
                          tr.expenses,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(tr.account, shift.account.toString()),
                        _buildInfoItem(tr.amount,
                            '${shift.totalAmount.toAmount()} $baseCurrency'),
                        if (shift.ordTrnRef != null)
                          _buildInfoItem(tr.reference, shift.ordTrnRef!),
                        if (shift.trnStateText != null)
                          _buildInfoItem(tr.status, shift.trnStateText == "Authorized"? tr.authorized : shift.trnStateText == "Pending"? tr.pending : ""),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Shift records table
          if (shift.records != null && shift.records!.isNotEmpty)
            _buildRecordsTable(shift.records!, tr),

          // Summary
          if (shift.records != null && shift.records!.isNotEmpty)
            _buildSummaryCard(shift, tr),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildRecordsTable(List<ShiftRecord> records, AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Items",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(40), // #
              1: FlexColumnWidth(2), // Type
              2: FlexColumnWidth(4), // Product
              3: FlexColumnWidth(3), // Storage
              4: FlexColumnWidth(2), // Quantity
            },
            border: TableBorder.all(
              color: color.outline.withValues(alpha: .1),
              width: 1,
            ),
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .9),
                ),
                children: [
                  _buildTableCell(
                    '#',
                    isHeader: true,
                    center: true,
                  ),
                  _buildTableCell(
                    tr.type,
                    isHeader: true,
                  ),
                  _buildTableCell(
                    tr.productName,
                    isHeader: true,
                  ),
                  _buildTableCell(
                    tr.storage,
                    isHeader: true,
                  ),
                  _buildTableCell(
                    tr.qty,
                    isHeader: true,
                    center: true,
                  ),
                ],
              ),

              // Data Rows
              ...records.asMap().entries.map((entry) {
                final index = entry.key;
                final record = entry.value;
                final isOut = record.isOutEntry;

                return TableRow(
                  decoration: BoxDecoration(
                    color: isOut
                        ? Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: .03)
                        : Colors.transparent,
                  ),
                  children: [
                    _buildTableCell(
                      (index + 1).toString(),
                      center: true,
                    ),

                    _buildTableCell(
                      isOut ? tr.outTitle : tr.inTitle,
                      color: isOut ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),

                    _buildTableCell(
                      record.proName ?? 'N/A',
                    ),

                    _buildTableCell(
                      record.storageName ?? 'N/A',
                    ),

                    _buildTableCell(
                      (record.quantity ?? 0).toAmount(),
                      center: true,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(
      String text, {
        bool isHeader = false,
        bool center = false,
        Color? color,
        FontWeight? fontWeight,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontWeight: fontWeight ?? (isHeader ? FontWeight.bold : FontWeight.normal),
          color: color ?? (isHeader
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(GoodShiftModel shift, AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;
    final totalItems = shift.records?.length ?? 0;


    return ZCover(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(tr.totalItems, totalItems.toString(),isBold: true),
            _buildSummaryRow(tr.outTitle, shift.outCount.toString(),isBold: true),
            _buildSummaryRow(tr.inTitle, shift.inCount.toString(),isBold: true),

            // Show expense separately if exists
            if (shift.hasExpense) ...[
              Divider(color: color.outline.withValues(alpha: .2)),
              _buildSummaryRow(
                tr.expense,
                '${shift.totalAmount.toAmount()} $baseCurrency',
                color: Colors.orange,
              ),

            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value, {
        bool isBold = false,
        Color? color,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 16,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Theme.of(context).colorScheme.onSurface,
              fontSize: isBold ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}