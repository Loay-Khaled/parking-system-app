import '../models/parking_spot.dart';
import 'api_constants.dart';
import 'api_service.dart';

class RecommendationService {
  static Future<Map<String, dynamic>> fetchRecommendations() async {
    final response = await ApiService.get(ApiConstants.recommendations);
    
    final preferredZone = response['preferredZone'] as String?;
    final message = response['message'] as String? ?? '';
    final zoneCounts = Map<String, int>.from(response['zoneCounts'] ?? {});
    
    final spotsList = response['recommendedSpots'] as List? ?? [];
    final recommendedSpots = spotsList.map((s) => ParkingSpot.fromJson(s)).toList();
    
    return {
      'preferredZone': preferredZone,
      'zoneCounts': zoneCounts,
      'recommendedSpots': recommendedSpots,
      'message': message,
    };
  }
}
