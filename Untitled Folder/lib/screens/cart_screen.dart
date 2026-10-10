import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';
import '../services/wishlist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'checkout_screen.dart';
import 'main_shell.dart';
import 'product_detail_screen.dart';

/// Shopping bag (Stitch screen 04).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();
  String _coupon = '';
  double _couponDiscount = 0;
  bool _applying = false;
  String? _couponError;
  final Set<int> _busy = {};

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(int itemId, Future<void> Function() action) async {
    setState(() => _busy.add(itemId));
    try {
      await action();
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy.remove(itemId));
    }
  }

  Future<void> _applyCoupon(double subtotal) async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _applying = true;
      _couponError = null;
    });
    try {
      final (valid, discount, detail) = await ApiService.instance.validateCoupon(code, subtotal);
      if (!mounted) return;
      setState(() {
        if (valid) {
          _coupon = code;
          _couponDiscount = discount;
          _couponCtrl.clear();
        } else {
          _couponError = detail ?? 'That code is not valid for this bag.';
        }
      });
    } catch (_) {
      if (mounted) setState(() => _couponError = "Couldn't check that code. Try again.");
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _moveToWishlist(CartItem item) async {
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    await _run(item.id, () async {
      final wish = context.read<WishlistProvider>();
      if (!wish.contains(item.product.id)) await wish.toggle(item.product.id);
      await context.read<CartProvider>().removeItem(item.id);
      if (mounted) toast(context, 'Moved to your lookbook');
    });
  }

  Widget _panel({required Widget child, EdgeInsetsGeometry? padding, Color? color}) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color ?? Colors.white, borderRadius: BorderRadius.circular(AppRadii.sm)),
        child: child,
      );

  Widget _freeDelivery(double subtotal) {
    final unlocked = subtotal > StoreRules.freeDeliveryThreshold;
    final remaining = StoreRules.freeDeliveryThreshold - subtotal;
    final progress = (subtotal / StoreRules.freeDeliveryThreshold).clamp(0.0, 1.0);
    return _panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_shipping_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(unlocked ? 'FREE DELIVERY' : 'DELIVERY',
                style: AppType.labelCaps(AppColors.ink).copyWith(fontSize: 10.5)),
          ),
          Text(unlocked ? 'UNLOCKED' : 'KSH ${formatNumber(StoreRules.deliveryFee)}',
              style: AppType.labelBadge(AppColors.goldDeep)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: AppColors.surface,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          unlocked
              ? 'Your order qualifies for free delivery.'
              : 'Add ${formatKES(remaining.toStringAsFixed(0))} more for free delivery.',
          style: AppType.bodySm(AppColors.inkSoft),
        ),
      ]),
    );
  }

  Widget _itemCard(CartItem item) {
    final busy = _busy.contains(item.id);
    final variant = item.variant;
    return _panel(
      child: Opacity(
        opacity: busy ? .5 : 1,
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 84,
              height: 108,
              child: Stack(fit: StackFit.expand, children: [
                NetImage(item.displayImage),
                if ((item.product.categoryName ?? '').isNotEmpty)
                  Positioned(
                    left: 0,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      color: Colors.white.withOpacity(.9),
                      child: Text(item.product.categoryName!.toUpperCase(),
                          maxLines: 1,
                          style: AppType.labelBadge(AppColors.ink).copyWith(fontSize: 8, letterSpacing: 1)),
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(slug: item.product.slug))),
                      child: Text(item.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.headlineSm(AppColors.ink).copyWith(fontSize: 17)),
                    ),
                  ),
                  GestureDetector(
                    onTap: busy ? null : () => _run(item.id, () => context.read<CartProvider>().removeItem(item.id)),
                    child: const Padding(
                        padding: EdgeInsets.only(left: 8), child: Icon(Icons.close, size: 20)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(formatKES(item.product.price), style: AppText.price(15)),
                const SizedBox(height: 8),
                if (variant != null)
                  Wrap(spacing: 14, children: [
                    if (variant.size.isNotEmpty)
                      Text('Size: ${variant.size}', style: AppType.bodySm(AppColors.inkSoft)),
                    if (variant.color.isNotEmpty)
                      Text('Colour: ${variant.color}', style: AppType.bodySm(AppColors.inkSoft)),
                  ]),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              decoration: BoxDecoration(
                  color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(AppRadii.xs)),
              child: Row(children: [
                _qtyButton(Icons.remove, busy ? null : () => _run(item.id, () {
                      final cart = context.read<CartProvider>();
                      return item.quantity <= 1
                          ? cart.removeItem(item.id)
                          : cart.updateItem(item.id, item.quantity - 1);
                    })),
                SizedBox(
                    width: 34,
                    child: Center(child: Text('${item.quantity}', style: AppText.price(14)))),
                _qtyButton(Icons.add, busy ? null : () => _run(item.id,
                    () => context.read<CartProvider>().updateItem(item.id, item.quantity + 1))),
              ]),
            ),
            const Spacer(),
            InkWell(
              onTap: busy ? null : () => _moveToWishlist(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  const Icon(Icons.favorite_border, size: 16),
                  const SizedBox(width: 6),
                  Text('MOVE TO LOOKBOOK',
                      style: AppType.labelBadge(AppColors.ink).copyWith(fontSize: 9.5, letterSpacing: 1.2)),
                ]),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 17)),
      );

  Widget _promo(double subtotal) {
    return _panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PROMO CODE', style: AppType.labelBadge(AppColors.ink)),
        const SizedBox(height: 12),
        if (_coupon.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.goldTint,
            child: Row(children: [
              const Icon(Icons.local_offer_outlined, size: 16, color: AppColors.goldDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text('$_coupon applied — you save ${formatKES(_couponDiscount.toStringAsFixed(0))}',
                    style: AppType.bodySm(AppColors.goldDeep).copyWith(fontWeight: FontWeight.w600)),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _coupon = '';
                  _couponDiscount = 0;
                }),
                child: const Icon(Icons.close, size: 16, color: AppColors.goldDeep),
              ),
            ]),
          )
        else
          Row(children: [
            Expanded(
              child: TextField(
                controller: _couponCtrl,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _applyCoupon(subtotal),
                decoration: const InputDecoration(hintText: 'ENTER VOUCHER CODE'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: InkButton('Apply', height: 48, loading: _applying, onPressed: () => _applyCoupon(subtotal)),
            ),
          ]),
        if (_couponError != null) ...[
          const SizedBox(height: 8),
          Text(_couponError!, style: AppType.bodySm(AppColors.error)),
        ],
      ]),
    );
  }

  Widget _paymentStrip() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final t in const ['M-PESA', 'VISA', 'MASTERCARD', 'CASH ON DELIVERY'])
              Padding(
                padding: const EdgeInsets.only(right: 28),
                child: Text(t, style: AppType.labelBadge(AppColors.inkSoft).copyWith(letterSpacing: 1.6)),
              ),
          ]),
        ),
      );

  Widget _summary(CartTotals t, bool member) {
    Widget row(String l, String v, {Color? color, bool strike = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Expanded(child: Text(l, style: AppType.bodyMd(AppColors.ink))),
            Text(v,
                style: color == null
                    ? AppText.price(14)
                    : AppType.labelBadge(color).copyWith(letterSpacing: 1.2, fontSize: 10.5)),
          ]),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.sm)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(children: [
            Row(children: [
              Expanded(child: Text('SUMMARY OF ORDER', style: AppType.labelBadge(AppColors.ink))),
              Text('KES', style: AppType.labelBadge(AppColors.inkSoft)),
            ]),
            const SizedBox(height: 10),
            row('Subtotal', formatKES(t.subtotal.toStringAsFixed(0))),
            row('Delivery',
                t.shipping == 0 ? 'FREE' : formatKES(t.shipping.toStringAsFixed(0)),
                color: t.shipping == 0 ? AppColors.goldDeep : null),
            if (member && t.member > 0)
              row('Member discount (5%)', '− ${formatKES(t.member.toStringAsFixed(0))}', color: AppColors.goldDeep),
            if (t.coupon > 0)
              row('Promo code', '− ${formatKES(t.coupon.toStringAsFixed(0))}', color: AppColors.goldDeep),
          ]),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadii.sm)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Text('GRAND TOTAL', style: AppType.headlineMd(AppColors.ink).copyWith(fontSize: 19)),
            ),
            Text(formatKES(t.total.toStringAsFixed(0)),
                style: AppType.headlineLg(AppColors.ink).copyWith(fontSize: 26)),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;
    final items = cart?.items ?? const <CartItem>[];
    final member = ApiService.instance.isLoggedIn;
    final subtotal = cart?.subtotal ?? 0;
    final totals = CartTotals.compute(subtotal, member: member, coupon: _couponDiscount);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(children: [
        const AtelierTopBar(line: false),
        Expanded(
          child: cartProvider.isLoading
              ? const LarkLoading()
              : items.isEmpty
                  ? LarkEmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Your bag is empty',
                      message: 'Pieces you add will wait for you here.',
                      actionLabel: 'Continue shopping',
                      onAction: () => shellTab.value = 0,
                    )
                  : RefreshIndicator(
                      color: AppColors.ink,
                      onRefresh: cartProvider.refresh,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Expanded(
                                child: Text('YOUR SHOPPING BAG',
                                    style: AppType.headlineLg(AppColors.ink).copyWith(fontSize: 28)),
                              ),
                              Text('${cartProvider.itemCount} ${cartProvider.itemCount == 1 ? 'ITEM' : 'ITEMS'}',
                                  style: AppType.labelBadge(AppColors.inkSoft)),
                            ]),
                          ),
                          _freeDelivery(subtotal),
                          for (final item in items) _itemCard(item),
                          if (!member)
                            _panel(
                              color: AppColors.goldTint,
                              child: Row(children: [
                                const Icon(Icons.workspace_premium_outlined, size: 20, color: AppColors.goldDeep),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('Sign in to save 5% on this order.',
                                      style: AppType.bodyMd(AppColors.goldDeep)
                                          .copyWith(fontWeight: FontWeight.w600)),
                                ),
                                GestureDetector(
                                  onTap: () => ensureSignedIn(context),
                                  child: Text('SIGN IN',
                                      style: AppType.labelBadge(AppColors.ink)
                                          .copyWith(decoration: TextDecoration.underline)),
                                ),
                              ]),
                            ),
                          _promo(subtotal),
                          _paymentStrip(),
                          _summary(totals, member),
                        ],
                      ),
                    ),
        ),
        if (!cartProvider.isLoading && items.isNotEmpty)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  const Icon(Icons.verified_user_outlined, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('SECURE CHECKOUT',
                        style: AppType.labelBadge(AppColors.ink).copyWith(fontSize: 9.5)),
                  ),
                  Text('TOTAL ', style: AppType.labelBadge(AppColors.inkSoft)),
                  Text(formatKES(totals.total.toStringAsFixed(0)), style: AppText.price(15)),
                ]),
                const SizedBox(height: 10),
                InkButton(
                  'Proceed to secure checkout',
                  icon: Icons.lock_outline,
                  onPressed: () async {
                    final done = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CheckoutScreen(couponCode: _coupon, couponDiscount: _couponDiscount)),
                    );
                    if (done == true && mounted) {
                      setState(() {
                        _coupon = '';
                        _couponDiscount = 0;
                      });
                    }
                  },
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}
