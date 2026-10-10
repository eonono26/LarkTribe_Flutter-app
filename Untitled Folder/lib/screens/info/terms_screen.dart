import 'package:flutter/material.dart';
import 'section_page.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    InfoSection(
      '1. Using Lark Tribe',
      'Lark Tribe is a marketplace connecting shoppers with independent vendors. By creating an account or placing '
          'an order, you agree to use the platform lawfully and provide accurate information at checkout.',
    ),
    InfoSection(
      '2. Vendors & listings',
      'Vendors are independent sellers responsible for the accuracy of their listings, product quality, and '
          'fulfillment. Lark Tribe moderates listings and can suspend vendors who violate our policies, but '
          'individual sale contracts are between buyer and vendor.',
    ),
    InfoSection(
      '3. Orders & payments',
      'Prices are shown in Kenyan Shillings and include applicable taxes unless stated otherwise. Payments are '
          'processed via M-Pesa, card, or cash on delivery where available. Orders are confirmed once payment is '
          'authorized.',
    ),
    InfoSection(
      '4. Returns, refunds & cancellations',
      'See our Returns & refunds page for the current policy. Some items are final sale as noted on the product '
          'page.',
    ),
    InfoSection(
      '5. Account responsibilities',
      "You're responsible for keeping your login credentials secure and for activity that happens under your "
          'account. Notify us immediately if you suspect unauthorized use.',
    ),
    InfoSection(
      '6. Prohibited use',
      'You may not use Lark Tribe to sell counterfeit goods, engage in fraud, scrape the platform, or violate the '
          'rights of vendors, shoppers, or other third parties.',
    ),
    InfoSection(
      '7. Changes to these terms',
      'We may update these terms from time to time. Continued use of Lark Tribe after changes take effect means '
          'you accept the updated terms.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const SectionPage(
      title: 'Terms of service',
      subtitle: 'Last updated August 2026',
      sections: _sections,
    );
  }
}
