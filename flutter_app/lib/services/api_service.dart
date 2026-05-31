import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_constants.dart';
import '../models/parking_spot.dart';

class ApiService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String url) async {
    final response = await http.get(Uri.parse(url), headers: await _headers());
    return _handleResponse(response);
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> patch(String url, [Map<String, dynamic>? body]) async {
    final response = await http.patch(
      Uri.parse(url),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String url) async {
    final response = await http.delete(Uri.parse(url), headers: await _headers());
    return _handleResponse(response);
  }

  static Future<dynamic> rechargeWallet(double amount) async {
    return await post('${ApiConstants.baseUrl}/payments/recharge', {'amount': amount});
  }

  static Future<dynamic> processPayment(double amount) async {
    return await post('${ApiConstants.baseUrl}/payments/pay', {'amount': amount});
  }

  static Future<List<dynamic>> getTransactionHistory() async {
    final response = await get('${ApiConstants.baseUrl}/payments/history');
    return response as List<dynamic>;
  }

  static Future<ParkingSpot?> getNearestSpot(double refX, double refY) async {
    try {
      final response = await get('${ApiConstants.baseUrl}/spots/nearest?x=$refX&y=$refY');
      return ParkingSpot.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Request failed: ${response.statusCode}');
  }
}
