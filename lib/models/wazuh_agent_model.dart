import 'package:cloud_firestore/cloud_firestore.dart';

/// A Wazuh endpoint agent deployed at a provincial office. Distinct from
/// the `spokes` collection (which represents the pfSense/WAN device at
/// that office) — an agent is the Wazuh monitoring process running there.
/// Linked back to its spoke via [spokeId] so future screens can filter
/// agents per-office.
///
/// Used by both the Overview dashboard (quick status list) and the
/// Endpoint Security screen (full inventory) — same underlying record,
/// different amount of detail shown.
class WazuhAgent {
  final String id; // Firestore document ID
  final String name; // e.g. 'cavite-po-agent'
  final String ip; // internal IP, e.g. '10.0.1.5'
  final bool active;
  final String spokeId; // FK -> spokes/{spokeId}, e.g. 'SPOKE-01'
  final String agentId; // Wazuh's own agent ID, e.g. '001'
  final String os; // e.g. 'Ubuntu 22.04.3 LTS'
  final String version; // Wazuh agent version, e.g. 'Wazuh v4.8.0'

  const WazuhAgent({
    required this.id,
    required this.name,
    required this.ip,
    required this.active,
    required this.spokeId,
    this.agentId = '',
    this.os = '',
    this.version = '',
  });

  factory WazuhAgent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return WazuhAgent(
      id: doc.id,
      name: data['name'] as String? ?? '',
      ip: data['ip'] as String? ?? '',
      active: data['active'] as bool? ?? false,
      spokeId: data['spoke_id'] as String? ?? '',
      agentId: data['agent_id'] as String? ?? '',
      os: data['os'] as String? ?? '',
      version: data['version'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'ip': ip,
        'active': active,
        'spoke_id': spokeId,
        'agent_id': agentId,
        'os': os,
        'version': version,
      };
}
