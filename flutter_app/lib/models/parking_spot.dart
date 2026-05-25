class ParkingSpot {
  final String spotId;
  final String zone;
  final String status; // available | occupied | reserved
  final String? availableAt;

  ParkingSpot({
    required this.spotId,
    required this.zone,
    required this.status,
    this.availableAt,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      spotId: json['spotId'] ?? '',
      zone: json['zone'] ?? '',
      status: json['status'] ?? 'available',
      availableAt: json['availableAt'],
    );
  }

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isReserved => status == 'reserved';
}
