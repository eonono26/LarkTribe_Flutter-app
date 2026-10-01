import 'package:flutter/material.dart';
import 'section_page.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = [
    InfoSection(
      '1. Information we collect',
      'We collect account details (name, email, phone), order and delivery information, and shopping behavior such '
          'as views, searches, clicks, wishlist activity, cart actions, and device/browser info — used to power '
          'search, recommendations, and analytics.',
    ),
    InfoSection(
      '2. How we use your data',
      'Your data helps us personalize product recommendations, improve search, prevent fraud, process orders and '
          'payments, send order and promotional notifications (which you can manage in Notification preferences), '
          'and generate aggregate business insights.',
    ),
    InfoSection(
      '3. Sharing with vendors & partners',
      "Vendors receive the order and shipping details needed to fulfill your purchase. Payment processors (M-Pesa, "
          "card gateways) receive what's required to complete transactions. We don't sell your personal data to "
          "third parties.",
    ),
    InfoSection(
      '4. Location data',
      "With your consent, we use your delivery location to estimate shipping times and suggest nearby availability. "
          "You can update or clear your saved location at any time from the app's location picker.",
    ),
    InfoSection(
      '5. Your choices',
      'You can review and update your profile from My account, manage notification channels from Notifications '
          'settings, and request account data deletion by contacting support.',
    ),
    InfoSection(
      '6. Data security',
      'We use industry-standard encryption in transit and restrict access to personal data on a need-to-know '
          'basis. No online platform can guarantee absolute security, so please use a strong, unique password.',
    ),
    InfoSection(
      '7. Changes to this policy',
      "We'll update this page when our practices change materially. Significant changes will also be communicated "
          'via in-app notification.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const SectionPage(
      title: 'Privacy policy',
      subtitle: 'Last updated August 2026',
      sections: _sections,
    );
  }
}
