import 'dart:convert';
import 'package:http/http.dart' as http;

class PredictionService {
  // IF USING PHYSICAL ANDROID PHONE: Replace 192.168.X.X with your PC IPv4 address
  // IF USING ANDROID EMULATOR: Keep http://10.0.2.2:5000
  static const String baseUrl = 'https://hifazat-ml-backend.onrender.com';

  static Future<Map<String, dynamic>> classifySample(
    Map<String, dynamic> sensorData,
  ) async {
    final url = Uri.parse('$baseUrl/predict');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sensorData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Could not connect to Flask Server: $e');
    }
  }
}
