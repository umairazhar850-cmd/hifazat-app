import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// Scope document: vendors "register their business, undergo admin
/// verification, and receive a public trust score derived from verified test
/// results."
enum VerificationStatus { pending, verified, rejected }

extension VerificationStatusX on VerificationStatus {
  String get label {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending review';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }

  static VerificationStatus fromName(String? name) {
    return VerificationStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => VerificationStatus.pending,
    );
  }
}

enum BusinessType { milk, water, both }

extension BusinessTypeX on BusinessType {
  String get label {
    switch (this) {
      case BusinessType.milk:
        return 'Milk / Dairy';
      case BusinessType.water:
        return 'Water Supply';
      case BusinessType.both:
        return 'Milk & Water';
    }
  }

  static BusinessType fromName(String? name) {
    return BusinessType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => BusinessType.milk,
    );
  }
}

class VendorModel {
  /// Same as the vendor user's Firebase Auth uid — one vendor doc per vendor
  /// account, so there is never an ambiguity about which user owns a shop.
  final String vendorId;
  final String businessName;
  final BusinessType businessType;
  final String address;
  final String city;

  /// CNIC or business registration number, entered as text.
  ///
  /// NOTE: the scope document says vendors upload a *document* for
  /// verification. Real file upload needs `firebase_storage` +
  /// `image_picker`, which are not in this project's pubspec yet. Rather
  /// than silently add packages you'd have to install, this collects the
  /// registration number and leaves the image upload as the one clearly
  /// marked TODO. See README_CHANGES.md.
  final String registrationNumber;

  final VerificationStatus verificationStatus;
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final String? verifiedBy; // admin uid

  /// Aggregates, incremented atomically each time a consumer tags a test to
  /// this vendor. Only CONCLUSIVE tests are counted (see the 80% rule) —
  /// an inconclusive reading must never move a vendor's score in either
  /// direction.
  final int totalTests;
  final int safeTests;

  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  VendorModel({
    required this.vendorId,
    required this.businessName,
    required this.businessType,
    required this.address,
    required this.city,
    required this.registrationNumber,
    required this.verificationStatus,
    required this.totalTests,
    required this.safeTests,
    required this.createdAt,
    this.rejectionReason,
    this.verifiedAt,
    this.verifiedBy,
    this.latitude,
    this.longitude,
  });

  // ---- Trust score -----------------------------------------------------

  bool get hasEnoughData => totalTests >= AppConstants.minTestsForTrustScore;

  /// Null when there isn't enough data to say anything honest. A "100% safe"
  /// badge earned from a single test is worse than no badge at all.
  double? get trustScore {
    if (!hasEnoughData || totalTests == 0) return null;
    return (safeTests / totalTests) * 100;
  }

  String get trustScoreLabel {
    final score = trustScore;
    if (score == null) {
      return 'Not enough data yet ($totalTests/${AppConstants.minTestsForTrustScore} tests)';
    }
    return '${score.toStringAsFixed(0)}% of $totalTests tests were safe';
  }

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  // ---- Firestore -------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'businessType': businessType.name,
      'address': address,
      'city': city,
      'registrationNumber': registrationNumber,
      'verificationStatus': verificationStatus.name,
      'rejectionReason': rejectionReason,
      'verifiedAt': verifiedAt == null ? null : Timestamp.fromDate(verifiedAt!),
      'verifiedBy': verifiedBy,
      'totalTests': totalTests,
      'safeTests': safeTests,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory VendorModel.fromMap(String vendorId, Map<String, dynamic> map) {
    return VendorModel(
      vendorId: vendorId,
      businessName: map['businessName'] as String? ?? '',
      businessType: BusinessTypeX.fromName(map['businessType'] as String?),
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      registrationNumber: map['registrationNumber'] as String? ?? '',
      verificationStatus: VerificationStatusX.fromName(
        map['verificationStatus'] as String?,
      ),
      rejectionReason: map['rejectionReason'] as String?,
      verifiedAt: (map['verifiedAt'] as Timestamp?)?.toDate(),
      verifiedBy: map['verifiedBy'] as String?,
      totalTests: (map['totalTests'] as num?)?.toInt() ?? 0,
      safeTests: (map['safeTests'] as num?)?.toInt() ?? 0,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
