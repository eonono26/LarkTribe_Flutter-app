import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common.dart';
import '../widgets/form_bits.dart';
import '../widgets/product_card.dart';

/// Payment methods & offers (Stitch screen 09). Cards are display-only
/// tokens (brand + last 4 + expiry) — full card numbers are never stored.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<SavedPaymentMethod> _methods = [];
  List<WalletCoupon> _available = [];
  List<WalletCoupon> _mine = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ApiService.instance;
    if (!api.isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    try {
      final r = await Future.wait<List<dynamic>>([
        api.paymentMethods(),
        api.availableCoupons(),
        api.myCoupons(),
      ]);
      if (!mounted) return;
      setState(() {
        _methods = r[0].cast<SavedPaymentMethod>();
        _available = r[1].cast<WalletCoupon>();
        _mine = r[2].cast<WalletCoupon>();
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

  Future<void> _guard(Future<void> Function() f, {String? done}) async {
    try {
      await f();
      if (done != null && mounted) toast(context, done);
      await _load();
    } catch (e) {
      if (mounted) toast(context, e.toString());
    }
  }

  Future<void> _openAdd() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddMethodForm(first: _methods.isEmpty),
      ),
    );
    if (saved == true) _load();
  }

  Widget _memberCard() {
    final cards = _methods.where((m) => m.isCard).toList();
    final def = cards.where((m) => m.isDefault).toList();
    final card = def.isNotEmpty ? def.first : (cards.isNotEmpty ? cards.first : null);
    final profile = ApiService.instance.cachedProfile;
    final since = profile?.dateJoined?.year;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      padding: const EdgeInsets.all(22),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A0A), Color(0xFF2B2B2B), Color(0xFF0A0A0A)],
        ),
        boxShadow: AppShadows.md,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MEMBER CARD', style: AppType.labelBadge(Colors.white70).copyWith(fontSize: 9)),
              const SizedBox(height: 2),
              Text('LarkTribe', style: AppType.headlineMd(Colors.white).copyWith(fontSize: 22)),
            ]),
          ),
          const Icon(Icons.nfc, color: Colors.white70, size: 22),
          const SizedBox(width: 10),
          const Icon(Icons.lock_outline, color: Colors.white70, size: 20),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Container(
            width: 44,
            height: 32,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(colors: [Color(0xFFD9BC8C), Color(0xFF9C7E50)])),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(3)),
            child: Text(card == null ? 'NO CARD SAVED' : card.cardBrand.toUpperCase(),
                style: AppType.labelBadge(AppColors.goldOnDark).copyWith(fontSize: 9)),
          ),
        ]),
        const Spacer(),
        Text(card == null ? '••••  ••••  ••••  ––––' : '••••  ••••  ••••  ${card.cardLast4}',
            style: AppText.price(18, color: Colors.white).copyWith(letterSpacing: 2.5)),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CARDHOLDER', style: AppType.labelBadge(Colors.white54).copyWith(fontSize: 8)),
              Text((profile?.displayName ?? 'MEMBER').toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.labelCaps(Colors.white).copyWith(fontSize: 11)),
            ]),
          ),
          if (since != null)
            Text("MEMBER SINCE '${(since % 100).toString().padLeft(2, '0')}",
                style: AppType.labelBadge(Colors.white70).copyWith(fontSize: 9)),
        ]),
      ]),
    );
  }

  Widget _benefits() {
    final unused = _mine.where((c) => !c.used).length;
    return Panel(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MEMBER BENEFITS', style: AppType.labelCaps(AppColors.ink).copyWith(fontSize: 10.5)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('5%', style: AppType.headlineLg(AppColors.ink).copyWith(fontSize: 38)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('off every order', style: AppType.bodyMd(AppColors.inkSoft)),
          ),
        ]),
        const SizedBox(height: 10),
        Text('Applied automatically at checkout while you are signed in.', style: AppType.bodySm(AppColors.inkSoft)),
        const Divider(height: 28),
        Row(children: [
          Container(width: 40, height: 40, color: AppColors.surfaceLow, child: const Icon(Icons.local_offer_outlined, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Saved offers', style: AppType.bodyMd(AppColors.ink).copyWith(fontWeight: FontWeight.w600)),
              Text('$unused ready to use', style: AppType.bodySm(AppColors.inkSoft)),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _methodRow(SavedPaymentMethod m) {
    return Panel(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          color: m.isDefault ? AppColors.ink : AppColors.surfaceLow,
          child: Icon(m.isCard ? Icons.credit_card : Icons.phone_android,
              size: 22, color: m.isDefault ? Colors.white : AppColors.ink),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(m.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.bodyMd(AppColors.ink).copyWith(fontWeight: FontWeight.w600)),
              ),
              if (m.isDefault) ...[const SizedBox(width: 8), const TagBadge('Default', tone: TagTone.grey)],
            ]),
            const SizedBox(height: 2),
            Text(m.subtitle, style: AppType.bodySm(AppColors.inkSoft)),
          ]),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (v) {
            if (v == 'default') {
              _guard(() => ApiService.instance.setDefaultPaymentMethod(m.id), done: 'Default updated');
            } else {
              _guard(() => ApiService.instance.deletePaymentMethod(m.id), done: 'Removed');
            }
          },
          itemBuilder: (_) => [
            if (!m.isDefault) const PopupMenuItem(value: 'default', child: Text('SET AS DEFAULT')),
            const PopupMenuItem(value: 'remove', child: Text('REMOVE')),
          ],
        ),
      ]),
    );
  }

  Widget _staticRow(IconData icon, String title, String subtitle, String status) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(width: 40, height: 40, color: AppColors.surfaceLow, child: Icon(icon, size: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppType.bodyMd(AppColors.ink).copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: AppType.bodySm(AppColors.inkSoft)),
            ]),
          ),
          Text(status, style: AppType.labelBadge(AppColors.goldDeep).copyWith(fontSize: 9)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final signedIn = ApiService.instance.isLoggedIn;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const AtelierAppBar(title: 'Payments & offers'),
      body: !signedIn
          ? LarkEmptyState(
              icon: Icons.credit_card,
              title: 'Sign in to manage payments',
              message: 'Save your preferred way to pay and keep your offers in one place.',
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
                  : RefreshIndicator(
                      color: AppColors.ink,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 40),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            color: AppColors.surfaceLow,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Row(children: [
                              const Icon(Icons.circle, size: 6, color: AppColors.goldDeep),
                              const SizedBox(width: 8),
                              Text('SAVED PAYMENT METHODS', style: AppType.labelBadge(AppColors.ink)),
                              const Spacer(),
                              Text('ACTIVE', style: AppType.labelBadge(AppColors.goldDeep)),
                            ]),
                          ),
                          _memberCard(),
                          _benefits(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Row(children: [
                              Expanded(child: Text('SAVED METHODS', style: AppType.labelCaps(AppColors.ink).copyWith(fontSize: 10.5))),
                              Text('${_methods.length} ${_methods.length == 1 ? 'instrument' : 'instruments'}',
                                  style: AppType.bodySm(AppColors.inkSoft)),
                            ]),
                          ),
                          if (_methods.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Text('No cards or M-Pesa numbers saved yet.', style: AppType.bodyMd(AppColors.inkSoft)),
                            ),
                          for (final m in _methods) _methodRow(m),
                          Panel(
                            margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Column(children: [
                              _staticRow(Icons.phone_android, 'M-Pesa', 'Pay with your phone at checkout', 'AVAILABLE'),
                              const Divider(height: 1),
                              _staticRow(Icons.payments_outlined, 'Cash on delivery', 'Pay the courier on arrival', 'AVAILABLE'),
                            ]),
                          ),
                          Panel(
                            color: AppColors.surface,
                            onTap: _openAdd,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.add, size: 18),
                              const SizedBox(width: 8),
                              Text('ADD PAYMENT METHOD', style: AppType.labelCaps(AppColors.ink).copyWith(fontSize: 10.5)),
                            ]),
                          ),
                          if (_available.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Text('OFFERS WALLET', style: AppType.labelCaps(AppColors.ink).copyWith(fontSize: 10.5)),
                            ),
                            for (final c in _available)
                              Panel(
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    color: AppColors.goldTint,
                                    child: const Icon(Icons.local_offer_outlined, size: 20, color: AppColors.goldDeep),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(c.code, style: AppType.bodyMd(AppColors.ink).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1)),
                                      Text(
                                          '${c.summary}${c.validUntil == null ? '' : ' • until ${formatDate(c.validUntil)}'}',
                                          style: AppType.bodySm(AppColors.inkSoft)),
                                    ]),
                                  ),
                                  c.saved
                                      ? Text('SAVED', style: AppType.labelBadge(AppColors.goldDeep))
                                      : SizedBox(
                                          width: 84,
                                          child: InkButton('Save',
                                              height: 40,
                                              onPressed: () => _guard(() => ApiService.instance.claimCoupon(c.code),
                                                  done: 'Offer saved to your wallet')),
                                        ),
                                ]),
                              ),
                          ],
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            padding: const EdgeInsets.all(20),
                            color: AppColors.surfaceLow,
                            child: Column(children: [
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.shield_outlined, size: 16),
                                const SizedBox(width: 8),
                                Text('PAYMENT SECURITY', style: AppType.labelCaps(AppColors.ink).copyWith(fontSize: 10.5)),
                              ]),
                              const SizedBox(height: 8),
                              Text(
                                  'We only keep the card brand, last four digits and expiry on your account. Full card numbers are never stored in the app.',
                                  textAlign: TextAlign.center,
                                  style: AppType.bodySm(AppColors.inkSoft)),
                            ]),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _AddMethodForm extends StatefulWidget {
  final bool first;
  const _AddMethodForm({required this.first});

  @override
  State<_AddMethodForm> createState() => _AddMethodFormState();
}

