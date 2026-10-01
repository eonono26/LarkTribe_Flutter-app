// Data models mirroring the Django REST API (catalog, cart, orders,
// delivery, notifications, promotions, accounts). Field names follow the
// backend serializers exactly (snake_case JSON -> camelCase Dart).

String? _asString(dynamic v) => v == null ? null : v.toString();

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();

  final value = v.toString().trim();
  if (value.isEmpty) return null;

  return int.tryParse(value) ?? double.tryParse(value)?.round();
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim());
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

List<Map<String, dynamic>> _asMapList(dynamic v) {
  if (v is! List) return const [];
  return v.whereType<Map<String, dynamic>>().toList();
}

class AgeGroup {
  final int id;
  final String name;
  final String slug;

  // 'baby' | 'kids' | 'teens' — matches the backend's AgeGroup.Stage choices.
  // Gender (boys/girls) is NOT a property of the age group itself; it's a
  // separate product-level filter, same as the web app's Header.tsx.
  final String stage;
  final String? stageDisplay;
  final String? icon;
  final int order;
  final int? minAgeYears;
  final int? maxAgeYears;
  final String? primaryImageUrl;
  final int productCount;

  AgeGroup({
    required this.id,
    required this.name,
    required this.slug,
    this.stage = 'baby',
    this.stageDisplay,
    this.icon,
    this.order = 0,
    this.minAgeYears,
    this.maxAgeYears,
    this.primaryImageUrl,
    this.productCount = 0,
  });

  factory AgeGroup.fromJson(Map<String, dynamic> json) => AgeGroup(
        id: _asInt(json['id']) ?? 0,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        stage: json['stage']?.toString() ?? 'baby',
        stageDisplay: json['stage_display']?.toString(),
        icon: json['icon']?.toString(),
        order: _asInt(json['order']) ?? 0,
        minAgeYears: _asInt(json['min_age_years']),
        maxAgeYears: _asInt(json['max_age_years']),
        primaryImageUrl: json['primary_image'] is Map
            ? json['primary_image']['file_url']?.toString()
            : null,
        productCount: _asInt(json['product_count']) ?? 0,
      );
}

class Department {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? primaryImageUrl;
  final int categoryCount;
  final int productCount;

  Department({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.primaryImageUrl,
    this.categoryCount = 0,
    this.productCount = 0,
  });

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        id: _asInt(json['id']) ?? 0,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        description: json['description']?.toString(),
        primaryImageUrl: json['primary_image'] is Map
            ? json['primary_image']['file_url']?.toString()
            : null,
        categoryCount: _asInt(json['category_count']) ?? 0,
        productCount: _asInt(json['product_count']) ?? 0,
      );
}

class Category {
  final int id;
  final String name;
  final String slug;
  final Department? department;
  final String? primaryImageUrl;
  final int productCount;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.department,
    this.primaryImageUrl,
    this.productCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: _asInt(json['id']) ?? 0,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        department: json['department'] is Map<String, dynamic>
            ? Department.fromJson(json['department'] as Map<String, dynamic>)
            : null,
        primaryImageUrl: json['primary_image'] is Map
            ? json['primary_image']['file_url']?.toString()
            : null,
        productCount: _asInt(json['product_count']) ?? 0,
      );
}

class Brand {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final int productCount;

  Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.productCount = 0,
  });

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: _asInt(json['id']) ?? 0,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        logoUrl: json['logo_url']?.toString(),
        productCount: _asInt(json['product_count']) ?? 0,
      );
}

/// One gallery photo. `color` is the variant colour it depicts ('' = general).
class ProductImage {
  final String url;
  final String color;
  final String alt;

  const ProductImage({required this.url, this.color = '', this.alt = ''});
}

