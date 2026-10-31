# 🛡️ HIFAZAT — Smart IoT Milk & Water Safety Screening System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![ESP32](https://img.shields.io/badge/Hardware-ESP32-E7352C?logo=espressif&logoColor=white)](https://www.espressif.com/)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**HIFAZAT** is an IoT-enabled handheld safety and quality screening device designed for real-time preliminary analysis of milk and water. By combining a multi-sensor array driven by an ESP32 microcontroller with a Flutter mobile application, HIFAZAT detects physical, chemical, and gas-based contamination anomalies instantly.

---

## 📌 Key Features

- **⚡ Real-Time Telemetry:** Syncs continuous sensor readings from hardware to mobile interface via Firebase in real time.
- **🔬 Multi-Parameter Screening:** Evaluates temperature, total dissolved solids (TDS), clarity, color profile, and volatile organic compound emissions.
- **📱 Cross-Platform Flutter App:** Clean, modern UI providing instant quality indicators, historical logs, and safety metrics.
- **⚠️ Anomaly Alerts:** Flags potential adulteration or thermal spoofing before consumption or storage.

---

## 🛠️ System Architecture & Technology Stack

### **Hardware & Sensors**
- **Microcontroller:** ESP32 Wi-Fi / Bluetooth Dual-Core MCU
- **Temperature Sensor:** DS18B20 (Waterproof digital probe)
- **Water Purity:** Analog TDS Sensor & Turbidity Sensor
- **Color Analysis:** TCS34725 RGB Color Light Sensor with IR Filter
- **Gas / Volatiles Detection:** MQ-135 (Air Quality/Ammonia) & MQ-3 (Alcohol/Organic vapors)

### **Software & Cloud**
- **Mobile Framework:** Flutter (Dart)
- **State Management:** GetX / Provider architecture
- **Cloud Backend:** Firebase Realtime Database & Authentication
- **Firmware Development:** C++ (Arduino IDE / PlatformIO)

---

## 📊 Sensor Functionality Matrix

| Sensor | Parameter Monitored | Primary Safety Use Case |
| :--- | :--- | :--- |
| **DS18B20** | Temperature (°C) | Thermal storage check & density adjustment |
| **TDS Sensor** | Total Dissolved Solids (ppm) | Chemical adulteration & mineral concentration |
| **Turbidity Sensor** | Fluid Optical Clarity (NTU) | Suspended solids & dilution verification |
| **TCS34725** | RGB Color Profile | Synthetic whitening agent & dye detection |
| **MQ-135 / MQ-3** | Gas Vapors & Volatiles | Spoilage, fermentation, & chemical additive gas detection |

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your development machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.0.0`)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter & Dart extensions

### Flutter Application Setup

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/umairazhar850-cmd/hifazat-app.git](https://github.com/umairazhar850-cmd/hifazat-app.git)
   cd hifazat-app
