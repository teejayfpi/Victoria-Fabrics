import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Displays a product image from a bundled asset path (prefix `assets/`), an
/// inline `data:` URI (free-tier fallback when Firebase Storage is
/// unavailable), or a remote URL, with a consistent placeholder and error
/// state.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String imageUrl;
  final BoxFit fit;

  /// Rendered instead of the default placeholder when there is no usable image.
  /// Lets callers keep a category-specific icon.
  final Widget? fallback;

  Widget get _fallbackWidget => fallback ?? _Placeholder(fit: fit);

  bool get _isAsset =>
      imageUrl.startsWith('assets/') || imageUrl.startsWith('asset://');

  bool get _isInlineData => imageUrl.startsWith('data:image/');

  /// A blank URL is a valid state (a product saved without a photo) and must
  /// render the placeholder rather than a broken-image box. Without this guard
  /// `CachedNetworkImage` throws on an empty string, which fails the whole
  /// widget subtree — the cause of otherwise inexplicable blank screens.
  bool get _isEmpty => imageUrl.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    if (_isEmpty) return _fallbackWidget;

    if (_isAsset) {
      final path = imageUrl.replaceFirst('asset://', '');
      return Image.asset(path, fit: fit, errorBuilder: (_, __, ___) => _fallbackWidget);
    }

    if (_isInlineData) {
      final bytes = _decodeInline();
      if (bytes == null) return _fallbackWidget;
      return Image.memory(bytes, fit: fit, errorBuilder: (_, __, ___) => _fallbackWidget);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (_, __) => _fallbackWidget,
      errorWidget: (_, __, ___) => _fallbackWidget,
    );
  }

  Uint8List? _decodeInline() {
    try {
      return base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1));
    } catch (_) {
      return null;
    }
  }
}

/// Consistent "no image" treatment for every consumer of [ProductImage].
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.fit});

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.divider.withValues(alpha: 0.3),
      child: const Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: 44,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
