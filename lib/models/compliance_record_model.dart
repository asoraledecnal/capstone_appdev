import 'package:cloud_firestore/cloud_firestore.dart';

class ComplianceRecord {
  final String id;
  final String framework;
  final double percent;
  final int passed;
  final int failed;
  final String spokeId; // FK -> spokes/{spokeId}, e.g. 'SPOKE-01'

  ComplianceRecord({
    required this.id,
    required this.framework,
    required this.percent,
    required this.passed,
    required this.failed,
    this.spokeId = '',
  });

  factory ComplianceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final raw = data['percent'];
    final double pct;
    if (raw is num) {
      pct = raw.toDouble();
    } else if (raw is String) {
      pct = double.tryParse(raw) ?? 0.0;
    } else {
      pct = 0.0;
    }

    return ComplianceRecord(
      id: doc.id,
      framework: data['framework'] as String? ?? '',
      // Clamp to [0, 100] to prevent NaN / out-of-range crashes in the UI.
      percent: pct.isNaN || pct.isInfinite ? 0.0 : pct.clamp(0.0, 100.0),
      passed: (data['passed'] as num?)?.toInt() ?? 0,
      failed: (data['failed'] as num?)?.toInt() ?? 0,
      spokeId: data['spoke_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'framework': framework,
      'percent': percent,
      'passed': passed,
      'failed': failed,
      'spoke_id': spokeId,
    };
  }
}
