import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/form_bits.dart';

/// Create account. Pops `true` once registered and signed in.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _user = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_first, _last, _user, _email, _phone, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_user.text.trim().isEmpty || _email.text.trim().isEmpty || _pass.text.length < 6) {
      setState(() => _error = 'Username, email and a password of at least 6 characters are required.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await ApiService.instance.register(
      username: _user.text.trim(),
      email: _email.text.trim(),
      password: _pass.text,
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      phone: _phone.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const AtelierAppBar(title: 'Create account', showAvatar: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 40),
        children: [
          const Eyebrow('Membership'),
          const SizedBox(height: 14),
          Text('Join LarkTribe', style: AppType.display(AppColors.ink)),
          const SizedBox(height: 10),
          Text('Members save 5% on every order and can track deliveries live.',
              style: AppType.bodyLg(AppColors.inkSoft)),
          const SizedBox(height: 28),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: LabeledField(label: 'First name', controller: _first, capitalization: TextCapitalization.words)),
            const SizedBox(width: 12),
            Expanded(child: LabeledField(label: 'Last name', controller: _last, capitalization: TextCapitalization.words)),
          ]),
          LabeledField(label: 'Username', controller: _user),
          LabeledField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress),
          LabeledField(label: 'Phone (optional)', controller: _phone, keyboardType: TextInputType.phone, hint: '07XX XXX XXX'),
          LabeledField(
            label: 'Password',
            controller: _pass,
            obscure: _hide,
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              onPressed: () => setState(() => _hide = !_hide),
            ),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(_error!, style: AppType.bodySm(AppColors.error))),
          InkButton('Create account', trailingIcon: Icons.arrow_forward, loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
