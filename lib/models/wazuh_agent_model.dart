import 'package:cloud_firestore/cloud_firestore.dart';

/// A Wazuh endpoint agent deployed at a provincial office. Distinct from
/// the `spokes` collection (which represents the pfSense/WAN device at
/// that office) — an agent is the Wazuh monitoring process running there.
/// Linked back to its spoke via [spokeId] so future screens can filter
/// agents per-office.
class WazuhAgent {
  final String id; // Firestore document ID
  final String name; // e.g. 'cavite-po-agent'
  final String ip; // internal IP, e.g. '10.0.1.5'
  final bool active;
  final String spokeId; // FK -> spokes/{spokeId}, e.g. 'SPOKE-01'

  const WazuhAgent({
    required this.id,
    required this.name,
    required this.ip,
    required this.active,
    required this.spokeId,
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
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'ip': ip,
        'active': active,
        'spoke_id': spokeId,
      };
}
