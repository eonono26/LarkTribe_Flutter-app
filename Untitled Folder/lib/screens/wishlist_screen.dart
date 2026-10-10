import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';
import '../services/wishlist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_gate.dart';
import '../widgets/chatbot_sheet.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'main_shell.dart';
import 'product_detail_screen.dart';

/// Lookbook — the customer's saved pieces (Stitch screen 10).
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String? _dept;
  String _sort = 'recent'; // recent | price_asc | price_desc
  bool _select = false;
  final Set<int> _selected = {}; // product ids
  List<ProductListItem> _pairings = [];
  bool _movingAll = false;

  @override
  void initState() {
    super.initState();
    shellTab.addListener(_onTab);
    _loadPairings();
  }

  @override
  void dispose() {
    shellTab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (shellTab.value == 2 && mounted) {
      context.read<WishlistProvider>().refresh();
      _loadPairings();
    }
  }

  Future<void> _loadPairings() async {
    if (!ApiService.instance.isLoggedIn) return;
    final r = await ApiService.instance.recommendedForYou();
    if (mounted) setState(() => _pairings = r);
  }

  /// Adds straight to the bag when no choice is needed; otherwise opens the
  /// product so the person can pick a size/colour. Returns true if added.
  Future<bool> _moveToBag(ProductListItem p, {bool quiet = false}) async {
    if (!p.inStock) {
      if (!quiet) toast(context, 'This piece is sold out right now.');
      return false;
    }
    if (p.needsSize || p.colors.length > 1) {
      if (!quiet) {
        await Navigator.push(
            context, MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: p.slug)));
      }
      return false;
    }
    final variantId = p.colors.length == 1 ? p.colorVariantIds[p.colors.first] : null;
    try {
      await context.read<CartProvider>().addItem(p.id, variantId: variantId);
      ApiService.instance.track('cart_add', extra: {'product': p.id});
      if (!quiet && mounted) {
        toast(context, 'Moved to your bag', actionLabel: 'VIEW BAG', onAction: () => shellTab.value = 3);
      }
      return true;
    } catch (e) {
      if (!quiet && mounted) toast(context, e.toString());
      return false;
    }
  }

  Future<void> _moveSelected(List<WishlistItem> all) async {
    setState(() => _movingAll = true);
    var added = 0;
    var needChoice = 0;
    for (final w in all.where((w) => _selected.contains(w.product.id))) {
      final ok = await _moveToBag(w.product, quiet: true);
      if (ok) {
        added++;
      } else {
        needChoice++;
      }
    }
    if (!mounted) return;
    setState(() {
      _movingAll = false;
      _select = false;
      _selected.clear();
    });
    toast(
      context,
      added > 0
          ? 'Added $added to your bag${needChoice > 0 ? ' — $needChoice need a size or colour' : ''}'
          : 'Those pieces need a size or colour — open them to choose.',
      actionLabel: added > 0 ? 'VIEW BAG' : null,
      onAction: () => shellTab.value = 3,
    );
  }

  Widget _tile(WishlistItem w, double width) {
    final p = w.product;
    final selected = _selected.contains(p.id);
    ({String text, TagTone tone})? badge;
    if (!p.inStock) {
      badge = (text: 'Sold out', tone: TagTone.grey);
    } else if (p.lowStock) {
      badge = (text: 'Low stock: ${p.stock} left', tone: TagTone.red);
    } else if (p.onSale && p.discountPercent > 0) {
      badge = (text: '-${p.discountPercent}%', tone: TagTone.gold);
    }
    return GestureDetector(
      onTap: _select
          ? () => setState(() => selected ? _selected.remove(p.id) : _selected.add(p.id))
          : () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: p.slug))),
      child: Container(
        color: Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: .75,
            child: Stack(fit: StackFit.expand, children: [
              NetImage(p.imageUrl),
              if (badge != null) Positioned(top: 10, left: 10, child: TagBadge(badge.text, tone: badge.tone)),
              Positioned(
                top: 8,
                right: 8,
                child: _select
                    ? Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: selected ? AppColors.ink : Colors.white.withOpacity(.92)),
                        child: Icon(selected ? Icons.check : Icons.add, size: 17, color: selected ? Colors.white : AppColors.ink),
                      )
                    : Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(.92), shape: BoxShape.circle),
                        child: GestureDetector(
                          onTap: () async {
                            try {
                              await context.read<WishlistProvider>().toggle(p.id);
                            } catch (e) {
                              if (mounted) toast(context, e.toString());
                            }
                          },
                          child: const Icon(Icons.favorite, size: 17),
                        ),
                      ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text((p.categoryName ?? '').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.labelBadge(AppColors.inkSoft).copyWith(fontSize: 9)),
                ),
                Text(formatKES(p.price), style: AppText.price(13.5, weight: FontWeight.w600)),
              ]),
              const SizedBox(height: 5),
              Text(p.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.headlineSm(AppColors.ink).copyWith(fontSize: 16)),
              const SizedBox(height: 3),
              Text(
                [if (p.colors.isNotEmpty) p.colors.first, if (p.needsSize) 'Choose size' else 'One size']
                    .join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.bodySm(AppColors.inkSoft).copyWith(fontSize: 11.5),
              ),
              const SizedBox(height: 10),
              Material(
                color: p.inStock ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.xs),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  onTap: _select ? null : () => _moveToBag(p),
                  child: SizedBox(
                    height: 42,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.shopping_bag_outlined, size: 15, color: p.inStock ? Colors.white : AppColors.subtext),
                      const SizedBox(width: 8),
                      Text(
                        !p.inStock ? 'SOLD OUT' : ((p.needsSize || p.colors.length > 1) ? 'CHOOSE OPTIONS' : 'MOVE TO BAG'),
                        style: AppType.labelBadge(p.inStock ? Colors.white : AppColors.subtext)
                            .copyWith(fontSize: 9.5, letterSpacing: 1.1),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wish = context.watch<WishlistProvider>();
    final signedIn = ApiService.instance.isLoggedIn;

    var items = [...wish.items];
    final depts = <String, String>{};
    for (final w in items) {
      final slug = w.product.departmentSlug;
      if (slug != null && slug.isNotEmpty) depts[slug] = w.product.departmentName ?? slug;
    }
    if (_dept != null) items = items.where((w) => w.product.departmentSlug == _dept).toList();
    double price(WishlistItem w) => double.tryParse(w.product.price) ?? 0;
    if (_sort == 'price_asc') {
      items.sort((a, b) => price(a).compareTo(price(b)));
    } else if (_sort == 'price_desc') {
      items.sort((a, b) => price(b).compareTo(price(a)));
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(children: [
        const AtelierTopBar(line: false),
        Expanded(
          child: !signedIn
              ? LarkEmptyState(
                  icon: Icons.favorite_border,
                  title: 'Your lookbook is waiting',
                  message: 'Sign in to save pieces you love and find them on every device.',
                  actionLabel: 'Sign in',
                  onAction: () async {
                    if (await ensureSignedIn(context) && mounted) {
                      await refreshSessionData(context);
                      _loadPairings();
                    }
                  },
                )
              : !wish.loaded
                  ? const LarkLoading()
                  : wish.items.isEmpty
                      ? LarkEmptyState(
                          icon: Icons.favorite_border,
                          title: 'Nothing saved yet',
                          message: 'Tap the heart on any piece to keep it here.',
                          actionLabel: 'Discover pieces',
                          onAction: () => shellTab.value = 0,
                        )
                      : RefreshIndicator(
                          color: AppColors.ink,
                          onRefresh: wish.refresh,
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 40),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                child: Row(children: [
                                  Text('YOUR LOOKBOOK', style: AppType.labelBadge(AppColors.ink)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                        color: AppColors.goldTint, borderRadius: BorderRadius.circular(AppRadii.pill)),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.circle, size: 5, color: AppColors.goldDeep),
                                      const SizedBox(width: 6),
                                      Text('SAVED', style: AppType.labelBadge(AppColors.goldDeep).copyWith(fontSize: 9)),
                                    ]),
                                  ),
                                ]),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                                child: Text('Curated Wishlist & Lookbook', style: AppType.headlineLg(AppColors.ink)),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text('${wish.count} ${wish.count == 1 ? 'piece' : 'pieces'} saved',
                                    style: AppType.bodyMd(AppColors.inkSoft)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  color: AppColors.surfaceLow,
                                  child: Row(children: [
                                    Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                        child: const Icon(Icons.auto_awesome, size: 18, color: AppColors.goldDeep)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text('SHOPPING ASSISTANT', style: AppType.labelBadge(AppColors.ink)),
                                        const SizedBox(height: 2),
                                        Text('Ask for pairings or sizing advice.', style: AppType.bodySm(AppColors.inkSoft)),
                                      ]),
                                    ),
                                    GestureDetector(
                                      onTap: () => showChatbotSheet(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        color: AppColors.ink,
                                        child: Row(children: [
                                          const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.white),
                                          const SizedBox(width: 6),
                                          Text('ASK', style: AppType.labelBadge(Colors.white)),
                                        ]),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 42,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  children: [
                                    PillChip('All pieces (${wish.count})',
                                        selected: _dept == null, onTap: () => setState(() => _dept = null)),
                                    for (final e in depts.entries) ...[
                                      const SizedBox(width: 8),
                                      PillChip(e.value,
                                          selected: _dept == e.key, onTap: () => setState(() => _dept = e.key)),
                                    ],
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                child: Row(children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _select = !_select;
                                        _selected.clear();
                                      }),
                                      child: Container(
                                        height: 44,
                                        decoration: BoxDecoration(
                                            color: _select ? AppColors.ink : AppColors.surface,
                                            borderRadius: BorderRadius.circular(AppRadii.xs)),
                                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          Icon(Icons.checklist, size: 16, color: _select ? Colors.white : AppColors.ink),
                                          const SizedBox(width: 8),
                                          Text(_select ? 'DONE' : 'SELECT ITEMS',
                                              style: AppType.labelBadge(_select ? Colors.white : AppColors.ink)),
                                        ]),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: PopupMenuButton<String>(
                                      onSelected: (v) => setState(() => _sort = v),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'recent', child: Text('RECENT')),
                                        PopupMenuItem(value: 'price_asc', child: Text('PRICE: LOW TO HIGH')),
                                        PopupMenuItem(value: 'price_desc', child: Text('PRICE: HIGH TO LOW')),
                                      ],
                                      child: Container(
                                        height: 44,
                                        decoration: BoxDecoration(
                                            color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.xs)),
                                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          Text(
                                              'SORT: ${_sort == 'recent' ? 'RECENT' : (_sort == 'price_asc' ? 'PRICE ↑' : 'PRICE ↓')}',
                                              style: AppType.labelBadge(AppColors.ink)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.keyboard_arrow_down, size: 16),
                                        ]),
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                              LayoutBuilder(builder: (context, c) {
                                final width = (c.maxWidth - 32 - 12) / 2;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: items.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      mainAxisExtent: width / .75 + 148,
                                    ),
                                    itemBuilder: (_, i) => _tile(items[i], width),
                                  ),
                                );
                              }),
                              if (_select && _selected.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: InkButton('Move ${_selected.length} to bag',
                                      icon: Icons.shopping_bag_outlined,
                                      loading: _movingAll,
                                      onPressed: () => _moveSelected(wish.items)),
                                ),
                              if (_pairings.isNotEmpty) ...[
                                const SizedBox(height: 36),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    color: AppColors.surfaceLow,
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Eyebrow('Recommended for you'),
                                      const SizedBox(height: 6),
                                      Text('Curated Pairings', style: AppType.headlineMd(AppColors.ink)),
                                      const SizedBox(height: 14),
                                      for (final p in _pairings.take(3))
                                        GestureDetector(
                                          onTap: () => Navigator.push(context,
                                              MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: p.slug))),
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(10),
                                            color: Colors.white,
                                            child: Row(children: [
                                              SizedBox(width: 54, height: 68, child: NetImage(p.imageUrl)),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                  Text(p.name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: AppType.headlineSm(AppColors.ink).copyWith(fontSize: 16)),
                                                  const SizedBox(height: 2),
                                                  Text(formatKES(p.price), style: AppText.price(13)),
                                                  const SizedBox(height: 6),
                                                  if (!wish.contains(p.id))
                                                    GestureDetector(
                                                      onTap: () async {
                                                        try {
                                                          await wish.toggle(p.id);
                                                        } catch (e) {
                                                          if (mounted) toast(context, e.toString());
                                                        }
                                                      },
                                                      child: Text('ADD TO LOOKBOOK',
                                                          style: AppType.labelBadge(AppColors.ink)
                                                              .copyWith(decoration: TextDecoration.underline, fontSize: 9.5)),
                                                    ),
                                                ]),
                                              ),
                                            ]),
                                          ),
                                        ),
                                    ]),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
        ),
      ]),
    );
  }
}
