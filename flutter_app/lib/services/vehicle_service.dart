import '../models/vehicle.dart';
import 'api_constants.dart';
import 'api_service.dart';

class VehicleService {
  static Future<List<Vehicle>> getVehicles() async {
    final response = await ApiService.get(ApiConstants.vehicles);
    if (response is List) {
      return response.map((v) => Vehicle.fromJson(v)).toList();
    }
    return [];
  }

  static Future<Vehicle> addVehicle({
    required String licensePlate,
    required String brand,
    required String model,
    required String color,
  }) async {
    final response = await ApiService.post(ApiConstants.vehicles, {
      'licensePlate': licensePlate,
      'brand': brand,
      'model': model,
      'color': color,
    });
    return Vehicle.fromJson(response);
  }

  static Future<void> deleteVehicle(String id) async {
    await ApiService.delete(ApiConstants.deleteVehicle(id));
  }
}
