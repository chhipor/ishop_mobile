import '../models/cron_status.dart';
import '../models/order.dart';
import '../models/reports.dart';
import 'api_client.dart';

class AdminApi {
  AdminApi(this._client);

  final ApiClient _client;

  Future<List<OrderResponse>> orders() async {
    final json =
        await _client.get('/api/operations/orders', auth: true)
            as List<dynamic>;
    return json
        .map((e) => OrderResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductReportResponse> productReport() async =>
      ProductReportResponse.fromJson(await _map('/api/reports/products'));

  Future<OrderReportResponse> orderReport() async =>
      OrderReportResponse.fromJson(await _map('/api/reports/orders'));

  Future<CustomerReportResponse> customerReport() async =>
      CustomerReportResponse.fromJson(await _map('/api/reports/customers'));

  Future<SalesReportResponse> salesReport() async =>
      SalesReportResponse.fromJson(await _map('/api/reports/sales'));

  Future<CronStatusResponse> cronStatus() async =>
      CronStatusResponse.fromJson(await _map('/api/jobs/status'));

  Future<Map<String, dynamic>> _map(String path) async =>
      await _client.get(path, auth: true) as Map<String, dynamic>;
}
