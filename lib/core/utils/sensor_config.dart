import '../../models/sample_type.dart';
import '../../models/sensor_reading_model.dart';

class SensorSpec {
  final String label;
  final String meaning;
  final String Function(SensorReadingModel) valueText;

  SensorSpec({
    required this.label,
    required this.meaning,
    required this.valueText,
  });
}

class SensorConfig {
  static List<SensorSpec> forSampleType(SampleType type) {
    // Both milk and water share the exact same formatting rules now
    // to match the live ESP32 screen formatting perfectly.
    return [
      SensorSpec(
        label: 'pH Level',
        meaning: 'Souring / spoilage',
        valueText: (r) => r.ph.toStringAsFixed(1),
      ),
      SensorSpec(
        label: 'TDS / EC',
        meaning: 'Added water, starch, detergent',
        valueText: (r) => '${r.tds.toInt()} ppm',
      ),
      SensorSpec(
        label: 'Turbidity',
        meaning: 'Dilution, thickening agents',
        valueText: (r) => '${r.turbidity.toInt()} NTU',
      ),
      SensorSpec(
        label: 'Gas Sensors',
        meaning: 'MQ135 (Air/Ammonia) | MQ3 (Alcohol/Urea)',
        // Matches the live screen's dual gas output
        valueText: (r) => 'MQ135: ${r.gas.toInt()} | MQ3: ${r.gasMq3.toInt()}',
      ),
      SensorSpec(
        label: 'Temperature',
        meaning: 'Safe storage temperature check',
        valueText: (r) => '${r.temperature.toStringAsFixed(2)} °C',
      ),
      SensorSpec(
        label: 'Color (RGB)',
        meaning: 'Whiteness / tint shift from dilution',
        // Matches the live screen's R: G: B: output instead of Hex
        valueText: (r) => 'R:${r.colorR} G:${r.colorG} B:${r.colorB}',
      ),
    ];
  }
}
