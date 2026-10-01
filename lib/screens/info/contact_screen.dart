import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _status = 'idle'; // idle | sending | sent | error

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _status = 'sending');
    try {
      if (ApiService.instance.isLoggedIn) {
        await ApiService.instance.openSupportTicket(
          'Contact form — ${_nameCtrl.text.trim().isEmpty ? "App visitor" : _nameCtrl.text.trim()}',
          '${_messageCtrl.text.trim()}\n\nReply-to: ${_emailCtrl.text.trim()}',
        );
      }
      setState(() {
        _status = 'sent';
        _nameCtrl.clear();
        _emailCtrl.clear();
        _messageCtrl.clear();
      });
    } catch (_) {
      setState(() => _status = 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ApiService.instance.isLoggedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Contact us')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Have a question about an order, a vendor, or the platform? Send us a message and we'll get back to you.",
            style: TextStyle(color: AppColors.subtext, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Your name')),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email address'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _messageCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(hintText: 'How can we help?'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Tell us how we can help' : null,
                ),
                const SizedBox(height: 12),
                if (_status == 'sent')
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text("Thanks — we've got your message.", style: TextStyle(color: AppColors.success)),
                  ),
                if (_status == 'error')
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text('Something went wrong, please try again.', style: TextStyle(color: AppColors.flag)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _status == 'sending' ? null : _submit,
                    child: Text(_status == 'sending' ? 'Sending…' : 'Send message'),
                  ),
                ),
                if (!loggedIn)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Log in to track replies from My account → Help & Support.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.subtext),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const _ContactRow(icon: Icons.mail_outline_rounded, label: 'Email', value: 'support@larktribe.co.ke'),
          const SizedBox(height: 14),
          const _ContactRow(icon: Icons.phone_outlined, label: 'Phone', value: '+254 700 000 000'),
          const SizedBox(height: 14),
          const _ContactRow(icon: Icons.location_on_outlined, label: 'Office', value: 'Nairobi, Kenya'),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.ink),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(value, style: const TextStyle(color: AppColors.subtext, fontSize: 12.5)),
          ],
        ),
      ],
    );
  }
}
