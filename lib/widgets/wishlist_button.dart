import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/wishlist_provider.dart';
import '../theme/app_theme.dart';
import 'auth_gate.dart';
import 'common.dart';

/// White circular heart used on every product tile (top-right of the image).
class WishlistButton extends StatefulWidget {
  final int productId;
  final double size;
  const WishlistButton({super.key, required this.productId, this.size = 34});

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton> {
  bool _busy = false;

  Future<void> _tap() async {
    if (_busy) return;
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final added = await context.read<WishlistProvider>().toggle(widget.productId);
      if (added) ApiService.instance.track('wishlist_add', extra: {'product': widget.productId});
      if (mounted) toast(context, added ? 'Saved to your lookbook' : 'Removed from your lookbook');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.select<WishlistProvider, bool>((w) => w.contains(widget.productId));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: Colors.white.withOpacity(.92), shape: BoxShape.circle),
        child: Icon(
          saved ? Icons.favorite : Icons.favorite_border,
          size: widget.size * .5,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
