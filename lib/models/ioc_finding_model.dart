import 'package:cloud_firestore/cloud_firestore.dart';

/// A matched Indicator of Compromise (IoC) — an IP, file hash, or DNS
/// query that matched a known threat feed against live traffic.
/// Metadata only (indicator value, type, attributed campaign, which
/// agent, when) — no packet payloads.
class IocFinding {
  final String id; // Firestore document ID
  final String indicator; // e.g. '185.220.101.44' or a file hash
  final String type; // 'IP Address' | 'File Hash (SHA256)' | 'DNS Query'
  final String threatActor; // e.g. 'Mirai Botnet'
  final String agentName; // e.g. 'rizal-po-agent'
  final DateTime lastSeen;

  const IocFinding({
    required this.id,
    required this.indicator,
    required this.type,
    required this.threatActor,
    required this.agentName,
    required this.lastSeen,
  });

  factory IocFinding.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final raw = data['last_seen'];
    final DateTime ts;
    if (raw is Timestamp) {
      ts = raw.toDate();
    } else if (raw is String) {
      ts = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return IocFinding(
      id: doc.id,
      indicator: data['indicator'] as String? ?? '',
      type: data['type'] as String? ?? '',
      threatActor: data['threat_actor'] as String? ?? '',
      agentName: data['agent_name'] as String? ?? '',
      lastSeen: ts,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'indicator': indicator,
        'type': type,
        'threat_actor': threatActor,
        'agent_name': agentName,
        'last_seen': Timestamp.fromDate(lastSeen),
      };
}
