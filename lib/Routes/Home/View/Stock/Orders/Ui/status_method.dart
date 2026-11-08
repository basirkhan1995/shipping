import 'package:flutter/material.dart';
import '../../../../../../l10n/app_localizations.dart';

/// ===============================
/// 1️⃣ Status Enum
/// ===============================
enum TxStatus {
  pending,
  completed,
}

/// ===============================
/// 2️⃣ String → Status
/// ===============================
TxStatus parseStatus(String? value) {
  switch (value?.toLowerCase()) {
    case 'authorized':  // ✅ Check for lowercase
      return TxStatus.completed;
    case 'pending':     // ✅ Check for lowercase (optional)
      return TxStatus.pending;
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
      case TxStatus.pending:
        return const StatusStyle(
          color: Color(0xFFF9A825),
          icon: Icons.schedule_rounded,
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