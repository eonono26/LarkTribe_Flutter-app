import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../theme/app_theme.dart';
import 'section_page.dart';
import 'contact_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'About Lark Tribe',
      subtitle: 'Built in Nairobi, for Kenya.',
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Lark Tribe is a multi-vendor marketplace bringing together independent sellers across Women's fashion, "
            "Kids & Baby, Beauty, Maternity, and Home & Lifestyle into one place to shop. We built it because Kenyan "
            "shoppers deserve a discovery experience as good as anywhere else in the world — fast search, smart "
            "recommendations, and checkout that just works with M-Pesa.",
            style: TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF3A3A38)),
          ),
          const SizedBox(height: 14),
          const Text(
            'Every product on Lark Tribe is listed and fulfilled by an independent vendor. We handle the platform, '
            'payments, and delivery coordination so vendors can focus on what they do best — and shoppers get a wide, '
            'curated selection with buyer protection built in.',
            style: TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF3A3A38)),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              _StatCard(value: '100+', label: 'Vendors onboarded'),
              SizedBox(width: 10),
              _StatCard(value: '6', label: 'Product departments'),
              SizedBox(width: 10),
              _StatCard(value: 'Nairobi', label: 'Headquartered'),
            ],
          ),
          const SizedBox(height: 18),
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF3A3A38)),
            children: [
              const TextSpan(text: 'Have a question, partnership idea, or feedback? Visit our '),
              TextSpan(
                text: 'Contact page',
                style: const TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen())),
              ),
              const TextSpan(text: " — we'd love to hear from you."),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(AppRadii.md)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.subtext)),
          ],
        ),
      ),
    );
  }
}
