import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';

/// API base URL.
///
/// Override for a deployed backend:
/// flutter run --dart-define=API_BASE_URL=https://your-domain.com/api
///
/// Android Emulator cannot reach the host machine through 127.0.0.1,
/// so the local Android default uses 10.0.2.2.
String get _resolvedBaseUrl {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return configured.replaceFirst(RegExp(r'/$'), '');
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/api';
  }
  return 'http://127.0.0.1:8000/api';
}

/// Backend delivery rules (orders/views.py) — mirrored so the bag and
/// checkout show the same totals the server will charge.
class StoreRules {
  static const freeDeliveryThreshold = 5000.0;
  static const deliveryFee = 250.0;
  static const memberDiscountRate = 0.05;

  /// Backend: `shipping_fee = 0 if subtotal > 5000 else 250`.
  static double shippingFor(double subtotal) =>
      subtotal > freeDeliveryThreshold ? 0 : deliveryFee;
}

/// Order maths exactly as orders/views.py does it:
/// total = subtotal − coupon − member(5% of subtotal) + shipping.
class CartTotals {
  final double subtotal;
  final double shipping;
  final double member;
  final double coupon;
  final double total;

  const CartTotals._(this.subtotal, this.shipping, this.member, this.coupon, this.total);

  factory CartTotals.compute(double subtotal, {required bool member, double coupon = 0}) {
    final shipping = subtotal <= 0 ? 0.0 : StoreRules.shippingFor(subtotal);
    final m = member ? subtotal * StoreRules.memberDiscountRate : 0.0;
    final total = (subtotal - coupon - m + shipping).clamp(0, double.infinity).toDouble();
    return CartTotals._(subtotal, shipping, m, coupon, total);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

/// One page of a paginated list endpoint.
class Paged<T> {
  final List<T> items;
  final bool hasMore;
  final int count;
  const Paged(this.items, {this.hasMore = false, this.count = 0});
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final String baseUrl = _resolvedBaseUrl;
  String get apiBaseUrl => baseUrl;

  final _secureStorage = const FlutterSecureStorage();
  String? _sessionCookie; // guest cart session (Django sessionid)
  String? _accessToken; // member JWT
  bool _loaded = false;

  // ------------------------------------------------------------------
  // Transport
  // ------------------------------------------------------------------

  Future<void> _loadPersisted() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString('session_cookie');
    _accessToken = await _secureStorage.read(key: 'access_token');
    _loaded = true;
  }

  Future<void> _persistCookie(http.Response res) async {
    final setCookie = res.headers['set-cookie'];
    if (setCookie == null) return;
    final m = RegExp(r'sessionid=([^;,\s]+)').firstMatch(setCookie);
    if (m == null) return;
    final cookie = 'sessionid=${m.group(1)}';
    if (cookie == _sessionCookie) return;
    _sessionCookie = cookie;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_cookie', cookie);
  }

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    await _loadPersisted();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_sessionCookie != null) 'Cookie': _sessionCookie!,
      if (withAuth && _accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  Uri _u(String path, [Map<String, String>? query]) => Uri.parse('$baseUrl$path')
      .replace(queryParameters: (query == null || query.isEmpty) ? null : query);

  Future<http.Response> _raw(String method, Uri uri, Object? body, bool withAuth) async {
    final headers = await _headers(withAuth: withAuth);
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'POST':
        return http.post(uri, headers: headers, body: encoded ?? '{}');
      case 'PATCH':
        return http.patch(uri, headers: headers, body: encoded ?? '{}');
      case 'PUT':
        return http.put(uri, headers: headers, body: encoded ?? '{}');
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        return http.get(uri, headers: headers);
    }
  }

  /// Every request goes through here. An expired access token would make DRF
  /// reject even public endpoints with 401, so a 401 triggers one silent
  /// refresh; if that fails the session is dropped and the call is retried
  /// anonymously.
  Future<http.Response> _req(String method, String path,
      {Map<String, String>? query, Object? body}) async {
    final uri = _u(path, query);
    await _loadPersisted();
    var res = await _raw(method, uri, body, true);
    if (res.statusCode == 401 && _accessToken != null) {
      if (await _refreshAccessToken()) {
        res = await _raw(method, uri, body, true);
      } else {
        await _clearSession();
        res = await _raw(method, uri, body, false);
      }
    }
    await _persistCookie(res);
    return res;
  }

