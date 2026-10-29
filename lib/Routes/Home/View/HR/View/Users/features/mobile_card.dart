import 'package:flutter/material.dart';

import '../../../../../../../Features/Other/image_helper.dart';

/// Mobile-optimized card for displaying employees, stakeholders, and users
class MobileInfoCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String? subtitle;
  final List<MobileInfoItem> infoItems;
  final MobileStatus? status;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? accentColor;
  final bool showActions;

  const MobileInfoCard({
    super.key,
    this.imageUrl,
    required this.title,
    this.subtitle,
    this.infoItems = const [],
    this.status,
    this.onTap,
    this.onLongPress,
    this.accentColor,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final accent = accentColor ?? color.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.outline.withValues(alpha: .1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Image and Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar/Image Section
                  ImageHelper.stakeholderProfile(
                    imageName: imageUrl,
                    size: 46,
                  ),
                  const SizedBox(width: 12),

                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: color.onSurface.withValues(alpha: .6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status Badge
                  if (status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: status!.backgroundColor ??
                            status!.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status!.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: status!.color,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Info Items Grid
              if (infoItems.isNotEmpty)
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: infoItems.map((item) {
                    return _buildInfoChip(item, context);
                  }).toList(),
                ),

              // Action Buttons
              if (showActions && onTap != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onTap,
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: accent,
                      ),
                      label: Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          color: accent,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(MobileInfoItem item, BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            size: 12,
            color: item.iconColor ?? theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            item.text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile-optimized info item
class MobileInfoItem {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const MobileInfoItem({
    required this.icon,
    required this.text,
    this.iconColor,
  });
}

/// Mobile-optimized status
class MobileStatus {
  final String label;
  final Color color;
  final Color? backgroundColor;

  const MobileStatus({
    required this.label,
    required this.color,
    this.backgroundColor,
  });
}