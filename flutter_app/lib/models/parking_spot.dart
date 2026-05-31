class ParkingSpot {
  final String spotId;
  final String zone;
  final String status; // available | occupied | reserved
  final String? availableAt;
  final double x;
  final double y;
  final int floor;
  final bool previouslyUsed;
  final bool isAccessibility;
  final String accessibilityLabel;

  ParkingSpot({
    required this.spotId,
    required this.zone,
    required this.status,
    this.availableAt,
    this.x = 0.0,
    this.y = 0.0,
    this.floor = 1,
    this.previouslyUsed = false,
    this.isAccessibility = false,
    this.accessibilityLabel = '',
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      spotId: json['spotId'] ?? '',
      zone: json['zone'] ?? '',
      status: json['status'] ?? 'available',
      availableAt: json['availableAt'],
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      floor: json['floor'] ?? 1,
      previouslyUsed: json['previouslyUsed'] ?? false,
      isAccessibility: json['isAccessibility'] ?? false,
      accessibilityLabel: json['accessibilityLabel'] ?? '',
    );
  }

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isReserved => status == 'reserved';
}
