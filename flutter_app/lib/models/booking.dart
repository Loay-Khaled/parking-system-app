class Booking {
  final String id;
  final String spotId;
  final String zone;
  final int duration;
  final double cost;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? qrCode;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final bool isCheckedIn;
  final bool isCheckedOut;
  final bool noShowCancelled;
  final bool reminderSent;
  final bool reminderAcknowledged;

  Booking({
    required this.id,
    required this.spotId,
    required this.zone,
    required this.duration,
    required this.cost,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.qrCode,
    this.checkedInAt,
    this.checkedOutAt,
    this.isCheckedIn = false,
    this.isCheckedOut = false,
    this.noShowCancelled = false,
    this.reminderSent = false,
    this.reminderAcknowledged = false,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      spotId: json['spotId'] ?? '',
      zone: json['zone'] ?? '',
      duration: json['duration'] ?? 0,
      cost: (json['cost'] ?? 0).toDouble(),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'] ?? 'active',
      qrCode: json['qrCode'],
      checkedInAt: json['checkedInAt'] != null ? DateTime.parse(json['checkedInAt']) : null,
      checkedOutAt: json['checkedOutAt'] != null ? DateTime.parse(json['checkedOutAt']) : null,
      isCheckedIn: json['isCheckedIn'] ?? false,
      isCheckedOut: json['isCheckedOut'] ?? false,
      noShowCancelled: json['noShowCancelled'] ?? false,
      reminderSent: json['reminderSent'] ?? false,
      reminderAcknowledged: json['reminderAcknowledged'] ?? false,
    );
  }

  bool get isActive => status == 'active';

  String get costDisplay => cost == 0 ? 'FREE' : '${cost.toInt()} EGP';

  String get timeRange {
    final start = '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} ${startTime.hour < 12 ? 'AM' : 'PM'}';
    final end = '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')} ${endTime.hour < 12 ? 'AM' : 'PM'}';
    return '$start - $end';
  }
}
