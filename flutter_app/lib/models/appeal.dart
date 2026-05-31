class Appeal {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String bookingId;
  final String spotId;
  final String zone;
  final String transactionId;
  final double penaltyAmount;
  final String reason;
  final String status;
  final String adminNote;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final DateTime createdAt;

  Appeal({
    required this.id,
    required this.userId,
    this.userName = '',
    this.userEmail = '',
    required this.bookingId,
    this.spotId = '',
    this.zone = '',
    required this.transactionId,
    required this.penaltyAmount,
    required this.reason,
    required this.status,
    required this.adminNote,
    this.resolvedAt,
    this.resolvedBy,
    required this.createdAt,
  });

  factory Appeal.fromJson(Map<String, dynamic> json) {
    String uId = '';
    String uName = '';
    String uEmail = '';
    if (json['userId'] != null) {
      if (json['userId'] is Map) {
        uId = json['userId']['_id'] ?? '';
        uName = json['userId']['name'] ?? '';
        uEmail = json['userId']['email'] ?? '';
      } else {
        uId = json['userId'].toString();
      }
    }

    String bId = '';
    String sId = '';
    String zName = '';
    if (json['bookingId'] != null) {
      if (json['bookingId'] is Map) {
        bId = json['bookingId']['_id'] ?? '';
        sId = json['bookingId']['spotId'] ?? '';
        zName = json['bookingId']['zone'] ?? '';
      } else {
        bId = json['bookingId'].toString();
      }
    }

    String tId = '';
    if (json['transactionId'] != null) {
      if (json['transactionId'] is Map) {
        tId = json['transactionId']['_id'] ?? '';
      } else {
        tId = json['transactionId'].toString();
      }
    }

    return Appeal(
      id: json['_id'] ?? json['id'] ?? '',
      userId: uId,
      userName: uName,
      userEmail: uEmail,
      bookingId: bId,
      spotId: sId,
      zone: zName,
      transactionId: tId,
      penaltyAmount: (json['penaltyAmount'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      adminNote: json['adminNote'] ?? '',
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      resolvedBy: json['resolvedBy']?.toString(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
