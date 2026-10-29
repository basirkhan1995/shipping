import 'package:flutter/material.dart';

class ZCard extends StatefulWidget {
  final Widget? image;
  final String title;
  final String? subtitle;
  final List<InfoItem> infoItems;
  final InfoStatus? status;
  final VoidCallback? onTap;
  final bool hoverable;
  final double borderRadius;
  final EdgeInsets padding;

  /// Kept for backwards compatibility — the new layout does not draw
  /// a hard divider (it uses spacing instead). Ignored visually.
  final bool showDivider;

  final Widget Function(BuildContext context)? imageBuilder;
  final Widget Function(BuildContext context)? titleBuilder;
  final Widget Function(BuildContext context)? infoItemsBuilder;

  /// Optional widget pinned to the bottom of the card.
  final Widget? footer;

  /// Resting shadow strength. 0 = flat, 2 = subtle lift.
  final double elevation;

  const ZCard({
    super.key,
    this.image,
    required this.title,
    this.subtitle,
    this.infoItems = const [],
    this.status,
    this.onTap,
    this.hoverable = true,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.all(14),
    this.showDivider = true,
    this.imageBuilder,
    this.titleBuilder,
    this.infoItemsBuilder,
    this.footer,
    this.elevation = 1,
  });

  @override
  State<ZCard> createState() => _ZCardState();
}

class InfoItem {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final TextStyle? textStyle;

  const InfoItem({
    required this.icon,
    required this.text,
    this.iconColor,
    this.textStyle,
  });
}

class InfoStatus {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final TextStyle? labelStyle;

  const InfoStatus({
    required this.label,
    required this.color,
    this.backgroundColor,
    this.labelStyle,
  });
}

class _ZCardState extends State<ZCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    final effectiveBorder = _isHovering && widget.hoverable
        ? color.primary.withValues(alpha: .35)
        : color.outlineVariant.withValues(alpha: .35);

    final effectiveShadowAlpha = _isHovering && widget.hoverable
        ? (widget.elevation + 2) * .05
        : widget.elevation * .04;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: widget.hoverable
          ? (_) => setState(() => _isHovering = true)
          : null,
      onExit: widget.hoverable
          ? (_) => setState(() => _isHovering = false)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        // Lift a hair on hover.
        transform: Matrix4.translationValues(
          0,
          _isHovering && widget.hoverable ? -1.5 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: effectiveBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: color.primary.withValues(alpha: effectiveShadowAlpha),
              blurRadius: _isHovering ? 10 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          onTap: widget.onTap,
          child: Padding(
            padding: widget.padding,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Scrollable middle: header + info items ─────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderSection(context),
                        if (widget.infoItems.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildInfoItemsSection(context),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Pinned footer ──────────────────────────────
                if (widget.footer != null) ...[
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: color.outlineVariant.withValues(alpha: .5),
                  ),
                  const SizedBox(height: 8),
                  widget.footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header: avatar (left) + title (middle) + status (right) ──
  Widget _buildHeaderSection(BuildContext context) {
    if (widget.imageBuilder != null) {
      return widget.imageBuilder!(context);
    }

    final hasAvatar = widget.image != null;
    final hasStatus = widget.status != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        if (hasAvatar) ...[
          _buildAvatar(context),
          const SizedBox(width: 12),
        ],

        // Title + subtitle (takes remaining space)
        Expanded(
          child: widget.titleBuilder != null
              ? widget.titleBuilder!(context)
              : Padding(
            padding: EdgeInsets.only(top: hasAvatar ? 4 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    height: 1.2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null &&
                    widget.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Status pill on the top right
        if (hasStatus) ...[
          const SizedBox(width: 8),
          _buildStatusBadge(widget.status!),
        ],
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: .08),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: .18),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: ClipOval(child: widget.image!),
    );
  }

  // ── Info rows ────────────────────────────────────────────────
  Widget _buildInfoItemsSection(BuildContext context) {
    if (widget.infoItemsBuilder != null) {
      return widget.infoItemsBuilder!(context);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widget.infoItems
          .map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _buildInfoRow(item, context),
      ))
          .toList(),
    );
  }

  Widget _buildInfoRow(InfoItem item, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          item.icon,
          size: 14,
          color: item.iconColor ?? scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.text,
            style: item.textStyle ??
                Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11.5,
                  color: scheme.onSurface,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  // ── Status pill ─────────────────────────────────────────────
  Widget _buildStatusBadge(InfoStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.backgroundColor ?? status.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: status.labelStyle ??
            TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
              color: status.color,
            ),
      ),
    );
  }
}