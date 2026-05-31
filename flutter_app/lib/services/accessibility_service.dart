import '../models/user.dart';
import '../models/parking_spot.dart';
import 'api_service.dart';
import 'api_constants.dart';

class AccessibilityService {
  static Future<Map<String, dynamic>> applyForPermit({
    required String disabilityType,
    required String conditionDescription,
  }) async {
    final response = await ApiService.post(
      ApiConstants.applyAccessibilityPermit,
      {
        'disabilityType': disabilityType,
        'conditionDescription': conditionDescription,
      },
    );
    return Map<String, dynamic>.from(response);
  }

  static Future<AccessibilityPermit> fetchMyPermit() async {
    final response = await ApiService.get(ApiConstants.myAccessibilityPermit);
    return AccessibilityPermit.fromJson(response);
  }

  static Future<List<User>> fetchPendingApplications() async {
    final response = await ApiService.get(ApiConstants.adminAccessibilityApplications);
    if (response is List) {
      return response.map((u) => User.fromJson(u)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> resolveApplication({
    required String userId,
    required String decision, // 'approved' or 'rejected'
    required String adminNote,
  }) async {
    final response = await ApiService.patch(
      ApiConstants.resolveAccessibilityApplication(userId),
      {
        'decision': decision,
        'adminNote': adminNote,
      },
    );
    return Map<String, dynamic>.from(response);
  }

  static Future<ParkingSpot> toggleSpotAccessibility({
    required String spotId,
    required bool isAccessibility,
    required String accessibilityLabel,
  }) async {
    final response = await ApiService.patch(
      ApiConstants.toggleSpotAccessibility(spotId),
      {
        'isAccessibility': isAccessibility,
        'accessibilityLabel': accessibilityLabel,
      },
    );
    return ParkingSpot.fromJson(response);
  }

  static Future<Map<String, dynamic>> dismissNotification() async {
    final response = await ApiService.patch(
      '${ApiConstants.baseUrl}/accessibility/my-permit/dismiss-notification',
    );
    return Map<String, dynamic>.from(response);
  }
}
