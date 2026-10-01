import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart' show mediaUrl;
import 'product_list_screen.dart';

/// The "Shop" tab: browse by department, then by category — a real app
/// navigation surface (expandable list + chips), not a mega-menu.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Department> _departments = [];
  final Map<int, List<Category>> _categoriesByDept = {};
  int? _expanded;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final departments = await ApiService.instance.departments();
    if (mounted) {
      setState(() {
        _departments = departments;
        _loading = false;
      });
    }
  }

  Future<void> _expand(Department d) async {
    setState(() => _expanded = _expanded == d.id ? null : d.id);
    if (_expanded == d.id && !_categoriesByDept.containsKey(d.id)) {
      final cats = await ApiService.instance.categories(departmentSlug: d.slug);
      if (mounted) setState(() => _categoriesByDept[d.id] = cats);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: _loading
          ? const LarkLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                itemCount: _departments.length,
                itemBuilder: (context, i) {
                  final d = _departments[i];
                  final color = AppColors.departmentColor(d.slug);
                  final expanded = _expanded == d.id;
                  final cats = _categoriesByDept[d.id];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: AppColors.line)),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => _expand(d),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: (d.primaryImageUrl != null && d.primaryImageUrl!.isNotEmpty)
                                      ? CachedNetworkImage(
                                          imageUrl: mediaUrl(d.primaryImageUrl),
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(color: color.withOpacity(0.12)),
                                          errorWidget: (_, __, ___) =>
                                              Container(color: color.withOpacity(0.12), child: Icon(Icons.storefront_rounded, color: color)),
                                        )
                                      : Container(color: color.withOpacity(0.12), child: Icon(Icons.storefront_rounded, color: color)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.name, style: AppType.headlineSm(AppColors.ink).copyWith(fontSize: 16)),
                                      if (d.productCount > 0)
                                        Text('${d.productCount} PIECES', style: AppType.labelSm(AppColors.subtext)),
                                    ],
                                  ),
                                ),
                                Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.subtext),
                              ],
                            ),
                          ),
                        ),
                        if (expanded)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _shopAllButton(d),
                                const SizedBox(height: 8),
                                if (cats == null)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  )
                                else if (cats.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text('No sub-categories yet.', style: TextStyle(color: AppColors.subtext, fontSize: 12)),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: cats.map((c) => _CategoryChip(category: c, color: color)).toList(),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _shopAllButton(Department d) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductListScreen(title: d.name, departmentSlug: d.slug)),
      ),
      icon: const Icon(Icons.grid_view_rounded, size: 16),
      label: Text('Shop all ${d.name}'),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final Color color;
  const _CategoryChip({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductListScreen(title: category.name, categorySlug: category.slug)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.primaryImageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: CachedNetworkImage(
                  imageUrl: ApiService.instance.absoluteMediaUrl(category.primaryImageUrl),
                  width: 18,
                  height: 18,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => const SizedBox(width: 18, height: 18),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(category.name, style: AppType.bodySm(AppColors.ink).copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