class ProductListItem {
  final int id;
  final String name;
  final String slug;
  final String price;
  final String? compareAtPrice;
  final int discountPercent;
  final String ratingAvg;
  final int ratingCount;
  final String? imageUrl;
  final String vendorName;
  final String? categoryName;
  final String? categorySlug;
  final String? departmentName;
  final String? departmentSlug;
  final bool isFeatured;
  final int stock;
  final String status;
  final List<AgeGroup> ageGroups;
  final bool needsSize;
  final Map<String, int> colorVariantIds;
  final List<String> colors;
  final Map<String, String> colorImages;
  final String gender; // 'boys' | 'girls' | 'unisex'
  final DateTime? createdAt;

  ProductListItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.compareAtPrice,
    required this.discountPercent,
    required this.ratingAvg,
    required this.ratingCount,
    this.imageUrl,
    required this.vendorName,
    this.categoryName,
    this.categorySlug,
    this.departmentName,
    this.departmentSlug,
    this.isFeatured = false,
    this.stock = 0,
    this.status = 'active',
    this.ageGroups = const [],
    this.needsSize = false,
    this.colorVariantIds = const {},
    this.colors = const [],
    this.colorImages = const {},
    this.gender = '',
    this.createdAt,
  });

  bool get onSale =>
      compareAtPrice != null &&
      (double.tryParse(compareAtPrice!) ?? 0) > (double.tryParse(price) ?? 0);

  bool get inStock => stock > 0;

  bool get lowStock => inStock && stock <= 5;

  /// Added in the last 14 days — drives the "NEW DROP" badge.
  bool get isNew =>
      createdAt != null && DateTime.now().difference(createdAt!).inDays <= 14;

  factory ProductListItem.fromJson(Map<String, dynamic> json) =>
      ProductListItem(
        id: _asInt(json['id']) ?? 0,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        price: _asString(json['price']) ?? '0',
        compareAtPrice: _asString(json['compare_at_price']),
        discountPercent: _asInt(json['discount_percent']) ?? 0,
        ratingAvg: _asString(json['rating_avg']) ?? '0.00',
        ratingCount: _asInt(json['rating_count']) ?? 0,
        imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
        vendorName: json['vendor_name']?.toString() ?? '',
        categoryName: json['category_name']?.toString(),
        categorySlug: json['category_slug']?.toString(),
        departmentName: json['department_name']?.toString(),
        departmentSlug: json['department_slug']?.toString(),
        isFeatured: json['is_featured'] == true,
        stock: _asInt(json['stock']) ?? 0,
        status: json['status']?.toString() ?? 'active',
        ageGroups: _asMapList(json['age_groups']).map(AgeGroup.fromJson).toList(),
        needsSize: json['needs_size'] == true,
        colorVariantIds: (json['color_variant_ids'] is Map)
            ? (json['color_variant_ids'] as Map)
                .map((k, v) => MapEntry(k.toString(), _asInt(v) ?? 0))
            : const {},
        colors: (json['colors'] is List)
            ? (json['colors'] as List).map((e) => e.toString()).toList()
            : const [],
        colorImages: (json['color_images'] is Map)
            ? (json['color_images'] as Map)
                .map((k, v) => MapEntry(k.toString(), v.toString()))
            : const {},
        gender: json['gender']?.toString() ?? '',
        createdAt: _asDate(json['created_at']),
      );
}

class ProductVariant {
  final int id;
  final String size;
  final String color;
  final int stock;
  final String skuSuffix;

  ProductVariant({
    required this.id,
    this.size = '',
    this.color = '',
    this.stock = 0,
    this.skuSuffix = '',
  });

  bool get inStock => stock > 0;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: _asInt(json['id']) ?? 0,
        size: json['size']?.toString() ?? '',
        color: json['color']?.toString() ?? '',
        stock: _asInt(json['stock']) ?? 0,
        skuSuffix: json['sku_suffix']?.toString() ?? '',
      );

  /// "Black / M" — same label the backend snapshots on order items.
  String get label => [color, size].where((s) => s.isNotEmpty).join(' / ');
}

class SizeGuide {
  final String name;
  final List<String> columns;
  final List<List<String>> rows;
  final String notes;

  const SizeGuide({
    required this.name,
    this.columns = const [],
    this.rows = const [],
    this.notes = '',
  });

