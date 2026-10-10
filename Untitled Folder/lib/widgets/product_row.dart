import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'product_card.dart';

/// Horizontal strip of product tiles with an editorial heading and optional
/// arrow buttons (the "Trending" row in the Discover mockup).
class ProductRow extends StatefulWidget {
  final String title;
  final String? eyebrow;
  final List<ProductListItem> products;
  final VoidCallback? onViewAll;
  final String viewAllLabel;
  final bool arrows;
  final double cardWidth;

  const ProductRow({
    super.key,
    required this.title,
    required this.products,
    this.eyebrow,
    this.onViewAll,
    this.viewAllLabel = 'View all',
    this.arrows = false,
    this.cardWidth = 172,
  });

  @override
  State<ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<ProductRow> {
  final _controller = ScrollController();

  void _nudge(int dir) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + dir * (widget.cardWidth + 12) * 1.5)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(target, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _arrow(IconData icon, int dir) => GestureDetector(
        onTap: () => _nudge(dir),
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(left: 8),
          decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          eyebrow: widget.eyebrow,
          title: widget.title,
          trailing: widget.arrows ? null : (widget.onViewAll == null ? null : widget.viewAllLabel),
          onTrailing: widget.onViewAll,
          trailingWidget: widget.arrows
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    _arrow(Icons.chevron_left, -1),
                    _arrow(Icons.chevron_right, 1),
                  ]),
                )
              : null,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: widget.cardWidth / .75 + 62,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: widget.cardWidth,
              child: ProductCard(product: widget.products[i], compact: true),
            ),
          ),
        ),
      ],
    );
  }
}
