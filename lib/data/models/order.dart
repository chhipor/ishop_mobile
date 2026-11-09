class CustomerResponse {
  const CustomerResponse({
    required this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final String? userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();

  factory CustomerResponse.fromJson(Map<String, dynamic> json) =>
      CustomerResponse(
        id: json['id'] as String,
        userId: json['userId'] as String?,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'address': address,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

class CustomerProfileRequest {
  const CustomerProfileRequest({
    required this.firstName,
    required this.lastName,
    this.phone,
    this.address,
  });

  final String firstName;
  final String lastName;
  final String? phone;
  final String? address;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'address': address,
  };
}

class OrderItemResponse {
  const OrderItemResponse({
    required this.id,
    required this.productId,
    required this.productName,
    this.thumbnail,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String id;
  final String productId;
  final String productName;
  final String? thumbnail;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) =>
      OrderItemResponse(
        id: json['id'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        thumbnail: json['thumbnail'] as String?,
        quantity: (json['quantity'] as num).toInt(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        lineTotal: (json['lineTotal'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'thumbnail': thumbnail,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'lineTotal': lineTotal,
  };
}

class OrderStatus {
  const OrderStatus._();

  static const String pending = 'PENDING';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
}

class OrderResponse {
  const OrderResponse({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.customer,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String orderNumber;
  final DateTime orderDate;
  final double totalAmount;

  final String status;
  final CustomerResponse customer;
  final List<OrderItemResponse> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == OrderStatus.pending;

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  factory OrderResponse.fromJson(Map<String, dynamic> json) => OrderResponse(
    id: json['id'] as String,
    orderNumber: json['orderNumber'] as String,
    orderDate: DateTime.parse(json['orderDate'] as String),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    status: json['status'] as String,
    customer: CustomerResponse.fromJson(
      json['customer'] as Map<String, dynamic>,
    ),
    items: (json['items'] as List<dynamic>)
        .map((e) => OrderItemResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'orderDate': orderDate.toUtc().toIso8601String(),
    'totalAmount': totalAmount,
    'status': status,
    'customer': customer.toJson(),
    'items': items.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}