  factory SizeGuide.fromJson(Map<String, dynamic> json) => SizeGuide(
        name: json['name']?.toString() ?? 'Size guide',
        columns: (json['columns'] is List)
            ? (json['columns'] as List).map((e) => e.toString()).toList()
            : const [],
        rows: (json['rows'] is List)
            ? (json['rows'] as List)
                .map<List<String>>((r) => r is List
                    ? r.map((e) => e.toString()).toList()
                    : <String>[r.toString()])
                .toList()
            : const [],
        notes: json['notes']?.toString() ?? '',
      );
}

class ProductDetail extends ProductListItem {
  final String description;
  final List<ProductImage> gallery;
  final List<String> availableSizes;
  final List<ProductVariant> variants;
  final Category? category;
  final Brand? brand;
  final List<String> features;
  final String materials;
  final String careInstructions;
  final SizeGuide? sizeGuide;

  /// Plain URLs, in gallery order (kept for older call sites).
  List<String> get images => gallery.map((g) => g.url).toList();

  ProductDetail({
    required super.id,
    required super.name,
    required super.slug,
    required super.price,
    super.compareAtPrice,
    required super.discountPercent,
    required super.ratingAvg,
    required super.ratingCount,
    required super.vendorName,
    super.categoryName,
    super.categorySlug,
    super.departmentName,
    super.departmentSlug,
    super.isFeatured,
    required super.stock,
    super.status,
    super.ageGroups,
    super.gender,
    super.createdAt,
    required this.description,
    required this.gallery,
    this.availableSizes = const [],
    this.variants = const [],
    this.category,
    this.brand,
    this.features = const [],
    this.materials = '',
    this.careInstructions = '',
    this.sizeGuide,
  }) : super(
          imageUrl: gallery.isNotEmpty ? gallery.first.url : null,
          needsSize: variants.any((v) => v.size.isNotEmpty),
        );

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final gallery = _asMapList(json['images'])
        .map((i) {
          final url = (i['image_url'] ?? i['image'])?.toString();
          if (url == null || url.isEmpty) return null;
          return ProductImage(
            url: url,
            color: i['color']?.toString() ?? '',
            alt: i['alt_text']?.toString() ?? '',
          );
        })
        .whereType<ProductImage>()
        .toList();

    final cat = json['category'] is Map<String, dynamic>
        ? Category.fromJson(json['category'] as Map<String, dynamic>)
        : null;

