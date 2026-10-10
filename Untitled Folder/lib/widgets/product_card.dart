import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../screens/product_detail_screen.dart';
import 'color_swatch.dart';
import 'common.dart';
import 'wishlist_button.dart';

String formatKES(String amount) {
  final n = double.tryParse(amount) ?? 0;
  return 'KSh ${formatNumber(n)}';
}

String formatNumber(num n) {
  final whole = n == n.roundToDouble();
  final s = whole ? n.toStringAsFixed(0) : n.toStringAsFixed(2);

  final parts = s.split('.');

  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
}

String mediaUrl(String? path) =>
    ApiService.instance.absoluteMediaUrl(path);

/// Cover image with the shared placeholder + fade.
class NetImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;

  const NetImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final u = mediaUrl(url);

    if (u.isEmpty) {
      return const ImageFallback();
    }

    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => Container(
        color: AppColors.surfaceLow,
      ),
      errorWidget: (_, __, ___) => const ImageFallback(),
    );
  }
}

/// Editorial product card.
///
/// Designed to work in narrow 2-column grids without horizontal
/// RenderFlex overflow.
class ProductCard extends StatelessWidget {
  final ProductListItem product;

  /// Narrower typography for horizontal carousels.
  final bool compact;

  /// Optional bottom-left image label.
  final String? imageBadge;

  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
    this.imageBadge,
  });

  ({String text, TagTone tone})? get _badge {
    if (!product.inStock) {
      return (
        text: 'Sold out',
        tone: TagTone.grey,
      );
    }

    if (product.lowStock) {
      return (
        text: 'Low stock: ${product.stock} left',
        tone: TagTone.red,
      );
    }

    if (product.onSale && product.discountPercent > 0) {
      return (
        text: '-${product.discountPercent}%',
        tone: TagTone.gold,
      );
    }

    if (product.isNew) {
      return (
        text: 'New drop',
        tone: TagTone.ink,
      );
    }

    if (product.isFeatured) {
      return (
        text: 'Featured',
        tone: TagTone.white,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              slug: product.slug,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// PRODUCT IMAGE
          AspectRatio(
            aspectRatio: .75,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetImage(product.imageUrl),

                if (badge != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: TagBadge(
                      badge.text,
                      tone: badge.tone,
                    ),
                  ),

                Positioned(
                  top: 8,
                  right: 8,
                  child: WishlistButton(
                    productId: product.id,
                  ),
                ),

                if (imageBadge != null &&
                    imageBadge!.isNotEmpty)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      color: Colors.white.withOpacity(.88),
                      child: Text(
                        imageBadge!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType
                            .labelBadge(AppColors.ink)
                            .copyWith(
                              fontSize: 9,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// PRODUCT NAME
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType
                .headlineSm(AppColors.ink)
                .copyWith(
                  fontSize: compact ? 15.5 : 17,
                ),
          ),

          const SizedBox(height: 4),

          /// PRICE + META
          _ProductMetaRow(
            product: product,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

/// Responsive price/meta row.
///
/// The important change here is that the price section gets an
/// Expanded constraint and the colour/category section is also
/// constrained. This prevents narrow 2-column cards from overflowing.
class _ProductMetaRow extends StatelessWidget {
  final ProductListItem product;
  final bool compact;

  const _ProductMetaRow({
    required this.product,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// PRICE SECTION
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  formatKES(product.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.price(
                    compact ? 13 : 14,
                  ),
                ),
              ),

              if (product.onSale &&
                  product.compareAtPrice != null) ...[
                const SizedBox(width: 5),

                Flexible(
                  child: Text(
                    formatKES(product.compareAtPrice!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText
                        .price(
                          11.5,
                          color: AppColors.subtext,
                        )
                        .copyWith(
                          decoration:
                              TextDecoration.lineThrough,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 6),

        /// COLOURS / CATEGORY
        if (product.colors.isNotEmpty)
          Flexible(
            flex: 0,
            child: _ColorDots(
              colors: product.colors,
            ),
          )
        else if ((product.categoryName ?? '').isNotEmpty)
          Flexible(
            child: Text(
              product.categoryName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppType.bodySm(
                AppColors.inkSoft,
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact colour-dot group.
///
/// Keeps the dots from becoming wider than the card.
class _ColorDots extends StatelessWidget {
  final List<dynamic> colors;

  const _ColorDots({
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final visibleColors = colors.take(3).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < visibleColors.length; i++)
          Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 3,
            ),
            child: ColorDot(
              visibleColors[i],
              size: 10,
            ),
          ),
      ],
    );
  }
}

/// Two-column product grid.
///
/// Products are laid out in rows of two so the left and right cards share
/// the same top and bottom edges. Cards use the same image ratio and a
/// single-line name/price block, so every card is the same height.
///
/// Non-scrolling — place inside a ListView/SingleChildScrollView.
class MasonryProducts extends StatelessWidget {
  final List<ProductListItem> products;
  final EdgeInsetsGeometry padding;
  final bool showCategoryBadge;

  const MasonryProducts({
    super.key,
    required this.products,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 16,
    ),
    this.showCategoryBadge = false,
  });

  static const double _gap = 12;
  static const double _rowSpacing = 26;

  Widget _cell(ProductListItem p) => ProductCard(
        product: p,
        imageBadge: showCategoryBadge ? p.categoryName : null,
      );

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var i = 0; i < products.length; i += 2) {
      final hasRight = i + 1 < products.length;

      rows.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i + 2 < products.length ? _rowSpacing : 0,
          ),
          // IntrinsicHeight + stretch keeps both cards on the exact same
          // top and bottom line even if one card's text wraps differently.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _cell(products[i])),
                const SizedBox(width: _gap),
                // Empty slot keeps a lone last card the same width.
                Expanded(
                  child: hasRight
                      ? _cell(products[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Column(children: rows),
    );
  }
}
