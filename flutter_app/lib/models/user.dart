class AccessibilityPermit {
  final String status; // none | pending | approved | rejected
  final String disabilityType;
  final String conditionDescription; // stores description text
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String adminNote;
  final bool notified;

  AccessibilityPermit({
    required this.status,
    required this.disabilityType,
    required this.conditionDescription,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.adminNote = '',
    this.notified = false,
  });

  factory AccessibilityPermit.fromJson(Map<String, dynamic> json) {
    return AccessibilityPermit(
      status: json['status'] ?? 'none',
      disabilityType: json['disabilityType'] ?? '',
      conditionDescription: json['conditionDescription'] ?? json['documentUrl'] ?? '',
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt'].toString()) : null,
      reviewedAt: json['reviewedAt'] != null ? DateTime.tryParse(json['reviewedAt'].toString()) : null,
      reviewedBy: json['reviewedBy']?.toString(),
      adminNote: json['adminNote'] ?? '',
      notified: json['notified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'disabilityType': disabilityType,
    'conditionDescription': conditionDescription,
    'submittedAt': submittedAt?.toIso8601String(),
    'reviewedAt': reviewedAt?.toIso8601String(),
    'reviewedBy': reviewedBy,
    'adminNote': adminNote,
    'notified': notified,
  };
}

class User {
  final String id;
  final String name;
  final String email;
  final String carPlate;
  final String idNumber;
  final int totalBookings;
  final double totalSpent;
  final double activePenalties;
  final double walletBalance;
  final bool isAdmin;
  final AccessibilityPermit accessibilityPermit;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.carPlate,
    required this.idNumber,
    this.totalBookings = 0,
    this.totalSpent = 0,
    this.activePenalties = 0,
    this.walletBalance = 0.0,
    this.isAdmin = false,
    required this.accessibilityPermit,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      carPlate: json['carPlate'] ?? '',
      idNumber: json['idNumber'] ?? '',
      totalBookings: json['totalBookings'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      activePenalties: (json['activePenalties'] ?? 0).toDouble(),
      walletBalance: (json['walletBalance'] ?? 0.0).toDouble(),
      isAdmin: json['isAdmin'] ?? false,
      accessibilityPermit: json['accessibilityPermit'] != null
          ? AccessibilityPermit.fromJson(json['accessibilityPermit'])
          : AccessibilityPermit(status: 'none', disabilityType: '', conditionDescription: ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'carPlate': carPlate,
    'idNumber': idNumber,
    'totalBookings': totalBookings,
    'totalSpent': totalSpent,
    'activePenalties': activePenalties,
    'walletBalance': walletBalance,
    'isAdmin': isAdmin,
    'accessibilityPermit': accessibilityPermit.toJson(),
  };
}
