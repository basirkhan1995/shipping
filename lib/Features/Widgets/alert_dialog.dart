import 'package:flutter/material.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';

class ZAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onYes;
  final VoidCallback? onNo;
  final bool isYesLoading;
  final bool isNoLoading;
  final String yesLabel;
  final String noLabel;
  final IconData? icon;
  final Widget? child;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ZAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.onYes,
    this.onNo,
    this.isYesLoading = false,
    this.isNoLoading = false,
    this.yesLabel = 'Yes',
    this.noLabel = 'Cancel',
    this.padding,
    this.margin,
    this.width,
    this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Container(
        margin: margin ?? EdgeInsets.zero,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        width: width ?? 380,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: theme.primary),
                    const SizedBox(width: 8),
                  ],
                  Row(
                    spacing: 8,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5),
                child: Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            SizedBox(
              child: child,
            ),
            _buildAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    // Yes is enabled only if onYes is provided and we're not currently loading.
    final bool yesEnabled = onYes != null && !isYesLoading;

    // No (Cancel) is enabled while neither action is loading.
    final bool noEnabled = !isYesLoading && !isNoLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // ---- YES button ----
              ZOutlineButton(
                height: 40,
                width: 100,
                isActive: true,
                // Do NOT auto-pop. The caller decides what happens on Yes
                // (e.g. show spinner, call async op, pop on success).
                onPressed: yesEnabled ? () => onYes!() : null,
                label: isYesLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(yesLabel),
              ),
              const SizedBox(width: 7),

              // ---- CANCEL / NO button ----
              ZOutlineButton(
                height: 40,
                width: 100,
                backgroundHover: color.error,
                // Default behavior: pop the dialog. Override with onNo
                // only if you need custom logic (e.g. block closing while
                // an operation is in flight).
                onPressed: noEnabled
                    ? (onNo ?? () => Navigator.of(context).pop())
                    : null,
                label: isNoLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(noLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}