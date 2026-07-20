import 'package:cloud_firestore/cloud_firestore.dart';

/// A single CVE finding surfaced against a monitored agent. Kept simple
/// and metadata-only (package name/version, CVSS score, which agent) —
/// consistent with the RA 10173 metadata-only constraint.
///
/// [severity] is stored and displayed as-is in ALL CAPS ('CRITICAL',
/// 'HIGH', etc.) matching the original mockup convention for this screen
/// specifically (other screens, like incidents, use Title Case instead —
/// intentionally not unified, to avoid a risky rename across an existing
/// working screen). Only 'CRITICAL' renders red; anything else currently
/// renders orange, same behavior as the original hardcoded version.
class CveFinding {
  final String id; // Firestore document ID
  final String cveId; // e.g. 'CVE-2023-38408'
  final String severity; // 'CRITICAL' | 'HIGH' | ...
  final String cvssScore; // e.g. '9.8' (kept as string to match display)
  final String affectedPackage; // e.g. 'openssh-server (9.3p1)'
  final String agentName; // e.g. 'rizal-po-agent'
  final String spokeId; // FK -> spokes/{spokeId}, e.g. 'SPOKE-01'
  final DateTime detectedAt; // When the CVE was first detected

  const CveFinding({
    required this.id,
    required this.cveId,
    required this.severity,
    required this.cvssScore,
    required this.affectedPackage,
    required this.agentName,
    this.spokeId = '',
    required this.detectedAt,
  });

  factory CveFinding.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final rawTs = data['detected_at'];
    final DateTime ts;
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return CveFinding(
      id: doc.id,
      cveId: data['cve_id'] as String? ?? '',
      severity: (data['severity'] as String? ?? 'HIGH').toUpperCase(),
      cvssScore: data['cvss_score']?.toString() ?? '',
      affectedPackage: data['affected_package'] as String? ?? '',
      agentName: data['agent_name'] as String? ?? '',
      spokeId: data['spoke_id'] as String? ?? '',
      detectedAt: ts,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'cve_id': cveId,
        'severity': severity,
        'cvss_score': cvssScore,
        'affected_package': affectedPackage,
        'agent_name': agentName,
        'spoke_id': spokeId,
        'detected_at': Timestamp.fromDate(detectedAt),
      };
}
