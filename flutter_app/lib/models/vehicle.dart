class Vehicle {
  final String id;
  final String licensePlate;
  final String brand;
  final String model;
  final String color;

  Vehicle({
    required this.id,
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.color,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? json['_id'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'licensePlate': licensePlate,
    'brand': brand,
    'model': model,
    'color': color,
  };
}
