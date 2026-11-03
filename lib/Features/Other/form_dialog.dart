import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../Widgets/zbutton.dart';

class ZFormDialog extends StatefulWidget {
  final VoidCallback? onAction;
  final Widget? actionLabel;
  final String title;
  final Color? backgroundColor;
  final IconData? icon;
  final Widget? child;
  final bool isButtonEnabled;
  final bool isActionTrue;
  final double? width;
  final double? height;
  final Widget? expandedAction;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Widget? expandedHeader;

  /// When non-null and non-empty, a red inline banner is shown
  /// between the form content and the action buttons.
  final String? errorMessage;

  const ZFormDialog({
    super.key,
    required this.onAction,
    this.backgroundColor,
    this.actionLabel,
    this.child,
    this.alignment,
    this.isButtonEnabled = true,
    this.expandedAction,
    this.isActionTrue = true,
    this.width,
    this.height,
    this.icon,
    required this.title,
    this.margin,
    this.expandedHeader,
    this.padding,
    this.errorMessage,
  });

  @override
  State<ZFormDialog> createState() => _ZFormDialogState();
}

class _ZFormDialogState extends State<ZFormDialog> {
  // ── Inline error banner ─────────────────────────────────────────
  Widget _buildErrorBanner(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(15, 4, 15, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: scheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w500,
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: widget.padding ?? const EdgeInsets.all(15.0),
          child: AlertDialog(
            alignment: widget.alignment ?? AlignmentGeometry.center,
            contentPadding: EdgeInsets.zero,
            insetPadding: EdgeInsets.zero,
            titlePadding: EdgeInsets.zero,
            actionsPadding: EdgeInsets.zero,
            content: Material(
              color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: widget.width ?? MediaQuery.sizeOf(context).width * .4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildHeader(),
                    Flexible(
                      child: Container(
                        padding: widget.padding ??
                            const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 5),
                        child: widget.child,
                      ),
                    ),

                    // ── Inline error banner ───────────────────────
                    if (widget.errorMessage != null &&
                        widget.errorMessage!.isNotEmpty)
                      _buildErrorBanner(context, widget.errorMessage!),

                    if (widget.isActionTrue) buildAction(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildAction(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Padding(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 8,
            children: [
              ZOutlineButton(
                label: Text(tr.cancel),
                backgroundHover: Theme.of(context).colorScheme.error,
                onPressed: () => Navigator.of(context).pop(),
                height: 35,
                width: 100,
              ),
              Shortcuts(
                shortcuts: {
                  LogicalKeySet(LogicalKeyboardKey.enter):
                  const ActivateIntent(),
                },
                child: Actions(
                  actions: {
                    ActivateIntent: CallbackAction<ActivateIntent>(
                      onInvoke: (intent) {
                        if (widget.isButtonEnabled &&
                            widget.onAction != null) {
                          widget.onAction!();
                        }
                        return null;
                      },
                    ),
                  },
                  child: Focus(
                    child: ZOutlineButton(
                      isActive: true,
                      backgroundColor:
                      Theme.of(context).colorScheme.primary,
                      height: 35,
                      width: 100,
                      label: widget.actionLabel ?? Text("Submit"),
                      onPressed: widget.onAction,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              widget.expandedAction ?? Text(""),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      height: 50,
      child: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      widget.icon != null
                          ? Icon(
                        widget.icon,
                        color:
                        Theme.of(context).colorScheme.secondary,
                        size: 24,
                      )
                          : SizedBox(),
                      widget.icon != null
                          ? const SizedBox(width: 8)
                          : SizedBox(),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 17,
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: widget.expandedHeader ??
                        Icon(Icons.close, size: 23),
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