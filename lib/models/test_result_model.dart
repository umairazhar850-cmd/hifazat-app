import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import 'sample_type.dart';
import 'sensor_reading_model.dart';

/// What the ML model itself returned.
enum ResultSeverity { safe, caution, unsafe }

/// What we are actually allowed to SHOW the user, after applying the 80%
/// confidence rule from the scope document. This is deliberately a separate
/// type from [ResultSeverity]: the model's raw opinion and the app's
/// presented verdict are not the same thing, and conflating them is how the
/// safety rule quietly gets bypassed.
enum DisplayVerdict { safe, caution, unsafe, inconclusive }

class TestResultModel {
  final String id;
  final SampleType sampleType;
  final ResultSeverity severity;
  final String? contaminant;
  final double confidence; // 0.0 - 1.0
  final SensorReadingModel reading;
  final DateTime testedAt;
  final double? latitude;
  final double? longitude;

  /// Milk only. 0-100. Null for water samples — water has no meaningful
  /// "purity percentage"; it is either within safe limits or it isn't.
  /// Scope document: the model "additionally estimates a purity percentage
  /// (e.g. 92% pure / 8% impure) so the user sees the degree of adulteration
  /// rather than only a binary result."
  final double? purityPercent;

  /// Optional. Set when the consumer tags this sample to a registered vendor
  /// ("this is milk I bought from Ahmed Dairy"). Feeds that vendor's public
  /// trust score.
  final String? vendorId;
  final String? vendorName;

  TestResultModel({
    required this.id,
    required this.sampleType,
    required this.severity,
    required this.contaminant,
    required this.confidence,
    required this.reading,
    required this.testedAt,
    this.latitude,
    this.longitude,
    this.purityPercent,
    this.vendorId,
    this.vendorName,
  });

  // ---- The 80% confidence rule ----------------------------------------

  bool get isInconclusive => confidence < AppConstants.confidenceThreshold;

  /// The ONLY thing the UI should ever render. Never render [severity]
  /// directly — go through this, so a low-confidence result can never leak
  /// out as a confident-looking SAFE or UNSAFE badge.
  DisplayVerdict get verdict {
    if (isInconclusive) return DisplayVerdict.inconclusive;
    switch (severity) {
      case ResultSeverity.safe:
        return DisplayVerdict.safe;
      case ResultSeverity.caution:
        return DisplayVerdict.caution;
      case ResultSeverity.unsafe:
        return DisplayVerdict.unsafe;
    }
  }

  /// Only conclusive results should count toward community stats, vendor
  /// trust scores, and the hotspot map. An inconclusive reading is an absence
  /// of information, not evidence of safety.
  bool get countsTowardStats => !isInconclusive;

  double? get impurityPercent =>
      purityPercent == null ? null : (100 - purityPercent!);

  // ---- Dummy data (until the ESP32 + ML API are wired in) --------------

  factory TestResultModel.dummy({required SampleType sampleType}) {
    final random = Random();

    // Vary the confidence so the INCONCLUSIVE path is actually reachable in
    // a demo instead of being dead code you can never show an examiner.
    final confidence = 0.62 + random.nextDouble() * 0.36; // 0.62 - 0.98

    final severity =
        ResultSeverity.values[random.nextInt(ResultSeverity.values.length)];

    double? purity;
    if (sampleType == SampleType.milk) {
      purity = switch (severity) {
        ResultSeverity.safe => 94 + random.nextDouble() * 6, // 94-100
        ResultSeverity.caution => 82 + random.nextDouble() * 10, // 82-92
        ResultSeverity.unsafe => 55 + random.nextDouble() * 25, // 55-80
      };
    }

    return TestResultModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sampleType: sampleType,
      severity: severity,
      contaminant: _dummyContaminant(sampleType, severity),
      confidence: confidence,
      reading: SensorReadingModel.dummy(),
      testedAt: DateTime.now(),
      purityPercent: purity,
    );
  }

  static String? _dummyContaminant(SampleType type, ResultSeverity severity) {
    if (severity == ResultSeverity.safe) return null;
    if (type == SampleType.water) {
      return severity == ResultSeverity.unsafe
          ? 'High turbidity + chemical contamination'
          : 'Elevated turbidity';
    }
    return severity == ResultSeverity.unsafe
        ? 'Urea / detergent adulteration'
        : 'Added water (dilution)';
  }

  // ---- Firestore ------------------------------------------------------

  /// Enums are stored as their name string (not index) so the data stays
  /// readable/stable even if you reorder the enum values later.
  Map<String, dynamic> toMap() {
    return {
      'sampleType': sampleType.name,
      'severity': severity.name,
      'contaminant': contaminant,
      'confidence': confidence,
      'reading': reading.toJson(),
      'testedAt': Timestamp.fromDate(testedAt),
      'latitude': latitude,
      'longitude': longitude,
      'purityPercent': purityPercent,
      'vendorId': vendorId,
      'vendorName': vendorName,
      // Denormalized so aggregate queries (community stats, vendor trust
      // score) can filter out low-confidence tests without re-deriving the
      // rule on every read.
      'isInconclusive': isInconclusive,
    };
  }

  factory TestResultModel.fromMap(String id, Map<String, dynamic> map) {
    return TestResultModel(
      id: id,
      sampleType: SampleType.values.firstWhere(
        (e) => e.name == map['sampleType'],
        orElse: () => SampleType.water,
      ),
      severity: ResultSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => ResultSeverity.caution,
      ),
      contaminant: map['contaminant'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      reading: SensorReadingModel.fromJson(
        Map<String, dynamic>.from(map['reading'] as Map),
      ),
      testedAt: (map['testedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      purityPercent: (map['purityPercent'] as num?)?.toDouble(),
      vendorId: map['vendorId'] as String?,
      vendorName: map['vendorName'] as String?,
    );
  }

  TestResultModel copyWith({String? vendorId, String? vendorName}) {
    return TestResultModel(
      id: id,
      sampleType: sampleType,
      severity: severity,
      contaminant: contaminant,
      confidence: confidence,
      reading: reading,
      testedAt: testedAt,
      latitude: latitude,
      longitude: longitude,
      purityPercent: purityPercent,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
    );
  }
}
