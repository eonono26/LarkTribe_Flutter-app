import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'product_list_screen.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  late Future<List<Brand>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.brands();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const AtelierAppBar(title: 'Brand index'),
      body: FutureBuilder<List<Brand>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LarkLoading();
          if (snap.hasError) {
            return LarkErrorState(onRetry: () => setState(() => _future = ApiService.instance.brands()));
          }
          final brands = snap.data ?? [];
          if (brands.isEmpty) {
            return const LarkEmptyState(
                icon: Icons.sell_outlined, title: 'No brands yet', message: 'Check back soon.');
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: SectionHeading(
                    eyebrow: 'The makers', title: 'Brands', padding: EdgeInsets.zero),
              ),
              for (final b in brands)
                InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProductListScreen(
                              title: b.name, eyebrow: 'Brand', brandSlug: b.slug))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.hairline))),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        color: Colors.white,
                        child: (b.logoUrl != null && b.logoUrl!.isNotEmpty)
                            ? NetImage(b.logoUrl, fit: BoxFit.contain)
                            : Center(
                                child: Text(b.name.isEmpty ? '?' : b.name[0].toUpperCase(),
                                    style: AppType.headlineMd(AppColors.ink))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(b.name, style: AppType.headlineSm(AppColors.ink)),
                          const SizedBox(height: 2),
                          Text('${b.productCount} pieces', style: AppType.bodySm(AppColors.subtext)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.subtext),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
