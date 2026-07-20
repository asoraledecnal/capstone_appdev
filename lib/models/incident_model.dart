import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed model for a single heuristic behavioral-analytics log
/// entry in the `incidents` collection.
///
/// Field names and enum values are kept in sync with the schema already
/// checked into `assets/firestore_schema_and_data.json`. Two values differ
/// from a first-draft spec that used different casing/wording:
///   - `severity` uses Title Case ('Low'/'Medium'/'High'/'Critical') to match
///     the committed schema, not SCREAMING_CASE. `AppColors.severityColor`
///     already lower-cases before comparing, so both render correctly.
///   - `ticketStatus` uses the schema's four-state lifecycle
///     ('Open'/'Investigating'/'Resolved'/'Mitigated') rather than a
///     three-state OPEN/IN PROGRESS/RESOLVED set, since that's what's
///     already documented for this collection.
///
/// `heuristicRule` is a genuinely new field (not in the original schema)
/// that records which heuristic rule fired — this is metadata only
/// (a rule name/tag), never a packet payload or personal data, so it stays
/// within the RA 10173 metadata-only constraint.
class IncidentLog {
  final String id; // Firestore document ID, e.g. INC-YYYYMMDD-XXX
  final String spokeId;
  final DateTime timestamp;
  final String alertType;
  final String severity; // Low | Medium | High | Critical
  final String heuristicRule;
  final String ticketStatus; // Open | Investigating | Resolved | Mitigated
  final String description;
  final String assignedTo;
  final String sourceIp;
  final String endpoint;
  final String actionTaken;

  const IncidentLog({
    required this.id,
    required this.spokeId,
    required this.timestamp,
    required this.alertType,
    required this.severity,
    required this.heuristicRule,
    required this.ticketStatus,
    this.description = '',
    this.assignedTo = '',
    this.sourceIp = '',
    this.endpoint = '',
    this.actionTaken = '',
  });

  static const List<String> alertTypes = [
    'High Latency',
    'IPsec Tunnel Down',
    'Port Scan Detected',
    'Brute Force Attempt',
    'DDoS Heuristic Threat',
    'Gateway Connectivity Alert',
  ];

  static const List<String> severities = ['Low', 'Medium', 'High', 'Critical'];

  static const List<String> ticketStatuses = [
    'Open',
    'Investigating',
    'Resolved',
    'Mitigated',
  ];

  factory IncidentLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};

    // `timestamp` is authored as a native Firestore Timestamp going forward,
    // but stays tolerant of ISO-8601 strings in case older/seeded rows use
    // the string format documented in the original schema file.
    final rawTs = data['timestamp'];
    final DateTime ts;
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return IncidentLog(
      id: doc.id,
      spokeId: data['spoke_id'] as String? ?? '',
      timestamp: ts,
      alertType: data['alert_type'] as String? ?? '',
      // Normalize SCREAMING_CASE from old seed data to Title Case
      severity: _toTitleCase(data['severity'] as String? ?? 'Low'),
      heuristicRule: data['heuristic_rule'] as String? ?? '',
      // Normalize legacy status values to model's expected lifecycle values
      ticketStatus: _normalizeStatus(data['ticket_status'] as String? ?? 'Open'),
      description: data['description'] as String? ?? '',
      assignedTo: data['assigned_to'] as String? ?? '',
      sourceIp: data['source_ip'] as String? ?? '',
      endpoint: data['endpoint'] as String? ?? '',
      actionTaken: data['action_taken'] as String? ?? '',
    );
  }

  static String _toTitleCase(String s) {
    if (s.isEmpty) return s;
    final lower = s.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  static String _normalizeStatus(String s) {
    switch (s.toUpperCase()) {
      case 'OPEN': return 'Open';
      case 'IN PROGRESS': return 'Investigating';
      case 'RESOLVED': return 'Resolved';
      case 'CLOSED': return 'Mitigated';
      default: return _toTitleCase(s);
    }
  }

  /// Note: the document ID (`id`) is never written back into the map — it's
  /// the Firestore document's own key, set via `.doc(id)` at write time.
  Map<String, dynamic> toFirestore() {
    return {
      'spoke_id': spokeId,
      'timestamp': Timestamp.fromDate(timestamp),
      'alert_type': alertType,
      'severity': severity,
      'heuristic_rule': heuristicRule,
      'ticket_status': ticketStatus,
      'description': description,
      'assigned_to': assignedTo,
      'source_ip': sourceIp,
      'endpoint': endpoint,
      'action_taken': actionTaken,
    };
  }

  IncidentLog copyWith({
    String? spokeId,
    DateTime? timestamp,
    String? alertType,
    String? severity,
    String? heuristicRule,
    String? ticketStatus,
    String? description,
    String? assignedTo,
    String? sourceIp,
    String? endpoint,
    String? actionTaken,
  }) {
    return IncidentLog(
      id: id,
      spokeId: spokeId ?? this.spokeId,
      timestamp: timestamp ?? this.timestamp,
      alertType: alertType ?? this.alertType,
      severity: severity ?? this.severity,
      heuristicRule: heuristicRule ?? this.heuristicRule,
      ticketStatus: ticketStatus ?? this.ticketStatus,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      sourceIp: sourceIp ?? this.sourceIp,
      endpoint: endpoint ?? this.endpoint,
      actionTaken: actionTaken ?? this.actionTaken,
    );
  }
}
