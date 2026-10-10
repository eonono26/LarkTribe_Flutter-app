import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common.dart';
import '../widgets/form_bits.dart';
import '../widgets/order_bits.dart';
import '../widgets/product_card.dart';

class _Step {
  final String title;
  final String description;
  final bool done;
  final bool current;
  final DateTime? at;
  const _Step(this.title, this.description, {this.done = false, this.current = false, this.at});
}

/// Order dispatch & courier tracking (Stitch screen 12).
class OrderDetailScreen extends StatefulWidget {
  final String orderNumber;
  const OrderDetailScreen({super.key, required this.orderNumber});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderDetail? _order;
  DeliveryTracking? _tracking;
  bool _loading = true;
  bool _error = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final order = await ApiService.instance.orderDetail(widget.orderNumber);
      final tracking = await ApiService.instance.orderTracking(widget.orderNumber);
      if (!mounted) return;
      setState(() {
        _order = order;
        _tracking = tracking;
        _loading = false;
        _error = false;
      });
      _startPolling();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _order == null;
        });
      }
    }
  }

  void _startPolling() {
    _poll?.cancel();
    if (_tracking?.isLive != true) return;
    _poll = Timer.periodic(const Duration(seconds: 15), (_) async {
      final t = await ApiService.instance.orderTracking(widget.orderNumber);
      if (!mounted) return;
      setState(() => _tracking = t ?? _tracking);
      if (t?.isLive != true) _poll?.cancel();
    });
  }

  // --------------------------------------------------------------- steps

  List<_Step> _steps(OrderDetail o) {
    final t = _tracking;
    if (t != null && t.events.isNotEmpty) {
      final events = [...t.events]..sort((a, b) => (a.at ?? DateTime(0)).compareTo(b.at ?? DateTime(0)));
      final steps = <_Step>[
        _Step('Order placed', 'We received your order and are getting it ready.', done: true, at: o.createdDate),
      ];
      for (var i = 0; i < events.length; i++) {
        final e = events[i];
        final last = i == events.length - 1;
        steps.add(_Step(
          deliveryStatusLabel(e.status),
          e.note.isNotEmpty ? e.note : _defaultNote(e.status),
          done: !last || e.status == 'delivered',
          current: last && e.status != 'delivered' && e.status != 'cancelled' && e.status != 'failed',
          at: e.at,
        ));
      }
      if (events.last.status != 'delivered' && !o.isCancelled) {
        steps.add(const _Step('Delivered', 'Your order arrives at your address.'));
      }
      return steps;
    }
    final stage = orderStage(o.status);
    return [
      _Step('Order placed', 'We received your order.', done: true, at: o.createdDate),
      _Step('Payment', o.status == 'pending_payment' ? 'Waiting for payment to be confirmed.' : 'Payment received.',
          done: o.status != 'pending_payment', current: o.status == 'pending_payment'),
      _Step('Being prepared', 'The seller is packing your items.', done: stage >= 3, current: stage == 2),
      _Step('On its way', 'Your courier is heading to you.', done: stage >= 4, current: stage == 3),
      _Step('Delivered', 'Your order arrives at your address.', done: stage >= 4),
    ];
  }

  String _defaultNote(String status) {
    switch (status) {
      case 'assigned':
        return 'A courier has been assigned to your order.';
      case 'picked_up':
        return 'Your order has left the seller.';
      case 'en_route':
        return 'Your courier is heading to your address.';
      case 'delivered':
        return 'Your order has been delivered.';
      case 'failed':
        return 'The delivery attempt was unsuccessful.';
      case 'cancelled':
        return 'This delivery was cancelled.';
      default:
        return '';
    }
  }

  // ------------------------------------------------------------- actions

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri) && mounted) toast(context, "Couldn't open the phone app.");
  }

  Future<void> _openMaps(OrderDetail o) async {
    final t = _tracking;
    final Uri uri;
    if (t?.dropoffLat != null && t?.dropoffLng != null) {
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${t!.dropoffLat},${t.dropoffLng}');
    } else {
      final q = Uri.encodeComponent('${o.shippingAddress}, ${o.shippingCity}');
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      toast(context, "Couldn't open maps.");
    }
  }

  Future<void> _openTicket(OrderDetail o, {required String subjectPrefix, required String hint}) async {
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    final ctrl = TextEditingController();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: _TicketForm(
          title: subjectPrefix,
          hint: hint,
          controller: ctrl,
          onSend: () async {
            try {
              await ApiService.instance.openSupportTicket(
                  '$subjectPrefix — Order #${o.orderNumber}', ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx, true);
            } catch (e) {
              if (ctx.mounted) toast(ctx, e.toString());
            }
          },
        ),
      ),
    );
    ctrl.dispose();
    if (sent == true && mounted) toast(context, 'Sent — our team will get back to you.');
  }

  // --------------------------------------------------------------- build

  Widget _statCell(String label, String value) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppType.labelBadge(AppColors.inkSoft).copyWith(fontSize: 8.5)),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.headlineSm(AppColors.ink).copyWith(fontSize: 15)),
          ]),
        ),
      );

  Widget _timeline(List<_Step> steps) {
    return Column(children: [
      for (var i = 0; i < steps.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 34,
              child: Column(children: [
                Container(
                  width: 26,
                  height: 26,
                  color: steps[i].done
                      ? AppColors.ink
                      : (steps[i].current ? AppColors.goldDeep : AppColors.surface),
                  child: Icon(
                      steps[i].done ? Icons.check : (steps[i].current ? Icons.local_shipping_outlined : Icons.circle_outlined),
                      size: 15,
                      color: (steps[i].done || steps[i].current) ? Colors.white : AppColors.subtext),
                ),
                if (i < steps.length - 1) Expanded(child: Container(width: 1, color: AppColors.line)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(steps[i].title,
                          style: AppType.bodyMd(AppColors.ink).copyWith(fontWeight: FontWeight.w600)),
                    ),
                    if (steps[i].current) const TagBadge('Active', tone: TagTone.peach),
                    if (steps[i].at != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text('${formatDate(steps[i].at).split(',').first} ${formatTime(steps[i].at)}',
                            style: AppType.bodySm(AppColors.inkSoft).copyWith(fontSize: 11)),
                      ),
                  ]),
                  if (steps[i].description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(steps[i].description, style: AppType.bodySm(AppColors.inkSoft)),
                  ],
                ]),
              ),
            ),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: AppColors.paper, appBar: AtelierAppBar(title: 'Order details'), body: LarkLoading());
    }
    final o = _order;
    if (_error || o == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: const AtelierAppBar(title: 'Order details'),
        body: LarkErrorState(
            message: "We couldn't load this order.",
            onRetry: () {
              setState(() => _loading = true);
              _load();
            }),
      );
    }

    final t = _tracking;
    final driver = t?.driver;
    final km = distanceKm(driver?.lat, driver?.lng, t?.dropoffLat, t?.dropoffLng);
    final couponDiscount =
        ((double.tryParse(o.discountTotal) ?? 0) - (double.tryParse(o.memberDiscountTotal) ?? 0)).clamp(0, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AtelierAppBar(
        title: 'Order details',
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_outlined),
            onPressed: () => _openTicket(o, subjectPrefix: 'Order enquiry', hint: 'How can we help with this order?'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.ink,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ORDER', style: AppType.labelBadge(AppColors.inkSoft)),
                    const SizedBox(height: 4),
                    Text('#${o.orderNumber}', style: AppType.display(AppColors.ink).copyWith(fontSize: 30)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  color: AppColors.ink,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (o.isInTransit)
                      Container(
                          margin: const EdgeInsets.only(right: 7),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppColors.goldOnDark, shape: BoxShape.circle)),
                    Text(orderStatusLabel(o.status).toUpperCase(),
                        style: AppType.labelBadge(Colors.white).copyWith(fontSize: 9.5)),
                  ]),
                ),
              ]),
            ),
            if (!o.isCancelled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  RoutePanel(tracking: t),
                  Container(
                    color: Colors.white,
                    child: Row(children: [
                      _statCell('STATUS', deliveryStatusLabel(t?.status ?? (o.isDelivered ? 'delivered' : 'unassigned')).toUpperCase()),
                      Container(width: 1, height: 38, color: AppColors.line),
                      _statCell('DISTANCE', km == null ? '—' : '${km.toStringAsFixed(1)} km'),
                      Container(width: 1, height: 38, color: AppColors.line),
                      _statCell('PLACED', formatDate(o.createdDate).split(',').first),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
            ],
            if (driver != null)
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('COURIER', style: AppType.labelBadge(AppColors.goldDeep)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      color: AppColors.surface,
                      child: const Icon(Icons.person_outline, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(driver.name, style: AppType.headlineSm(AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(
                          [driver.vehicleLabel, driver.plate].where((s) => s.isNotEmpty).join(' • '),
                          style: AppType.bodySm(AppColors.inkSoft),
                        ),
                      ]),
                    ),
                    const Icon(Icons.star, size: 14, color: AppColors.goldDeep),
                    const SizedBox(width: 3),
                    Text(driver.rating.toStringAsFixed(1), style: AppType.bodySm(AppColors.ink)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: InkButton('Call courier',
                          icon: Icons.call, height: 46,
                          onPressed: driver.phone.isEmpty ? null : () => _call(driver.phone)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkButton('Open in maps',
                          icon: Icons.map_outlined, variant: InkVariant.surface, height: 46,
                          onPressed: () => _openMaps(o)),
                    ),
                  ]),
                ]),
              ),
            Panel(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Builder(builder: (_) {
                  final steps = _steps(o);
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('Delivery Timeline', style: AppType.headlineMd(AppColors.ink).copyWith(fontSize: 20))),
                      Text('${steps.length} STAGES', style: AppType.labelBadge(AppColors.inkSoft)),
                    ]),
                    const SizedBox(height: 18),
                    _timeline(steps),
                  ]);
                }),
              ]),
            ),
            Panel(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Order Items', style: AppType.headlineMd(AppColors.ink).copyWith(fontSize: 20))),
                  Text('${o.itemCount} ${o.itemCount == 1 ? 'PIECE' : 'PIECES'}', style: AppType.labelBadge(AppColors.inkSoft)),
                ]),
                const SizedBox(height: 14),
                for (final i in o.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 60, height: 76, child: NetImage(i.productImage)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(i.fulfillmentStatus.replaceAll('_', ' ').toUpperCase(),
                              style: AppType.labelBadge(AppColors.goldDeep).copyWith(fontSize: 9)),
                          const SizedBox(height: 3),
                          Text(i.productName,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: AppType.headlineSm(AppColors.ink).copyWith(fontSize: 16)),
                          const SizedBox(height: 3),
                          Text([if (i.variantLabel.isNotEmpty) i.variantLabel, 'Qty ${i.quantity}'].join(' • '),
                              style: AppType.bodySm(AppColors.inkSoft)),
                        ]),
                      ),
                      Text(formatKES(i.lineTotal.toStringAsFixed(0)), style: AppText.price(14)),
                    ]),
                  ),
                const Divider(height: 24),
                KeyValueRow('Subtotal', formatKES(o.subtotal)),
                KeyValueRow('Delivery', (double.tryParse(o.shippingFee) ?? 0) == 0 ? 'FREE' : formatKES(o.shippingFee),
                    valueColor: (double.tryParse(o.shippingFee) ?? 0) == 0 ? AppColors.goldDeep : null),
                if ((double.tryParse(o.memberDiscountTotal) ?? 0) > 0)
                  KeyValueRow('Member discount', '− ${formatKES(o.memberDiscountTotal)}', valueColor: AppColors.goldDeep),
                if (couponDiscount > 0)
                  KeyValueRow('Promo ${o.couponCode}', '− ${formatKES(couponDiscount.toString())}', valueColor: AppColors.goldDeep),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: Text('TOTAL', style: AppType.labelBadge(AppColors.ink))),
                  Text(formatKES(o.total), style: AppType.headlineLg(AppColors.ink).copyWith(fontSize: 26)),
                ]),
              ]),
            ),
            Panel(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Delivery Details', style: AppType.headlineMd(AppColors.ink).copyWith(fontSize: 20))),
                ]),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.place_outlined, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('DESTINATION', style: AppType.labelBadge(AppColors.inkSoft).copyWith(fontSize: 9)),
                      const SizedBox(height: 3),
                      Text(o.shippingName, style: AppType.bodyMd(AppColors.ink).copyWith(fontWeight: FontWeight.w600)),
                      Text('${o.shippingAddress}, ${o.shippingCity}', style: AppType.bodyMd(AppColors.inkSoft)),
                      if (o.shippingPhone.isNotEmpty) Text(o.shippingPhone, style: AppType.bodySm(AppColors.inkSoft)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.payments_outlined, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('PAYMENT', style: AppType.labelBadge(AppColors.inkSoft).copyWith(fontSize: 9)),
                      const SizedBox(height: 3),
                      Text(paymentLabel(o.paymentMethod), style: AppType.bodyMd(AppColors.ink)),
                    ]),
                  ),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                if (o.isDelivered)
                  InkButton('Request return',
                      onPressed: () => _openTicket(o,
                          subjectPrefix: 'Return request',
                          hint: 'Tell us what you would like to return and why.')),
                if (o.isDelivered) const SizedBox(height: 8),
                InkButton('Contact support about this order',
                    variant: o.isDelivered ? InkVariant.surface : InkVariant.filled,
                    onPressed: () => _openTicket(o,
                        subjectPrefix: 'Order enquiry', hint: 'How can we help with this order?')),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketForm extends StatefulWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final Future<void> Function() onSend;
  const _TicketForm({required this.title, required this.hint, required this.controller, required this.onSend});

  @override
  State<_TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends State<_TicketForm> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.title, style: AppType.headlineMd(AppColors.ink)),
      const SizedBox(height: 14),
      TextField(
        controller: widget.controller,
        maxLines: 5,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      const SizedBox(height: 14),
      InkButton('Send', loading: _sending, onPressed: () async {
        if (widget.controller.text.trim().isEmpty) return;
        setState(() => _sending = true);
        await widget.onSend();
        if (mounted) setState(() => _sending = false);
      }),
    ]);
  }
}
