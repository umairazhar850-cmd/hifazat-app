import 'package:cloud_firestore/cloud_firestore.dart';

/// Scope document, Module 8: "Add area-based safety alert broadcast to
/// users." An admin/authority publishes a warning for a named area
/// ("Avoid tap water in Mandian, Abbottabad this week") and every user sees
/// it on their home screen.
///
/// This writes the alert document to Firestore. Actually PUSHING it to
/// devices as a notification requires a Cloud Function listening on this
/// collection and calling FCM — that lives on the backend, not in the app.
/// The app already depends on firebase_messaging, so the device side is
/// ready; the trigger function is the remaining piece.
class AlertModel {
  final String id;
  final String title;
  final String body;
  final String area; // free-text area/city name, e.g. "Mandian, Abbottabad"
  final AlertSeverityLevel level;
  final String createdBy; // admin uid
  final DateTime createdAt;
  final bool active;

  AlertModel({
    required this.id,
    required this.title,
    required this.body,
    required this.area,
    required this.level,
    required this.createdBy,
    required this.createdAt,
    required this.active,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'area': area,
      'level': level.name,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'active': active,
    };
  }

  factory AlertModel.fromMap(String id, Map<String, dynamic> map) {
    return AlertModel(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      area: map['area'] as String? ?? '',
      level: AlertSeverityLevelX.fromName(map['level'] as String?),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: map['active'] as bool? ?? true,
    );
  }
}

enum AlertSeverityLevel { info, warning, danger }

extension AlertSeverityLevelX on AlertSeverityLevel {
  String get label {
    switch (this) {
      case AlertSeverityLevel.info:
        return 'Information';
      case AlertSeverityLevel.warning:
        return 'Warning';
      case AlertSeverityLevel.danger:
        return 'Danger';
    }
  }

  static AlertSeverityLevel fromName(String? name) {
    return AlertSeverityLevel.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AlertSeverityLevel.info,
    );
  }
}
