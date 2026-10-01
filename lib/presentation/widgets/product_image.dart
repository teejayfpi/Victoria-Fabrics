import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Displays a product image from either a bundled asset path (prefix
/// `assets/`) or a remote URL, with a consistent placeholder and error state.
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

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (_, __) =>
          Container(color: AppColors.divider.withOpacity(0.3)),
      errorWidget: (_, __, ___) => error,
    );
  }
}
