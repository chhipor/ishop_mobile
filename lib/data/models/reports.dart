class ProductReportResponse {
  const ProductReportResponse({
    required this.totalProducts,
    required this.activeProducts,
    required this.totalStockQuantity,
    required this.averagePrice,
  });

  final int totalProducts;
  final int activeProducts;
  final int totalStockQuantity;
  final double averagePrice;

  factory ProductReportResponse.fromJson(Map<String, dynamic> json) =>
      ProductReportResponse(
        totalProducts: (json['totalProducts'] as num).toInt(),
        activeProducts: (json['activeProducts'] as num).toInt(),
        totalStockQuantity: (json['totalStockQuantity'] as num).toInt(),
        averagePrice: (json['averagePrice'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'totalProducts': totalProducts,
    'activeProducts': activeProducts,
    'totalStockQuantity': totalStockQuantity,
    'averagePrice': averagePrice,
  };
}

class OrderReportResponse {
  const OrderReportResponse({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalSales,
    required this.averageOrderValue,
  });

  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalSales;
  final double averageOrderValue;

  factory OrderReportResponse.fromJson(Map<String, dynamic> json) =>
      OrderReportResponse(
        totalOrders: (json['totalOrders'] as num).toInt(),
        completedOrders: (json['completedOrders'] as num).toInt(),
        cancelledOrders: (json['cancelledOrders'] as num).toInt(),
        totalSales: (json['totalSales'] as num).toDouble(),
        averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'totalOrders': totalOrders,
    'completedOrders': completedOrders,
    'cancelledOrders': cancelledOrders,
    'totalSales': totalSales,
    'averageOrderValue': averageOrderValue,
  };
}

class CustomerReportResponse {
  const CustomerReportResponse({
    required this.totalCustomers,
    required this.distinctCustomerEmails,
  });

  final int totalCustomers;
  final int distinctCustomerEmails;

  factory CustomerReportResponse.fromJson(Map<String, dynamic> json) =>
      CustomerReportResponse(
        totalCustomers: (json['totalCustomers'] as num).toInt(),
        distinctCustomerEmails: (json['distinctCustomerEmails'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
    'totalCustomers': totalCustomers,
    'distinctCustomerEmails': distinctCustomerEmails,
  };
}

class SalesReportResponse {
  const SalesReportResponse({
    required this.totalRevenue,
    required this.totalOrders,
    this.bestSellingProduct,
    required this.bestSellingQuantity,
  });

  final double totalRevenue;
  final int totalOrders;
  final String? bestSellingProduct;
  final int bestSellingQuantity;

  factory SalesReportResponse.fromJson(Map<String, dynamic> json) =>
      SalesReportResponse(
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
        totalOrders: (json['totalOrders'] as num).toInt(),
        bestSellingProduct: json['bestSellingProduct'] as String?,
        bestSellingQuantity: (json['bestSellingQuantity'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
    'totalRevenue': totalRevenue,
    'totalOrders': totalOrders,
    'bestSellingProduct': bestSellingProduct,
    'bestSellingQuantity': bestSellingQuantity,
  };
}
