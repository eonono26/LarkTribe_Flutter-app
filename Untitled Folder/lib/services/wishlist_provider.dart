import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Single source of truth for the signed-in customer's wishlist, so every
/// heart button in the app shares one request instead of fetching the whole
/// list per tile.
class WishlistProvider extends ChangeNotifier {
  List<WishlistItem> _items = [];
  final Map<int, int> _itemIdByProduct = {};
  bool _loaded = false;

  List<WishlistItem> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get loaded => _loaded;
  bool contains(int productId) => _itemIdByProduct.containsKey(productId);

  Future<void> refresh() async {
    if (!ApiService.instance.isLoggedIn) {
      _items = [];
      _itemIdByProduct.clear();
      _loaded = true;
      notifyListeners();
      return;
    }
    try {
      _items = await ApiService.instance.wishlist();
      _itemIdByProduct
        ..clear()
        ..addEntries(_items.map((w) => MapEntry(w.product.id, w.id)));
    } catch (_) {
      // keep previous state when offline
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  void clear() {
    _items = [];
    _itemIdByProduct.clear();
    notifyListeners();
  }

  /// Adds or removes. Caller must ensure the user is signed in.
  Future<bool> toggle(int productId) async {
    final existing = _itemIdByProduct[productId];
    if (existing != null) {
      await ApiService.instance.removeFromWishlist(existing);
      _itemIdByProduct.remove(productId);
      _items.removeWhere((w) => w.id == existing);
      notifyListeners();
      return false;
    }
    final item = await ApiService.instance.addToWishlist(productId);
    _itemIdByProduct[productId] = item.id;
    _items.insert(0, item);
    notifyListeners();
    return true;
  }
}
