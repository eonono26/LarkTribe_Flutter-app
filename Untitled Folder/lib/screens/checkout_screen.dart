import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common.dart';
import '../widgets/form_bits.dart';
import '../widgets/product_card.dart';
import 'main_shell.dart';
import 'order_detail_screen.dart';

/// Secure checkout — same fields and totals as the storefront, styled to
/// match the bag. Pops `true` after an order is placed.
class CheckoutScreen extends StatefulWidget {
  final String couponCode;
  final double couponDiscount;
  const CheckoutScreen({super.key, this.couponCode = '', this.couponDiscount = 0});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();

  String _payment = 'mpesa';
  List<SavedAddress> _saved = [];
  int? _selectedAddress;
  bool _placing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    for (final c in [_email, _name, _phone, _address, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _prefill() async {
    final api = ApiService.instance;
    if (!api.isLoggedIn) return;
    final profile = api.cachedProfile ?? await api.me();
    final addresses = await api.addresses();
    final methods = await api.paymentMethods();
    if (!mounted) return;
    setState(() {
      _saved = addresses;
      if (profile != null) {
        if (_name.text.isEmpty) _name.text = profile.displayName;
        if (_phone.text.isEmpty) _phone.text = profile.phone;
      }
      final def = addresses.where((a) => a.isDefault).toList();
      if (def.isNotEmpty) {
        _useAddress(def.first);
      } else if (addresses.isNotEmpty) {
        _useAddress(addresses.first);
      }
      final defMethod = methods.where((m) => m.isDefault).toList();
      if (defMethod.isNotEmpty) _payment = defMethod.first.type;
    });
  }

  void _useAddress(SavedAddress a) {
    _selectedAddress = a.id;
    _name.text = a.fullName;
    _phone.text = a.phone;
    _address.text = a.addressLine;
    _city.text = a.city;
  }

  Future<void> _place() async {
    final api = ApiService.instance;
    if (!api.isLoggedIn && _email.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email so we can send your receipt.');
      return;
    }
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _address.text.trim().isEmpty ||
        _city.text.trim().isEmpty) {
      setState(() => _error = 'Please complete your delivery details.');
      return;
    }
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final order = await api.checkout(
        guestEmail: api.isLoggedIn ? null : _email.text.trim(),
        paymentMethod: _payment,
        shippingName: _name.text.trim(),
        shippingPhone: _phone.text.trim(),
        shippingAddress: _address.text.trim(),
        shippingCity: _city.text.trim(),
        couponCode: widget.couponCode,
      );
      if (!mounted) return;
      await context.read<CartProvider>().refresh();
      if (!mounted) return;
      final number = order['order_number']?.toString() ?? '';
      final total = order['total']?.toString() ?? '0';
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text('Order placed', style: AppType.headlineMd(AppColors.ink)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('Order number'),
            const SizedBox(height: 4),
            Text('#$number', style: AppType.headlineSm(AppColors.ink)),
            const SizedBox(height: 12),
            Text('Total ${formatKES(total)}', style: AppText.price(15)),
            const SizedBox(height: 12),
            Text(
              _payment == 'cod'
                  ? 'Pay the courier when your order arrives.'
                  : 'We will confirm your payment shortly.',
              style: AppType.bodyMd(AppColors.inkSoft),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Done'),
            ),
            if (api.isLoggedIn || number.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderNumber: number)));
                },
                child: const Text('Track order'),
              ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.popUntil(context, (r) => r.isFirst);
      shellTab.value = api.isLoggedIn ? 4 : 0;
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Checkout failed. Please try again.');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Widget _step(String number, String title, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('0$number', style: AppType.labelBadge(AppColors.goldDeep)),
            const SizedBox(width: 8),
            Text('/ 03', style: AppType.labelBadge(AppColors.inkSoft)),
            const SizedBox(width: 12),
            Text(title.toUpperCase(), style: AppType.labelCaps(AppColors.ink)),
          ]),
          const SizedBox(height: 16),
          child,
        ]),
      );

  Widget _paymentOption(String value, String title, String subtitle, IconData icon) {
    final selected = _payment == value;
    return GestureDetector(
      onTap: () => setState(() => _payment = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: selected ? Colors.white : AppColors.ink),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppType.bodyMd(selected ? Colors.white : AppColors.ink).copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: AppType.bodySm(selected ? Colors.white70 : AppColors.inkSoft)),
            ]),
          ),
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20, color: selected ? AppColors.goldOnDark : AppColors.stone400),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final api = ApiService.instance;
    final member = api.isLoggedIn;
    final t = CartTotals.compute(cart.subtotal, member: member, coupon: widget.couponDiscount);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const AtelierAppBar(title: 'Secure checkout'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
        children: [
          Text('Checkout', style: AppType.headlineLg(AppColors.ink)),
          const SizedBox(height: 22),
          _step(
            '1',
            'Contact',
            member
                ? Panel(
                    margin: EdgeInsets.zero,
                    child: Row(children: [
                      const Icon(Icons.verified_user_outlined, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Signed in as ${api.cachedProfile?.displayName ?? 'member'}',
                            style: AppType.bodyMd(AppColors.ink)),
                      ),
                    ]),
                  )
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    LabeledField(
                        label: 'Email for your receipt',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress),
                    GestureDetector(
                      onTap: () async {
                        if (await ensureSignedIn(context) && mounted) {
                          setState(() {});
                          _prefill();
                        }
                      },
                      child: Text('ALREADY A MEMBER? SIGN IN TO SAVE 5%',
                          style: AppType.labelBadge(AppColors.goldDeep)
                              .copyWith(decoration: TextDecoration.underline)),
                    ),
                  ]),
          ),
          _step(
            '2',
            'Delivery',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_saved.isNotEmpty) ...[
                SizedBox(
                  height: 44,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final a in _saved)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: PillChip(a.label.isEmpty ? 'Address' : a.label[0].toUpperCase() + a.label.substring(1),
                            selected: _selectedAddress == a.id,
                            icon: Icons.place_outlined,
                            onTap: () => setState(() => _useAddress(a))),
                      ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
              LabeledField(label: 'Full name', controller: _name, capitalization: TextCapitalization.words),
              LabeledField(label: 'Phone', controller: _phone, keyboardType: TextInputType.phone, hint: '07XX XXX XXX'),
              LabeledField(label: 'Address', controller: _address, hint: 'Street, building, apartment'),
              LabeledField(label: 'City / town', controller: _city, capitalization: TextCapitalization.words),
            ]),
          ),
          _step(
            '3',
            'Payment',
            Column(children: [
              _paymentOption('mpesa', 'M-Pesa', 'Pay with your phone via Daraja', Icons.phone_android),
              _paymentOption('card', 'Card', 'Visa or Mastercard', Icons.credit_card),
              _paymentOption('cod', 'Cash on delivery', 'Pay the courier on arrival', Icons.payments_outlined),
            ]),
          ),
          Panel(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              KeyValueRow('Subtotal', formatKES(t.subtotal.toStringAsFixed(0))),
              KeyValueRow('Delivery', t.shipping == 0 ? 'FREE' : formatKES(t.shipping.toStringAsFixed(0)),
                  valueColor: t.shipping == 0 ? AppColors.goldDeep : null),
              if (member && t.member > 0)
                KeyValueRow('Member discount (5%)', '− ${formatKES(t.member.toStringAsFixed(0))}',
                    valueColor: AppColors.goldDeep),
              if (t.coupon > 0)
                KeyValueRow('Promo ${widget.couponCode}', '− ${formatKES(t.coupon.toStringAsFixed(0))}',
                    valueColor: AppColors.goldDeep),
              const Divider(height: 24),
              Row(children: [
                Expanded(child: Text('TOTAL', style: AppType.headlineMd(AppColors.ink).copyWith(fontSize: 19))),
                Text(formatKES(t.total.toStringAsFixed(0)),
                    style: AppType.headlineLg(AppColors.ink).copyWith(fontSize: 26)),
              ]),
            ]),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(_error!, style: AppType.bodySm(AppColors.error)),
            ),
          const SizedBox(height: 18),
          InkButton('Place order', icon: Icons.lock_outline, loading: _placing, onPressed: _place),
          const SizedBox(height: 10),
          Text('Final totals are confirmed by the store when your order is placed.',
              textAlign: TextAlign.center, style: AppType.bodySm(AppColors.subtext)),
        ],
      ),
    );
  }
}
