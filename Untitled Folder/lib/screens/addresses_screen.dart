import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common.dart';
import '../widgets/form_bits.dart';
import '../widgets/product_card.dart';

/// Delivery addresses (Stitch screen 08) — full CRUD on /auth/addresses/.
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<SavedAddress> _items = [];
  bool _loading = true;
  bool _error = false;

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
      final a = await ApiService.instance.addresses();
      if (!mounted) return;
      setState(() {
        _items = a;
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

  Future<void> _guard(Future<void> Function() f) async {
    try {
      await f();
      await _load();
    } catch (e) {
      if (mounted) toast(context, e.toString());
    }
  }

  Future<void> _openForm([SavedAddress? existing]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddressForm(existing: existing, first: _items.isEmpty),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _confirmDelete(SavedAddress a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove address?', style: AppType.headlineMd(AppColors.ink)),
        content: Text('${a.addressLine}, ${a.city}', style: AppType.bodyMd(AppColors.inkSoft)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) _guard(() => ApiService.instance.deleteAddress(a.id));
  }

  Widget _card(SavedAddress a) {
    return Panel(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Row(children: [
              Text(a.label.toUpperCase(), style: AppType.labelCaps(AppColors.ink).copyWith(fontSize: 10.5)),
              if (a.isDefault) ...[
                const SizedBox(width: 8),
                const Icon(Icons.circle, size: 6, color: AppColors.goldDeep),
              ],
            ]),
          ),
          if (a.isDefault) const TagBadge('Default delivery', tone: TagTone.peach),
        ]),
        const SizedBox(height: 6),
        Text('${a.fullName}${a.phone.isEmpty ? '' : '  ·  ${a.phone}'}', style: AppType.bodyMd(AppColors.inkSoft)),
        const SizedBox(height: 14),
        Text(a.addressLine, style: AppType.bodyLg(AppColors.ink)),
        Text(a.city, style: AppType.bodyMd(AppColors.inkSoft)),
        const SizedBox(height: 16),
        Row(children: [
          if (!a.isDefault)
            Expanded(
              flex: 3,
              child: InkButton('Set as default',
                  icon: Icons.star_border,
                  variant: InkVariant.surface,
                  height: 44,
                  onPressed: () => _guard(() => ApiService.instance.setDefaultAddress(a.id))),
            ),
          if (!a.isDefault) const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: InkButton('Edit', variant: a.isDefault ? InkVariant.filled : InkVariant.surface, height: 44, onPressed: () => _openForm(a)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: InkButton('', icon: Icons.delete_outline, variant: InkVariant.surface, height: 44, onPressed: () => _confirmDelete(a)),
          ),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ApiService.instance.isLoggedIn;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const AtelierAppBar(title: 'Delivery addresses'),
      body: !signedIn
          ? LarkEmptyState(
              icon: Icons.place_outlined,
              title: 'Sign in to manage addresses',
              message: 'Save where you like to receive your orders.',
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Row(children: [
                              const Icon(Icons.verified_user_outlined, size: 14),
                              const SizedBox(width: 6),
                              Text('ADDRESS BOOK', style: AppType.labelBadge(AppColors.inkSoft)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                color: AppColors.surface,
                                child: Text('${_items.length} SAVED', style: AppType.labelBadge(AppColors.ink).copyWith(fontSize: 9)),
                              ),
                            ]),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                            child: Eyebrow('Where we deliver'),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                            child: Text('Your Addresses', style: AppType.headlineLg(AppColors.ink)),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            child: Text('Choose a default and we will fill it in at checkout.',
                                style: AppType.bodyMd(AppColors.inkSoft)),
                          ),
                          if (_items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: LarkEmptyState(
                                  icon: Icons.place_outlined,
                                  title: 'No addresses yet',
                                  message: 'Add one to speed up checkout.'),
                            ),
                          for (final a in _items) _card(a),
                          Panel(
                            color: AppColors.surface,
                            onTap: () => _openForm(),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.add, size: 18),
                              const SizedBox(width: 8),
                              Text('ADD NEW ADDRESS', style: AppType.labelCaps(AppColors.ink).copyWith(fontSize: 10.5)),
                            ]),
                          ),
                          Panel(
                            color: AppColors.ink,
                            padding: const EdgeInsets.all(20),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.goldOnDark),
                                const SizedBox(width: 8),
                                Text('DELIVERY', style: AppType.labelBadge(AppColors.goldOnDark)),
                              ]),
                              const SizedBox(height: 10),
                              Text(
                                  'Delivery is KSh ${formatNumber(StoreRules.deliveryFee)}, and free on orders above '
                                  'KSh ${formatNumber(StoreRules.freeDeliveryThreshold)}.',
                                  style: AppType.bodyMd(Colors.white)),
                            ]),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _AddressForm extends StatefulWidget {
  final SavedAddress? existing;
  final bool first;
  const _AddressForm({this.existing, required this.first});

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _line;
  late final TextEditingController _city;
  late String _label;
  late bool _default;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.fullName ?? ApiService.instance.cachedProfile?.displayName ?? '');
    _phone = TextEditingController(text: e?.phone ?? ApiService.instance.cachedProfile?.phone ?? '');
    _line = TextEditingController(text: e?.addressLine ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _label = e?.label ?? 'home';
    _default = e?.isDefault ?? widget.first;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _line, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if ([_name, _phone, _line, _city].any((c) => c.text.trim().isEmpty)) {
      setState(() => _error = 'Please fill in every field.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService.instance.saveAddress(
        id: widget.existing?.id,
        label: _label,
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        addressLine: _line.text.trim(),
        city: _city.text.trim(),
        isDefault: _default,
      );
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(widget.existing == null ? 'New address' : 'Edit address',
                  style: AppType.headlineMd(AppColors.ink)),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 12),
          const FieldLabel('Label'),
          Row(children: [
            for (final l in const ['home', 'work', 'other'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PillChip(l, selected: _label == l, onTap: () => setState(() => _label = l)),
              ),
          ]),
          const SizedBox(height: 18),
          LabeledField(label: 'Full name', controller: _name, capitalization: TextCapitalization.words),
          LabeledField(label: 'Phone', controller: _phone, keyboardType: TextInputType.phone),
          LabeledField(label: 'Address', controller: _line, hint: 'Street, building, apartment'),
          LabeledField(label: 'City / town', controller: _city, capitalization: TextCapitalization.words),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.ink,
            title: Text('Use as default delivery address', style: AppType.bodyMd(AppColors.ink)),
            value: _default,
            onChanged: (v) => setState(() => _default = v),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: AppType.bodySm(AppColors.error))),
          InkButton('Save address', loading: _saving, onPressed: _save),
        ]),
      ),
    );
  }
}
