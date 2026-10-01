import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'styling_screen.dart';

const _sortLabels = <String, String>{
  '-created_at': 'Newest',
  'price': 'Price: low to high',
  '-price': 'Price: high to low',
  '-rating_avg': 'Top rated',
  '-discount_percentage': 'Biggest discount',
};

// Same option lists as the storefront's filters.
const _sizes = ['2T', '3T', '4T', 'XS', 'S', 'M', 'L', 'XL'];
const _priceRanges = <String, String>{
  '0-999': 'Under KSh 1,000',
  '1000-1999': 'KSh 1,000 – 1,999',
  '2000-2999': 'KSh 2,000 – 2,999',
  '3000-4999': 'KSh 3,000 – 4,999',
  '5000-': 'KSh 5,000 and above',
};
const _genders = <String, String>{'girls': 'Girls', 'boys': 'Boys', 'unisex': 'Unisex'};

/// Collections grid (Stitch screen 02) used for departments, categories,
/// brands, age groups, sale and new-arrival listings.
class ProductListScreen extends StatefulWidget {
  final String title;
  final String? eyebrow;
  final String? departmentSlug;
  final String? categorySlug;
  final String? brandSlug;
  final int? ageGroupId;
  final String? ageGroupSlug;
  final String? gender; // 'boys' | 'girls' | 'unisex'
  final String? stage; // 'baby' | 'kids' | 'teens'
  final String? ordering;
  final bool? onSale;

