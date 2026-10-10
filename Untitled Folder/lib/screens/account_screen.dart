import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';
import '../services/wishlist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common.dart';
import '../widgets/form_bits.dart';
import '../widgets/order_bits.dart';
import '../widgets/product_card.dart';
import 'addresses_screen.dart';
import 'brands_screen.dart';
import 'info/about_screen.dart';
import 'info/contact_screen.dart';
import 'info/delivery_screen.dart';
import 'info/faq_screen.dart';
import 'info/help_screen.dart';
import 'info/privacy_screen.dart';
import 'info/returns_screen.dart';
import 'info/terms_screen.dart';
import 'main_shell.dart';
import 'notifications_screen.dart';
import 'order_detail_screen.dart';
import 'orders_screen.dart';
import 'payments_screen.dart';
import 'product_detail_screen.dart';
import 'styling_screen.dart';

/// Profile (Stitch screen 05).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserProfile? _profile;
  List<OrderSummary> _orders = [];
  List<SavedAddress> _addresses = [];
  List<SavedPaymentMethod> _methods = [];
  List<WalletCoupon> _coupons = [];
  bool _loading = true;
  int _tab = 0; // 0 orders & purchases · 1 saved

  @override
  void initState() {
    super.initState();
    shellTab.addListener(_onTab);
    _load();
  }

  @override
  void dispose() {
    shellTab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (shellTab.value == 4 && mounted) _load();
  }

  Future<T> _safe<T>(Future<T> f, T fallback) async {
    try {
      return await f;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _load() async {
    final api = ApiService.instance;
    if (!api.isLoggedIn) {
      if (mounted) {
        setState(() {
          _profile = null;
          _loading = false;
        });
      }
      return;
    }
    final r = await Future.wait<dynamic>([
      _safe<UserProfile?>(api.me(), api.cachedProfile),
      _safe<List<OrderSummary>>(api.myOrders(), _orders),
      _safe<List<SavedAddress>>(api.addresses(), _addresses),
      _safe<List<SavedPaymentMethod>>(api.paymentMethods(), _methods),
      _safe<List<WalletCoupon>>(api.myCoupons(), _coupons),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = r[0] as UserProfile?;
      _orders = r[1] as List<OrderSummary>;
      _addresses = r[2] as List<SavedAddress>;
      _methods = r[3] as List<SavedPaymentMethod>;
      _coupons = r[4] as List<WalletCoupon>;
      _loading = false;
    });
  }

  void _go(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Future<void> _signIn() async {
    if (await ensureSignedIn(context) && mounted) {
      setState(() => _loading = true);
      await _load();
    }
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out?', style: AppType.headlineMd(AppColors.ink)),
        content: Text('Your lookbook and orders will be here when you sign back in.',
            style: AppType.bodyMd(AppColors.inkSoft)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ApiService.instance.logout();
    if (!mounted) return;
    context.read<WishlistProvider>().clear();
    await context.read<CartProvider>().refresh();
    if (!mounted) return;
    setState(() {
      _profile = null;
      _orders = [];
      _addresses = [];
      _methods = [];
      _coupons = [];
    });
  }

  // ------------------------------------------------------------ sections

  Widget _header(UserProfile p) {
    final url = p.profilePictureUrl;
    final since = p.dateJoined?.year;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.line)),
            child: ClipOval(
              child: (url != null && url.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: ApiService.instance.absoluteMediaUrl(url),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ImageFallback())
                  : Container(
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: Text(p.displayName.isEmpty ? '?' : p.displayName[0].toUpperCase(),
                          style: AppType.display(AppColors.ink).copyWith(fontSize: 40)),
                    ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
              child: const Icon(Icons.verified, size: 15, color: Colors.white),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.goldTint, borderRadius: BorderRadius.circular(AppRadii.pill)),
            child: Text('MEMBER', style: AppType.labelBadge(AppColors.goldDeep).copyWith(fontSize: 9)),
          ),
          if (since != null) ...[
            const SizedBox(width: 8),
            Text('• SINCE $since', style: AppType.labelBadge(AppColors.inkSoft).copyWith(fontSize: 9)),
          ],
        ]),
        const SizedBox(height: 10),
        Text(p.displayName.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppType.headlineLg(AppColors.ink).copyWith(fontSize: 30, letterSpacing: 1)),
        if (p.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(p.email, style: AppType.bodyMd(AppColors.inkSoft)),
        ],
      ]),
    );
  }

  Widget _stats(int saved) {
    Widget cell(int i, String value, String label, {bool highlight = false}) => Expanded(
          child: GestureDetector(
            onTap: () {
              if (i == 0) setState(() => _tab = 0);
              if (i == 1) setState(() => _tab = 1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: highlight ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.xs),
              ),
              child: Column(children: [
                Text(value, style: AppType.headlineMd(AppColors.ink).copyWith(fontSize: 26)),
                const SizedBox(height: 2),
                Text(label.toUpperCase(), style: AppType.labelBadge(AppColors.inkSoft).copyWith(fontSize: 8.5)),
              ]),
            ),
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.sm)),
      child: Row(children: [
        cell(0, _orders.length.toString().padLeft(2, '0'), 'Orders', highlight: _tab == 0),
        cell(1, saved.toString().padLeft(2, '0'), 'Saved pieces', highlight: _tab == 1),
        cell(2, _coupons.where((c) => !c.used).length.toString().padLeft(2, '0'), 'Offers'),
      ]),
    );
  }

  Widget _activeOrder() {
    final active = _orders.where((o) => o.isActive).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    final o = active.firstWhere((x) => x.isInTransit, orElse: () => active.first);
    return Panel(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.goldDeep, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text('ACTIVE ORDER', style: AppType.labelBadge(AppColors.goldDeep))),
          Text('#${o.orderNumber}', style: AppType.labelBadge(AppColors.inkSoft)),
        ]),
        const SizedBox(height: 10),
        Text(orderStatusLabel(o.status), style: AppType.headlineMd(AppColors.ink).copyWith(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
            '${o.itemCount} ${o.itemCount == 1 ? 'item' : 'items'}'
            '${o.shippingCity.isEmpty ? '' : ' • ${o.shippingCity}'}',
            style: AppType.bodySm(AppColors.inkSoft)),
        const SizedBox(height: 16),
        OrderProgressBar(status: o.status),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.local_shipping_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('Total ${formatKES(o.total)}', style: AppType.bodyMd(AppColors.ink))),
          GestureDetector(
            onTap: () => _go(OrderDetailScreen(orderNumber: o.orderNumber)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppColors.surface,
              child: Text(o.isInTransit ? 'LIVE TRACKING' : 'VIEW ORDER',
                  style: AppType.labelBadge(AppColors.ink).copyWith(fontSize: 9.5)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _pill(String label, int i) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = i),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _tab == i ? AppColors.ink : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(label.toUpperCase(),
                style: AppType.labelCaps(_tab == i ? Colors.white : AppColors.ink).copyWith(fontSize: 10, letterSpacing: 1.1)),
          ),
        ),
      );

  Widget _miniGrid(List<_MiniCard> cards) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final c in cards)
            LayoutBuilder(builder: (context, _) {
              final w = (MediaQuery.of(context).size.width - 32 - 12) / 2;
              return SizedBox(width: w, child: c);
            }),
        ],
      ),
    );
  }

  Widget _collection() {
    // Pieces from delivered orders, newest first, de-duplicated.
    final seen = <int>{};
    final pieces = <(OrderSummary, OrderItemDetail)>[];
    for (final o in _orders.where((o) => o.isDelivered)) {
      for (final i in o.items) {
        final key = i.productId ?? i.id;
        if (seen.add(key)) pieces.add((o, i));
      }
    }
    if (pieces.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Text('Pieces from delivered orders will collect here.', style: AppType.bodyMd(AppColors.subtext)),
      );
    }
    return Column(children: [
      const SectionHeading(eyebrow: 'My collection', title: 'Recent Purchases'),
      const SizedBox(height: 16),
      _miniGrid([
        for (final (o, i) in pieces.take(6))
          _MiniCard(
            image: i.productImage,
            tag: formatDate(o.createdDate).split(',').first,
            title: i.productName,
            meta: [if (i.variantLabel.isNotEmpty) i.variantLabel].join(' • '),
            actionLabel: 'Buy again',
            actionIcon: Icons.refresh,
            onTap: i.productSlug == null ? null : () => _go(ProductDetailScreen(slug: i.productSlug!)),
            onAction: () async {
              if (i.productId == null) return;
              try {
                await context.read<CartProvider>().addItem(i.productId!, variantId: i.variantId);
                if (mounted) toast(context, 'Added to your bag', actionLabel: 'VIEW BAG', onAction: () => shellTab.value = 3);
              } catch (e) {
                if (mounted) toast(context, e.toString());
              }
            },
          ),
      ]),
    ]);
  }

  Widget _savedGrid(List<WishlistItem> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Text('Nothing saved yet — tap the heart on any piece.', style: AppType.bodyMd(AppColors.subtext)),
      );
    }
    return Column(children: [
      SectionHeading(
        eyebrow: 'Saved',
        title: 'Your Lookbook',
        trailing: 'View all',
        onTrailing: () => shellTab.value = 2,
      ),
      const SizedBox(height: 16),
      _miniGrid([
        for (final w in items.take(6))
          _MiniCard(
            image: w.product.imageUrl,
            tag: w.product.categoryName ?? '',
            title: w.product.name,
            meta: formatKES(w.product.price),
            actionLabel: 'View piece',
            actionIcon: Icons.arrow_forward,
            onTap: () => _go(ProductDetailScreen(slug: w.product.slug)),
            onAction: () => _go(ProductDetailScreen(slug: w.product.slug)),
          ),
      ]),
    ]);
  }

  Widget _stylingPromo() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0E0E0E), Color(0xFF2E2E2E)],
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.diamond_outlined, size: 16, color: AppColors.goldOnDark),
              const SizedBox(width: 8),
              Text('COMPLIMENTARY SESSION', style: AppType.labelBadge(AppColors.goldOnDark)),
            ]),
            const SizedBox(height: 12),
            Text('Personal Styling', style: AppType.headlineLgMobile(Colors.white).copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            Text('Book a one-to-one session with our team to put together your next look.',
                style: AppType.bodyMd(Colors.white.withOpacity(.72))),
            const SizedBox(height: 18),
            InkButton('Reserve time',
                variant: InkVariant.white, icon: Icons.calendar_today_outlined, expand: false, height: 46,
                onPressed: () => _go(const StylingScreen())),
          ]),
        ),
      );

  Widget _row(IconData icon, String title, String subtitle, VoidCallback onTap, {bool last = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(children: [
          Container(width: 42, height: 42, color: AppColors.surfaceLow, child: Icon(icon, size: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppType.bodyMd(AppColors.ink).copyWith(fontWeight: FontWeight.w600)),
              if (subtitle.isNotEmpty)
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.bodySm(AppColors.inkSoft)),
            ]),
          ),
          const Icon(Icons.chevron_right, size: 22),
        ]),
      ),
    );
  }

  Widget _group(String label, List<Widget> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
          child: Text(label.toUpperCase(), style: AppType.labelCaps(AppColors.ink).copyWith(fontSize: 10.5)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.sm)),
          child: Column(children: rows),
        ),
      ]);

  List<Widget> _infoRows() => [
        _row(Icons.sell_outlined, 'Brands', 'Browse every brand', () => _go(const BrandsScreen())),
        _row(Icons.help_outline, 'Help centre', 'Orders, delivery and returns', () => _go(const HelpScreen())),
        _row(Icons.forum_outlined, 'FAQ', '', () => _go(const FaqScreen())),
        _row(Icons.local_shipping_outlined, 'Delivery information', '', () => _go(const DeliveryScreen())),
        _row(Icons.assignment_return_outlined, 'Returns & refunds', '', () => _go(const ReturnsScreen())),
        _row(Icons.support_agent_outlined, 'Contact us', '', () => _go(const ContactScreen())),
        _row(Icons.info_outline, 'About LarkTribe', '', () => _go(const AboutScreen())),
        _row(Icons.description_outlined, 'Terms of service', '', () => _go(const TermsScreen())),
        _row(Icons.lock_outline, 'Privacy policy', '', () => _go(const PrivacyScreen()), last: true),
      ];

  Widget _signedOut() => ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(24),
              color: AppColors.ink,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Eyebrow('Member access', color: AppColors.goldOnDark, dot: true),
                const SizedBox(height: 12),
                Text('Sign in to LarkTribe', style: AppType.headlineLgMobile(Colors.white).copyWith(fontSize: 28)),
                const SizedBox(height: 8),
                Text('Track orders live, keep a lookbook and save 5% on every order.',
                    style: AppType.bodyMd(Colors.white.withOpacity(.72))),
                const SizedBox(height: 20),
                InkButton('Sign in or join', variant: InkVariant.white, onPressed: _signIn),
              ]),
            ),
          ),
          _group('Support & information', _infoRows()),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final signedIn = ApiService.instance.isLoggedIn;
    final wish = context.watch<WishlistProvider>();
    final p = _profile ?? ApiService.instance.cachedProfile;

    final def = _addresses.where((a) => a.isDefault).toList();
    final defAddress = def.isNotEmpty ? def.first : (_addresses.isNotEmpty ? _addresses.first : null);
    final defM = _methods.where((m) => m.isDefault).toList();
    final defMethod = defM.isNotEmpty ? defM.first : (_methods.isNotEmpty ? _methods.first : null);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(children: [
        const AtelierTopBar(line: false),
        Expanded(
          child: _loading && signedIn
              ? const LarkLoading()
              : (!signedIn || p == null)
                  ? _signedOut()
                  : RefreshIndicator(
                      color: AppColors.ink,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 40),
                        children: [
                          _header(p),
                          _stats(wish.count),
                          _activeOrder(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            child: Row(children: [
                              _pill('Orders & purchases', 0),
                              const SizedBox(width: 8),
                              _pill('Saved (${wish.count})', 1),
                            ]),
                          ),
                          if (_tab == 0) _collection() else _savedGrid(wish.items),
                          if (_orders.isNotEmpty && _tab == 0)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                              child: InkButton('All orders (${_orders.length})',
                                  variant: InkVariant.surface, trailingIcon: Icons.arrow_forward, height: 46,
                                  onPressed: () => _go(const OrdersScreen())),
                            ),
                          _stylingPromo(),
                          _group('Account & preferences', [
                            _row(Icons.receipt_long_outlined, 'Orders & tracking',
                                _orders.isEmpty ? 'No orders yet' : '${_orders.length} placed', () => _go(const OrdersScreen())),
                            _row(Icons.place_outlined, 'Delivery addresses',
                                defAddress == null ? 'Add where you want orders delivered' : 'Default: ${defAddress.addressLine}, ${defAddress.city}',
                                () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen()));
                              _load();
                            }),
                            _row(Icons.credit_card, 'Payments & offers',
                                defMethod == null ? 'Cards, M-Pesa and saved offers' : '${defMethod.title} • ${defMethod.subtitle}',
                                () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen()));
                              _load();
                            }),
                            _row(Icons.notifications_none_rounded, 'Notifications', 'Order updates and offers',
                                () => _go(const NotificationsScreen())),
                            _row(Icons.favorite_border, 'Lookbook', '${wish.count} saved', () => shellTab.value = 2, last: true),
                          ]),
                          _group('Support & information', _infoRows()),
                          const SizedBox(height: 28),
                          Center(
                            child: TextButton(
                              onPressed: _signOut,
                              child: Text('SIGN OUT',
                                  style: AppType.labelCaps(AppColors.error).copyWith(fontSize: 10.5)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text('LARKTRIBE • VERSION 1.0.0',
                                style: AppType.labelBadge(AppColors.subtext).copyWith(fontSize: 9)),
                          ),
                        ],
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String? image;
  final String tag;
  final String title;
  final String meta;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback? onTap;
  final VoidCallback onAction;
  const _MiniCard({
    required this.image,
    required this.tag,
    required this.title,
    required this.meta,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.sm)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: .8,
            child: Stack(fit: StackFit.expand, children: [
              NetImage(image),
              if (tag.isNotEmpty)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    color: Colors.white.withOpacity(.92),
                    child: Text(tag.toUpperCase(),
                        maxLines: 1,
                        style: AppType.labelBadge(AppColors.ink).copyWith(fontSize: 8.5, letterSpacing: 1)),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.headlineSm(AppColors.ink).copyWith(fontSize: 16)),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.bodySm(AppColors.inkSoft)),
        ],
        const SizedBox(height: 10),
        InkWell(
          onTap: onAction,
          child: Container(
            height: 38,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.xs)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(actionIcon, size: 14),
              const SizedBox(width: 6),
              Text(actionLabel.toUpperCase(), style: AppType.labelBadge(AppColors.ink).copyWith(fontSize: 9)),
            ]),
          ),
        ),
      ]),
    );
  }
}