  dynamic _decode(http.Response res) {
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  String _errorMessage(http.Response res, [String fallback = 'Something went wrong. Please try again.']) {
    final data = _decode(res);
    String? pick(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is List && v.isNotEmpty) return pick(v.first);
      if (v is Map && v.isNotEmpty) {
        if (v['detail'] != null) return pick(v['detail']);
        return pick(v.values.first);
      }
      return v.toString();
    }

    return pick(data) ?? fallback;
  }

  dynamic _ok(http.Response res, [String? fallback]) {
    if (res.statusCode >= 400) {
      throw ApiException(_errorMessage(res, fallback ?? 'Request failed (${res.statusCode}).'), res.statusCode);
    }
    return _decode(res);
  }

  List<dynamic> _list(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    return const [];
  }

  List<T> _mapList<T>(dynamic data, T Function(Map<String, dynamic>) f) => _list(data)
      .whereType<Map<String, dynamic>>()
      .map(f)
      .toList();

  Future<List<T>> _getList<T>(String path, T Function(Map<String, dynamic>) f,
      {Map<String, String>? query}) async {
    final res = await _req('GET', path, query: query);
    return _mapList(_ok(res), f);
  }

  String absoluteMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = baseUrl.replaceAll(RegExp(r'/api$'), '');
    return '$base$path';
  }

  // ------------------------------------------------------------------
  // Catalog
  // ------------------------------------------------------------------

  Future<List<Department>> departments() => _getList('/catalog/departments/', Department.fromJson);

  Future<List<Category>> categories({String? departmentSlug}) => _getList(
        '/catalog/categories/',
        Category.fromJson,
        query: {if (departmentSlug != null) 'department__slug': departmentSlug},
      );

  Future<List<Brand>> brands() => _getList('/catalog/brands/', Brand.fromJson);

  Future<List<AgeGroup>> ageGroups() =>
      _getList('/catalog/age-groups/', AgeGroup.fromJson, query: {'is_active': 'true'});

  /// Backend ordering fields: price, created_at, rating_avg, discount_percentage.
  static String? _fixOrdering(String? o) =>
      o?.replaceAllMapped(RegExp(r'discount_percent(?!age)'), (_) => 'discount_percentage');

  Map<String, String> _productQuery({
    String? departmentSlug,
    String? categorySlug,
    String? brandSlug,
    String? search,
    String? ordering,
    String? gender,
    String? ageGroupSlug,
    String? stage,
    String? size,
    String? priceRange,
    bool? isFeatured,
    bool? onSale,
    int page = 1,
  }) =>
      {
        if (departmentSlug != null) 'department': departmentSlug,
        if (categorySlug != null) 'category': categorySlug,
        if (brandSlug != null) 'brand': brandSlug,
        if (search != null && search.isNotEmpty) 'search': search,
        if (ordering != null) 'ordering': _fixOrdering(ordering)!,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
        if (ageGroupSlug != null) 'age_group': ageGroupSlug,
        if (stage != null) 'stage': stage,
        if (size != null && size.isNotEmpty) 'size': size,
        if (priceRange != null && priceRange.isNotEmpty) 'price_range': priceRange,
        if (isFeatured != null) 'is_featured': isFeatured.toString(),
        if (onSale != null) 'on_sale': onSale.toString(),
        if (page > 1) 'page': '$page',
      };

  Future<Paged<ProductListItem>> productsPage({
    String? departmentSlug,
    String? categorySlug,
    String? brandSlug,
    String? search,
    String? ordering,
    String? gender,
    String? ageGroupSlug,
    String? stage,
    String? size,
    String? priceRange,
    bool? isFeatured,
    bool? onSale,
    int page = 1,
  }) async {
    final res = await _req('GET', '/catalog/products/',
        query: _productQuery(
          departmentSlug: departmentSlug,
          categorySlug: categorySlug,
          brandSlug: brandSlug,
          search: search,
          ordering: ordering,
          gender: gender,
          ageGroupSlug: ageGroupSlug,
          stage: stage,
          size: size,
          priceRange: priceRange,
          isFeatured: isFeatured,
          onSale: onSale,
          page: page,
        ));
    final data = _ok(res);
    final items = _mapList(data, ProductListItem.fromJson);
    if (data is Map) {
      return Paged(items,
          hasMore: data['next'] != null, count: (data['count'] as num?)?.toInt() ?? items.length);
    }
    return Paged(items, count: items.length);
  }

  Future<List<ProductListItem>> products({
    String? departmentSlug,
    String? categorySlug,
    String? brandSlug,
    String? search,
    String? ordering,
    String? gender,
    String? ageGroupSlug,
    String? stage,
    bool? isFeatured,
    bool? onSale,
  }) async =>
      (await productsPage(
        departmentSlug: departmentSlug,
        categorySlug: categorySlug,
        brandSlug: brandSlug,
        search: search,
        ordering: ordering,
        gender: gender,
        ageGroupSlug: ageGroupSlug,
        stage: stage,
        isFeatured: isFeatured,
        onSale: onSale,
      ))
          .items;

  Future<ProductDetail> product(String slug) async {
    final res = await _req('GET', '/catalog/products/$slug/');
    return ProductDetail.fromJson(_ok(res) as Map<String, dynamic>);
  }

  Future<List<ProductListItem>> featuredProducts() =>
      products(ordering: '-created_at', isFeatured: true);
  Future<List<ProductListItem>> newArrivals() => products(ordering: '-created_at');
  Future<List<ProductListItem>> onSaleProducts() => products(ordering: '-created_at', onSale: true);
  Future<List<ProductListItem>> topRatedProducts() => products(ordering: '-rating_avg');

  Future<List<ProductListItem>> productsByAgeGroup(int ageGroupId) =>
      _getList('/catalog/age-groups/$ageGroupId/products/', ProductListItem.fromJson);

  // ------------------------------------------------------------------
  // Promotions
  // ------------------------------------------------------------------

  Future<List<Campaign>> campaigns() =>
      _getList('/promotions/campaigns/', Campaign.fromJson, query: {'live': 'true'});

  Future<List<ShowcaseVideoItem>> showcaseVideos() =>
      _getList('/promotions/showcase-videos/', ShowcaseVideoItem.fromJson);

  Future<(bool, double, String?)> validateCoupon(String code, double subtotal) async {
    final res = await _req('POST', '/promotions/validate-coupon/',
        body: {'code': code, 'subtotal': subtotal});
    final data = _decode(res);
    if (data is Map && data['valid'] == true) {
      return (true, (data['discount'] as num).toDouble(), null);
    }
    return (false, 0.0, data is Map ? data['detail']?.toString() : null);
  }

  Future<List<WalletCoupon>> availableCoupons() async {
    if (!isLoggedIn) return [];
    final res = await _req('GET', '/promotions/coupons/available/');
    if (res.statusCode != 200) return [];
    return _mapList(_decode(res), WalletCoupon.fromAvailable);
  }

  Future<List<WalletCoupon>> myCoupons() async {
    if (!isLoggedIn) return [];
    final res = await _req('GET', '/promotions/coupons/mine/');
    if (res.statusCode != 200) return [];
    return _mapList(_decode(res), WalletCoupon.fromClaim);
  }

  Future<void> claimCoupon(String code) async {
    _ok(await _req('POST', '/promotions/coupons/claim/', body: {'code': code}));
  }

  // ------------------------------------------------------------------
  // Cart
  // ------------------------------------------------------------------

  Future<Cart> getCart() async {
    final res = await _req('GET', '/cart/');
    return Cart.fromJson(_ok(res) as Map<String, dynamic>);
  }

  Future<Cart> addToCart(int productId, {int quantity = 1, int? variantId}) async {
    final res = await _req('POST', '/cart/items/', body: {
      'product_id': productId,
      'quantity': quantity,
      if (variantId != null) 'variant_id': variantId,
    });
    return Cart.fromJson(_ok(res, "Couldn't add this item to your bag.") as Map<String, dynamic>);
  }

  Future<Cart> updateCartItem(int itemId, int quantity) async {
    final res = await _req('PATCH', '/cart/items/$itemId/', body: {'quantity': quantity});
    return Cart.fromJson(_ok(res, "Couldn't update the quantity.") as Map<String, dynamic>);
  }

  Future<Cart> removeCartItem(int itemId) async {
    final res = await _req('DELETE', '/cart/items/$itemId/');
    return Cart.fromJson(_ok(res, "Couldn't remove this item.") as Map<String, dynamic>);
  }

  // ------------------------------------------------------------------
  // Auth
  // ------------------------------------------------------------------

  bool get isLoggedIn => _accessToken != null;

  /// Restores the token from secure storage so [isLoggedIn] is accurate at
  /// app start (before the first request).
  Future<void> init() => _loadPersisted();

  Future<String?> loginWithMessage(String username, String password) async {
    await _loadPersisted();
    final res = await _raw('POST', _u('/auth/login/'), {'username': username, 'password': password}, false);
    if (res.statusCode != 200) {
      final data = _decode(res);
      if (res.statusCode == 401 || res.statusCode == 400) {
        return (data is Map && data['detail'] != null)
            ? data['detail'].toString()
            : 'Incorrect username or password.';
      }
      return 'Could not sign in (${res.statusCode}). Please try again.';
    }
    await _storeTokens(_decode(res) as Map<String, dynamic>);
    return null;
  }

  Future<bool> login(String username, String password) async =>
      (await loginWithMessage(username, password)) == null;

  Future<void> _clearSession() async {
    _accessToken = null;
    _profile = null;
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  Future<void> logout() => _clearSession();

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    _accessToken = data['access']?.toString();
    await _secureStorage.write(key: 'access_token', value: _accessToken);
    if (data['refresh'] != null) {
      await _secureStorage.write(key: 'refresh_token', value: data['refresh'].toString());
    }
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) return false;
    try {
      final res = await http.post(
        _u('/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _accessToken = data['access']?.toString();
      await _secureStorage.write(key: 'access_token', value: _accessToken);
      if (data['refresh'] != null) {
        await _secureStorage.write(key: 'refresh_token', value: data['refresh'].toString());
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
    String phone = '',
  }) async {
    final res = await _raw('POST', _u('/auth/register/'), {
      'username': username,
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
    }, false);
    if (res.statusCode >= 400) {
      return _errorMessage(res, "Couldn't create your account — check your details and try again.");
    }
    final err = await loginWithMessage(username, password);
    return err == null ? null : 'Account created — please sign in.';
  }

  Future<bool> socialLogin(String provider, String idToken) async {
    final res = await _req('POST', '/auth/social/', body: {'provider': provider, 'id_token': idToken});
    if (res.statusCode != 200) return false;
    await _storeTokens(_decode(res) as Map<String, dynamic>);
    return true;
  }

  Future<String?> requestPhoneOTP(String phone) async {
    final res = await _req('POST', '/auth/phone/request-otp/', body: {'phone': phone});
    if (res.statusCode != 200) return null;
    final data = _decode(res);
    return data is Map ? data['debug_code']?.toString() ?? '' : '';
  }

  Future<bool> verifyPhoneOTP(String phone, String code) async {
    final res = await _req('POST', '/auth/phone/verify-otp/', body: {'phone': phone, 'code': code});
    if (res.statusCode != 200) return false;
    await _storeTokens(_decode(res) as Map<String, dynamic>);
    return true;
  }

  UserProfile? _profile;
  UserProfile? get cachedProfile => _profile;

  Future<UserProfile?> me() async {
    await _loadPersisted();
    if (!isLoggedIn) return null;
    final res = await _req('GET', '/auth/me/');
    if (res.statusCode != 200) return null;
    _profile = UserProfile.fromJson(_decode(res) as Map<String, dynamic>);
    return _profile;
  }

  // ---- Address book ----

  Future<List<SavedAddress>> addresses() async {
    if (!isLoggedIn) return [];
    final res = await _req('GET', '/auth/addresses/');
    if (res.statusCode != 200) return [];
    return _mapList(_decode(res), SavedAddress.fromJson);
  }

  Future<SavedAddress> saveAddress({
    int? id,
    required String label,
    required String fullName,
    required String phone,
    required String addressLine,
    required String city,
    required bool isDefault,
  }) async {
    final body = {
      'label': label,
      'full_name': fullName,
      'phone': phone,
      'address_line': addressLine,
      'city': city,
      'is_default': isDefault,
    };
    final res = id == null
        ? await _req('POST', '/auth/addresses/', body: body)
        : await _req('PATCH', '/auth/addresses/$id/', body: body);
    return SavedAddress.fromJson(_ok(res, "Couldn't save this address.") as Map<String, dynamic>);
  }

  Future<void> setDefaultAddress(int id) async {
    _ok(await _req('POST', '/auth/addresses/$id/set_default/'));
  }

  Future<void> deleteAddress(int id) async {
    _ok(await _req('DELETE', '/auth/addresses/$id/'));
  }

  // ---- Payment methods ----

  Future<List<SavedPaymentMethod>> paymentMethods() async {
    if (!isLoggedIn) return [];
    final res = await _req('GET', '/auth/payment-methods/');
    if (res.statusCode != 200) return [];
    return _mapList(_decode(res), SavedPaymentMethod.fromJson);
  }

  Future<SavedPaymentMethod> addPaymentMethod({
    required String type,
    String label = '',
    String cardBrand = '',
    String cardLast4 = '',
    int? expMonth,
    int? expYear,
    String mpesaPhone = '',
    bool isDefault = false,
  }) async {
    final res = await _req('POST', '/auth/payment-methods/', body: {
      'type': type,
      'label': label,
      if (type == 'card') ...{
        'card_brand': cardBrand,
        'card_last4': cardLast4,
        if (expMonth != null) 'card_exp_month': expMonth,
        if (expYear != null) 'card_exp_year': expYear,
      },
      if (type == 'mpesa') 'mpesa_phone': mpesaPhone,
      'is_default': isDefault,
    });
    return SavedPaymentMethod.fromJson(_ok(res, "Couldn't save this payment method.") as Map<String, dynamic>);
  }

  Future<void> setDefaultPaymentMethod(int id) async {
    _ok(await _req('POST', '/auth/payment-methods/$id/set_default/'));
  }

  Future<void> deletePaymentMethod(int id) async {
    _ok(await _req('DELETE', '/auth/payment-methods/$id/'));
  }

  // ------------------------------------------------------------------
  // Wishlist
  // ------------------------------------------------------------------

  Future<List<WishlistItem>> wishlist() async {
    final res = await _req('GET', '/catalog/wishlist/');
    if (res.statusCode == 401 || res.statusCode == 403) return [];
    return _mapList(_ok(res), WishlistItem.fromJson);
  }

  Future<WishlistItem> addToWishlist(int productId) async {
    final res = await _req('POST', '/catalog/wishlist/', body: {'product_id': productId});
    return WishlistItem.fromJson(_ok(res, "Couldn't save this piece.") as Map<String, dynamic>);
  }

  Future<void> removeFromWishlist(int wishlistItemId) async {
    _ok(await _req('DELETE', '/catalog/wishlist/$wishlistItemId/'));
  }

  // ------------------------------------------------------------------
  // Reviews
  // ------------------------------------------------------------------

  Future<List<Review>> reviews(int productId) =>
      _getList('/catalog/products/$productId/reviews/', Review.fromJson);

  Future<bool> addReview(int productId, int rating, String comment) async {
    final res = await _req('POST', '/catalog/products/$productId/reviews/',
        body: {'rating': rating, 'comment': comment});
    return res.statusCode == 201;
  }

  // ------------------------------------------------------------------
  // AI
  // ------------------------------------------------------------------

  Future<List<ProductListItem>> _aiList(String path) async {
    try {
      final res = await _req('GET', path);
      if (res.statusCode != 200) return [];
      return _mapList(_decode(res), ProductListItem.fromJson);
    } catch (_) {
      return [];
    }
  }

  Future<List<ProductListItem>> recommendedForYou() => _aiList('/ai/recommended-for-you/');
  Future<List<ProductListItem>> similarProducts(int productId) =>
      _aiList('/ai/products/$productId/similar/');
  Future<List<ProductListItem>> frequentlyBoughtTogether(int productId) =>
      _aiList('/ai/products/$productId/frequently-bought-together/');

  /// Smart search with typo correction. Returns (usedQuery, wasCorrected, results).
  Future<(String, bool, List<ProductListItem>)> smartSearch(String q) async {
    final res = await _req('GET', '/ai/search/', query: {'q': q});
    final data = _ok(res) as Map<String, dynamic>;
    final results = _mapList(data['results'], ProductListItem.fromJson);
    return (data['used_query']?.toString() ?? q, data['corrected'] == true, results);
  }

  int? _chatSessionId;

  Future<ChatMessage> chatbot(String message) async {
    final res = await _req('POST', '/ai/chatbot/',
        body: {'message': message, 'session_id': _chatSessionId});
    final data = _ok(res) as Map<String, dynamic>;
    _chatSessionId = (data['session_id'] as num?)?.toInt();
    return ChatMessage.fromBotReply(data['reply'] as Map<String, dynamic>);
  }

  // ------------------------------------------------------------------
  // Notifications & support
  // ------------------------------------------------------------------

  Future<List<AppNotification>> notifications() async {
    if (!isLoggedIn) return [];
    final res = await _req('GET', '/notifications/inbox/');
    if (res.statusCode != 200) return [];
    return _mapList(_decode(res), AppNotification.fromJson);
  }

  Future<void> markAllNotificationsRead() async {
    await _req('POST', '/notifications/inbox/mark-all-read/');
  }

  Future<SupportTicket> openSupportTicket(String subject, String message) async {
    final res = await _req('POST', '/notifications/support-tickets/',
        body: {'subject': subject, 'message': message});
    return SupportTicket.fromJson(_ok(res, "Couldn't send your request.") as Map<String, dynamic>);
  }

  // ------------------------------------------------------------------
  // Orders & delivery
  // ------------------------------------------------------------------

  Future<List<OrderSummary>> myOrders() async {
    if (!isLoggedIn) return [];
    final res = await _req('GET', '/orders/mine/');
    return _mapList(_ok(res), OrderSummary.fromJson);
  }

  Future<OrderDetail> orderDetail(String orderNumber) async {
    final res = await _req('GET', '/orders/$orderNumber/');
    return OrderDetail.fromJson(_ok(res, "Couldn't load this order.") as Map<String, dynamic>);
  }

  Future<DeliveryTracking?> orderTracking(String orderNumber) async {
    try {
      final res = await _req('GET', '/delivery/orders/$orderNumber/tracking/');
      if (res.statusCode != 200) return null;
      return DeliveryTracking.fromJson(_decode(res) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------------
  // Analytics (fire-and-forget)
  // ------------------------------------------------------------------

  Future<void> track(String eventType, {Map<String, dynamic> extra = const {}}) async {
    try {
      await _req('POST', '/analytics/track/', body: {'event_type': eventType, ...extra});
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // Checkout
  // ------------------------------------------------------------------

  Future<Map<String, dynamic>> checkout({
    String? guestEmail,
    required String paymentMethod,
    required String shippingName,
    required String shippingPhone,
    required String shippingAddress,
    required String shippingCity,
    String couponCode = '',
  }) async {
    final res = await _req('POST', '/orders/checkout/', body: {
      if (guestEmail != null && guestEmail.isNotEmpty) 'guest_email': guestEmail,
      'payment_method': paymentMethod,
      'shipping_name': shippingName,
      'shipping_phone': shippingPhone,
      'shipping_address': shippingAddress,
      'shipping_city': shippingCity,
      'coupon_code': couponCode,
    });
    if (res.statusCode != 201) {
      throw ApiException(_errorMessage(res, 'Checkout failed. Please try again.'), res.statusCode);
    }
    return _decode(res) as Map<String, dynamic>;
  }

  /// Starts Safaricom STK Push for an order already created by checkout.
  Future<Map<String, dynamic>> initiateMpesa({
    required String orderNumber,
    String? phone,
  }) async {
    final res = await _req(
      'POST',
      '/orders/mpesa/initiate/${Uri.encodeComponent(orderNumber)}/',
      body: {if (phone != null && phone.isNotEmpty) 'phone': phone},
    );
    if (res.statusCode != 202) {
      throw ApiException(_errorMessage(res, 'Could not start M-Pesa payment.'), res.statusCode);
    }
    return _decode(res) as Map<String, dynamic>;
  }

  /// Fetches the current order state while waiting for the Daraja callback.
  Future<Map<String, dynamic>> orderByNumber(String orderNumber) async {
    final res = await _req('GET', '/orders/${Uri.encodeComponent(orderNumber)}/');
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Could not check payment status.'), res.statusCode);
    }
    return _decode(res) as Map<String, dynamic>;
  }
}
