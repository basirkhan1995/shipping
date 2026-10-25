import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../Features/Widgets/cover.dart';
import '../../../../../../Features/Widgets/extensions.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../bloc/menu_bloc.dart';
import '../../bloc/financial_tab_bloc.dart';
import 'add_edit_reminders.dart';
import 'bloc/reminder_bloc.dart';
import 'model/reminder_model.dart';

class DashboardAlertReminder extends StatefulWidget {
  const DashboardAlertReminder({super.key});

  @override
  State<DashboardAlertReminder> createState() =>
      _DashboardAlertReminderState();
}

class _DashboardAlertReminderState extends State<DashboardAlertReminder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderBloc>().add(const LoadAlertReminders(alert: 1));
    });
  }

  String? usrName;

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }
    usrName = authState.loginData.usrName ?? '';

    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        return Stack(
          children: [
            ZCover(
              radius: 6,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr.reminders,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),

                      _CircleActionButton(
                        tooltip: tr.settings,
                        isActive: true,
                        icon: Icons.settings,
                        onPressed: () {
                          context
                              .read<MenuBloc>()
                              .add(MenuOnChangedEvent(MenuName.finance));
                          context.read<FinanceTabBloc>().add(
                              FinanceOnChangedEvent(FinanceTabName.reminder));
                        },
                      ),
                      const SizedBox(width: 6),

                      _CircleActionButton(
                        tooltip: tr.newKeyword,
                        icon: Icons.add,
                        isActive: true,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const AddEditReminderView(),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Empty
                  if (state.reminders.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 56,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: .4),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tr.noReminder,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...state.reminders.map(
                          (e) => _ReminderTile(
                        model: e,
                        usrName: usrName ?? '',
                      ),
                    ),
                ],
              ),
            ),

            // ── Loading overlay
            if (state.loading)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .05),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Compact reminder tile
// Layout: [type / customer / account · date]      [amount · Done ☐]
// ═══════════════════════════════════════════════════════════════════
class _ReminderTile extends StatelessWidget {
  final ReminderModel model;
  final String usrName;

  const _ReminderTile({
    required this.model,
    required this.usrName,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;
    final isPaid = model.rmdStatus == 1;

    final typeLabel = model.rmdName == 'receivable'
        ? tr.receivableDue
        : tr.payableDue;

    return ZCover(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: color.surface,
      radius: 5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: type · customer · account/date/status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  typeLabel,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((model.fullName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    model.fullName!,
                    style: text.bodySmall?.copyWith(
                      fontSize: 11,
                      color: color.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 12,
                      color: color.outline,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${model.rmdAccount}',
                      style: text.bodySmall?.copyWith(
                        fontSize: 11,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: color.outline,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _formatDate(model.rmdAlertDate),
                      style: text.bodySmall?.copyWith(
                        fontSize: 11,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        model.rmdAlertDate?.toDueStatus(tr) ?? '',
                        style: text.bodySmall?.copyWith(
                          fontSize: 11,
                          color: color.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Right: amount · Done · checkbox
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(model.rmdAmount ?? '0').toAmount()} ${model.currency}',
                style: text.titleSmall?.copyWith(
                  color: color.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isPaid,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(color: color.outline, width: 1.5),
                  activeColor: Colors.green,
                  onChanged: (v) {
                    final updated = model.copyWith(
                      rmdStatus: (v ?? false) ? 1 : 0,
                      usrName: usrName,
                    );
                    context
                        .read<ReminderBloc>()
                        .add(UpdateReminderEvent(updated));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Circle header button
// ═══════════════════════════════════════════════════════════════════
class _CircleActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;

  const _CircleActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final bg = isActive
        ? color.outline.withValues(alpha: .07)
        : color.surfaceContainerHighest.withValues(alpha: .5);
    final fg = isActive ? color.primary : color.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: fg),
          ),
        ),
      ),
    );
  }
}