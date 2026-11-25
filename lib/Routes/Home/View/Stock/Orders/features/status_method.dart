import 'package:flutter/material.dart';
import '../../../../../../l10n/app_localizations.dart';

/// ===============================
/// 1️⃣ Status Enum
/// ===============================
enum TxStatus {
  pending,
  completed,
  authorized,
  delivered,
  shipped,
  deleted,
}

/// ===============================
/// 2️⃣ String → Status
/// ===============================
TxStatus parseStatus(String? value) {
  switch (value?.toLowerCase()) {
    case 'authorized':
      return TxStatus.authorized;
    case 'completed':
      return TxStatus.completed;
    case 'delivered':
      return TxStatus.delivered;
    case 'shipped':
      return TxStatus.shipped;
    case 'deleted':
      return TxStatus.deleted;
    case 'pending':
    default:
      return TxStatus.pending;
  }
}

/// ===============================
/// 3️⃣ Status Style
/// ===============================
class StatusStyle {
  final Color color;
  final IconData icon;

  const StatusStyle({
    required this.color,
    required this.icon,
  });

  static StatusStyle getStyle(TxStatus status) {
    switch (status) {
      case TxStatus.completed:
        return const StatusStyle(
          color: Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
        );
      case TxStatus.authorized:
        return const StatusStyle(
          color: Color(0xFF1565C0),
          icon: Icons.verified_rounded,
        );
      case TxStatus.pending:
        return const StatusStyle(
          color: Color(0xFFF9A825),
          icon: Icons.schedule_rounded,
        );
      case TxStatus.delivered:
        return const StatusStyle(
          color: Color(0xFF00897B),
          icon: Icons.local_shipping_rounded,
        );
      case TxStatus.shipped:
        return const StatusStyle(
          color: Color(0xFF6A1B9A),
          icon: Icons.flight_takeoff_rounded,
        );
      case TxStatus.deleted:
        return const StatusStyle(
          color: Color(0xFFC62828),
          icon: Icons.delete_rounded,
        );
    }
  }
}

/// ===============================
/// 4️⃣ Status Icon (with background)
/// ===============================
class StatusIcon extends StatelessWidget {
  final String status; // "Pending" or "Completed"
  final double size;

  const StatusIcon({
    super.key,
    required this.status,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final txStatus = parseStatus(status);
    final style = StatusStyle.getStyle(txStatus);

    return Container(
      padding: EdgeInsets.all(size * 0.3),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        style.icon,
        size: size,
        color: style.color,
      ),
    );
  }
}

/// ===============================
/// 5️⃣ Simple Status Icon (no background)
/// ===============================
class SimpleStatusIcon extends StatelessWidget {
  final String status; // "Pending" or "Completed"
  final double size;

  const SimpleStatusIcon({
    super.key,
    required this.status,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final txStatus = parseStatus(status);
    final style = StatusStyle.getStyle(txStatus);

    return Icon(
      style.icon,
      size: size,
      color: style.color,
    );
  }
}

/// ===============================
/// 6️⃣ Status Badge (with label)
/// ===============================

class StatusBadge extends StatelessWidget {
  final int status;
  final String? trueValue;
  final String? falseValue;

  const StatusBadge({
    super.key,
    required this.status,
    this.trueValue,
    this.falseValue
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final bool isCompleted = status == 1;

    final Color bgColor =
    isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);

    final Color textColor =
    isCompleted ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00);

    final IconData icon =
    isCompleted ? Icons.check_circle_rounded : Icons.schedule_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: textColor.withValues(alpha: .4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            isCompleted ? trueValue ?? tr.completed : falseValue ?? tr.pending,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusDotIndicator extends StatefulWidget {
  final dynamic status;
  final double size;

  /// NEW — optional, defaults to false. Shows the uppercase bold label.
  final bool showText;

  /// NEW — optional, defaults to after the dot. 'before' | 'after'.
  final String textPosition;

  /// NEW — optional gap between dot and text.
  final double spacing;

  const StatusDotIndicator({
    super.key,
    required this.status,
    this.size = 15,
    this.showText = false,
    this.textPosition = 'after',
    this.spacing = 8,
  });

  @override
  State<StatusDotIndicator> createState() => _StatusDotIndicatorState();
}

class _StatusDotIndicatorState extends State<StatusDotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  TxStatus get _tx {
    final v = widget.status;
    if (v is TxStatus) return v;
    if (v is int) return v == 1 ? TxStatus.authorized : TxStatus.pending;
    if (v is bool) return v ? TxStatus.authorized : TxStatus.pending;
    return parseStatus(v?.toString() ?? '');
  }

  /// Uppercase label, e.g. "AUTHORIZED".
  String get _label => _tx.name.toUpperCase();

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (_tx == TxStatus.pending) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant StatusDotIndicator old) {
    super.didUpdateWidget(old);
    if (_tx == TxStatus.pending && !_c.isAnimating) {
      _c.repeat();
    } else if (_tx != TxStatus.pending) {
      _c.stop();
      _c.reset();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _buildDot() {
    final style = StatusStyle.getStyle(_tx);

    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final pulse = _tx == TxStatus.pending ? _c.value : 0.0;
        return SizedBox(
          width: widget.size * 2,
          height: widget.size * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_tx == TxStatus.pending)
                Transform.scale(
                  scale: 1.0 + pulse * 0.6,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: style.color.withValues(
                        alpha: (1 - pulse) * 0.9,
                      ),
                    ),
                  ),
                ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.color,
                  boxShadow: [
                    BoxShadow(
                      color: style.color.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildText() {
    final style = StatusStyle.getStyle(_tx);
    return Text(
      _label,
      style: TextStyle(
        color: style.color,
        fontSize: widget.size * 0.85,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dot = Tooltip(message: _tx.name, child: _buildDot());

    if (!widget.showText) return dot;

    final isBefore = widget.textPosition == 'before';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isBefore) ...[
          _buildText(),
          SizedBox(width: widget.spacing),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: 4,top: 0,right: 0,left: 0),
          child: dot,
        ),
        if (!isBefore) ...[
          SizedBox(width: widget.spacing),
          _buildText(),
        ],
      ],
    );
  }
}