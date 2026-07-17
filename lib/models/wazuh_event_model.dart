import 'package:cloud_firestore/cloud_firestore.dart';

/// A raw Wazuh alert/event log line, as parsed by the Wazuh Server and
/// indexed by the Wazuh Indexer. Distinct from `IncidentLog` (which
/// represents a curated, ticket-worthy incident after the heuristic
/// engine flags it) — this is the underlying event stream itself.
/// Metadata only: agent name, rule ID, severity level, and a
/// human-readable rule description. No packet payloads or PII.
class WazuhEvent {
  final String id; // Firestore document ID
  final DateTime timestamp;
  final String agent; // e.g. 'laguna-agent-01'
  final String ruleId; // Wazuh rule ID, e.g. '5710'
  final int level; // Wazuh rule level, 0-16
  final String description;

  const WazuhEvent({
    required this.id,
    required this.timestamp,
    required this.agent,
    required this.ruleId,
    required this.level,
    required this.description,
  });

  factory WazuhEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final rawTs = data['timestamp'];
    final DateTime ts;
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    final rawLevel = data['level'];
    final level = (rawLevel is num) ? rawLevel.toInt() : 0;

    return WazuhEvent(
      id: doc.id,
      timestamp: ts,
      agent: data['agent'] as String? ?? '',
      ruleId: data['rule_id'] as String? ?? '',
      level: level,
      description: data['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'timestamp': Timestamp.fromDate(timestamp),
        'agent': agent,
        'rule_id': ruleId,
        'level': level,
        'description': description,
      };
}