    return ProductDetail(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      price: _asString(json['price']) ?? '0',
      compareAtPrice: _asString(json['compare_at_price']),
      discountPercent: _asInt(json['discount_percent']) ?? 0,
      ratingAvg: _asString(json['rating_avg']) ?? '0.00',
      ratingCount: _asInt(json['rating_count']) ?? 0,
      vendorName: json['vendor_name']?.toString() ?? '',
      categoryName: cat?.name,
      categorySlug: cat?.slug,
      departmentName: cat?.department?.name,
      departmentSlug: cat?.department?.slug,
      isFeatured: json['is_featured'] == true,
      stock: _asInt(json['stock']) ?? 0,
      status: json['status']?.toString() ?? 'active',
      ageGroups: _asMapList(json['age_groups']).map(AgeGroup.fromJson).toList(),
      gender: json['gender']?.toString() ?? '',
      createdAt: _asDate(json['created_at']),
      description: json['description']?.toString() ?? '',
      gallery: gallery,
      availableSizes: (json['available_sizes'] is List)
          ? (json['available_sizes'] as List).map((s) => s.toString()).toList()
          : const [],
      variants: _asMapList(json['variants']).map(ProductVariant.fromJson).toList(),
      category: cat,
      brand: json['brand'] is Map<String, dynamic>
          ? Brand.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
      features: (json['features'] is List)
          ? (json['features'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : const [],
      materials: json['materials']?.toString() ?? '',
      careInstructions: json['care_instructions']?.toString() ?? '',
      sizeGuide: json['size_guide'] is Map<String, dynamic>
          ? SizeGuide.fromJson(json['size_guide'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CartItem {
  final int id;
  final ProductListItem product;
  final ProductVariant? variant;
  final String? image; // photo of the colour actually chosen
  final int quantity;
  final String subtotal;

  CartItem({
    required this.id,
    required this.product,
    this.variant,
    this.image,
    required this.quantity,
    required this.subtotal,
  });

  String? get displayImage => (image != null && image!.isNotEmpty) ? image : product.imageUrl;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: _asInt(json['id']) ?? 0,
        product: ProductListItem.fromJson(json['product'] as Map<String, dynamic>),
        variant: json['variant'] is Map<String, dynamic>
            ? ProductVariant.fromJson(json['variant'] as Map<String, dynamic>)
            : null,
        image: json['image']?.toString(),
        quantity: _asInt(json['quantity']) ?? 0,
        subtotal: json['subtotal']?.toString() ?? '0',
      );
}

class Cart {
  final int id;
  final List<CartItem> items;
  final String total;

  Cart({
    required this.id,
    required this.items,
    required this.total,
  });

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        id: _asInt(json['id']) ?? 0,
        items: _asMapList(json['items']).map(CartItem.fromJson).toList(),
        total: json['total']?.toString() ?? '0',
      );

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => double.tryParse(total) ?? 0;
}

class Review {
  final int id;
  final String user;
  final int rating;
  final String comment;
  final String createdAt;

  Review({
    required this.id,
    required this.user,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: _asInt(json['id']) ?? 0,
        user: json['user']?.toString() ?? '',
        rating: _asInt(json['rating']) ?? 0,
        comment: json['comment']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
      );
}

class WishlistItem {
  final int id;
  final ProductListItem product;
  final DateTime? addedAt;

  WishlistItem({
    required this.id,
    required this.product,
    this.addedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: _asInt(json['id']) ?? 0,
        product: ProductListItem.fromJson(json['product'] as Map<String, dynamic>),
        addedAt: _asDate(json['added_at'] ?? json['created_at']),
      );
}

class AppNotification {
  final int id;
  final String channel;
  final String category;
  final String title;
  final String body;
  final String link;
  final bool isRead;
  final String sentAt;

  AppNotification({
    required this.id,
    required this.channel,
    required this.category,
    required this.title,
    required this.body,
    required this.link,
    required this.isRead,
    required this.sentAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: _asInt(json['id']) ?? 0,
        channel: json['channel']?.toString() ?? 'in_app',
        category: json['category']?.toString() ?? 'system',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        link: json['link']?.toString() ?? '',
        isRead: json['is_read'] == true,
        sentAt: json['sent_at']?.toString() ?? '',
      );
}

class ChatMessage {
  final int? id;
  final String sender;
  final String text;
  final List<ProductListItem> products;

  ChatMessage({
    this.id,
    required this.sender,
    required this.text,
    this.products = const [],
  });

  factory ChatMessage.fromBotReply(Map<String, dynamic> json) => ChatMessage(
        id: _asInt(json['id']),
        sender: json['sender']?.toString() ?? 'bot',
        text: json['text']?.toString() ?? '',
        products: _asMapList(json['products']).map(ProductListItem.fromJson).toList(),
      );
}

class SupportTicket {
  final int id;
  final String subject;
  final String message;
  final String status;
  final String createdAt;

  SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: _asInt(json['id']) ?? 0,
        subject: json['subject']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        status: json['status']?.toString() ?? 'open',
        createdAt: json['created_at']?.toString() ?? '',
      );
}

class OrderItemDetail {
  final int id;
  final int? productId;
  final int? variantId;
  final String productName;
  final String? productImage;
  final String? productSlug;
  final String variantLabel;
  final int quantity;
  final String unitPrice;
  final String fulfillmentStatus;

  OrderItemDetail({
    required this.id,
    this.productId,
    this.variantId,
    required this.productName,
    this.productImage,
    this.productSlug,
    this.variantLabel = '',
    required this.quantity,
    required this.unitPrice,
    this.fulfillmentStatus = 'pending',
  });

  double get lineTotal => (double.tryParse(unitPrice) ?? 0) * quantity;

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) => OrderItemDetail(
        id: _asInt(json['id']) ?? 0,
        productId: _asInt(json['product']),
        variantId: _asInt(json['variant']),
        productName: json['product_name']?.toString() ?? '',
        productImage: json['product_image']?.toString(),
        productSlug: json['product_slug']?.toString(),
        variantLabel: json['variant_label']?.toString() ?? '',
        quantity: _asInt(json['quantity']) ?? 0,
        unitPrice: json['unit_price']?.toString() ?? '0',
        fulfillmentStatus: json['fulfillment_status']?.toString() ?? 'pending',
      );
}

/// Full order — the list endpoint (/orders/mine/) and the detail endpoint
/// use the same serializer, so one model serves both.
class OrderDetail {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentMethod;
  final String subtotal;
  final String shippingFee;
  final String discountTotal;
  final String memberDiscountTotal;
  final String total;
  final String shippingName;
  final String shippingPhone;
  final String shippingAddress;
  final String shippingCity;
  final String couponCode;
  final String createdAt;
  final List<OrderItemDetail> items;

  OrderDetail({
    this.id = 0,
    required this.orderNumber,
    required this.status,
    this.paymentMethod = '',
    this.subtotal = '0',
    this.shippingFee = '0',
    this.discountTotal = '0',
    this.memberDiscountTotal = '0',
    required this.total,
    this.shippingName = '',
    this.shippingPhone = '',
    this.shippingAddress = '',
    this.shippingCity = '',
    this.couponCode = '',
    required this.createdAt,
    this.items = const [],
  });

  DateTime? get createdDate => _asDate(createdAt);

  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled' || status == 'refunded';
  bool get isInTransit => status == 'shipped';
  bool get isActive => !isDelivered && !isCancelled;

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
        id: _asInt(json['id']) ?? 0,
        orderNumber: json['order_number']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        paymentMethod: json['payment_method']?.toString() ?? '',
        subtotal: json['subtotal']?.toString() ?? '0',
        shippingFee: json['shipping_fee']?.toString() ?? '0',
        discountTotal: json['discount_total']?.toString() ?? '0',
        memberDiscountTotal: json['member_discount_total']?.toString() ?? '0',
        total: json['total']?.toString() ?? '0',
        shippingName: json['shipping_name']?.toString() ?? '',
        shippingPhone: json['shipping_phone']?.toString() ?? '',
        shippingAddress: json['shipping_address']?.toString() ?? '',
        shippingCity: json['shipping_city']?.toString() ?? '',
        couponCode: json['coupon_code']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
        items: _asMapList(json['items']).map(OrderItemDetail.fromJson).toList(),
      );
}

/// The list screen only needs the same fields as the detail screen.
typedef OrderSummary = OrderDetail;

class DriverInfo {
  final String name;
  final String phone;
  final String vehicleType;
  final String vehicleLabel;
  final String plate;
  final double? lat;
  final double? lng;
  final double rating;

  DriverInfo({
    required this.name,
    this.phone = '',
    this.vehicleType = '',
    this.vehicleLabel = '',
    this.plate = '',
    this.lat,
    this.lng,
    this.rating = 5,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) => DriverInfo(
        name: json['name']?.toString() ?? 'Courier',
        phone: json['phone']?.toString() ?? '',
        vehicleType: json['vehicle_type']?.toString() ?? '',
        vehicleLabel: json['vehicle_type_display']?.toString() ?? '',
        plate: json['vehicle_plate']?.toString() ?? '',
        lat: _asDouble(json['current_lat']),
        lng: _asDouble(json['current_lng']),
        rating: _asDouble(json['rating_avg']) ?? 5,
      );
}

class DeliveryEvent {
  final String status;
  final String note;
  final DateTime? at;

  DeliveryEvent({required this.status, this.note = '', this.at});

  factory DeliveryEvent.fromJson(Map<String, dynamic> json) => DeliveryEvent(
        status: json['status']?.toString() ?? '',
        note: json['note']?.toString() ?? '',
        at: _asDate(json['created_at']),
      );
}

/// /delivery/orders/<number>/tracking/ — status, courier, live position, timeline.
class DeliveryTracking {
  final String status; // unassigned|assigned|picked_up|en_route|delivered|cancelled|failed
  final DriverInfo? driver;
  final String pickupLabel;
  final double? pickupLat;
  final double? pickupLng;
  final String dropoffLabel;
  final double? dropoffLat;
  final double? dropoffLng;
  final List<DeliveryEvent> events;
  final DateTime? deliveredAt;

  DeliveryTracking({
    required this.status,
    this.driver,
    this.pickupLabel = '',
    this.pickupLat,
    this.pickupLng,
    this.dropoffLabel = '',
    this.dropoffLat,
    this.dropoffLng,
    this.events = const [],
    this.deliveredAt,
  });

  bool get isLive => status == 'assigned' || status == 'picked_up' || status == 'en_route';

  factory DeliveryTracking.fromJson(Map<String, dynamic> json) => DeliveryTracking(
        status: json['status']?.toString() ?? 'unassigned',
        driver: json['driver'] is Map<String, dynamic>
            ? DriverInfo.fromJson(json['driver'] as Map<String, dynamic>)
            : null,
        pickupLabel: json['pickup_label']?.toString() ?? '',
        pickupLat: _asDouble(json['pickup_lat']),
        pickupLng: _asDouble(json['pickup_lng']),
        dropoffLabel: json['dropoff_label']?.toString() ?? '',
        dropoffLat: _asDouble(json['dropoff_lat']),
        dropoffLng: _asDouble(json['dropoff_lng']),
        events: _asMapList(json['events']).map(DeliveryEvent.fromJson).toList(),
        deliveredAt: _asDate(json['delivered_at']),
      );
}

/// A homepage/category promo banner (backend: promotions.Campaign).
class Campaign {
  final int id;
  final String title;
  final String description;
  final String placement;
  final String style;
  final String? backgroundColor;
  final String ctaLabel;
  final String? image;
  final String linkUrl;
  final int? department;
  final bool isLive;

  Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.placement,
    required this.style,
    this.backgroundColor,
    required this.ctaLabel,
    this.image,
    required this.linkUrl,
    this.department,
    required this.isLive,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: _asInt(json['id']) ?? 0,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        placement: json['placement']?.toString() ?? '',
        style: json['style']?.toString() ?? 'hero',
        backgroundColor: json['background_color']?.toString(),
        ctaLabel: json['cta_label']?.toString() ?? 'Shop now',
        image: json['image']?.toString(),
        linkUrl: json['link_url']?.toString() ?? '',
        department: _asInt(json['department']),
        isLive: json['is_live'] != false,
      );
}

/// A shoppable video tile for the homepage "Watch & shop" section
/// (backend: promotions.ShowcaseVideo).
class ShowcaseVideoItem {
  final int id;
  final String title;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String ctaLabel;
  final String? productSlug;
  final String? departmentSlug;
  final String? resolvedLink;

  ShowcaseVideoItem({
    required this.id,
    required this.title,
    this.videoUrl,
    this.thumbnailUrl,
    required this.ctaLabel,
    this.productSlug,
    this.departmentSlug,
    this.resolvedLink,
  });

  factory ShowcaseVideoItem.fromJson(Map<String, dynamic> json) =>
      ShowcaseVideoItem(
        id: _asInt(json['id']) ?? 0,
        title: json['title']?.toString() ?? '',
        videoUrl: json['video_url']?.toString(),
        thumbnailUrl: json['thumbnail_url']?.toString(),
        ctaLabel: json['cta_label']?.toString() ?? 'Shop now',
        productSlug: json['product_slug']?.toString(),
        departmentSlug: json['department_slug']?.toString(),
        resolvedLink: json['resolved_link']?.toString() ?? json['link_url']?.toString(),
      );
}

class UserProfile {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String? profilePictureUrl;
  final DateTime? dateJoined;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.profilePictureUrl,
    this.dateJoined,
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : username;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: _asInt(json['id']) ?? 0,
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        firstName: json['first_name']?.toString() ?? '',
        lastName: json['last_name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        profilePictureUrl: json['profile_picture_url']?.toString(),
        dateJoined: _asDate(json['date_joined']),
      );
}

/// A saved delivery address (/auth/addresses/).
class SavedAddress {
  final int id;
  final String label; // home | work | other
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final bool isDefault;

  SavedAddress({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.isDefault,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        id: _asInt(json['id']) ?? 0,
        label: json['label']?.toString() ?? 'home',
        fullName: json['full_name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        addressLine: json['address_line']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        isDefault: json['is_default'] == true,
      );
}

/// A saved payment method (/auth/payment-methods/). Cards are display-only
/// tokens (brand + last 4); M-Pesa entries carry the phone number.
class SavedPaymentMethod {
  final int id;
  final String type; // card | mpesa
  final String label;
  final String cardBrand;
  final String cardLast4;
  final int? expMonth;
  final int? expYear;
  final String mpesaPhone;
  final bool isDefault;

  SavedPaymentMethod({
    required this.id,
    required this.type,
    this.label = '',
    this.cardBrand = '',
    this.cardLast4 = '',
    this.expMonth,
    this.expYear,
    this.mpesaPhone = '',
    this.isDefault = false,
  });

  bool get isCard => type == 'card';

  String get title => label.isNotEmpty
      ? label
      : (isCard ? (cardBrand.isNotEmpty ? cardBrand : 'Card') : 'M-Pesa');

  String get subtitle {
    if (isCard) {
      final mm = expMonth?.toString().padLeft(2, '0');
      final yy = expYear == null ? null : (expYear! % 100).toString().padLeft(2, '0');
      final exp = (mm != null && yy != null) ? '  •  Exp $mm/$yy' : '';
      return '•••• $cardLast4$exp';
    }
    return mpesaPhone;
  }

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) => SavedPaymentMethod(
        id: _asInt(json['id']) ?? 0,
        type: json['type']?.toString() ?? 'card',
        label: json['label']?.toString() ?? '',
        cardBrand: json['card_brand']?.toString() ?? '',
        cardLast4: json['card_last4']?.toString() ?? '',
        expMonth: _asInt(json['card_exp_month']),
        expYear: _asInt(json['card_exp_year']),
        mpesaPhone: json['mpesa_phone']?.toString() ?? '',
        isDefault: json['is_default'] == true,
      );
}

/// A coupon in the customer's wallet (/promotions/coupons/mine/).
class WalletCoupon {
  final String code;
  final int? percentOff;
  final double? amountOff;
  final DateTime? validUntil;
  final bool used;
  final bool saved;

  WalletCoupon({
    required this.code,
    this.percentOff,
    this.amountOff,
    this.validUntil,
    this.used = false,
    this.saved = true,
  });

  /// /promotions/coupons/available/ rows (public coupons, `saved` flag).
  factory WalletCoupon.fromAvailable(Map<String, dynamic> json) => WalletCoupon(
        code: json['code']?.toString() ?? '',
        percentOff: _asInt(json['percent_off']),
        amountOff: _asDouble(json['amount_off']),
        validUntil: _asDate(json['valid_until']),
        saved: json['saved'] == true,
      );

  String get summary {
    if (percentOff != null && percentOff! > 0) return '$percentOff% OFF';
    if (amountOff != null && amountOff! > 0) return 'KSh ${amountOff!.toStringAsFixed(0)} OFF';
    return 'PROMO';
  }

  factory WalletCoupon.fromClaim(Map<String, dynamic> json) {
    final c = json['coupon'] is Map<String, dynamic>
        ? json['coupon'] as Map<String, dynamic>
        : <String, dynamic>{};
    return WalletCoupon(
      code: c['code']?.toString() ?? '',
      percentOff: _asInt(c['percent_off']),
      amountOff: _asDouble(c['amount_off']),
      validUntil: _asDate(c['valid_until']),
      used: json['used_at'] != null,
    );
  }
}
