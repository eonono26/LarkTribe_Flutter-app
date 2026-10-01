import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

String orderStatusLabel(String status) {
  switch (status) {
    case 'pending_payment':
      return 'Awaiting payment';
    case 'paid':
      return 'Payment received';
    case 'processing':
      return 'Being prepared';
    case 'shipped':
      return 'On its way';
    case 'delivered':
      return 'Delivered';
    case 'cancelled':
      return 'Cancelled';
    case 'refunded':
      return 'Refunded';
    default:
      return status.replaceAll('_', ' ');
  }
}

/// 0–4 filled segments for the progress bar.
int orderStage(String status) {
  switch (status) {
    case 'pending_payment':
    case 'paid':
      return 1;
    case 'processing':
      return 2;
    case 'shipped':
      return 3;
    case 'delivered':
      return 4;
    default:
      return 0;
  }
}

String paymentLabel(String method) {
  switch (method) {
    case 'mpesa':
      return 'M-Pesa';
    case 'card':
      return 'Card';
    case 'cod':
      return 'Cash on delivery';
    default:
      return method;
  }
}

String deliveryStatusLabel(String status) {
  switch (status) {
    case 'unassigned':
      return 'Awaiting courier';
    case 'assigned':
      return 'Courier assigned';
    case 'picked_up':
      return 'Picked up';
    case 'en_route':
      return 'On the way';
    case 'delivered':
      return 'Delivered';
    case 'cancelled':
      return 'Cancelled';
    case 'failed':
      return 'Delivery failed';
    default:
      return status.replaceAll('_', ' ');
  }
}

/// Four-segment progress bar with captions (Placed · Packing · On the way · Delivered).
class OrderProgressBar extends StatelessWidget {
  final String status;
  const OrderProgressBar({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final filled = orderStage(status);
    const labels = ['PLACED', 'PACKING', 'ON THE WAY', 'DELIVERED'];
    return Column(children: [
      Row(children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(child: Container(height: 3, color: i < filled ? AppColors.ink : AppColors.surfaceHigh)),
          if (i < 3) const SizedBox(width: 4),
        ],
      ]),
      const SizedBox(height: 8),
      Row(children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Text(labels[i],
                textAlign: i == 0 ? TextAlign.left : (i == 3 ? TextAlign.right : TextAlign.center),
                style: AppType.labelBadge(i < filled ? AppColors.ink : AppColors.subtext)
                    .copyWith(fontSize: 8.5, letterSpacing: .8)),
          ),
      ]),
    ]);
  }
}

double? distanceKm(double? lat1, double? lng1, double? lat2, double? lng2) {
  if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) return null;
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a.toDouble()));
}

/// Draws pickup → courier → drop-off on a neutral canvas. There is no map
/// SDK in the app, so positions are normalised into the panel.
class RoutePanel extends StatelessWidget {
  final DeliveryTracking? tracking;
  final double height;
  const RoutePanel({super.key, required this.tracking, this.height = 190});

  @override
  Widget build(BuildContext context) {
    final t = tracking;
    final hasPoints = t != null &&
        ((t.driver?.lat != null && t.driver?.lng != null) ||
            (t.dropoffLat != null && t.dropoffLng != null));
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEDEDED), Color(0xFFD9D9D9)],
        ),
      ),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        if (hasPoints)
          Positioned.fill(child: CustomPaint(painter: _RoutePainter(t!)))
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text('Live location appears here once a courier is on the way.',
                  textAlign: TextAlign.center, style: AppType.bodySm(AppColors.inkSoft)),
            ),
          ),
        if (t != null && t.isLive)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: Colors.white.withOpacity(.92),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.live, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('LIVE LOCATION', style: AppType.labelBadge(AppColors.ink).copyWith(fontSize: 9)),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(.45)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  final DeliveryTracking t;
  _RoutePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final pts = <String, (double, double)>{};
    if (t.pickupLat != null && t.pickupLng != null) pts['pickup'] = (t.pickupLat!, t.pickupLng!);
    if (t.driver?.lat != null && t.driver?.lng != null) pts['driver'] = (t.driver!.lat!, t.driver!.lng!);
    if (t.dropoffLat != null && t.dropoffLng != null) pts['drop'] = (t.dropoffLat!, t.dropoffLng!);
    if (pts.isEmpty) return;

    final lats = pts.values.map((e) => e.$1).toList();
    final lngs = pts.values.map((e) => e.$2).toList();
    var minLat = lats.reduce(math.min), maxLat = lats.reduce(math.max);
    var minLng = lngs.reduce(math.min), maxLng = lngs.reduce(math.max);
    if ((maxLat - minLat).abs() < 1e-5) {
      minLat -= .005;
      maxLat += .005;
    }
    if ((maxLng - minLng).abs() < 1e-5) {
      minLng -= .005;
      maxLng += .005;
    }
    const pad = 44.0;
    Offset map((double, double) p) => Offset(
          pad + (p.$2 - minLng) / (maxLng - minLng) * (size.width - pad * 2),
          pad + (1 - (p.$1 - minLat) / (maxLat - minLat)) * (size.height - pad * 2),
        );

    final order = ['pickup', 'driver', 'drop'].where(pts.containsKey).toList();
    final line = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < order.length - 1; i++) {
      final a = map(pts[order[i]]!);
      final b = map(pts[order[i + 1]]!);
      final dist = (b - a).distance;
      if (dist == 0) continue;
      final dir = (b - a) / dist;
      var d = 0.0;
      while (d < dist) {
        canvas.drawLine(a + dir * d, a + dir * math.min(d + 7, dist), line);
        d += 12;
      }
    }

    if (pts.containsKey('pickup')) {
      final o = map(pts['pickup']!);
      canvas.drawRect(Rect.fromCenter(center: o, width: 10, height: 10), Paint()..color = AppColors.ink);
    }
    if (pts.containsKey('drop')) {
      final o = map(pts['drop']!);
      canvas.drawCircle(o, 11, Paint()..color = Colors.white);
      canvas.drawCircle(o, 11, Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
      canvas.drawCircle(o, 4, Paint()..color = AppColors.ink);
    }
    if (pts.containsKey('driver')) {
      final o = map(pts['driver']!);
      canvas.drawCircle(o, 16, Paint()..color = AppColors.ink.withOpacity(.18));
      canvas.drawCircle(o, 11, Paint()..color = AppColors.ink);
      canvas.drawCircle(o, 4, Paint()..color = AppColors.gold);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.t != t;
}
