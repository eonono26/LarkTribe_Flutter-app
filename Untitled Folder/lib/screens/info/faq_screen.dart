import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'contact_screen.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _faqs = [
    (
      q: 'How do I track my order?',
      a: "Go to My account → Orders to see live status updates as your vendor prepares, ships, and delivers your items.",
    ),
    (
      q: 'What payment methods do you accept?',
      a: 'We accept M-Pesa, major credit and debit cards, and cash on delivery in eligible areas. You can also apply '
          'a coupon code at checkout for extra savings.',
    ),
    (
      q: 'How do returns and refunds work?',
      a: 'Most items can be returned within 7 days of delivery if unused and in original packaging. Open a return '
          'request from My account → Orders, or visit our Returns & refunds page for full details.',
    ),
    (
      q: 'How long does delivery take?',
      a: 'Delivery times vary by vendor and location, but most orders within Nairobi arrive in 1–3 business days. '
          'Upcountry deliveries typically take 3–5 business days.',
    ),
    (
      q: 'Can I become a vendor on Lark Tribe?',
      a: "Yes! Head to the 'Sell on Lark Tribe' page to apply. Once approved, you'll get access to a full vendor "
          'dashboard with inventory, order, and AI sales insight tools.',
    ),
    (
      q: 'Is my payment information safe?',
      a: "Yes. We never store your full card details on our servers — payments are processed through secure, "
          "PCI-compliant providers and M-Pesa's Daraja API.",
    ),
    (
      q: 'How do I contact customer support?',
      a: 'Log in and go to My account → Help & Support to open a ticket, or use the Contact us page. Our team '
          'typically responds within one business day.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frequently asked questions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text('Answers to the things shoppers ask us most.', style: TextStyle(color: AppColors.subtext, fontSize: 13)),
          ),
          ..._faqs.map((f) => Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(f.q, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  expandedAlignment: Alignment.topLeft,
                  children: [
                    Text(f.a, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.subtext)),
                  ],
                ),
              )),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen())),
              child: const Align(alignment: Alignment.centerLeft, child: Text('Still stuck? Contact us →')),
            ),
          ),
        ],
      ),
    );
  }
}
