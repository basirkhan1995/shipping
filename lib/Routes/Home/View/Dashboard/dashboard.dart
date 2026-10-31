import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/cover.dart';
import 'package:shipping/Features/Widgets/digital_clock.dart';
import 'package:shipping/Routes/Auth/bloc/auth_bloc.dart';
import 'package:shipping/Routes/Home/View/Finance/View/Reminder/reminder_widget.dart';
import 'package:shipping/Services/api_services.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../Features/Other/responsive_widget.dart';
import '../Finance/View/ExchangeRate/Ui/exchange_rate.dart';
import 'bloc/dashboard_stats_bloc.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshSilentlyIfReady();
    });
  }

  void _refreshSilentlyIfReady() {
    final statsBloc = context.read<DashboardStatsBloc>();
    final hasStats = statsBloc.state is DashboardStatsLoaded;
    statsBloc.add(DashboardStatsLoadRequested(silent: hasStats));
  }

  void _manualRefresh() {
    context
        .read<DashboardStatsBloc>()
        .add(const DashboardStatsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileDashboard(onRefresh: _manualRefresh),
      tablet: _TabletDashboard(onRefresh: _manualRefresh),
      desktop: _DesktopDashboard(onRefresh: _manualRefresh),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED: Stats section — grid + cash + finance cards
// ═══════════════════════════════════════════════════════════════════
class _StatsSection extends StatelessWidget {
  final int gridColumns;
  final bool stackFinancials;

  const _StatsSection({
    required this.gridColumns,
    this.stackFinancials = false,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return BlocBuilder<DashboardStatsBloc, DashboardStatsState>(
      builder: (context, state) {
        if (state is DashboardStatsFailure) {
          return _ErrorTile(
            message: state.message,
            onRetry: () => context
                .read<DashboardStatsBloc>()
                .add(const DashboardStatsLoadRequested()),
          );
        }

        final loading =
            state is DashboardStatsInitial || state is DashboardStatsLoading;
        final s = state is DashboardStatsLoaded ? state.stats : null;

        final countCards = <Widget>[
          _CountCard(
            label: tr.accounts,
            value: loading ? null : '${s!.counts.accounts}',
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.blue,
          ),
          _CountCard(
            label: tr.stakeholders,
            value: loading ? null : '${s!.counts.stakeholders}',
            icon: Icons.people_alt_outlined,
            color: Colors.teal,
          ),
          _CountCard(
            label: tr.users,
            value: loading ? null : '${s!.counts.users}',
            icon: Icons.person_outline,
            color: Colors.deepPurple,
          ),
          _CountCard(
            label: tr.employees,
            value: loading ? null : '${s!.counts.employees}',
            icon: Icons.badge_outlined,
            color: Colors.orange,
          ),
        ];

        // ═══════════════════════════════════════════════════════════
        // CASH — Net Cash card (main) + In/Out breakdown row.
        // Same visual language as count cards:
        //   icon box + label + big colored number + subtitle line.
        // ═══════════════════════════════════════════════════════════
        final netCash = s?.cash.net ?? 0;
        final netCashPos = !loading && netCash >= 0;

        final cashCard = _FinCard(
          icon: Icons.payments_outlined,
          label: 'Net Cash',
          value: loading ? null : netCash,
          currency: loading ? null : s!.currency,
          accent: netCashPos
              ? const Color(0xFF059669)
              : const Color(0xFFDC2626),
          bg: netCashPos
              ? const Color(0xFFD1FAE5)
              : const Color(0xFFFEE2E2),
          showSign: true,
          breakdown: loading
              ? null
              : [
            _BreakdownItem(
              label: 'In',
              value: s!.cash.inAmount,
              icon: Icons.arrow_downward_rounded,
              color: const Color(0xFF059669),
            ),
            _BreakdownItem(
              label: 'Out',
              value: s.cash.outAmount,
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFFDC2626),
            ),
          ],
        );

        // ═══════════════════════════════════════════════════════════
        // FINANCE — Profit card (main) + Income/Expense breakdown row.
        // ═══════════════════════════════════════════════════════════
        final profit = s?.finance.profit ?? 0;
        final profitPos = !loading && profit >= 0;

        final financeCard = _FinCard(
          icon: profitPos
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          label: 'Profit',
          value: loading ? null : profit,
          currency: loading ? null : s!.currency,
          accent: profitPos
              ? const Color(0xFF059669)
              : const Color(0xFFDC2626),
          bg: profitPos
              ? const Color(0xFFD1FAE5)
              : const Color(0xFFFEE2E2),
          showSign: true,
          breakdown: loading
              ? null
              : [
            _BreakdownItem(
              label: 'Income',
              value: s!.finance.income,
              icon: Icons.add_circle_outline,
              color: const Color(0xFF059669),
            ),
            _BreakdownItem(
              label: 'Expense',
              value: s.finance.expense,
              icon: Icons.remove_circle_outline,
              color: const Color(0xFFDC2626),
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = gridColumns;
                final spacing = 12.0;
                final cardWidth =
                    (constraints.maxWidth - spacing * (cols - 1)) / cols;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: countCards
                      .map((c) => SizedBox(width: cardWidth, child: c))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            if (stackFinancials) ...[
              cashCard,
              const SizedBox(height: 12),
              financeCard,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cashCard),
                  const SizedBox(width: 12),
                  Expanded(child: financeCard),
                ],
              ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE — single column, everything stacks vertically
// ═══════════════════════════════════════════════════════════════════
class _MobileDashboard extends StatelessWidget {
  final VoidCallback onRefresh;
  const _MobileDashboard({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dashboard),
        titleSpacing: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: const [
            _StatsSection(gridColumns: 2, stackFinancials: true),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TABLET — stats as 4-up grid, side-by-side cash / finance
// ═══════════════════════════════════════════════════════════════════
class _TabletDashboard extends StatelessWidget {
  final VoidCallback onRefresh;
  const _TabletDashboard({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dashboard),
        titleSpacing: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: const _StatsSection(
            gridColumns: 4,
            stackFinancials: false,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP — main + right rail, stats as 4-up grid
// ═══════════════════════════════════════════════════════════════════
class _DesktopDashboard extends StatelessWidget {
  final VoidCallback onRefresh;
  const _DesktopDashboard({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    const rightSideWidth = 350.0;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                _DesktopTopBar(onRefresh: onRefresh),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 3,
                          child: _StatsSection(
                            gridColumns: 4,
                            stackFinancials: false,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Column(
                          spacing: 8,
                          children: [
                            SizedBox(
                              width: rightSideWidth,
                              child: DigitalClock(),
                            ),
                            ExchangeRateView(
                              width: rightSideWidth,
                              settingButton: true,
                              newRateButton: true,
                            ),
                            SizedBox(
                              width: rightSideWidth,
                              child: DashboardAlertReminder(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Top bar
// ═══════════════════════════════════════════════════════════════════
class _DesktopTopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _DesktopTopBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthenticatedState ? authState.loginData : null;

    final fullName = user?.usrFullName ?? user?.usrName ?? 'Guest';
    final username = user?.usrName ?? '';

    final rawPhoto = user?.usrPhoto?.trim();
    final hasPhoto = rawPhoto != null &&
        rawPhoto.isNotEmpty &&
        rawPhoto.toLowerCase() != 'null' &&
        rawPhoto.toLowerCase() != 'undefined';
    final photoUrl = hasPhoto ? "${ApiServices.imageUrl}$rawPhoto" : null;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.dashboard,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_greeting()}, $fullName 👋',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          _CircleIconButton(
            icon: Icons.refresh,
            tooltip: 'Refresh',
            size: 40,
            iconSize: 22,
            onPressed: onRefresh,
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            icon: Icons.notifications_outlined,
            tooltip: 'Notifications',
            size: 40,
            iconSize: 22,
            onPressed: () {
              // open notifications
            },
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            icon: Icons.settings,
            tooltip: 'Settings',
            size: 40,
            iconSize: 22,
            onPressed: () {
              // open settings
            },
          ),
          const SizedBox(width: 8),
          ZCover(
            radius: 50,
            padding: const EdgeInsets.all(5),
            child: PopupMenuButton<String>(
              tooltip: 'Account',
              offset: const Offset(0, 48),
              onSelected: (value) {
                if (value == 'logout') {
                  context.read<AuthBloc>().add(OnLogoutEvent());
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? Text(
                      _initials(fullName),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onPrimaryContainer,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                            height: 1.2,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

// ═══════════════════════════════════════════════════════════════════
// Count card
// ═══════════════════════════════════════════════════════════════════
class _CountCard extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Color color;

  const _CountCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ZCover(
      radius: 5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              child: value == null
                  ? const _ShimmerBar(width: 60, height: 24)
                  : Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value!,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Finance / Cash card — same visual language as _CountCard:
//   icon box + label + currency pill + big colored number +
//   breakdown chips row (In/Out or Income/Expense).
// ═══════════════════════════════════════════════════════════════════
class _FinCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? value;
  final String? currency;
  final Color accent;
  final Color bg;
  final bool showSign;
  final List<_BreakdownItem>? breakdown;

  const _FinCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.currency,
    required this.accent,
    required this.bg,
    this.showSign = false,
    this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neg = (value ?? 0) < 0;

    return ZCover(
      radius: 5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — icon box + label + currency pill
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bg.withAlpha(80),
                    border: Border.all(color: bg),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 22, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (currency != null && currency!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      currency!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Big amount — same colored number as count cards
            SizedBox(
              height: 30,
              child: value == null
                  ? const _ShimmerBar(width: 100, height: 24)
                  : Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _fmt(value!, neg, showSign),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: accent,
                  ),
                ),
              ),
            ),

            // Breakdown chips
            if (breakdown != null && breakdown!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  for (int i = 0; i < breakdown!.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _BreakdownChip(item: breakdown![i])),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(double v, bool neg, bool showSign) {
    final s = v.abs().toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    final sign = neg ? '-' : (showSign && v > 0 ? '+' : '');
    return '$sign${buf.toString()}.${parts[1]}';
  }
}

class _BreakdownItem {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _BreakdownItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _BreakdownChip extends StatelessWidget {
  final _BreakdownItem item;
  const _BreakdownChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: item.color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: item.color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 14, color: item.color),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _fmt(item.value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: item.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    final neg = v < 0;
    final s = v.abs().toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '${neg ? '-' : ''}${buf.toString()}.${parts[1]}';
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shimmer bar
// ═══════════════════════════════════════════════════════════════════
class _ShimmerBar extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerBar({required this.width, required this.height});

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final highlight = scheme.surfaceContainerLowest.withValues(alpha: 0.95);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + _ctrl.value * 3, 0),
              end: Alignment(-0.5 + _ctrl.value * 3, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Error tile
// ═══════════════════════════════════════════════════════════════════
class _ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorTile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ZCover(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 42, color: scheme.error),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Circle icon button (top bar)
// ═══════════════════════════════════════════════════════════════════
class _CircleIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  final double iconSize;

  const _CircleIconButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 40,
    this.iconSize = 22,
  }) : color = null;

  @override
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _active => _hovered || _pressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseIconColor = widget.color ?? scheme.onPrimaryContainer;

    final borderColor = _active
        ? scheme.primary
        : scheme.outline.withValues(alpha: 0.25);

    final iconColor = _active ? scheme.primary : baseIconColor;

    final bgColor = Colors.transparent;

    final button = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: widget.onPressed == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onPressed == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onPressed == null
            ? null
            : () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: _active ? 1.4 : 1.0,
            ),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}