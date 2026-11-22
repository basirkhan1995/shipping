import 'package:flutter/material.dart';

enum WatermarkPosition {
  topLeft,
  top,
  topRight,
  left,
  center,
  right,
  bottomLeft,
  bottom,
  bottomRight,
}

class Box extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? shadowColor;
  final double? radius;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  // ── Watermark ──
  final Widget? watermark;
  final WatermarkPosition watermarkPosition;
  final Offset? watermarkOffset;
  final double watermarkOpacity;
  final double watermarkAngle; // radians
  final double watermarkScale;
  final EdgeInsets watermarkPadding;
  final Color? watermarkColor;

  const Box({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.shadowColor,
    this.radius,
    this.padding,
    this.margin,
    this.watermark,
    this.watermarkPosition = WatermarkPosition.center,
    this.watermarkOffset,
    this.watermarkOpacity = 0.15, // bumped default so it's actually visible
    this.watermarkAngle = 0.0,
    this.watermarkScale = 1.0,
    this.watermarkPadding = const EdgeInsets.all(8),
    this.watermarkColor,
  });

  bool _isChildEmpty() {
    if (child is Text) {
      final text = (child as Text).data ?? '';
      return text.trim().isEmpty;
    }
    return false;
  }

  Alignment _alignmentFor(WatermarkPosition p) {
    switch (p) {
      case WatermarkPosition.topLeft:
        return Alignment.topLeft;
      case WatermarkPosition.top:
        return Alignment.topCenter;
      case WatermarkPosition.topRight:
        return Alignment.topRight;
      case WatermarkPosition.left:
        return Alignment.centerLeft;
      case WatermarkPosition.center:
        return Alignment.center;
      case WatermarkPosition.right:
        return Alignment.centerRight;
      case WatermarkPosition.bottomLeft:
        return Alignment.bottomLeft;
      case WatermarkPosition.bottom:
        return Alignment.bottomCenter;
      case WatermarkPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }

  Widget _buildWatermark(BuildContext context) {
    final wm = Transform.translate(
      offset: watermarkOffset ?? Offset.zero,
      child: Transform.rotate(
        angle: watermarkAngle,
        child: Transform.scale(
          scale: watermarkScale,
          child: Opacity(
            opacity: watermarkOpacity,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: watermarkColor ??
                    Theme.of(context).colorScheme.onSurface,
              ),
              child: watermark!,
            ),
          ),
        ),
      ),
    );

    // Center the child inside the aligned slot so text keeps its natural size
    return Align(
      alignment: _alignmentFor(watermarkPosition),
      child: Padding(
        padding: watermarkPadding,
        child: wm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChildEmpty()) {
      return const SizedBox();
    }

    final effectiveRadius = radius ?? 3;
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 3, vertical: 0);

    final decorated = Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor ??
              Theme.of(context).colorScheme.outline.withValues(alpha: .2),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor ??
                Theme.of(context)
                    .colorScheme
                    .surfaceContainer
                    .withValues(alpha: .7),
            blurRadius: 3,
            spreadRadius: 2,
          ),
        ],
        borderRadius: BorderRadius.circular(effectiveRadius),
        color: color ??
            Theme.of(context)
                .colorScheme
                .surfaceContainerLowest
                .withValues(alpha: .8),
      ),
      // ClipRRect inside the decorated container so the shadow isn't clipped.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: watermark == null
            ? Padding(padding: effectivePadding, child: child)
            : Stack(
          // Intrinsic sizing keeps the box the size of the child,
          // NOT the watermark.
          fit: StackFit.passthrough,
          children: [
            // 1) Content first so it defines the stack's size.
            Padding(padding: effectivePadding, child: child),
            // 2) Watermark fills the resolved size and paints ON TOP of
            //    the content — but at low opacity + IgnorePointer it
            //    reads as "behind" visually while never letting the
            //    stack collapse. If you truly need it *behind* the
            //    content (e.g. child has transparent background),
            //    swap the two entries below.
            Positioned.fill(
              child: IgnorePointer(
                child: _buildWatermark(context),
              ),
            ),
          ],
        ),
      ),
    );

    return decorated;
  }
}