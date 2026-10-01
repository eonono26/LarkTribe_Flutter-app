import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';
import '../services/wishlist_provider.dart';

/// Re-sync everything that depends on who is signed in.
Future<void> refreshSessionData(BuildContext context) async {
  final cart = context.read<CartProvider>();
  final wish = context.read<WishlistProvider>();
  await ApiService.instance.me();
  await Future.wait([cart.refresh(), wish.refresh()]);
}

/// Returns true when the person is (or just became) signed in.
Future<bool> ensureSignedIn(BuildContext context) async {
  if (ApiService.instance.isLoggedIn) return true;
  final ok = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  if (ok == true && context.mounted) {
    await refreshSessionData(context);
    return true;
  }
  return false;
}
