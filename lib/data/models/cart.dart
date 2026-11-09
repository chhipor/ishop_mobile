class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    this.thumbnail,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.quantityInStock,
    required this.available,
    required this.addedAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String sku;
  final String? thumbnail;

  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final int quantityInStock;

  final bool available;
  final DateTime addedAt;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as String,
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    sku: json['sku'] as String,
    thumbnail: json['thumbnail'] as String?,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    quantity: (json['quantity'] as num).toInt(),
    lineTotal: (json['lineTotal'] as num).toDouble(),
    quantityInStock: (json['quantityInStock'] as num).toInt(),
    available: json['available'] as bool,
    addedAt: DateTime.parse(json['addedAt'] as String),
  );
}

class Cart {
  const Cart({
    required this.id,
    required this.customerId,
    required this.items,
    required this.totalQuantity,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final List<CartItem> items;
  final int totalQuantity;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEmpty => items.isEmpty;

  bool get hasUnavailableItems => items.any((i) => !i.available);

  int quantityOf(String productId) {
    for (final i in items) {
      if (i.productId == productId) return i.quantity;
    }
    return 0;
  }

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    id: json['id'] as String,
    customerId: json['customerId'] as String,
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalQuantity: (json['totalQuantity'] as num).toInt(),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
