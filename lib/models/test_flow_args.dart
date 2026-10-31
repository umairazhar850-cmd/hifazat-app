import 'sample_type.dart';

/// Carries state through the testing flow (device connect -> progress ->
/// result). Previously the flow only passed a bare [SampleType]; it now also
/// needs to know whether the consumer is attributing this sample to a
/// registered vendor, because that's what feeds the vendor's public trust
/// score.
class TestFlowArgs {
  final SampleType sampleType;

  /// Null means "I'm just testing my own water/milk" — the common case.
  /// Non-null means "this is what I bought from this shop", and the result
  /// will count toward that shop's trust score.
  final String? vendorId;
  final String? vendorName;
  final bool demoIsPure;

  const TestFlowArgs({
    required this.sampleType,
    this.vendorId,
    this.vendorName,
    this.demoIsPure = false,
  });

  bool get hasVendor => vendorId != null;

  TestFlowArgs copyWith({String? vendorId, String? vendorName}) {
    return TestFlowArgs(
      sampleType: sampleType,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
    );
  }
}
