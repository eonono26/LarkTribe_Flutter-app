import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/order_detail_screen.dart';

/// Resolves the same internal paths the web storefront uses
/// (/product/:slug, /category/:slug, /categories/:slug, /brand/:id, /deals)
/// to native screens, and falls back to an external browser for anything
/// else (e.g. a full https:// URL).
Future<void> openLink(BuildContext context, String? link) async {
  if (link == null || link.isEmpty || link == '#' || link == '/') return;

  final path = link.startsWith('http') ? Uri.parse(link).path : link;
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();

  if (segments.isEmpty) return;

  if (segments[0] == 'product' && segments.length > 1) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: segments[1])));
    return;
  }
  if (segments[0] == 'category' && segments.length > 1) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListScreen(title: segments[1], departmentSlug: segments[1])));
    return;
  }
  if (segments[0] == 'categories' && segments.length > 1) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListScreen(title: segments[1], categorySlug: segments[1])));
    return;
  }
  if (segments[0] == 'brand' && segments.length > 1) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListScreen(title: 'Brand', brandSlug: segments[1])));
    return;
  }
  if (segments[0] == 'deals') {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen(title: 'Deals', ordering: '-discount_percentage', onSale: true)));
    return;
  }
  if ((segments[0] == 'orders' || segments[0] == 'order') && segments.length > 1) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderNumber: segments[1])));
    return;
  }

  if (link.startsWith('http')) {
    final uri = Uri.tryParse(link);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
