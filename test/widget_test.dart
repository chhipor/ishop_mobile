import 'dart:convert';

import 'package:ishop_mobile/core/formatters.dart';
import 'package:ishop_mobile/core/validators.dart';
import 'package:ishop_mobile/data/api/api_client.dart';
import 'package:ishop_mobile/data/api/admin_api.dart';
import 'package:ishop_mobile/data/api/cart_api.dart';
import 'package:ishop_mobile/data/api/product_api.dart';
import 'package:ishop_mobile/data/models/api_error.dart';
import 'package:ishop_mobile/data/models/auth_response.dart';
import 'package:ishop_mobile/data/models/cart.dart';
import 'package:ishop_mobile/data/models/cron_status.dart';
import 'package:ishop_mobile/data/models/order.dart';
import 'package:ishop_mobile/data/models/product.dart';
import 'package:ishop_mobile/data/storage/token_storage.dart';
import 'package:ishop_mobile/widgets/pagination_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _userJson = {
  'id': '7f1d2c3b-1111-4222-8333-944455556666',
  'firstName': 'Ada',
  'lastName': 'Admin',
  'email': 'admin@local.test',
  'enabled': true,
  'accountNonLocked': true,
  'roles': ['ADMIN'],
  'permissions': ['product:write'],
  'createdAt': '2026-11-06T08:21:13.021432300Z',
  'updatedAt': '2026-11-06T08:21:13.021432300Z',
};

Map<String, dynamic> _auth(String access, String refresh) => {
  'tokenType': 'Bearer',
  'accessToken': access,
  'refreshToken': refresh,
  'accessTokenExpiresInSeconds': 3600,
  'refreshTokenExpiresInSeconds': 604800,
  'user': _userJson,
};

const _productJson = {
  'id': '0b6f8a52-4c1e-4c35-9a0e-2f3c1d5e7a90',
  'name': 'Pixel Phone',
  'sku': 'PX-1',
  'description': null,
  'unitPrice': 1299.99,
  'quantityInStock': 3,
  'active': true,
  'createdAt': '2026-11-06T08:21:13.021432300Z',
  'updatedAt': '2026-11-06T08:21:13Z',
};

const _pid = '10000000-0000-0000-0000-000000000001';

Map<String, dynamic> _cartJson({bool available = true}) => {
  'id': 'c0000000-0000-0000-0000-000000000001',
  'customerId': 'd0000000-0000-0000-0000-000000000001',
  'items': [
    {
      'id': 'e0000000-0000-0000-0000-000000000001',
      'productId': _pid,
      'productName': 'Pixel Phone',
      'sku': 'PX-1',
      'thumbnail': 'https://cdn.example.com/p1.webp',
      'unitPrice': 10.5,
      'quantity': 2,
      'lineTotal': 21,
      'quantityInStock': 7,
      'available': available,
      'addedAt': '2026-11-09T10:00:00.123456789Z',
    },
  ],
  'totalQuantity': 2,
  'totalAmount': 21,
  'createdAt': '2026-11-09T10:00:00Z',
  'updatedAt': '2026-11-09T10:00:00Z',
};

Future<TokenStorage> _storageWith({String? access, String? refresh}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await TokenStorage.create();
  if (access != null) {
    await storage.save(AuthResponse.fromJson(_auth(access, refresh ?? 'r0')));
  }
  return storage;
}

