/// Project-wide constants that come straight from the HIFAZAT scope
/// document. Keeping them in one place means the rules stated in the FYP
/// scope are enforced from a single source of truth rather than being
/// re-typed (and drifting) across screens.
class AppConstants {
  AppConstants._();

  /// Scope document, "Problem Solution" + "Advantages" sections:
  ///
  ///   "An 80% confidence threshold is used: if the model is not confident
  ///    enough, the app tells the user to re-test rather than risk a wrong
  ///    answer."
  ///
  /// This is a SAFETY requirement, not a UI preference. Below this value
  /// the app must NOT present a SAFE/UNSAFE verdict at all.
  static const double confidenceThreshold = 0.80;

  /// A vendor trust score computed from only one or two tests is noise, not
  /// signal. Below this count we show "Not enough data yet" instead of a
  /// misleading percentage.
  static const int minTestsForTrustScore = 5;

  /// Milk purity below this is treated as meaningfully adulterated even if
  /// the classifier hasn't named a specific contaminant.
  static const double milkPurityConcernThreshold = 90.0;
}
