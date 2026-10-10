import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/recent_searches.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'brands_screen.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';

String _roman(int n) {
  const map = [
    [10, 'X'], [9, 'IX'], [5, 'V'], [4, 'IV'], [1, 'I'],
  ];
  var out = '';
  var v = n;
  for (final m in map) {
    while (v >= (m[0] as int)) {
      out += m[1] as String;
      v -= m[0] as int;
    }
  }
  return out;
}

/// Catalog tab — search plus visual taxonomy (Stitch screen 11).
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  bool _failed = false;
  List<Department> _departments = [];
  List<Category> _categories = [];
  List<AgeGroup> _ageGroups = [];
  List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    _load();
    RecentSearches.load().then((r) {
      if (mounted) setState(() => _recent = r);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = ApiService.instance;
    try {
      final r = await Future.wait<List<dynamic>>([
        api.departments(),
        api.categories(),
        api.ageGroups().catchError((_) => <AgeGroup>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _departments = r[0].cast<Department>();
        _categories = r[1].cast<Category>();
        _ageGroups = r[2].cast<AgeGroup>();
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = _departments.isEmpty;
        });
      }
    }
  }

  Future<void> _runSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    final updated = await RecentSearches.add(query);
    if (!mounted) return;
    setState(() => _recent = updated);
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: query)));
  }

  void _go(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Widget _caps(String text, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(children: [
          Expanded(child: Text(text.toUpperCase(), style: AppType.labelCaps(AppColors.ink))),
          if (trailing != null) trailing,
        ]),
      );

  Widget _quickTile(IconData icon, String top, String bottom, VoidCallback onTap) => Expanded(
        child: Material(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadii.xs),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.xs),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(icon, size: 20, color: AppColors.goldDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(top.toUpperCase(), style: AppType.labelBadge(AppColors.ink).copyWith(fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(bottom, style: AppType.bodySm(AppColors.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );

  Widget _chip(String label, VoidCallback onTap) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.xs),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Text(label, style: AppType.bodyMd(AppColors.ink)),
          ),
        ),
      );

  String _subtitleFor(Department d) {
    final names = _categories
        .where((c) => c.department?.slug == d.slug)
        .take(3)
        .map((c) => c.name)
        .toList();
    return names.isEmpty ? (d.description ?? '') : names.join(', ');
  }

  Widget _volumeTile(int index, Department d, {required double aspect, bool large = false}) {
    return GestureDetector(
      onTap: () => _go(ProductListScreen(
          title: d.name, eyebrow: 'Collections / ${d.name}', departmentSlug: d.slug)),
      child: AspectRatio(
        aspectRatio: aspect,
        child: Stack(fit: StackFit.expand, children: [
          Container(color: AppColors.stone900),
          if (d.primaryImageUrl != null) NetImage(d.primaryImageUrl),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xE6000000)],
                stops: [.4, 1],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              color: Colors.white,
              child: Text('VOL. ${_roman(index + 1)}',
                  style: AppType.labelBadge(AppColors.ink).copyWith(fontSize: 9.5)),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_subtitleFor(d),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.bodySm(Colors.white.withOpacity(.85))),
              const SizedBox(height: 4),
              Text(d.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.headlineMd(Colors.white).copyWith(fontSize: large ? 26 : 20)),
              const SizedBox(height: 4),
              Text('${d.productCount} Items',
                  style: AppType.labelBadge(AppColors.goldOnDark).copyWith(letterSpacing: 1)),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topCategories = ([..._categories]..sort((a, b) => b.productCount.compareTo(a.productCount)))
        .where((c) => c.productCount > 0)
        .take(8)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(children: [
        const AtelierTopBar(line: false),
        Expanded(
          child: _loading
              ? const LarkLoading()
              : _failed
                  ? LarkErrorState(onRetry: () {
                      setState(() => _loading = true);
                      _load();
                    })
                  : RefreshIndicator(
                      color: AppColors.ink,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 40),
                        children: [
                          // Search field
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadii.xs),
                              ),
                              child: TextField(
                                controller: _search,
                                textInputAction: TextInputAction.search,
                                onSubmitted: _runSearch,
                                decoration: InputDecoration(
                                  hintText: 'Search styles, brands, categories…',
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  prefixIcon: const Icon(Icons.search, color: AppColors.inkSoft),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.arrow_forward, size: 20),
                                    onPressed: () => _runSearch(_search.text),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(children: [
                              _quickTile(Icons.local_offer_outlined, 'Sale edit', 'Reduced pieces',
                                  () => _go(const ProductListScreen(
                                      title: 'The Sale Edit',
                                      eyebrow: 'Limited time',
                                      ordering: '-discount_percentage',
                                      onSale: true))),
                              const SizedBox(width: 12),
                              _quickTile(Icons.auto_awesome_outlined, 'New arrivals', 'Just landed',
                                  () => _go(const ProductListScreen(
                                      title: 'New Arrivals', eyebrow: 'Just landed', ordering: '-created_at'))),
                            ]),
                          ),
                          if (topCategories.isNotEmpty) ...[
                            const SizedBox(height: 30),
                            _caps('Trending inquiries',
                                trailing: Text('Popular categories', style: AppType.bodySm(AppColors.subtext))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Wrap(spacing: 8, runSpacing: 8, children: [
                                for (final c in topCategories)
                                  _chip(c.name,
                                      () => _go(ProductListScreen(title: c.name, categorySlug: c.slug))),
                              ]),
                            ),
                          ],
                          if (_ageGroups.isNotEmpty) ...[
                            const SizedBox(height: 30),
                            _caps('Shop by age'),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Wrap(spacing: 8, runSpacing: 8, children: [
                                for (final g in _ageGroups)
                                  _chip(g.name,
                                      () => _go(ProductListScreen(title: g.name, ageGroupSlug: g.slug))),
                              ]),
                            ),
                          ],
                          if (_departments.isNotEmpty) ...[
                            const SizedBox(height: 34),
                            _caps('Shop by department',
                                trailing: Text('${_departments.length} DEPARTMENTS',
                                    style: AppType.labelBadge(AppColors.goldDeep))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(children: [
                                _volumeTile(0, _departments.first, aspect: 1.5, large: true),
                                if (_departments.length > 1) const SizedBox(height: 12),
                                if (_departments.length > 1)
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: .76,
                                    padding: EdgeInsets.zero,
                                    children: [
                                      for (var i = 1; i < _departments.length; i++)
                                        _volumeTile(i, _departments[i], aspect: .76),
                                    ],
                                  ),
                              ]),
                            ),
                          ],
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              color: const Color(0xFF1E1E1E),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Eyebrow("Curator's focus", color: AppColors.goldOnDark, dot: true),
                                const SizedBox(height: 12),
                                Text('Discover the Makers',
                                    style: AppType.headlineLgMobile(Colors.white).copyWith(fontSize: 26)),
                                const SizedBox(height: 8),
                                Text('Browse every brand on LarkTribe, from small studios to established labels.',
                                    style: AppType.bodyMd(Colors.white.withOpacity(.68))),
                                const SizedBox(height: 18),
                                InkWell(
                                  onTap: () => _go(const BrandsScreen()),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Text('ENTER BRAND INDEX',
                                        style: AppType.labelCaps(AppColors.goldOnDark)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.goldOnDark),
                                  ]),
                                ),
                              ]),
                            ),
                          ),
                          if (_recent.isNotEmpty) ...[
                            const SizedBox(height: 34),
                            _caps('Recent inquiries',
                                trailing: GestureDetector(
                                  onTap: () async {
                                    await RecentSearches.clear();
                                    if (mounted) setState(() => _recent = []);
                                  },
                                  child: Text('Clear', style: AppType.bodySm(AppColors.subtext)
                                      .copyWith(decoration: TextDecoration.underline)),
                                )),
                            for (final q in _recent)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppRadii.xs),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(AppRadii.xs),
                                    onTap: () => _runSearch(q),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                                      child: Row(children: [
                                        const Icon(Icons.history, size: 18, color: AppColors.subtext),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(q, style: AppType.bodyMd(AppColors.ink))),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.close, size: 18, color: AppColors.subtext),
                                          onPressed: () async {
                                            final r = await RecentSearches.remove(q);
                                            if (mounted) setState(() => _recent = r);
                                          },
                                        ),
                                      ]),
                                    ),
                                  ),
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