void main() {
  setUpAll(() => initializeDateFormatting('en_US'));

  group('models', () {
    test('ProductResponse parses 9-digit fractional ISO timestamps', () {
      final p = ProductResponse.fromJson(Map.of(_productJson));
      expect(p.unitPrice, 1299.99);
      expect(p.createdAt.isUtc, isTrue);
      expect(p.stockLevel, StockLevel.low);
      expect(p.description, isNull);
    });

    test('CronStatusResponse keeps nulls', () {
      final c = CronStatusResponse.fromJson({
        'lastMinuteRun': '2026-11-06T08:21:13Z',
        'lastMidnightRun': null,
        'lastSundayRun': null,
        'lastMinuteReportId': 'r1',
        'lastMidnightReportId': null,
        'lastSundayReportId': null,
      });
      expect(c.lastMinuteRun, isNotNull);
      expect(c.lastMidnightRun, isNull);
    });

    test('ProductResponse defaults images to [] and picks a cover', () {
      final p = ProductResponse.fromJson(Map.of(_productJson));
      expect(p.images, isEmpty);
      expect(p.thumbnail, isNull);
      expect(p.coverImage, isNull);
      expect(p.galleryImages, isEmpty);

      final withImages = ProductResponse.fromJson({
        ..._productJson,
        'thumbnail': 'https://x/t.webp',
        'images': ['https://x/1.webp', 'https://x/2.webp'],
      });
      expect(withImages.coverImage, 'https://x/t.webp');
      expect(withImages.galleryImages, hasLength(2));

      final thumbOnly = ProductResponse.fromJson({
        ..._productJson,
        'thumbnail': 'https://x/t.webp',
        'images': <String>[],
      });
      expect(thumbOnly.galleryImages, ['https://x/t.webp']);
    });

    test('ProductRequest always sends thumbnail and images', () {
      const r = ProductRequest(
        name: 'A',
        sku: 'B',
        unitPrice: 1,
        quantityInStock: 0,
        images: ['https://x/1.webp'],
      );
      final json = r.toJson();
      expect(json.containsKey('thumbnail'), isTrue);
      expect(json['images'], ['https://x/1.webp']);
    });

    test('Cart parses items, totals and availability', () {
      final cart = Cart.fromJson(_cartJson(available: false));
      expect(cart.items.single.lineTotal, 21.0);
      expect(cart.totalAmount, 21.0);
      expect(cart.quantityOf(_pid), 2);
      expect(cart.quantityOf('other'), 0);
      expect(cart.hasUnavailableItems, isTrue);
    });

    test('Order parses userId, item thumbnail and status', () {
      final order = OrderResponse.fromJson({
        'id': 'f0000000-0000-0000-0000-000000000001',
        'orderNumber': 'ORD-1',
        'orderDate': '2026-11-09T10:00:00.5Z',
        'totalAmount': 21,
        'status': 'PENDING',
        'customer': {
          'id': 'd0000000-0000-0000-0000-000000000001',
          'userId': null,
          'firstName': 'Sophia',
          'lastName': 'Carter',
          'email': 'sophia.carter@example.com',
          'phone': null,
          'address': null,
          'createdAt': '2026-11-09T10:00:00Z',
          'updatedAt': '2026-11-09T10:00:00Z',
        },
        'items': [
          {
            'id': 'e0000000-0000-0000-0000-000000000002',
            'productId': _pid,
            'productName': 'Pixel Phone',
            'thumbnail': 'https://x/t.webp',
            'quantity': 2,
            'unitPrice': 10.5,
            'lineTotal': 21,
          },
        ],
        'createdAt': '2026-11-09T10:00:00Z',
        'updatedAt': '2026-11-09T10:00:00Z',
      });
      expect(order.isPending, isTrue);
      expect(order.customer.userId, isNull);
      expect(order.items.single.thumbnail, 'https://x/t.webp');
      expect(order.totalQuantity, 2);
    });

    test('ProductRequest omits null active', () {
      const r = ProductRequest(
        name: 'A',
        sku: 'B',
        unitPrice: 1,
        quantityInStock: 0,
      );
      expect(r.toJson().containsKey('active'), isFalse);
    });
  });

  group('formatters & validators', () {
    test('currency and date', () {
      expect(Formatters.currency(1299.99), r'$1,299.99');
      expect(
        Formatters.dateTime(DateTime(2026, 11, 6, 14, 5)),
        'Nov 6, 2026 14:05',
      );
    });

    test('pagination window', () {
      expect(PaginationBar.pageWindow(0, 3), [0, 1, 2]);
      expect(PaginationBar.pageWindow(0, 12), [0, 1, null, 11]);
      expect(PaginationBar.pageWindow(5, 12), [0, null, 4, 5, 6, null, 11]);
      expect(PaginationBar.pageWindow(11, 12), [0, null, 10, 11]);
    });

    test('uuid', () {
      expect(Validators.isUuid(_productJson['id'] as String), isTrue);
      expect(Validators.isUuid('abc'), isFalse);
    });
  });

  group('ApiClient', () {
    test('public requests never send Authorization', () async {
      final storage = await _storageWith(access: 'a1');
      String? seenAuth;
      final client = ApiClient(
        storage: storage,
        baseUrl: 'http://host:8080',
        httpClient: MockClient((req) async {
          seenAuth = req.headers['Authorization'];
          return http.Response(jsonEncode([_productJson]), 200);
        }),
      );
      final products = await ProductApi(client).list();
      expect(products, hasLength(1));
      expect(seenAuth, isNull);
    });

    test('cart add sends Bearer + productId/quantity body', () async {
      final storage = await _storageWith(access: 'a1');
      late http.Request seen;
      final client = ApiClient(
        storage: storage,
        baseUrl: 'http://host:8080',
        httpClient: MockClient((req) async {
          seen = req;
          return http.Response(jsonEncode(_cartJson()), 200);
        }),
      );
      final cart = await CartApi(client).addItem(_pid, 2);
      expect(seen.method, 'POST');
      expect(seen.url.path, '/api/operations/cart/items');
      expect(seen.headers['Authorization'], 'Bearer a1');
      expect(jsonDecode(seen.body), {'productId': _pid, 'quantity': 2});
      expect(cart.totalQuantity, 2);
    });

    test('checkout 400 surfaces the business-rule message', () async {
      final storage = await _storageWith(access: 'a1');
      final client = ApiClient(
        storage: storage,
        baseUrl: 'http://host:8080',
        httpClient: MockClient(
          (req) async => http.Response(
            jsonEncode({
              'timestamp': '2026-11-09T10:00:00Z',
              'status': 400,
              'error': 'Bad Request',
              'message': 'Cart is empty',
              'path': '/cart/checkout',
            }),
            400,
          ),
        ),
      );
      await expectLater(
        CartApi(client).checkout(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.badRequest)
              .having((e) => e.message, 'message', 'Cart is empty'),
        ),
      );
    });

    test('403 empty body -> refresh once, save both tokens, retry', () async {
      final storage = await _storageWith(access: 'old', refresh: 'r-old');
      final calls = <String>[];
      final client = ApiClient(
        storage: storage,
        baseUrl: 'http://host:8080',
        httpClient: MockClient((req) async {
          calls.add(
            '${req.method} ${req.url.path} ${req.headers['Authorization']}',
          );
          if (req.url.path == '/api/auth/refresh') {
            expect(jsonDecode(req.body), {'refreshToken': 'r-old'});
            return http.Response(jsonEncode(_auth('new', 'r-new')), 200);
          }
          if (req.headers['Authorization'] == 'Bearer old') {
            return http.Response('', 403);
          }
          return http.Response(jsonEncode([]), 200);
        }),
      );
      final orders = await AdminApi(client).orders();
      expect(orders, isEmpty);
      expect(storage.accessToken, 'new');
      expect(storage.refreshToken, 'r-new');
      expect(calls, [
        'GET /api/operations/orders Bearer old',
        'POST /api/auth/refresh null',
        'GET /api/operations/orders Bearer new',
      ]);
    });

    test('concurrent expired requests share one refresh', () async {
      final storage = await _storageWith(access: 'old', refresh: 'r-old');
      var refreshes = 0;
      final client = ApiClient(
        storage: storage,
        baseUrl: 'http://host:8080',
        httpClient: MockClient((req) async {
          if (req.url.path == '/api/auth/refresh') {
            refreshes++;
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return http.Response(jsonEncode(_auth('new', 'r-new')), 200);
          }
          if (req.headers['Authorization'] == 'Bearer old') {
            return http.Response('', 403);
          }
          return http.Response(
            jsonEncode({
              'totalProducts': 1,
              'activeProducts': 1,
              'totalStockQuantity': 3,
              'averagePrice': 10,
            }),
            200,
          );
        }),
      );
      final api = AdminApi(client);
      await Future.wait([
        api.productReport(),
        api.productReport(),
        api.productReport(),
      ]);
      expect(refreshes, 1);
    });

    test('403 with JSON body is a permission error, no refresh', () async {
      final storage = await _storageWith(access: 'a1');
      var refreshed = false;
      final client = ApiClient(
        storage: storage,
        baseUrl: 'http://host:8080',
        httpClient: MockClient((req) async {
          if (req.url.path == '/api/auth/refresh') refreshed = true;
          return http.Response(
            jsonEncode({
              'timestamp': '2026-11-06T08:21:13Z',
              'status': 403,
              'error': 'Forbidden',
              'message': 'Access denied',
              'path': '/api/reports/sales',
            }),
            403,
          );
        }),
      );
      await expectLater(
        AdminApi(client).salesReport(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.forbidden,
          ),
        ),
      );
      expect(refreshed, isFalse);
      expect(storage.accessToken, 'a1');
    });

    test('refresh 400 -> storage cleared, session expired callback', () async {
      final storage = await _storageWith(access: 'old', refresh: 'r-old');
      var expired = 0;
      final client = ApiClient(
        storage: storage,
        baseUrl: 'http://host:8080',
        httpClient: MockClient((req) async {
          if (req.url.path == '/api/auth/refresh') {
            return http.Response(
              jsonEncode({
                'timestamp': '',
                'status': 400,
                'error': 'Bad Request',
                'message': 'Refresh token is expired or revoked',
                'path': '/api/auth/refresh',
              }),
              400,
            );
          }
          return http.Response('', 403);
        }),
      )..onSessionExpired = () => expired++;
      await expectLater(
        AdminApi(client).cronStatus(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.sessionExpired,
          ),
        ),
      );
      expect(expired, 1);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    });

    test('400 validation exposes fieldErrors', () async {
      final storage = await _storageWith(access: 'a1');
      final client = ApiClient(
        storage: storage,
        baseUrl: 'http://host:8080',
        httpClient: MockClient(
          (req) async => http.Response(
            jsonEncode({
              'timestamp': '',
              'status': 400,
              'error': 'Bad Request',
              'message': 'Validation failed',
              'path': '/api/operations/products',
              'fieldErrors': {'sku': 'must not be blank'},
            }),
            400,
          ),
        ),
      );
      await expectLater(
        ProductApi(client).create(
          const ProductRequest(
            name: 'x',
            sku: '',
            unitPrice: 1,
            quantityInStock: 0,
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.fieldErrors['sku'],
            'sku',
            'must not be blank',
          ),
        ),
      );
    });
  });
}
