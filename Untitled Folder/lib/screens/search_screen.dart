import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/recent_searches.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

/// Search results with the backend's typo-tolerant `/ai/search/`.
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  List<ProductListItem> _results = [];
  bool _loading = false;
  bool _searched = false;
  bool _error = false;
  String _asked = '';
  String _used = '';
  bool _corrected = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    if ((widget.initialQuery ?? '').trim().isNotEmpty) _run(widget.initialQuery!);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = false;
      _asked = query;
    });
    RecentSearches.add(query);
    try {
      final (used, corrected, results) = await ApiService.instance.smartSearch(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _used = used;
        _corrected = corrected;
        _searched = true;
        _loading = false;
      });
      ApiService.instance.track('search', extra: {'search_query': query});
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
          _searched = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.hairline)),
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            autofocus: (widget.initialQuery ?? '').isEmpty,
            textInputAction: TextInputAction.search,
            onSubmitted: _run,
            decoration: InputDecoration(
              hintText: 'Search styles, brands, categories…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(_controller.clear),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
      body: _loading
          ? const Padding(padding: EdgeInsets.only(top: 24), child: ProductGridSkeleton())
          : _error
              ? LarkErrorState(onRetry: () => _run(_asked))
              : !_searched
                  ? const LarkEmptyState(
                      icon: Icons.search,
                      title: 'Search LarkTribe',
                      message: 'Try a style, a brand or a category. Typos are fine — we will find it.')
                  : _results.isEmpty
                      ? LarkEmptyState(
                          icon: Icons.search_off,
                          title: 'No results',
                          message: 'We could not find "$_asked". Try a different word.')
                      : ListView(
                          padding: const EdgeInsets.only(top: 16, bottom: 40),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${_results.length} RESULT${_results.length == 1 ? '' : 'S'}',
                                    style: AppType.labelBadge(AppColors.goldDeep)),
                                if (_corrected) ...[
                                  const SizedBox(height: 6),
                                  Text('Showing results for "$_used" instead of "$_asked".',
                                      style: AppType.bodySm(AppColors.inkSoft)),
                                ],
                              ]),
                            ),
                            MasonryProducts(products: _results),
                          ],
                        ),
    );
  }
}
