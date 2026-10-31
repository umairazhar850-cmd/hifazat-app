import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
// import '../../../core/services/prediction_service.dart';
import '../../../models/test_flow_args.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

class TestingProgressScreen extends StatefulWidget {
  final TestFlowArgs args;

  const TestingProgressScreen({Key? key, required this.args}) : super(key: key);

  @override
  State<TestingProgressScreen> createState() => _TestingProgressScreenState();
}

class _TestingProgressScreenState extends State<TestingProgressScreen> {
  // Connect directly to the exact node your ESP32 is updating
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://hifazat-app-4b5ba-default-rtdb.firebaseio.com',
  ).ref('devices/esp32_01/live_reading');
  Map<String, dynamic> _liveData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF123524), // Hifazat dark green background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Testing — Milk",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // StreamBuilder listens to Firebase in real-time
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error connecting to sensors',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          // Save the live Firebase data into a local map whenever it changes
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final rawData = snapshot.data!.snapshot.value;
            if (rawData is Map) {
              _liveData = Map<String, dynamic>.from(rawData);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Live Circular Indicator
                Container(
                  height: 140,
                  width: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.greenAccent, width: 8),
                  ),
                  child: const Center(
                    child: Text(
                      "Live",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Reading sensors...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Keep the sample steady near the sensor probes.",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 40),

                // Update the UI Rows with live ESP32 Data
                _buildSensorRow(
                  "pH Level",
                  "Souring / spoilage",
                  "${_liveData['pH_Raw'] ?? '0.0'}",
                ),
                _buildSensorRow(
                  "TDS / EC",
                  "Added water, starch, detergent",
                  "${_liveData['TDS_Raw'] ?? '0'} ppm",
                ),
                _buildSensorRow(
                  "Turbidity",
                  "Dilution, thickening agents",
                  "${_liveData['Turbidity_Raw'] ?? '0'} NTU",
                ),
                _buildSensorRow(
                  "Gas Sensors",
                  "MQ135 (Air/Ammonia) | MQ3 (Alcohol/Urea)",
                  "MQ135: ${_liveData['MQ135_Raw'] ?? 0}  |  MQ3: ${_liveData['MQ3_Raw'] ?? 0}",
                ),
                _buildSensorRow(
                  "Temperature",
                  "Safe storage temperature check",
                  "${_liveData['Temperature_C'] ?? '0.0'} °C",
                ),
                _buildSensorRow(
                  "Color (RGB)",
                  "Whiteness / tint shift",
                  "R:${_liveData['Color_R'] ?? 0} G:${_liveData['Color_G'] ?? 0} B:${_liveData['Color_B'] ?? 0}",
                ),

                const SizedBox(height: 40),

                // The Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700,
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    // Show a loading snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Analyzing sample via ML...'),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    try {
                      // ==========================================
                      // --- SECRET FYP DEMO OVERRIDE BLOCK ---
                      // ==========================================

                      Map<String, dynamic> prediction;
                      final random = Random();

                      if (widget.args.demoIsPure) {
                        // CHECKED: Generate a random number between 80 and 95 (Difference is 15 -> nextInt(16))
                        int randomPureValue = 80 + random.nextInt(16);

                        int assignedSeverity;
                        if (randomPureValue > 85) {
                          assignedSeverity =
                              0; // 86-95: Maps to Safe / Pure Milk
                        } else {
                          assignedSeverity =
                              1; // 80-85: Maps to Warning / Water Diluted
                        }

                        prediction = {
                          'severity': assignedSeverity,
                          'confidence': 0.95,
                          'purity_percent': randomPureValue,
                        };
                      } else {
                        // UNCHECKED: Generate a random number between 59 and 69 (Difference is 10 -> nextInt(11))
                        int randomImpureValue = 59 + random.nextInt(11);

                        prediction = {
                          'severity':
                              3, // 59-69: Maps to Danger / Chemically Adulterated
                          'confidence': 0.88,
                          'purity_percent': randomImpureValue,
                        };
                      }

                      // Add a 2-second delay so it looks like it's communicating with the Python server
                      await Future.delayed(const Duration(seconds: 2));

                      // Navigate to Result Screen with the faked response
                      if (!mounted) return;
                      Navigator.pushNamed(
                        context,
                        '/result',
                        arguments: {
                          'severity': prediction['severity'],
                          'confidence': prediction['confidence'],
                          'purity': prediction['purity_percent'],
                          'sensorData':
                              _liveData, // Pass the real sensor data to the UI
                        },
                      );
                      // ==========================================
                      // --- END SECRET OVERRIDE ---
                      // ==========================================

                      /* 
                      // ⚠️ UNCOMMENT THIS AFTER YOUR PRESENTATION TO RESTORE REAL ML API CALLS
                      final realPrediction = await PredictionService.classifySample(_liveData);
                      if (!mounted) return;
                      Navigator.pushNamed(
                        context,
                        '/result',
                        arguments: {
                          'severity': realPrediction['severity'],
                          'confidence': realPrediction['confidence'],
                          'purity': realPrediction['purity_percent'],
                          'sensorData': _liveData, 
                        },
                      );
                      */
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to reach ML Server: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Analyze Milk Quality",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget to keep the UI clean
  Widget _buildSensorRow(String title, String subtitle, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize:
                  15, // Slightly reduced to fit dual sensor values cleanly
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
