import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentLog {
  final String id;
  final String spokeId;
  final DateTime timestamp;
  final String alertType;
  final String severity;
  final String heuristicRule;
  final String ticketStatus;

  IncidentLog({
    required this.id,
    required this.spokeId,
    required this.timestamp,
    required this.alertType,
    required this.severity,
    required this.heuristicRule,
    required this.ticketStatus,
  });

  // READ: Kinokonvert ang Firestore JSON pabalik sa Dart Object
  factory IncidentLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return IncidentLog(
      id: doc.id,
      spokeId: data['spoke_id'] ?? 'UNKNOWN',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      alertType: data['alert_type'] ?? 'Unknown Anomaly',
      severity: data['severity'] ?? 'LOW',
      heuristicRule: data['heuristic_rule'] ?? 'No Rule Triggered',
      ticketStatus: data['ticket_status'] ?? 'OPEN',
    );
  }

  // CREATE/UPDATE: Kinokonvert ang Dart Object papuntang Firestore JSON
  Map<String, dynamic> toFirestore() {
    return {
      'spoke_id': spokeId,
      'timestamp': Timestamp.fromDate(timestamp),
      'alert_type': alertType,
      'severity': severity,
      'heuristic_rule': heuristicRule,
      'ticket_status': ticketStatus,
    };
  }
}