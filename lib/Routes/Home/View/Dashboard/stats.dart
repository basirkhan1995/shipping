import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/dashboard_stats_bloc.dart';

class DashboardStatsView extends StatelessWidget {
  const DashboardStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardStatsBloc, DashboardStatsState>(
      builder: (context, state) {
        if (state is DashboardStatsFailure) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context
                .read<DashboardStatsBloc>()
                .add(const DashboardStatsLoadRequested()),
          );
        }

        final loading =
            state is DashboardStatsInitial || state is DashboardStatsLoading;
        final stats = state is DashboardStatsLoaded ? state.stats : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.line_axis_rounded,
                    size: 26,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Live snapshot of accounts, cash and finance',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => context
                      .read<DashboardStatsBloc>()
                      .add(const DashboardStatsLoadRequested(silent: true)),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── COUNTS
            const _SectionTitle('COUNTS'),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                final cols = _columnsFor(c.maxWidth);
                return _Grid(
                  cols: cols,
                  children: [
                    _CountCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Accounts',
                      value: loading ? null : '${stats!.counts.accounts}',
                      accent: const Color(0xFF2563EB),
                      bg: const Color(0xFFDBEAFE),
                    ),
                    _CountCard(
                      icon: Icons.people_alt_outlined,
                      label: 'Stakeholders',
                      value: loading ? null : '${stats!.counts.stakeholders}',
                      accent: const Color(0xFF0D9488),
                      bg: const Color(0xFFCCFBF1),
                    ),
                    _CountCard(
                      icon: Icons.person_outline,
                      label: 'Users',
                      value: loading ? null : '${stats!.counts.users}',
                      accent: const Color(0xFF7C3AED),
                      bg: const Color(0xFFEDE9FE),
                    ),
                    _CountCard(
                      icon: Icons.badge_outlined,
                      label: 'Employees',
                      value: loading ? null : '${stats!.counts.employees}',
                      accent: const Color(0xFFF59E0B),
                      bg: const Color(0xFFFEF3C7),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ── CASH
            const _SectionTitle('CASH'),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                final cols = _columnsFor(c.maxWidth);
                return _Grid(
                  cols: cols,
                  children: [
                    _MoneyCard(
                      icon: Icons.south_west_rounded,
                      label: 'Cash In',
                      amount: loading ? null : stats!.cash.inAmount,
                      currency: stats?.currency,
                      accent: const Color(0xFF059669),
                      bg: const Color(0xFFD1FAE5),
                      direction: _Direction.inflow,
                    ),
                    _MoneyCard(
                      icon: Icons.north_east_rounded,
                      label: 'Cash Out',
                      amount: loading ? null : stats!.cash.outAmount,
                      currency: stats?.currency,
                      accent: const Color(0xFFDC2626),
                      bg: const Color(0xFFFEE2E2),
                      direction: _Direction.outflow,
                    ),
                    _MoneyCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Net Cash',
                      amount: loading ? null : stats!.cash.net,
                      currency: stats?.currency,
                      accent: (stats?.cash.net ?? 0) < 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF2563EB),
                      bg: (stats?.cash.net ?? 0) < 0
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFDBEAFE),
                      highlight: true,
                      direction: _Direction.net,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ── FINANCE
            const _SectionTitle('FINANCE'),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                final cols = _columnsFor(c.maxWidth);
                return _Grid(
                  cols: cols,
                  children: [
                    _MoneyCard(
                      icon: Icons.trending_up_rounded,
                      label: 'Income',
                      amount: loading ? null : stats!.finance.income,
                      currency: stats?.currency,
                      accent: const Color(0xFF059669),
                      bg: const Color(0xFFD1FAE5),
                      direction: _Direction.inflow,
                    ),
                    _MoneyCard(
                      icon: Icons.trending_down_rounded,
                      label: 'Expense',
                      amount: loading ? null : stats!.finance.expense,
                      currency: stats?.currency,
                      accent: const Color(0xFFDC2626),
                      bg: const Color(0xFFFEE2E2),
                      direction: _Direction.outflow,
                    ),
                    _MoneyCard(
                      icon: (stats?.finance.profit ?? 0) < 0
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      label: 'Profit',
                      amount: loading ? null : stats!.finance.profit,
                      currency: stats?.currency,
                      accent: (stats?.finance.profit ?? 0) < 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF059669),
                      bg: (stats?.finance.profit ?? 0) < 0
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFD1FAE5),
                      highlight: true,
                      direction: _Direction.net,
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  int _columnsFor(double width) {
    if (width >= 900) return 4;
    if (width >= 560) return 2;
    return 1;
  }
}

// =====================================================================
// Section title
// =====================================================================
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// =====================================================================
// Responsive grid
// =====================================================================
class _Grid extends StatelessWidget {
  final int cols;
  final List<Widget> children;

  const _Grid({required this.cols, required this.children});

  @override
  Widget build(BuildContext context) {
    const gap = 10.0;
    return LayoutBuilder(
      builder: (context, c) {
        final itemW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
          children.map((w) => SizedBox(width: itemW, child: w)).toList(),
        );
      },
    );
  }
}

// =====================================================================
// COUNT card (unchanged)
// =====================================================================
class _CountCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color accent;
  final Color bg;

  const _CountCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bg.withValues(alpha: .5),
                    border: Border.all(color: bg),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 23, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 26,
              child: value == null
                  ? const _ShimmerNumber()
                  : Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Direction — drives the small arrow pill next to the amount
// =====================================================================
enum _Direction { inflow, outflow, net }

// =====================================================================
// MONEY card — polished, directional, highlighted when it's a total
// =====================================================================
class _MoneyCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? amount;
  final String? currency;
  final Color accent;
  final Color bg;
  final bool highlight;
  final _Direction direction;

  const _MoneyCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.currency,
    required this.accent,
    required this.bg,
    this.highlight = false,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNegative = (amount ?? 0) < 0;

    return Container(
      decoration: BoxDecoration(
        // Solid-ish tint for highlight cards, soft wash for others
        color: highlight
            ? bg.withValues(alpha: 0.55)
            : bg.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: highlight ? 0.55 : 0.25),
          width: highlight ? 1.6 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row — icon + label + currency pill
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 17, color: accent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      color: scheme.onSurface.withValues(alpha: 0.85),
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
                      color: scheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      currency!,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Amount row — directional pill + money
            SizedBox(
              height: 36,
              child: amount == null
                  ? const Align(
                alignment: Alignment.centerLeft,
                child: _ShimmerNumber(width: 130, height: 26),
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (direction != _Direction.net)
                    _DirectionPill(
                      direction: direction,
                      accent: accent,
                    ),
                  if (direction != _Direction.net)
                    const SizedBox(width: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatMoney(amount!, isNegative),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            letterSpacing: -0.4,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (highlight)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isNegative ? 'LOSS' : 'TOTAL',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double v, bool neg) {
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

// =====================================================================
// Small directional pill next to the amount
// =====================================================================
class _DirectionPill extends StatelessWidget {
  final _Direction direction;
  final Color accent;

  const _DirectionPill({required this.direction, required this.accent});

  @override
  Widget build(BuildContext context) {
    final icon = direction == _Direction.inflow
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 15, color: accent),
    );
  }
}

// =====================================================================
// Shimmer strip
// =====================================================================
class _ShimmerNumber extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerNumber({this.width = 72, this.height = 22});

  @override
  State<_ShimmerNumber> createState() => _ShimmerNumberState();
}

class _ShimmerNumberState extends State<_ShimmerNumber>
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

// =====================================================================
// Error view
// =====================================================================
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 32, color: scheme.error),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.onErrorContainer),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}