class SensorReadingModel {
  final double ph;
  final double tds;
  final double turbidity;
  final double gas; // MQ135
  final double gasMq3; // Add this for MQ3
  final double temperature;
  final String colorHex;
  final int colorR; // Add raw Red
  final int colorG; // Add raw Green
  final int colorB; // Add raw Blue

  SensorReadingModel({
    required this.ph,
    required this.tds,
    required this.turbidity,
    required this.gas,
    required this.gasMq3,
    required this.temperature,
    required this.colorHex,
    required this.colorR,
    required this.colorG,
    required this.colorB,
  });

  factory SensorReadingModel.dummy() {
    return SensorReadingModel(
      ph: 7.2,
      tds: 320,
      turbidity: 4.1,
      gas: 180,
      gasMq3: 150,
      temperature: 26.5,
      colorHex: '#E8F5E9',
      colorR: 232,
      colorG: 245,
      colorB: 233,
    );
  }

  factory SensorReadingModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int r = (json['Color_R'] as num?)?.toInt() ?? 0;
    int g = (json['Color_G'] as num?)?.toInt() ?? 0;
    int b = (json['Color_B'] as num?)?.toInt() ?? 0;

    String hex = '#E8F5E9';
    if (json['colorHex'] != null) {
      hex = json['colorHex'].toString();
    } else if (r > 0 || g > 0 || b > 0) {
      hex =
          '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
              .toUpperCase();
    }

    return SensorReadingModel(
      ph: parseDouble(json['ph'] ?? json['pH_Raw']),
      tds: parseDouble(json['tds'] ?? json['TDS_Raw']),
      turbidity: parseDouble(json['turbidity'] ?? json['Turbidity_Raw']),
      gas: parseDouble(json['gas'] ?? json['MQ135_Raw']),
      gasMq3: parseDouble(json['gasMq3'] ?? json['MQ3_Raw']), // Map MQ3
      temperature: parseDouble(json['temperature'] ?? json['Temperature_C']),
      colorHex: hex,
      colorR: r,
      colorG: g,
      colorB: b,
    );
  }

  Map<String, dynamic> toJson() => {
    'ph': ph,
    'tds': tds,
    'turbidity': turbidity,
    'gas': gas,
    'gasMq3': gasMq3,
    'temperature': temperature,
    'colorHex': colorHex,
    'Color_R': colorR,
    'Color_G': colorG,
    'Color_B': colorB,
  };
}
