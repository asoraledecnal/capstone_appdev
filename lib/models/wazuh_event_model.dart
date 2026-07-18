import 'package:cloud_firestore/cloud_firestore.dart';

/// A raw Wazuh alert/event log line, as parsed by the Wazuh Server and
/// indexed by the Wazuh Indexer. Distinct from `IncidentLog` (which
/// represents a curated, ticket-worthy incident after the heuristic
/// engine flags it) — this is the underlying event stream itself.
/// Metadata only: agent name, rule ID, severity level, and a
/// human-readable rule description. No packet payloads or PII.
///
/// One collection backs two views at different granularity:
///  - Regional Overview shows every event across the whole region, using
///    [agent], [ruleId], and [level] (a numeric Wazuh rule level).
///  - Provincial View filters this same stream to one office via
///    [spokeId], and additionally shows [endpoint] (the specific
///    workstation/server hostname, more granular than [agent]),
///    [severity] (Low/Medium/High, easier to scan than a raw level
///    number for a local office view), [sourceIp], and a suggested
///    [action] label. These provincial-only fields default to empty for
///    events seeded from the regional Overview screen.
class WazuhEvent {
  final String id; // Firestore document ID
  final DateTime timestamp;
  final String agent; // e.g. 'laguna-po-agent'
  final String ruleId; // Wazuh rule ID, e.g. '5710'
  final int level; // Wazuh rule level, 0-16
  final String description;
  final String spokeId; // FK -> spokes/{spokeId}, e.g. 'SPOKE-02'
  final String endpoint; // specific host, e.g. 'LAGUNA-WS-012'
  final String severity; // Low | Medium | High (provincial view only)
  final String sourceIp;
  final String action; // suggested action label, e.g. 'Block IP'

  const WazuhEvent({
    required this.id,
    required this.timestamp,
    required this.agent,
    required this.ruleId,
    required this.level,
    required this.description,
    this.spokeId = '',
    this.endpoint = '',
    this.severity = '',
    this.sourceIp = '',
    this.action = '',
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
      spokeId: data['spoke_id'] as String? ?? '',
      endpoint: data['endpoint'] as String? ?? '',
      severity: data['severity'] as String? ?? '',
      sourceIp: data['source_ip'] as String? ?? '',
      action: data['action'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'timestamp': Timestamp.fromDate(timestamp),
        'agent': agent,
        'rule_id': ruleId,
        'level': level,
        'description': description,
        'spoke_id': spokeId,
        'endpoint': endpoint,
        'severity': severity,
        'source_ip': sourceIp,
        'action': action,
      };
}
