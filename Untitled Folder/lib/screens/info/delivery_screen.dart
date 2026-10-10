import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'section_page.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  static const _zones = [
    (area: 'Nairobi (within the city)', time: '1–2 business days', fee: 'From KSh 200'),
    (area: 'Nairobi metro (Kiambu, Machakos, Kajiado)', time: '2–3 business days', fee: 'From KSh 300'),
    (area: 'Major towns (Mombasa, Kisumu, Nakuru, Eldoret)', time: '3–5 business days', fee: 'From KSh 400'),
    (area: 'Rest of Kenya', time: '4–7 business days', fee: 'From KSh 500'),
  ];

  static const _sections = [
    InfoSection(
      'Order tracking',
      "Once a vendor ships your order, you'll get a notification and can follow progress from "
          'My account → Orders.',
    ),
    InfoSection(
      'Multiple vendors, one cart',
      'If your order includes items from more than one vendor, they may arrive in separate packages on '
          'different days — each shipment can be tracked individually.',
    ),
    InfoSection(
      'Cash on delivery',
      'Available for eligible orders and locations — have the exact amount ready for the courier at drop-off.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'Delivery information',
      subtitle: 'Delivery is handled by individual vendors and partner couriers, so exact times can vary by item.',
      sections: _sections,
      header: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(AppRadii.md)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final z in _zones)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.line, width: z == _zones.last ? 0 : 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(z.area, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${z.time} · ${z.fee}', style: const TextStyle(fontSize: 12, color: AppColors.subtext)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
