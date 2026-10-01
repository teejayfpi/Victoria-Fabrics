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
  });

  final String imageUrl;
  final BoxFit fit;

  bool get _isAsset =>
      imageUrl.startsWith('assets/') || imageUrl.startsWith('asset://');

  bool get _isInlineData => imageUrl.startsWith('data:image/');

  @override
  Widget build(BuildContext context) {
    final error = Container(
      color: AppColors.divider.withOpacity(0.3),
      child: const Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: 44,
          color: AppColors.textMuted,
        ),
      ),
    );

    if (_isAsset) {
      final path = imageUrl.replaceFirst('asset://', '');
      return Image.asset(path, fit: fit, errorBuilder: (_, __, ___) => error);
    }

    if (_isInlineData) {
      final bytes = _decodeInline();
      if (bytes == null) return error;
      return Image.memory(bytes, fit: fit, errorBuilder: (_, __, ___) => error);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (_, __) =>
          Container(color: AppColors.divider.withOpacity(0.3)),
      errorWidget: (_, __, ___) => error,
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
