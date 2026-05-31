import '../models/appeal.dart';
import 'api_service.dart';
import 'api_constants.dart';

class AppealService {
  static Future<Appeal> submitAppeal({
    required String bookingId,
    required String transactionId,
    required double penaltyAmount,
    required String reason,
  }) async {
    final response = await ApiService.post(ApiConstants.submitAppeal, {
      'bookingId': bookingId,
      'transactionId': transactionId,
      'penaltyAmount': penaltyAmount,
      'reason': reason,
    });
    return Appeal.fromJson(response);
  }

  static Future<List<Appeal>> fetchMyAppeals() async {
    final response = await ApiService.get(ApiConstants.myAppeals);
    if (response is List) {
      return response.map((a) => Appeal.fromJson(a)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchPendingAppeals({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await ApiService.get(
      '${ApiConstants.adminAppeals}?page=$page&limit=$limit'
    );
    return Map<String, dynamic>.from(response);
  }

  static Future<Appeal> resolveAppeal({
    required String appealId,
    required String decision,
    required String adminNote,
  }) async {
    final response = await ApiService.patch(ApiConstants.resolveAppeal(appealId), {
      'decision': decision,
      'adminNote': adminNote,
    });
    return Appeal.fromJson(response);
  }

  static Future<Appeal> fetchAppealById(String appealId) async {
    final response = await ApiService.get('${ApiConstants.baseUrl}/appeals/$appealId');
    return Appeal.fromJson(response);
  }

  static Future<List<dynamic>> fetchPenaltyTransactions() async {
    final response = await ApiService.get('${ApiConstants.baseUrl}/transactions?type=penalty');
    return response as List<dynamic>;
  }
}
