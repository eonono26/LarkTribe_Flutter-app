import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/color_swatch.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import '../widgets/product_row.dart';
import '../widgets/review_form.dart';
import '../widgets/wishlist_button.dart';
import 'main_shell.dart';
import 'info/returns_screen.dart';

/// Garment details (Stitch screen 03).
class ProductDetailScreen extends StatefulWidget {
  final String slug;
  const ProductDetailScreen({super.key, required this.slug});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductDetail? _product;
  bool _loading = true;
  bool _error = false;

  List<Review> _reviews = [];
  List<ProductListItem> _pairings = [];
  List<ProductListItem> _similar = [];

  String _color = '';
  String? _size;
  int _imageIndex = 0;
  bool _adding = false;
  PageController _pager = PageController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final p = await ApiService.instance.product(widget.slug);
      if (!mounted) return;
      final colors = _colorsOf(p);
      setState(() {
        _product = p;
        _loading = false;
        _color = colors.isEmpty
            ? ''
            : colors.firstWhere((c) => p.variants.any((v) => v.color == c && v.inStock),
                orElse: () => colors.first);
        final sizes = _sizesOf(p);
        _size = sizes.length == 1 ? sizes.first : null;
      });
      ApiService.instance.track('product_view', extra: {'product': p.id});
      ApiService.instance.reviews(p.id).then((r) {
        if (mounted) setState(() => _reviews = r);
      }).catchError((_) {});
      ApiService.instance.frequentlyBoughtTogether(p.id).then((r) {
        if (mounted) setState(() => _pairings = r);
      });
      ApiService.instance.similarProducts(p.id).then((r) {
        if (mounted) setState(() => _similar = r);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  // ------------------------------------------------------------ variants

  List<String> _colorsOf(ProductDetail p) {
    final seen = <String>[];
    for (final v in p.variants) {
      if (v.color.isNotEmpty && !seen.contains(v.color)) seen.add(v.color);
    }
    return seen;
  }

  List<String> _sizesOf(ProductDetail p) {
    final seen = <String>[];
    for (final v in p.variants) {
      if (v.size.isNotEmpty && !seen.contains(v.size)) seen.add(v.size);
    }
    if (p.availableSizes.isNotEmpty) {
      seen.sort((a, b) {
        final ia = p.availableSizes.indexOf(a);
        final ib = p.availableSizes.indexOf(b);
        return (ia < 0 ? 999 : ia).compareTo(ib < 0 ? 999 : ib);
      });
    }
    return seen;
  }

  ProductVariant? _variantFor(ProductDetail p, String color, String? size) {
    for (final v in p.variants) {
      final colorOk = color.isEmpty || v.color == color;
      final sizeOk = size == null || v.size == size;
      if (colorOk && sizeOk) return v;
    }
    return null;
  }

  int _stockFor(ProductDetail p, String size) {
    final colorVariants = p.variants.where((v) => _color.isEmpty || v.color == _color);
    return colorVariants.where((v) => v.size == size).fold(0, (s, v) => s + v.stock);
  }

  List<ProductImage> _galleryFor(ProductDetail p) {
    if (_color.isEmpty) return p.gallery;
    final matching = p.gallery.where((g) => g.color.isEmpty || g.color == _color).toList();
    return matching.isEmpty ? p.gallery : matching;
  }

  void _selectColor(ProductDetail p, String color) {
    setState(() {
      _color = color;
      _imageIndex = 0;
      if (_size != null && _stockFor(p, _size!) <= 0) _size = null;
    });
    if (_pager.hasClients) _pager.jumpToPage(0);
  }

  int get _availableStock {
    final p = _product!;
    if (p.variants.isEmpty) return p.stock;
    final v = _variantFor(p, _color, _size);
    if (_size == null) {
      return p.variants.where((x) => _color.isEmpty || x.color == _color).fold(0, (s, x) => s + x.stock);
    }
    return v?.stock ?? 0;
  }

  // ----------------------------------------------------------------- bag

  Future<void> _addToBag() async {
    final p = _product!;
    final sizes = _sizesOf(p);
    final colors = _colorsOf(p);
    if (colors.length > 1 && _color.isEmpty) {
      toast(context, 'Choose a colour first');
      return;
    }
    if (sizes.isNotEmpty && _size == null) {
      toast(context, 'Select a size to add this to your bag');
      return;
    }
    int? variantId;
    if (p.variants.isNotEmpty) {
      final v = _variantFor(p, _color, _size);
      if (v == null || !v.inStock) {
        toast(context, 'That combination is sold out');
        return;
      }
      variantId = v.id;
    } else if (!p.inStock) {
      toast(context, 'This piece is sold out');
      return;
    }
    setState(() => _adding = true);
    try {
      await context.read<CartProvider>().addItem(p.id, variantId: variantId);
      ApiService.instance.track('cart_add', extra: {'product': p.id});
      if (!mounted) return;
      toast(context, 'Added to your bag', actionLabel: 'VIEW BAG', onAction: () {
        Navigator.popUntil(context, (r) => r.isFirst);
        shellTab.value = 3;
      });
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  // --------------------------------------------------------------- views

  void _openSizeGuide(ProductDetail p) {
    final g = p.sizeGuide;
    if (g == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .8),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const Eyebrow('Size guide'),
            const SizedBox(height: 6),
            Text(g.name, style: AppType.headlineMd(AppColors.ink)),
            const SizedBox(height: 16),
            if (g.columns.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 38,
                  dataRowMaxHeight: 44,
                  columnSpacing: 24,
                  horizontalMargin: 0,
                  columns: [
                    for (final c in g.columns)
                      DataColumn(label: Text(c.toUpperCase(), style: AppType.labelBadge(AppColors.ink))),
                  ],
                  rows: [
                    for (final r in g.rows)
                      DataRow(cells: [
                        for (var i = 0; i < g.columns.length; i++)
                          DataCell(Text(i < r.length ? r[i] : '', style: AppType.bodyMd(AppColors.ink))),
                      ]),
                  ],
                ),
              ),
            if (g.notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(g.notes, style: AppType.bodySm(AppColors.inkSoft)),
            ],
          ]),
        ),
      ),
    );
  }

  void _openZoom(List<ProductImage> gallery, int start) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(children: [
          PageView.builder(
            controller: PageController(initialPage: start),
            itemCount: gallery.length,
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(child: NetImage(gallery[i].url, fit: BoxFit.contain)),
            ),
          ),
          Positioned(
            top: MediaQuery.of(ctx).padding.top + 8,
            right: 8,
            child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
          ),
        ]),
      ),
    );
  }

  Widget _gallery(ProductDetail p) {
    final images = _galleryFor(p);
    ({String text, TagTone tone})? badge;
    if (!p.inStock) {
      badge = (text: 'Sold out', tone: TagTone.grey);
    } else if (p.onSale && p.discountPercent > 0) {
      badge = (text: '-${p.discountPercent}% off', tone: TagTone.gold);
    } else if (p.isNew) {
      badge = (text: 'New drop', tone: TagTone.ink);
    } else if (p.isFeatured) {
      badge = (text: 'Featured', tone: TagTone.white);
    }
    return AspectRatio(
      aspectRatio: .8,
      child: Stack(fit: StackFit.expand, children: [
        images.isEmpty
            ? const ImageFallback()
            : PageView.builder(
                controller: _pager,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _imageIndex = i),
                itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _openZoom(images, i), child: NetImage(images[i].url)),
              ),
        if (badge != null) Positioned(top: 14, left: 14, child: TagBadge(badge.text, tone: badge.tone)),
        Positioned(top: 12, right: 12, child: WishlistButton(productId: p.id, size: 40)),
        Positioned(
          top: 60,
          right: 12,
          child: GestureDetector(
            onTap: images.isEmpty ? null : () => _openZoom(images, _imageIndex),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(.92), shape: BoxShape.circle),
              child: const Icon(Icons.zoom_in, size: 22),
            ),
          ),
        ),
        if (images.length > 1) ...[
          Positioned(
            left: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.85), borderRadius: BorderRadius.circular(AppRadii.pill)),
              child: Row(children: [
                for (var i = 0; i < images.length && i < 8; i++)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _imageIndex ? AppColors.ink : AppColors.stone400),
                  ),
              ]),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.55), borderRadius: BorderRadius.circular(AppRadii.pill)),
              child: Text('${_imageIndex + 1} / ${images.length}',
                  style: AppType.bodySm(Colors.white).copyWith(fontSize: 11)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _colorway(ProductDetail p, List<String> colors) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceLow,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: 'COLOURWAY: ', style: AppType.labelBadge(AppColors.inkSoft)),
              TextSpan(text: _color.toUpperCase(), style: AppType.labelBadge(AppColors.ink)),
            ])),
          ),
          Text('${colors.length} ${colors.length == 1 ? 'COLOUR' : 'COLOURS'}',
              style: AppType.labelBadge(AppColors.inkSoft)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 14, runSpacing: 10, children: [
          for (final c in colors)
            ColorDot(c, size: 34, selected: c == _color, onTap: () => _selectColor(p, c)),
        ]),
      ]),
    );
  }

  Widget _sizes(ProductDetail p, List<String> sizes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('SELECT SIZE', style: AppType.labelBadge(AppColors.ink))),
          if (p.sizeGuide != null)
            GestureDetector(
              onTap: () => _openSizeGuide(p),
              child: Row(children: [
                const Icon(Icons.straighten, size: 14, color: AppColors.goldDeep),
                const SizedBox(width: 4),
                Text('SIZE GUIDE',
                    style: AppType.labelBadge(AppColors.goldDeep)
                        .copyWith(decoration: TextDecoration.underline)),
              ]),
            ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in sizes) _sizeBox(p, s),
        ]),
        if (_size != null && _stockFor(p, _size!) > 0 && _stockFor(p, _size!) <= 5) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            color: AppColors.goldTint,
            child: Row(children: [
              const Icon(Icons.schedule, size: 18, color: AppColors.goldDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Size $_size is in demand — only ${_stockFor(p, _size!)} left.',
                    style: AppType.bodySm(AppColors.goldDeep).copyWith(fontWeight: FontWeight.w500)),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _sizeBox(ProductDetail p, String s) {
    final stock = _stockFor(p, s);
    final selected = _size == s;
    final out = stock <= 0;
    final sub = out ? 'Sold out' : (stock <= 5 ? '$stock left' : 'Avail');
    return GestureDetector(
      onTap: out ? null : () => setState(() => _size = s),
      child: Container(
        width: 62,
        height: 58,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(s,
              style: AppType.bodyMd(
                      selected ? Colors.white : (out ? AppColors.stone400 : AppColors.ink))
                  .copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: out ? TextDecoration.lineThrough : null)),
          const SizedBox(height: 2),
          Text(sub,
              style: AppType.bodySm(selected
                      ? AppColors.goldOnDark
                      : (out ? AppColors.stone400 : AppColors.inkSoft))
                  .copyWith(fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _accordion(String title, Widget child, {bool open = false}) {
    return _Accordion(title: title, initiallyOpen: open, child: child);
  }

  Widget _specBox(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: AppType.labelBadge(AppColors.inkSoft).copyWith(fontSize: 9)),
            const SizedBox(height: 4),
            Text(value, style: AppType.bodyMd(AppColors.ink).copyWith(fontSize: 13)),
          ]),
        ),
      );

  Widget _details(ProductDetail p) {
    final hasMaterial = p.materials.isNotEmpty || p.features.isNotEmpty || p.brand != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(children: [
        if (hasMaterial)
          _accordion(
            'Material & craftsmanship',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final f in p.features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Padding(
                        padding: EdgeInsets.only(top: 7, right: 10),
                        child: Icon(Icons.circle, size: 4, color: AppColors.ink)),
                    Expanded(child: Text(f, style: AppType.bodyMd(AppColors.inkSoft))),
                  ]),
                ),
              if (p.materials.isNotEmpty || p.brand != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  if (p.materials.isNotEmpty) _specBox('Composition', p.materials),
                  if (p.materials.isNotEmpty && p.brand != null) const SizedBox(width: 8),
                  if (p.brand != null) _specBox('Brand', p.brand!.name),
                ]),
              ],
            ]),
            open: true,
          ),
        if (p.careInstructions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _accordion('Care instructions', Text(p.careInstructions, style: AppType.bodyMd(AppColors.inkSoft))),
        ],
        if (p.sizeGuide != null) ...[
          const SizedBox(height: 8),
          _accordion(
              'Silhouette & fit guide',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.sizeGuide!.notes.isNotEmpty
                    ? p.sizeGuide!.notes
                    : 'See the full measurements for ${p.sizeGuide!.name}.',
                    style: AppType.bodyMd(AppColors.inkSoft)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _openSizeGuide(p),
                  child: Text('OPEN SIZE GUIDE',
                      style: AppType.labelBadge(AppColors.goldDeep)
                          .copyWith(decoration: TextDecoration.underline)),
                ),
              ])),
        ],
        const SizedBox(height: 8),
        _accordion(
          'Delivery & returns',
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Delivery is KSh ${formatNumber(StoreRules.deliveryFee)} — free on orders from '
              'KSh ${formatNumber(StoreRules.freeDeliveryThreshold)}. Track your courier live from your orders.',
              style: AppType.bodyMd(AppColors.inkSoft),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ReturnsScreen())),
              child: Text('READ RETURNS POLICY',
                  style: AppType.labelBadge(AppColors.goldDeep)
                      .copyWith(decoration: TextDecoration.underline)),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        _accordion(
          'Reviews (${_reviews.length})',
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_reviews.isEmpty)
              Text('No reviews yet — be the first.', style: AppType.bodyMd(AppColors.inkSoft)),
            for (final r in _reviews)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(i <= r.rating ? Icons.star : Icons.star_border,
                          size: 14, color: AppColors.goldDeep),
                    const SizedBox(width: 8),
                    Text(r.user, style: AppType.bodySm(AppColors.inkSoft)),
                  ]),
                  if (r.comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(r.comment, style: AppType.bodyMd(AppColors.ink)),
                  ],
                ]),
              ),
            const Divider(),
            const SizedBox(height: 10),
            ReviewForm(
              productId: p.id,
              onSubmitted: () => ApiService.instance.reviews(p.id).then((r) {
                if (mounted) setState(() => _reviews = r);
              }),
            ),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: AppColors.paper, appBar: AtelierAppBar(title: 'Product details'), body: LarkLoading());
    }
    final p = _product;
    if (_error || p == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: const AtelierAppBar(title: 'Product details'),
        body: LarkErrorState(onRetry: _load),
      );
    }

    final colors = _colorsOf(p);
    final sizes = _sizesOf(p);
    final soldOut = p.variants.isEmpty ? !p.inStock : p.variants.every((v) => !v.inStock);
    final rating = double.tryParse(p.ratingAvg) ?? 0;
    final collection = (p.brand?.name.isNotEmpty ?? false) ? p.brand!.name : p.vendorName;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const AtelierAppBar(title: 'Product details'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _gallery(p),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text('${collection.toUpperCase()}${collection.isEmpty ? '' : ' COLLECTION'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.labelBadge(AppColors.ink).copyWith(letterSpacing: 1.4)),
                ),
                if (p.ratingCount > 0) ...[
                  const Icon(Icons.star_border, size: 16),
                  const SizedBox(width: 4),
                  Text('${rating.toStringAsFixed(1)} (${p.ratingCount})', style: AppType.bodySm(AppColors.ink)),
                ],
              ]),
              const SizedBox(height: 10),
              Text(p.name, style: AppType.headlineLg(AppColors.ink)),
              const SizedBox(height: 12),
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
                Text(formatKES(p.price), style: AppType.headlineMd(AppColors.ink).copyWith(fontSize: 26)),
                if (p.onSale)
                  Text(formatKES(p.compareAtPrice!),
                      style: AppText.price(15, color: AppColors.subtext)
                          .copyWith(decoration: TextDecoration.lineThrough)),
                Text(
                    'FREE DELIVERY OVER KSH ${formatNumber(StoreRules.freeDeliveryThreshold)}',
                    style: AppType.labelBadge(AppColors.inkSoft).copyWith(fontSize: 9.5)),
              ]),
              if (p.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(p.description, style: AppType.bodyMd(AppColors.inkSoft)),
              ],
            ]),
          ),
          if (colors.isNotEmpty) ...[const SizedBox(height: 22), _colorway(p, colors)],
          if (sizes.isNotEmpty) _sizes(p, sizes),
          _details(p),
          if (_pairings.isNotEmpty) ...[
            const SizedBox(height: 36),
            ProductRow(eyebrow: 'Editorial pairings', title: 'Complete The Look', products: _pairings, cardWidth: 150),
          ],
          if (_similar.isNotEmpty) ...[
            const SizedBox(height: 36),
            ProductRow(eyebrow: 'More to explore', title: 'You May Also Like', products: _similar, cardWidth: 150),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Material(
                color: soldOut ? AppColors.surface : AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadii.xs),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  onTap: (soldOut || _adding) ? null : _addToBag,
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _adding
                        ? const Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                        : Row(children: [
                            Expanded(
                              child: Text(soldOut ? 'SOLD OUT' : 'ADD TO BAG',
                                  style: AppType.labelCaps(soldOut ? AppColors.subtext : Colors.white)
                                      .copyWith(letterSpacing: 1.6)),
                            ),
                            if (!soldOut)
                              Text(formatKES(p.price), style: AppText.price(15, color: Colors.white)),
                          ]),
                  ),
                ),
              ),
              if (!soldOut && _availableStock > 0 && _availableStock <= 5 && _size == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Only $_availableStock left in this colour',
                      style: AppType.bodySm(AppColors.goldDeep)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Accordion extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyOpen;
  const _Accordion({required this.title, required this.child, this.initiallyOpen = false});

  @override
  State<_Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<_Accordion> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLow,
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: Text(widget.title.toUpperCase(), style: AppType.labelCaps(AppColors.ink))),
              Icon(_open ? Icons.remove : Icons.add, size: 18),
            ]),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Align(alignment: Alignment.centerLeft, child: widget.child),
          ),
      ]),
    );
  }
}
