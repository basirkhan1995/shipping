import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../Services/api_services.dart';

enum ShapeStyle { circle, roundedRectangle }

class ImageHelper {
  /// ---------------------------------------------------------------
  /// Main helper: renders an image with a camera overlay + tap zones.
  ///
  /// Sources (in priority order):
  ///   1. `localImageBytes`  — Uint8List from crop / picker (in-memory)
  ///   2. `imageName`        — file name resolved against `ApiServices.imageUrl`
  ///   3. neither            — placeholder icon
  ///
  /// Every source is validated before display, so `Invalid image data`
  /// can never crash the widget tree.
  /// ---------------------------------------------------------------
  static Widget stakeholderProfile({
    required String? imageName,
    Uint8List? localImageBytes,

    // Size
    double size = 80,

    // Image Fit
    BoxFit fit = BoxFit.cover,

    // Placeholders / errors
    Color placeholderColor = const Color.fromRGBO(128, 128, 128, 0.2),
    Color errorColor = Colors.red,
    IconData placeholderIcon = Icons.person,
    IconData errorIcon = Icons.error,

    // Shape
    ShapeStyle shapeStyle = ShapeStyle.circle,
    double borderRadius = 5,
    BoxBorder? border,

    // Camera icon
    bool showCameraIcon = false,
    IconData cameraIcon = Icons.camera_alt,
    double cameraIconSize = 20,
    Color cameraIconBackground = Colors.black54,
    Color cameraIconColor = Colors.white,
    Alignment cameraIconAlignment = Alignment.bottomRight,

    // Tap handlers
    VoidCallback? onCameraTap,
    VoidCallback? onImageTap,
  }) {
    /// ---------- Build main image (all safe paths) ----------
    Widget mainImage;

    if (localImageBytes != null && localImageBytes.isNotEmpty && _isValidImageBytes(localImageBytes)) {
      mainImage = _safeMemoryImage(
        bytes: localImageBytes,
        fit: fit,
        size: size,
        errorColor: errorColor,
        errorIcon: errorIcon,
      );
    } else if (imageName == null || imageName.isEmpty) {
      mainImage = Container(
        color: placeholderColor,
        child: Icon(
          placeholderIcon,
          size: size * 0.5,
          color: Colors.white,
        ),
      );
    } else {
      mainImage = _safeNetworkImage(
        url: "${ApiServices.imageUrl}$imageName",
        fit: fit,
        size: size,
        errorColor: errorColor,
        errorIcon: errorIcon,
      );
    }

    /// ---------- Shape-based clipping ----------
    Widget clippedImage = ClipRRect(
      borderRadius: shapeStyle == ShapeStyle.circle
          ? BorderRadius.circular(size)
          : BorderRadius.circular(borderRadius),
      child: mainImage,
    );

    /// ---------- Final widget with border and tap handling ----------
    return GestureDetector(
      onTap: onImageTap,
      child: Stack(
        children: [
          /// Outer border container
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: shapeStyle == ShapeStyle.circle
                  ? BoxShape.circle
                  : BoxShape.rectangle,
              borderRadius: shapeStyle == ShapeStyle.circle
                  ? null
                  : BorderRadius.circular(borderRadius),
              border: border,
            ),
            clipBehavior: Clip.none,
            child: clippedImage,
          ),

          /// Camera overlay with separate tap
          if (showCameraIcon)
            Positioned.fill(
              child: Align(
                alignment: cameraIconAlignment,
                child: GestureDetector(
                  onTap: onCameraTap,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: cameraIconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      cameraIcon,
                      size: cameraIconSize,
                      color: cameraIconColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// ---------------------------------------------------------------
  /// Full-screen image viewer (tap-to-dismiss).
  /// ---------------------------------------------------------------
  static Future<void> showImageViewer({
    required BuildContext context,
    required String? imageName,
    Uint8List? localImageBytes,
    String? heroTag,
  }) async {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        final image = InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildFullScreenImage(
            imageName: imageName,
            localImageBytes: localImageBytes,
          ),
        );

        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black87,
                  child: Center(
                    child: heroTag == null
                        ? image
                        : Hero(tag: heroTag, child: image),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(dialogContext),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ---------------------------------------------------------------
  /// Full-screen image body (also safe against invalid bytes).
  /// ---------------------------------------------------------------
  static Widget _buildFullScreenImage({
    required String? imageName,
    Uint8List? localImageBytes,
  }) {
    if (localImageBytes != null && localImageBytes.isNotEmpty && _isValidImageBytes(localImageBytes)) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.memory(
          localImageBytes,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _noImagePlaceholder(),
        ),
      );
    } else if (imageName == null || imageName.isEmpty) {
      return _noImagePlaceholder();
    } else {
      return Container(
        padding: const EdgeInsets.all(15),
        width: double.infinity,
        height: double.infinity,
        child: _safeNetworkImage(
          url: "${ApiServices.imageUrl}$imageName",
          fit: BoxFit.contain,
          size: 200,
          errorColor: Colors.grey[900]!,
          errorIcon: Icons.error,
          fullScreen: true,
        ),
      );
    }
  }

  static Widget _noImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 100, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'No Image Available',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------------------------------------------------------
  /// Safe network image:
  ///   1. download via `http` (small, cheap)
  ///   2. validate magic bytes
  ///   3. render via `Image.memory` (with errorBuilder)
  ///   4. fall back to the error icon on any failure
  ///
  /// Bypasses `CachedNetworkImage` entirely for the display path,
  /// so a non-image 200-OK response can no longer crash.
  /// ---------------------------------------------------------------
  static Widget _safeNetworkImage({
    required String url,
    required BoxFit fit,
    required double size,
    required Color errorColor,
    required IconData errorIcon,
    bool fullScreen = false,
  }) {
    return FutureBuilder<Uint8List?>(
      future: _fetchValidatedImage(url),
      builder: (context, snap) {
        // Loading
        if (snap.connectionState != ConnectionState.done) {
          return Center(
            child: SizedBox(
              width: (fullScreen ? 40.0 : size * 0.35).clamp(16.0, 60.0).toDouble(),
              height: (fullScreen ? 40.0 : size * 0.35).clamp(16.0, 60.0).toDouble(),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          );
        }

        // Error / invalid bytes
        final bytes = snap.data;
        if (bytes == null) {
          return _errorPlaceholder(
            errorColor: errorColor,
            errorIcon: errorIcon,
            size: fullScreen ? 100 : size * 0.5,
          );
        }

        // Success — render safely
        return Image.memory(
          bytes,
          fit: fit,
          width: fullScreen ? double.infinity : size,
          height: fullScreen ? double.infinity : size,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _errorPlaceholder(
            errorColor: errorColor,
            errorIcon: errorIcon,
            size: fullScreen ? 100 : size * 0.5,
          ),
        );
      },
    );
  }

  static Widget _errorPlaceholder({
    required Color errorColor,
    required IconData errorIcon,
    required double size,
  }) {
    return Container(
      color: errorColor,
      child: Icon(errorIcon, size: size, color: Colors.white),
    );
  }

  /// Download the URL and validate it's a real image. Returns `null`
  /// on any problem (network, empty body, non-image bytes).
  static Future<Uint8List?> _fetchValidatedImage(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        debugPrint('ImageHelper: HTTP ${res.statusCode} for $url');
        return null;
      }
      final bytes = res.bodyBytes;
      if (!_isValidImageBytes(bytes)) {
        debugPrint('ImageHelper: non-image bytes (${bytes.length} B) from $url');
        return null;
      }
      return bytes;
    } catch (e) {
      debugPrint('ImageHelper: fetch failed for $url — $e');
      return null;
    }
  }

  /// Sniff the magic bytes of common image formats.
  /// Rejects empty, too-short, or unknown-prefix payloads.
  static bool _isValidImageBytes(Uint8List bytes) {
    if (bytes.length < 12) return false;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // GIF: 47 49 46 38 ('GIF8')
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }
    // WebP: 'RIFF' xxxx 'WEBP'
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return true;
    return false;
  }

  /// Memory image with `errorBuilder` for the (rare) case the bytes
  /// pass magic-byte sniffing but still fail to decode.
  static Widget _safeMemoryImage({
    required Uint8List bytes,
    required BoxFit fit,
    required double size,
    required Color errorColor,
    required IconData errorIcon,
  }) {
    return Image.memory(
      bytes,
      fit: fit,
      width: size,
      height: size,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _errorPlaceholder(
        errorColor: errorColor,
        errorIcon: errorIcon,
        size: size * 0.5,
      ),
    );
  }

  /// Kept for compatibility — callers that still want the CDN cache
  /// can use this. It no longer crashes on non-image 200-OK responses
  /// because `errorWidget` catches decode failures as well.
  static Widget cachedNetworkImageSafe({
    required String url,
    required BoxFit fit,
    required double size,
    required Color errorColor,
    required IconData errorIcon,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: (size * MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.first,
      ).devicePixelRatio).round(),
      placeholder: (_, _) => Center(
        child: SizedBox(
          width: size * 0.35,
          height: size * 0.35,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, _, _) => _errorPlaceholder(
        errorColor: errorColor,
        errorIcon: errorIcon,
        size: size * 0.5,
      ),
    );
  }
}