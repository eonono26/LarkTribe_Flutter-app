import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/form_bits.dart';
import 'info/contact_screen.dart';
import 'register_screen.dart';

/// Sign in (Stitch screen 06). Pops `true` when the person is signed in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _tab = 0; // 0 member (username/password) · 1 phone code
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _hide = true;
  bool _loading = false;
  bool _codeSent = false;
  String? _error;
  String? _debugCode;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Enter your username and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await ApiService.instance.loginWithMessage(_user.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = err);
    }
  }

  Future<void> _sendCode() async {
    if (_phone.text.trim().isEmpty) {
      setState(() => _error = 'Enter your phone number.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final debug = await ApiService.instance.requestPhoneOTP(_phone.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (debug == null) {
        _error = "We couldn't send a code to that number.";
      } else {
        _codeSent = true;
        _debugCode = debug.isEmpty ? null : debug;
      }
    });
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await ApiService.instance.verifyPhoneOTP(_phone.text.trim(), _code.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = 'That code is not right. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const AtelierAppBar(title: 'Sign in', showAvatar: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 40),
        children: [
          Row(children: [
            const Expanded(child: Eyebrow('Authentication — member account')),
            const Icon(Icons.lock_outline, size: 14, color: AppColors.inkSoft),
            const SizedBox(width: 4),
            Text('SECURE', style: AppType.labelBadge(AppColors.inkSoft)),
          ]),
          const SizedBox(height: 14),
          Text('Welcome Back', style: AppType.display(AppColors.ink)),
          const SizedBox(height: 10),
          Text('Sign in to see your orders, your lookbook and your member savings.',
              style: AppType.bodyLg(AppColors.inkSoft)),
          const SizedBox(height: 28),
          SegmentTrack(
            labels: const ['Member', 'Phone code'],
            index: _tab,
            onChanged: (i) => setState(() {
              _tab = i;
              _error = null;
            }),
          ),
          const SizedBox(height: 24),
          if (_tab == 0) ...[
            LabeledField(
              label: 'Username',
              controller: _user,
              hint: 'your username',
              autofillHints: const [AutofillHints.username],
            ),
            LabeledField(
              label: 'Password',
              controller: _pass,
              hint: '••••••••••',
              obscure: _hide,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _signIn(),
              suffix: IconButton(
                icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
          ] else ...[
            LabeledField(
              label: 'Phone number',
              controller: _phone,
              hint: '07XX XXX XXX',
              keyboardType: TextInputType.phone,
            ),
            if (_codeSent)
              LabeledField(
                label: 'Verification code',
                controller: _code,
                hint: '6-digit code',
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _verify(),
              ),
            if (_codeSent && _debugCode != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text('Dev code: $_debugCode', style: AppType.bodySm(AppColors.goldDeep)),
              ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(_error!, style: AppType.bodySm(AppColors.error)),
            ),
          InkButton(
            _tab == 0 ? 'Sign in' : (_codeSent ? 'Verify & enter' : 'Send code'),
            trailingIcon: Icons.arrow_forward,
            loading: _loading,
            onPressed: _tab == 0 ? _signIn : (_codeSent ? _verify : _sendCode),
          ),
          const SizedBox(height: 32),
          Panel(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Eyebrow('New here?')),
                const Icon(Icons.vpn_key_outlined, size: 18, color: AppColors.goldDeep),
              ]),
              const SizedBox(height: 10),
              Text('Join LarkTribe', style: AppType.headlineMd(AppColors.ink)),
              const SizedBox(height: 6),
              Text('Create an account to save 5% on every order and keep a private lookbook.',
                  style: AppType.bodyMd(AppColors.inkSoft)),
              const SizedBox(height: 16),
              InkButton('Create account', variant: InkVariant.surface, height: 46, onPressed: () async {
                final ok = await Navigator.push<bool>(
                    context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                if (ok == true && mounted) Navigator.pop(context, true);
              }),
            ]),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(children: [
              Container(width: 40, height: 1, color: AppColors.line),
              const SizedBox(height: 14),
              Text('NEED ASSISTANCE?', style: AppType.labelBadge(AppColors.inkSoft)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const ContactScreen())),
                child: Text('CONTACT SUPPORT',
                    style: AppType.labelCaps(AppColors.ink)
                        .copyWith(decoration: TextDecoration.underline, fontSize: 10.5)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
