/// Aggregate, anonymized stats computed across ALL users' tests — this is the
/// data that would be exported/shared with regulatory bodies, health
/// departments, or NGOs. No individual user data is exposed, only counts and
/// frequencies.
///
/// [totalTests] deliberately counts only CONCLUSIVE tests. Inconclusive
/// readings (confidence below 80%) are tracked separately in
/// [inconclusiveCount] so they're visible as a data-quality signal, but they
/// never contaminate the safe/unsafe percentages a health authority would act
/// on.
class CommunityStatsModel {
  final int totalTests;
  final int safeCount;
  final int cautionCount;
  final int unsafeCount;
  final int inconclusiveCount;

  /// Mean milk purity across all conclusive milk tests. Null when no milk has
  /// been tested yet.
  final double? averageMilkPurity;

  final Map<String, int> contaminantFrequency; // contaminant -> count
  final Map<String, int> sampleTypeFrequency; // 'Water'/'Milk' -> count

  CommunityStatsModel({
    required this.totalTests,
    required this.safeCount,
    required this.cautionCount,
    required this.unsafeCount,
    required this.contaminantFrequency,
    required this.sampleTypeFrequency,
    this.inconclusiveCount = 0,
    this.averageMilkPurity,
  });

  factory CommunityStatsModel.empty() {
    return CommunityStatsModel(
      totalTests: 0,
      safeCount: 0,
      cautionCount: 0,
      unsafeCount: 0,
      inconclusiveCount: 0,
      averageMilkPurity: null,
      contaminantFrequency: {},
      sampleTypeFrequency: {},
    );
  }

  double get unsafePercent =>
      totalTests == 0 ? 0 : (unsafeCount / totalTests) * 100;
  double get cautionPercent =>
      totalTests == 0 ? 0 : (cautionCount / totalTests) * 100;
  double get safePercent =>
      totalTests == 0 ? 0 : (safeCount / totalTests) * 100;

  /// How much of the raw data the model wasn't confident enough to use. A high
  /// value here is a hardware/calibration signal worth surfacing, not
  /// something to hide.
  double get inconclusiveRate {
    final all = totalTests + inconclusiveCount;
    return all == 0 ? 0 : (inconclusiveCount / all) * 100;
  }

  /// Top N contaminants sorted by frequency, descending.
  List<MapEntry<String, int>> topContaminants({int limit = 3}) {
    final entries = contaminantFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  String get mostTestedSampleType {
    if (sampleTypeFrequency.isEmpty) return '—';
    final sorted = sampleTypeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}