class _AddMethodFormState extends State<_AddMethodForm> {
  int _type = 0; // 0 card · 1 mpesa
  String _brand = 'Visa';
  final _last4 = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  final _phone = TextEditingController();
  late bool _default = widget.first;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_last4, _month, _year, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_type == 0) {
      final m = int.tryParse(_month.text);
      final y = int.tryParse(_year.text);
      if (_last4.text.trim().length != 4 || m == null || m < 1 || m > 12 || y == null) {
        setState(() => _error = 'Enter the last 4 digits and a valid expiry (MM / YY).');
        return;
      }
    } else if (_phone.text.trim().length < 9) {
      setState(() => _error = 'Enter a valid M-Pesa phone number.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_type == 0) {
        final y = int.parse(_year.text);
        await ApiService.instance.addPaymentMethod(
          type: 'card',
          cardBrand: _brand,
          cardLast4: _last4.text.trim(),
          expMonth: int.parse(_month.text),
          expYear: y < 100 ? 2000 + y : y,
          isDefault: _default,
        );
      } else {
        await ApiService.instance.addPaymentMethod(
          type: 'mpesa',
          mpesaPhone: _phone.text.trim(),
          isDefault: _default,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Add payment method', style: AppType.headlineMd(AppColors.ink))),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 12),
          SegmentTrack(labels: const ['Card', 'M-Pesa'], index: _type, onChanged: (i) => setState(() => _type = i)),
          const SizedBox(height: 20),
          if (_type == 0) ...[
            const FieldLabel('Card brand'),
            Wrap(spacing: 8, children: [
              for (final b in const ['Visa', 'Mastercard', 'Amex'])
                PillChip(b, selected: _brand == b, onTap: () => setState(() => _brand = b)),
            ]),
            const SizedBox(height: 18),
            LabeledField(label: 'Last 4 digits', controller: _last4, keyboardType: TextInputType.number, hint: '1234'),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: LabeledField(label: 'Exp. month', controller: _month, keyboardType: TextInputType.number, hint: 'MM')),
              const SizedBox(width: 12),
              Expanded(child: LabeledField(label: 'Exp. year', controller: _year, keyboardType: TextInputType.number, hint: 'YY')),
            ]),
          ] else
            LabeledField(label: 'M-Pesa phone', controller: _phone, keyboardType: TextInputType.phone, hint: '07XX XXX XXX'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.ink,
            title: Text('Use as default', style: AppType.bodyMd(AppColors.ink)),
            value: _default,
            onChanged: (v) => setState(() => _default = v),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: AppType.bodySm(AppColors.error))),
          InkButton('Save', loading: _saving, onPressed: _save),
        ]),
      ),
    );
  }
}