  const ProductListScreen({
    super.key,
    required this.title,
    this.eyebrow,
    this.departmentSlug,
    this.categorySlug,
    this.brandSlug,
    this.ageGroupId,
    this.ageGroupSlug,
    this.gender,
    this.stage,
    this.ordering,
    this.onSale,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _scroll = ScrollController();
  final List<ProductListItem> _items = [];
  int _page = 1;
  int _count = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _error = false;

  late String _ordering = widget.ordering ?? '-created_at';
  String? _size;
  String? _price;
  String? _gender;
  bool _onSale = false;

  // A bare age-group id (older deep links) has no slug filter, so it uses
  // the dedicated endpoint — which can't be filtered further.
  bool get _dedicated => widget.ageGroupId != null && widget.ageGroupSlug == null;

  int get _activeFilters =>
      [_size, _price, _gender].where((v) => v != null).length + (_onSale ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _gender = widget.gender;
    _onSale = widget.onSale ?? false;
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) _loadMore();
    });
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<Paged<ProductListItem>> _fetch(int page) async {
    final api = ApiService.instance;
    if (_dedicated) {
      final all = await api.productsByAgeGroup(widget.ageGroupId!);
      return Paged(all, count: all.length);
    }
    return api.productsPage(
      departmentSlug: widget.departmentSlug,
      categorySlug: widget.categorySlug,
      brandSlug: widget.brandSlug,
      ageGroupSlug: widget.ageGroupSlug,
      stage: widget.stage,
      gender: _gender,
      ordering: _ordering,
      size: _size,
      priceRange: _price,
      onSale: _onSale ? true : null,
      page: page,
    );
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = false;
        _page = 1;
        _items.clear();
      });
    }
    try {
      final res = await _fetch(1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.items);
        _count = res.count;
        _hasMore = res.hasMore;
        _loading = false;
        _page = 1;
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

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final res = await _fetch(_page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _hasMore = res.hasMore;
        _page += 1;
      });
    } catch (_) {
      // leave _hasMore as-is so the next scroll retries
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _size = null;
      _price = null;
      _gender = widget.gender;
      _onSale = widget.onSale ?? false;
    });
    _load(reset: true);
  }

  // ---------------------------------------------------------------- sheets

  Future<void> _openSort() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('SORT BY', style: AppType.labelCaps(AppColors.ink))),
          ),
          for (final e in _sortLabels.entries)
            ListTile(
              title: Text(e.value, style: AppType.bodyMd(AppColors.ink)),
              trailing: _ordering == e.key ? const Icon(Icons.check, size: 20) : null,
              onTap: () => Navigator.pop(ctx, e.key),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (picked != null && picked != _ordering) {
      setState(() => _ordering = picked);
      _load(reset: true);
    }
  }

  Future<void> _openFilters() async {
    String? size = _size;
    String? price = _price;
    String? gender = _gender;
    bool onSale = _onSale;

    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        Widget group(String label, List<Widget> chips) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label.toUpperCase(), style: AppType.labelCaps(AppColors.subtext)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: chips),
              ]),
            );
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .85),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
                child: Row(children: [
                  Expanded(child: Text('FILTER & REFINE', style: AppType.labelCaps(AppColors.ink))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ]),
              ),
              Flexible(
                child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), children: [
                  group('Size', [
                    for (final s in _sizes)
                      PillChip(s,
                          selected: size == s,
                          onTap: () => setSheet(() => size = size == s ? null : s)),
                  ]),
                  group('Price', [
                    for (final e in _priceRanges.entries)
                      PillChip(e.value,
                          selected: price == e.key,
                          onTap: () => setSheet(() => price = price == e.key ? null : e.key)),
                  ]),
                  if (widget.gender == null)
                    group('For', [
                      for (final e in _genders.entries)
                        PillChip(e.value,
                            selected: gender == e.key,
                            onTap: () => setSheet(() => gender = gender == e.key ? null : e.key)),
                    ]),
                  group('Offers', [
                    PillChip('On sale',
                        selected: onSale, onTap: () => setSheet(() => onSale = !onSale)),
                  ]),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(children: [
                  Expanded(
                    child: InkButton('Reset',
                        variant: InkVariant.surface,
                        onPressed: () => setSheet(() {
                              size = null;
                              price = null;
                              gender = widget.gender;
                              onSale = widget.onSale ?? false;
                            })),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: InkButton('Show results', onPressed: () => Navigator.pop(ctx, true))),
                ]),
              ),
            ]),
          ),
        );
      }),
    );
    if (apply == true) {
      setState(() {
        _size = size;
        _price = price;
        _gender = gender;
        _onSale = onSale;
      });
      _load(reset: true);
    }
  }

  // ----------------------------------------------------------------- build

  Widget _toolbarPill(Widget child, {Color? bg, VoidCallback? onTap}) => Material(
        color: bg ?? AppColors.surface,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11), child: child),
        ),
      );

  Widget _activeChip(String label, VoidCallback onRemove) => Container(
        padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: AppType.bodySm(AppColors.ink)),
          const SizedBox(width: 2),
          GestureDetector(
              onTap: onRemove,
              child: const Padding(
                  padding: EdgeInsets.all(2), child: Icon(Icons.close, size: 14, color: AppColors.inkSoft))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (_price != null)
        _activeChip(_priceRanges[_price] ?? _price!, () {
          setState(() => _price = null);
          _load(reset: true);
        }),
      if (_gender != null && widget.gender == null)
        _activeChip(_genders[_gender] ?? _gender!, () {
          setState(() => _gender = null);
          _load(reset: true);
        }),
      if (_onSale && widget.onSale != true)
        _activeChip('On sale', () {
          setState(() => _onSale = false);
          _load(reset: true);
        }),
    ];

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const AtelierAppBar(title: 'Collections'),
      body: Stack(
        children: [
          _loading
              ? ListView(padding: const EdgeInsets.only(top: 24), children: const [ProductGridSkeleton()])
              : _error
                  ? LarkErrorState(onRetry: () => _load(reset: true))
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.only(bottom: 120),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                          child: Row(children: [
                            Expanded(
                              child: Text(
                                (widget.eyebrow ?? 'Collections').toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.labelBadge(AppColors.subtext),
                              ),
                            ),
                            Text('$_count ${_count == 1 ? 'piece' : 'pieces'}',
                                style: AppType.bodySm(AppColors.inkSoft)),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Text(widget.title, style: AppType.headlineLg(AppColors.ink)),
                        ),
                        if (!_dedicated) ...[
                          SizedBox(
                            height: 44,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                _toolbarPill(
                                  Row(children: [
                                    const Icon(Icons.tune, size: 16, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text('FILTER${_activeFilters > 0 ? ' ($_activeFilters)' : ''}',
                                        style: AppType.labelCaps(Colors.white)
                                            .copyWith(fontSize: 10.5, letterSpacing: 1.2)),
                                  ]),
                                  bg: AppColors.ink,
                                  onTap: _openFilters,
                                ),
                                const SizedBox(width: 8),
                                _toolbarPill(
                                  Row(children: [
                                    Text('SORT: ${(_sortLabels[_ordering] ?? 'Newest').toUpperCase()}',
                                        style: AppType.labelCaps(AppColors.ink)
                                            .copyWith(fontSize: 10.5, letterSpacing: 1.2)),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.keyboard_arrow_down, size: 16),
                                  ]),
                                  onTap: _openSort,
                                ),
                                if (_size != null) ...[
                                  const SizedBox(width: 8),
                                  _toolbarPill(
                                    Row(children: [
                                      Text('SIZE: $_size',
                                          style: AppType.labelCaps(AppColors.ink)
                                              .copyWith(fontSize: 10.5, letterSpacing: 1.2)),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.close, size: 14),
                                    ]),
                                    onTap: () {
                                      setState(() => _size = null);
                                      _load(reset: true);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (chips.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                                ...chips,
                                GestureDetector(
                                  onTap: _clearFilters,
                                  child: Text('Clear all',
                                      style: AppType.bodySm(AppColors.ink)
                                          .copyWith(decoration: TextDecoration.underline)),
                                ),
                              ]),
                            ),
                        ],
                        const SizedBox(height: 22),
                        if (_items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: LarkEmptyState(
                              icon: Icons.checkroom_outlined,
                              title: 'Nothing matches',
                              message: 'Try removing a filter to see more pieces.',
                              actionLabel: _activeFilters > 0 ? 'Clear filters' : null,
                              onAction: _clearFilters,
                            ),
                          )
                        else
                          MasonryProducts(products: _items, showCategoryBadge: false),
                        if (_loadingMore)
                          const Padding(padding: EdgeInsets.all(24), child: LarkLoading()),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            color: AppColors.surfaceLow,
                            child: Column(children: [
                              const Eyebrow('Styling service'),
                              const SizedBox(height: 10),
                              Text('Personal Styling Session',
                                  textAlign: TextAlign.center,
                                  style: AppType.headlineMd(AppColors.ink)),
                              const SizedBox(height: 8),
                              Text(
                                  'Tell us what you are shopping for and our team will help you put together the right pieces.',
                                  textAlign: TextAlign.center,
                                  style: AppType.bodyMd(AppColors.inkSoft)),
                              const SizedBox(height: 18),
                              InkButton('Request a session',
                                  expand: false,
                                  height: 46,
                                  onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const StylingScreen()))),
                            ]),
                          ),
                        ),
                      ],
                    ),
          if (!_loading && !_error && !_dedicated)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Center(
                child: Material(
                  color: AppColors.ink,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: _openFilters,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.tune, size: 16, color: Colors.white),
                        const SizedBox(width: 10),
                        Text('FILTER & REFINE',
                            style: AppType.labelCaps(Colors.white).copyWith(fontSize: 10.5, letterSpacing: 1.2)),
                        Container(
                            width: 1, height: 14, margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: Colors.white38),
                        Text('$_count Results', style: AppType.bodySm(Colors.white)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
