import 'dart:convert';
import 'dart:typed_data';

/// Central place for turning a raw `comLogo` string (as delivered by the
/// server) into usable image bytes / widgets.
///
/// The server may send the logo in any of these shapes:
///
///   1. `data:image/png;base64,iVBOR...`   ← current contract
///   2. `iVBORw0KGgo...`                  ← raw base64 (legacy)
///   3. `https://...` / `http://...`      ← remote URL (future)
///   4. `null` / `''`                     ← no logo
///
/// Every consumer (sidebar widget, PDF header, Excel export, ...) should
/// go through this class so decoding behaviour never diverges.
class CompanyLogoUtils {
  CompanyLogoUtils._(); // non-instantiable

  // ────────────────────────────────────────────────────────────
  //  Decoding
  // ────────────────────────────────────────────────────────────

  /// Returns decoded image bytes from [raw], or `null` when:
  ///   • [raw] is null / empty
  ///   • [raw] is a URL (use [isUrl] + `Image.network` for those)
  ///   • the base64 payload is invalid
  ///   • the decoded bytes don't look like a supported image format
  ///
  /// Handles both `data:` URLs and raw base64 transparently.
  static Uint8List? decodeToBytes(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (isUrl(raw)) return null; // caller should use network loading

    final payload = _extractBase64Payload(raw);
    if (payload == null) return null;

    Uint8List bytes;
    try {
      // Strip whitespace/newlines that break base64Decode.
      final clean = payload.trim().replaceAll(RegExp(r'\s+'), '');
      bytes = base64Decode(clean);
    } catch (_) {
      return null;
    }

    if (bytes.isEmpty) return null;
    if (!looksLikeImage(bytes)) return null;
    return bytes;
  }

  /// `true` when [raw] is an http(s) URL rather than inline base64.
  static bool isUrl(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    return raw.startsWith('http://') || raw.startsWith('https://');
  }

  /// Returns the raw base64 payload of [raw]:
  ///   • strips a `data:...;base64,` prefix if present
  ///   • returns [raw] unchanged otherwise
  ///   • returns `null` for malformed `data:` URLs
  static String? _extractBase64Payload(String raw) {
    if (!raw.startsWith('data:')) return raw;

    final comma = raw.indexOf(',');
    if (comma == -1 || comma == raw.length - 1) return null;
    return raw.substring(comma + 1);
  }

  // ────────────────────────────────────────────────────────────
  //  Validation
  // ────────────────────────────────────────────────────────────

  /// Cheap magic-number sniff so corrupted bytes never reach
  /// `Image.memory` / `pw.MemoryImage`.
  static bool looksLikeImage(Uint8List bytes) {
    if (bytes.length < 12) return false;

    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // GIF
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }
    // WebP ("RIFF....WEBP")
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
    // BMP
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return true;

    return false;
  }

  /// Convenience: decode and validate in one call.
  /// Returns `null` if the logo is unusable.
  static Uint8List? safeBytes(String? raw) => decodeToBytes(raw);

  // ────────────────────────────────────────────────────────────
  //  Re-encoding (rarely needed, but handy for exports)
  // ────────────────────────────────────────────────────────────

  /// Converts any supported input into a pure base64 string
  /// (no `data:` prefix). Returns `null` when decoding fails.
  static String? toPureBase64(String? raw) {
    final bytes = decodeToBytes(raw);
    if (bytes == null) return null;
    return base64Encode(bytes);
  }

  /// Converts any supported input into a `data:` URL. Returns `null`
  /// when the input cannot be decoded.
  static String? toDataUrl(String? raw, {String mime = 'image/png'}) {
    final pure = toPureBase64(raw);
    if (pure == null) return null;
    return 'data:$mime;base64,$pure';
  }
}