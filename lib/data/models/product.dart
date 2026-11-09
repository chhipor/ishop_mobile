import '../../core/config.dart';

enum StockLevel { inStock, low, out }

List<String> _stringList(Object? value) =>
    (value as List<dynamic>? ?? const []).cast<String>().toList();

class ProductResponse {
  const ProductResponse({
    required this.id,
    required this.name,
    required this.sku,
    this.description,
    required this.unitPrice,
    required this.quantityInStock,
    required this.active,
    this.thumbnail,
    this.images = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String sku;
  final String? description;
  final double unitPrice;
  final int quantityInStock;
  final bool active;

  final String? thumbnail;

  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockLevel get stockLevel {
    if (quantityInStock <= 0) return StockLevel.out;
    if (quantityInStock <= AppConfig.lowStockThreshold) return StockLevel.low;
    return StockLevel.inStock;
  }

  bool get isLowStock => quantityInStock <= AppConfig.lowStockThreshold;

  String? get coverImage =>
      _nonEmpty(thumbnail) ?? (images.isEmpty ? null : images.first);

  List<String> get galleryImages {
    final list = images.where((u) => u.trim().isNotEmpty).toList();
    if (list.isNotEmpty) return list;
    final t = _nonEmpty(thumbnail);
    return t == null ? const [] : [t];
  }

  static String? _nonEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s;

  factory ProductResponse.fromJson(Map<String, dynamic> json) =>
      ProductResponse(
        id: json['id'] as String,
        name: json['name'] as String,
        sku: json['sku'] as String,
        description: json['description'] as String?,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        quantityInStock: (json['quantityInStock'] as num).toInt(),
        active: json['active'] as bool,
        thumbnail: json['thumbnail'] as String?,
        images: _stringList(json['images']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'description': description,
    'unitPrice': unitPrice,
    'quantityInStock': quantityInStock,
    'active': active,
    'thumbnail': thumbnail,
    'images': images,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

class ProductRequest {
  const ProductRequest({
    required this.name,
    required this.sku,
    this.description,
    required this.unitPrice,
    required this.quantityInStock,
    this.active,
    this.thumbnail,
    this.images = const [],
  });

  final String name;
  final String sku;
  final String? description;
  final double unitPrice;
  final int quantityInStock;
  final bool? active;

  final String? thumbnail;

  final List<String> images;

  factory ProductRequest.fromJson(Map<String, dynamic> json) => ProductRequest(
    name: json['name'] as String,
    sku: json['sku'] as String,
    description: json['description'] as String?,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    quantityInStock: (json['quantityInStock'] as num).toInt(),
    active: json['active'] as bool?,
    thumbnail: json['thumbnail'] as String?,
    images: _stringList(json['images']),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'sku': sku,
    'description': description,
    'unitPrice': unitPrice,
    'quantityInStock': quantityInStock,
    if (active != null) 'active': active,
    'thumbnail': thumbnail,
    'images': images,
  };
}

class MessageResponse {
  const MessageResponse({required this.message});

  final String message;

  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      MessageResponse(message: json['message'] as String? ?? '');

  Map<String, dynamic> toJson() => {'message': message};
}
