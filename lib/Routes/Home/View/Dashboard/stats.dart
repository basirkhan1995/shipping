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
                    _StatCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Accounts',
                      value: loading ? null : '${stats!.counts.accounts}',
                      accent: const Color(0xFF2563EB),
                      bg: const Color(0xFFDBEAFE),
                    ),
                    _StatCard(
                      icon: Icons.people_alt_outlined,
                      label: 'Stakeholders',
                      value: loading ? null : '${stats!.counts.stakeholders}',
                      accent: const Color(0xFF0D9488),
                      bg: const Color(0xFFCCFBF1),
                    ),
                    _StatCard(
                      icon: Icons.person_outline,
                      label: 'Users',
                      value: loading ? null : '${stats!.counts.users}',
                      accent: const Color(0xFF7C3AED),
                      bg: const Color(0xFFEDE9FE),
                    ),
                    _StatCard(
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
                    _StatCard(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Cash In',
                      value: loading
                          ? null
                          : _money(stats!.cash.inAmount, stats.currency),
                      accent: const Color(0xFF059669),
                      bg: const Color(0xFFD1FAE5),
                    ),
                    _StatCard(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Cash Out',
                      value: loading
                          ? null
                          : _money(stats!.cash.outAmount, stats.currency),
                      accent: const Color(0xFFDC2626),
                      bg: const Color(0xFFFEE2E2),
                    ),
                    _StatCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Net Cash',
                      value: loading
                          ? null
                          : _money(stats!.cash.net, stats.currency),
                      accent: stats != null && stats.cash.net < 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF2563EB),
                      bg: stats != null && stats.cash.net < 0
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFDBEAFE),
                      subtitle: stats?.currency,
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
                    _StatCard(
                      icon: Icons.add_circle_outline,
                      label: 'Income',
                      value: loading
                          ? null
                          : _money(stats!.finance.income, stats.currency),
                      accent: const Color(0xFF059669),
                      bg: const Color(0xFFD1FAE5),
                    ),
                    _StatCard(
                      icon: Icons.remove_circle_outline,
                      label: 'Expense',
                      value: loading
                          ? null
                          : _money(stats!.finance.expense, stats.currency),
                      accent: const Color(0xFFDC2626),
                      bg: const Color(0xFFFEE2E2),
                    ),
                    _StatCard(
                      icon: Icons.trending_up,
                      label: 'Profit',
                      value: loading
                          ? null
                          : _money(stats!.finance.profit, stats.currency),
                      accent: stats != null && stats.finance.profit < 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF059669),
                      bg: stats != null && stats.finance.profit < 0
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFD1FAE5),
                      subtitle: stats?.currency,
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

  String _money(double v, String ccy) {
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
// Stat card — value null → shimmer
// =====================================================================
class _StatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color accent;
  final Color bg;
  final VoidCallback? onTap;
  final String? subtitle;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.bg,
    this.subtitle,
  }) : onTap = null;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final interactive = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor:
      interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered && interactive
                ? widget.accent.withValues(alpha: 0.5)
                : scheme.outline.withValues(alpha: 0.18),
            width: _hovered && interactive ? 1.3 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
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
                          color: widget.bg.withValues(alpha: .5),
                          border: Border.all(color: widget.bg),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.center,
                        child: Icon(widget.icon,
                            size: 23, color: widget.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      if (interactive)
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 150),
                          offset:
                          _hovered ? const Offset(0.15, 0) : Offset.zero,
                          child: Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 12,
                            color: _hovered
                                ? widget.accent
                                : scheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 26,
                    child: widget.value == null
                        ? const _ShimmerNumber()
                        : Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            widget.value!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: widget.accent,
                            ),
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Shimmer strip
// =====================================================================
class _ShimmerNumber extends StatefulWidget {
  const _ShimmerNumber();

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
          width: 72,
          height: 22,
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