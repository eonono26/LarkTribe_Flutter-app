import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_gate.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/chatbot_sheet.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import '../widgets/product_row.dart';
import '../widgets/video_showcase.dart';
import 'main_shell.dart';
import 'product_list_screen.dart';

/// Discover — the editorial home feed (Stitch screen 01).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  bool _failed = false;

  List<Campaign> _campaigns = [];
  List<ProductListItem> _newArrivals = [];
  List<ProductListItem> _onSale = [];
  List<ProductListItem> _topRated = [];
  List<ProductListItem> _recommended = [];
  List<ShowcaseVideoItem> _videos = [];
  List<Department> _departments = [];
  String? _dept; // selected department slug; null = all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<List<T>> _safe<T>(Future<List<T>> f, List<int> failures) async {
    try {
      return await f;
    } catch (_) {
      failures.add(1);
      return <T>[];
    }
  }

  Future<void> _load() async {
    final api = ApiService.instance;
    final failures = <int>[];
    if (mounted && !_loading) setState(() => _loading = _newArrivals.isEmpty);
    // The consolidated /catalog/home/ endpoint is deliberately not used:
    // composing the public list endpoints keeps the feed working even when
    // that aggregate endpoint errors, same fallback the website uses.
    final results = await Future.wait<List<dynamic>>([
      _safe(api.campaigns(), failures),
      _safe(api.newArrivals(), failures),
      _safe(api.onSaleProducts(), failures),
      _safe(api.topRatedProducts(), failures),
      _safe(api.showcaseVideos(), failures),
      _safe(api.departments(), failures),
      _safe(api.isLoggedIn ? api.recommendedForYou() : Future.value(<ProductListItem>[]), failures),
    ]);
    if (!mounted) return;
    setState(() {
      _campaigns = results[0].cast<Campaign>();
      _newArrivals = results[1].cast<ProductListItem>();
      _onSale = results[2].cast<ProductListItem>();
      _topRated = results[3].cast<ProductListItem>();
      _videos = results[4].cast<ShowcaseVideoItem>();
      _departments = results[5].cast<Department>();
      _recommended = results[6].cast<ProductListItem>();
      _failed = failures.length >= 5;
      _loading = false;
    });
  }

  void _openList(String title, {String? eyebrow, String? ordering, bool? onSale, String? departmentSlug}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          title: title,
          eyebrow: eyebrow,
          ordering: ordering,
          onSale: onSale,
          departmentSlug: departmentSlug,
        ),
      ),
    );
  }

  Widget _fallbackHero() {
    final first = _newArrivals.isNotEmpty ? _newArrivals.first : null;
    return AspectRatio(
      aspectRatio: 1.6,
      child: Stack(fit: StackFit.expand, children: [
        Container(color: const Color(0xFF1A1A1A)),
        if (first?.imageUrl != null) NetImage(first!.imageUrl),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55000000), Color(0x00000000), Color(0xE6000000)],
              stops: [0, .35, 1],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 22,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('Just landed', color: Colors.white, dot: true),
            const SizedBox(height: 8),
            Text('THE LATEST EDIT', style: AppType.display(Colors.white).copyWith(fontSize: 28)),
            const SizedBox(height: 14),
            InkButton('Explore new arrivals',
                variant: InkVariant.white,
                trailingIcon: Icons.arrow_forward,
                expand: false,
                height: 48,
                onPressed: () => _openList('New Arrivals', eyebrow: 'Just landed', ordering: '-created_at')),
          ]),
        ),
      ]),
    );
  }

  Widget _circleCard() {
    final signedIn = ApiService.instance.isLoggedIn;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E0E0E), Color(0xFF2A2A2A)],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.workspace_premium_outlined, color: AppColors.goldOnDark, size: 18),
            const SizedBox(width: 10),
            Text('MEMBER BENEFITS', style: AppType.labelBadge(AppColors.goldOnDark)),
          ]),
          const SizedBox(height: 14),
          Text(signedIn ? 'Your membership is active' : 'The LarkTribe Circle',
              style: AppType.headlineLgMobile(Colors.white).copyWith(fontSize: 26)),
          const SizedBox(height: 10),
          Text(
            signedIn
                ? 'You save 5% on every order — applied automatically at checkout — and your lookbook and orders stay in sync across devices.'
                : 'Members save 5% on every order, keep a private lookbook and follow deliveries live from dispatch to your door.',
            style: AppType.bodyMd(Colors.white.withOpacity(.72)),
          ),
          const SizedBox(height: 20),
          InkButton(
            signedIn ? 'View profile' : 'Sign in or join',
            variant: InkVariant.white,
            height: 48,
            onPressed: () async {
              if (signedIn) {
                shellTab.value = 4;
              } else if (await ensureSignedIn(context) && mounted) {
                _load();
              }
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroCampaigns = homepageBanners(_campaigns);

    final filtered = _dept == null
        ? _newArrivals
        : _newArrivals.where((p) => p.departmentSlug == _dept).toList();
    final shown = filtered.take(8).toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'home-chat',
        elevation: 0,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xs)),
        onPressed: () => showChatbotSheet(context),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
      ),
      body: Column(
        children: [
          const AtelierTopBar(line: false),
          Expanded(
            child: _loading
                ? const HomeSkeleton()
                : _failed
                    ? LarkErrorState(
                        message: "We couldn't reach LarkTribe. Check your connection and try again.",
                        onRetry: () {
                          setState(() => _loading = true);
                          _load();
                        })
                    : RefreshIndicator(
                        color: AppColors.ink,
                        onRefresh: _load,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            heroCampaigns.isNotEmpty
                                ? HeroCarousel(campaigns: heroCampaigns)
                                : _fallbackHero(),
                            if (_departments.isNotEmpty)
                              SizedBox(
                                height: 64,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                                  children: [
                                    PillChip('All', selected: _dept == null, onTap: () => setState(() => _dept = null)),
                                    for (final d in _departments) ...[
                                      const SizedBox(width: 8),
                                      PillChip(d.name,
                                          selected: _dept == d.slug,
                                          onTap: () => setState(() => _dept = d.slug)),
                                    ],
                                  ],
                                ),
                              ),
                            const SizedBox(height: 18),
                            SectionHeading(
                              eyebrow: 'New arrivals',
                              title: 'Curated Archive',
                              trailing: 'View all',
                              onTrailing: () => _openList('New Arrivals',
                                  eyebrow: 'Just landed', ordering: '-created_at', departmentSlug: _dept),
                            ),
                            const SizedBox(height: 16),
                            if (shown.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                child: Text('Nothing here yet — check back soon.',
                                    style: AppType.bodyMd(AppColors.subtext)),
                              )
                            else
                              MasonryProducts(products: shown),
                            if (_topRated.isNotEmpty) ...[
                              const SizedBox(height: 40),
                              ProductRow(
                                eyebrow: 'Top rated',
                                title: 'Trending Now',
                                products: _topRated.take(10).toList(),
                                arrows: true,
                              ),
                            ],
                            if (_onSale.isNotEmpty) ...[
                              const SizedBox(height: 36),
                              ProductRow(
                                eyebrow: 'Limited time',
                                title: 'The Sale Edit',
                                products: _onSale.take(10).toList(),
                                onViewAll: () => _openList('The Sale Edit',
                                    eyebrow: 'Limited time', ordering: '-discount_percentage', onSale: true),
                              ),
                            ],
                            if (_videos.isNotEmpty) ...[
                              const SizedBox(height: 36),
                              VideoShowcase(videos: _videos),
                            ],
                            if (_recommended.isNotEmpty) ...[
                              const SizedBox(height: 36),
                              ProductRow(
                                eyebrow: 'Curated for you',
                                title: 'Recommended',
                                products: _recommended.take(10).toList(),
                              ),
                            ],
                            const SizedBox(height: 40),
                            _circleCard(),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
