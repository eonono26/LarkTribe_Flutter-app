import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../orders_screen.dart';
import '../account_screen.dart';
import 'delivery_screen.dart';
import 'faq_screen.dart';
import 'returns_screen.dart';
import 'contact_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = <_Topic>[
      _Topic(Icons.local_shipping_outlined, 'Track my order', "See live status on any order you've placed.", () async {
        if (!ApiService.instance.isLoggedIn) {
          final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          if (ok != true) return;
        }
        if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
      }),
      _Topic(Icons.replay_rounded, 'Returns & refunds', 'Our policy and how to start a return.',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReturnsScreen()))),
      _Topic(Icons.local_shipping_rounded, 'Delivery info', 'Delivery times, areas, and fees.',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryScreen()))),
      _Topic(Icons.help_outline_rounded, 'FAQs', 'Quick answers to common questions.',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen()))),
      _Topic(Icons.support_agent_rounded, 'Contact support', 'Open a ticket and chat with our team.',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen()))),
      _Topic(Icons.verified_user_outlined, 'Account & security', 'Manage your profile and login details.',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()))),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Help center')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: topics.length,
        itemBuilder: (context, i) {
          final t = topics[i];
          return InkWell(
            borderRadius: BorderRadius.zero,
            onTap: t.onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.zero),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(t.icon, size: 24, color: AppColors.ink),
                  const SizedBox(height: 10),
                  Text(t.title, style: AppType.bodyMd(AppColors.ink).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(t.desc, style: const TextStyle(fontSize: 11.5, color: AppColors.subtext)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Topic {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;
  _Topic(this.icon, this.title, this.desc, this.onTap);
}
