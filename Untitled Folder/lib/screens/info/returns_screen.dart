import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import 'section_page.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  bool _submitting = false;

  static const _sections = [
    InfoSection(
      'Eligibility window',
      "Most items purchased on Lark Tribe can be returned within 7 days of delivery, provided they're unused, "
          'unworn, and in their original packaging with tags attached. Perishables, personal care, and intimate '
          'apparel are final sale unless the item arrived damaged or defective.',
    ),
    InfoSection(
      'How to start a return',
      '1. Go to My account → Orders and find the order.\n'
          '2. Open a support ticket referencing the order number and reason for return.\n'
          '3. Our team or the vendor will confirm pickup or drop-off instructions.\n'
          '4. Once the item is received and inspected, your refund is processed to your original payment method.',
    ),
    InfoSection(
      'Refund timing',
      'M-Pesa refunds typically land within 1–2 business days of approval. Card refunds can take 5–10 business '
          'days depending on your bank. Cash on delivery orders are refunded via M-Pesa to the number on file.',
    ),
    InfoSection(
      'Damaged or wrong items',
      'If an item arrives damaged, defective, or different from what you ordered, contact us within 48 hours of '
          "delivery with photos — we'll prioritize a replacement or full refund, including return shipping.",
    ),
  ];

  Future<void> _startReturn() async {
    if (!ApiService.instance.isLoggedIn) {
      final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (ok != true) return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.instance.openSupportTicket(
        'Return request',
        "I'd like to start a return. Order number: \nReason: ",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support ticket opened — our team will follow up shortly.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong, please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'Returns & refunds',
      subtitle: 'Last updated August 2026',
      sections: _sections,
      footer: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(AppRadii.md)),
        child: Row(
          children: [
            const Expanded(child: Text('Ready to start a return?', style: TextStyle(fontWeight: FontWeight.w700))),
            ElevatedButton(
              onPressed: _submitting ? null : _startReturn,
              child: Text(_submitting ? 'Opening…' : 'Open a return request'),
            ),
          ],
        ),
      ),
    );
  }
}
