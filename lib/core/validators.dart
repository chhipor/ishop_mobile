class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool isUuid(String? value) => value != null && _uuid.hasMatch(value);

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final req = required(value, field: 'Email');
    if (req != null) return req;
    if (!_email.hasMatch(value!.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) => required(value, field: 'Password');

  static String? productName(String? value) {
    final req = required(value, field: 'Name');
    if (req != null) return req;
    if (value!.trim().length > 150) {
      return 'Name must be at most 150 characters';
    }
    return null;
  }

  static String? sku(String? value) {
    final req = required(value, field: 'SKU');
    if (req != null) return req;
    if (value!.trim().length > 80) return 'SKU must be at most 80 characters';
    return null;
  }

  static String? description(String? value) {
    if (value != null && value.trim().length > 500) {
      return 'Description must be at most 500 characters';
    }
    return null;
  }

  static String? unitPrice(String? value) {
    final req = required(value, field: 'Unit price');
    if (req != null) return req;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || !parsed.isFinite) return 'Enter a valid price';
    if (parsed <= 0) return 'Price must be greater than 0';
    return null;
  }

  static String? quantity(String? value) {
    final req = required(value, field: 'Quantity');
    if (req != null) return req;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Enter a whole number';
    if (parsed < 0) return 'Quantity cannot be negative';
    return null;
  }

  static bool isHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static String? thumbnailUrl(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.length > 1000) return 'URL must be at most 1000 characters';
    if (!isHttpUrl(v)) return 'Enter a valid http(s) URL';
    return null;
  }

  static String? imageUrl(String? value) => thumbnailUrl(value);

  static String? firstName(String? value) =>
      required(value, field: 'First name');

  static String? lastName(String? value) => required(value, field: 'Last name');
}
