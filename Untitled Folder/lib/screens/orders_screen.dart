import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_gate.dart';
import '../widgets/chatbot_sheet.dart';
import '../widgets/common.dart';
import '../widgets/form_bits.dart';
import '../widgets/order_bits.dart';
import '../widgets/product_card.dart';
import 'main_shell.dart';
import 'order_detail_screen.dart';

/// Order history & tracking (Stitch screen 07).
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<OrderSummary> _orders = [];
  bool _loading = true;
  bool _error = false;
  int _filter = 0; // 0 all · 1 in progress · 2 delivered

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!ApiService.instance.isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    try {
      final o = await ApiService.instance.myOrders();
      if (!mounted) return;
      setState(() {
        _orders = o;
        _loading = false;
        _error = false;
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

  void _open(OrderSummary o) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderNumber: o.orderNumber)));

  Future<void> _reorder(OrderSummary o) async {
    final cart = context.read<CartProvider>();
    var added = 0;
    var skipped = 0;
    for (final i in o.items) {
      if (i.productId == null) {
        skipped++;
        continue;
      }
      try {
        await cart.addItem(i.productId!, quantity: i.quantity, variantId: i.variantId);
        added++;
      } catch (_) {
        skipped++;
      }
    }
    if (!mounted) return;
    if (added > 0) {
      toast(context, skipped == 0 ? 'Added to your bag' : 'Added $added — $skipped unavailable',
          actionLabel: 'VIEW BAG', onAction: () {
        Navigator.popUntil(context, (r) => r.isFirst);
        shellTab.value = 3;
      });
    } else {
      toast(context, 'Those pieces are no longer available.');
    }
  }

  Widget _itemRow(OrderItemDetail i) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        color: AppColors.surfaceLow,
        child: Row(children: [
          SizedBox(width: 56, height: 72, child: NetImage(i.productImage)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (i.variantLabel.isNotEmpty)
                Text(i.variantLabel.toUpperCase(),
                    style: AppType.labelBadge(AppColors.goldDeep).copyWith(fontSize: 9)),
              const SizedBox(height: 3),
              Text(i.productName,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.headlineSm(AppColors.ink).copyWith(fontSize: 16)),
              const SizedBox(height: 3),
              Row(children: [
                Text('Qty ${i.quantity}', style: AppType.bodySm(AppColors.inkSoft)),
                const Spacer(),
                Text(formatKES(i.unitPrice), style: AppText.price(14)),
              ]),
            ]),
          ),
        ]),
      );

  Widget _activeCard(OrderSummary o) {
    final city = o.shippingCity.isEmpty ? 'Your address' : o.shippingCity;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        color: Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            color: AppColors.ink,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.goldOnDark, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(orderStatusLabel(o.status).toUpperCase(),
                    style: AppType.labelBadge(Colors.white).copyWith(letterSpacing: 1.4)),
              ),
              Text('#${o.orderNumber}', style: AppType.labelBadge(Colors.white).copyWith(letterSpacing: 1)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('DELIVERING TO', style: AppType.labelBadge(AppColors.goldDeep)),
                    const SizedBox(height: 4),
                    Text(city, style: AppType.headlineMd(AppColors.ink).copyWith(fontSize: 24)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('PLACED', style: AppType.labelBadge(AppColors.inkSoft)),
                  const SizedBox(height: 4),
                  Text(formatDate(o.createdDate), style: AppType.bodyMd(AppColors.ink)),
                ]),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                color: AppColors.surfaceLow,
                child: OrderProgressBar(status: o.status),
              ),
              const SizedBox(height: 14),
              InkButton(
                o.isInTransit ? 'Track live location' : 'View order',
                icon: o.isInTransit ? Icons.near_me_outlined : null,
                trailingIcon: Icons.arrow_forward,
                variant: InkVariant.surface,
                height: 46,
                onPressed: () => _open(o),
              ),
              const SizedBox(height: 14),
              Text('ITEMS (${o.itemCount})', style: AppType.labelBadge(AppColors.ink)),
              for (final i in o.items) _itemRow(i),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Text('TOTAL', style: AppType.labelBadge(AppColors.inkSoft))),
                Text(formatKES(o.total), style: AppText.price(16, weight: FontWeight.w600)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _archiveCard(OrderSummary o) {
    final first = o.items.isNotEmpty ? o.items.first : null;
    final more = o.items.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _open(o),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ORDER #${o.orderNumber}', style: AppType.labelBadge(AppColors.ink).copyWith(letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('${o.isDelivered ? 'Delivered' : 'Placed'} ${formatDate(o.createdDate)}'
                      '${o.shippingCity.isEmpty ? '' : ' • ${o.shippingCity}'}',
                      style: AppType.bodySm(AppColors.inkSoft)),
                ]),
              ),
            ),
            TagBadge(orderStatusLabel(o.status), tone: o.isDelivered ? TagTone.grey : (o.isCancelled ? TagTone.red : TagTone.peach)),
          ]),
          if (first != null) ...[
            _itemRow(first),
            if (more > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('+ $more more ${more == 1 ? 'item' : 'items'}', style: AppType.bodySm(AppColors.inkSoft)),
              ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text('TOTAL', style: AppType.labelBadge(AppColors.inkSoft))),
            Text(formatKES(o.total), style: AppText.price(15, weight: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: InkButton(o.isDelivered ? 'Request return' : 'View order',
                  variant: InkVariant.surface, height: 46, onPressed: () => _open(o)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkButton('Re-order', icon: Icons.refresh, height: 46, onPressed: () => _reorder(o)),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ApiService.instance.isLoggedIn;
    final active = _orders.where((o) => o.isActive).toList();
    final delivered = _orders.where((o) => o.isDelivered).toList();
    final shown = _filter == 0 ? _orders : (_filter == 1 ? active : delivered);
    final shownActive = shown.where((o) => o.isActive).toList();
    final shownArchive = shown.where((o) => !o.isActive).toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const AtelierAppBar(title: 'Order history'),
      body: !signedIn
          ? LarkEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sign in to see your orders',
              message: 'Your orders and live delivery tracking live in your account.',
              actionLabel: 'Sign in',
              onAction: () async {
                if (await ensureSignedIn(context) && mounted) {
                  setState(() => _loading = true);
                  _load();
                }
              },
            )
          : _loading
              ? const LarkLoading()
              : _error
                  ? LarkErrorState(onRetry: () {
                      setState(() => _loading = true);
                      _load();
                    })
                  : _orders.isEmpty
                      ? LarkEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No orders yet',
                          message: 'When you place an order it will appear here with live tracking.',
                          actionLabel: 'Start shopping',
                          onAction: () {
                            Navigator.popUntil(context, (r) => r.isFirst);
                            shellTab.value = 0;
                          })
                      : RefreshIndicator(
                          color: AppColors.ink,
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 40),
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 22, 16, 0),
                                child: Eyebrow('Order history'),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                                child: Text('Your Orders & Deliveries', style: AppType.headlineLgMobile(AppColors.ink)),
                              ),
                              SizedBox(
                                height: 42,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  children: [
                                    PillChip('All (${_orders.length})', selected: _filter == 0, onTap: () => setState(() => _filter = 0)),
                                    const SizedBox(width: 8),
                                    PillChip('In progress (${active.length})', selected: _filter == 1, onTap: () => setState(() => _filter = 1)),
                                    const SizedBox(width: 8),
                                    PillChip('Delivered (${delivered.length})', selected: _filter == 2, onTap: () => setState(() => _filter = 2)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              for (final o in shownActive) _activeCard(o),
                              if (shownArchive.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const SectionHeading(eyebrow: 'Past orders', title: 'Delivered Archive'),
                                const SizedBox(height: 14),
                                for (final o in shownArchive) _archiveCard(o),
                              ],
                              if (shown.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(child: Text('Nothing in this view.', style: AppType.bodyMd(AppColors.subtext))),
                                ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                child: Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                                  child: Row(children: [
                                    const Icon(Icons.support_agent, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text('ORDER ENQUIRIES',
                                            style: AppType.labelBadge(AppColors.goldDeep).copyWith(fontSize: 9)),
                                        Text('Questions about an order?', style: AppType.bodyMd(AppColors.ink)),
                                      ]),
                                    ),
                                    SizedBox(
                                      width: 92,
                                      child: InkButton('Speak', height: 42, onPressed: () => showChatbotSheet(context)),
                                    ),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        ),
    );
  }
}
