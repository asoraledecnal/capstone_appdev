import 'package:cloud_firestore/cloud_firestore.dart';

class ComplianceRecord {
  final String id;
  final String framework;
  final double percent;
  final int passed;
  final int failed;

  ComplianceRecord({
    required this.id,
    required this.framework,
    required this.percent,
    required this.passed,
    required this.failed,
  });

  factory ComplianceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComplianceRecord(
      id: doc.id,
      framework: data['framework'] ?? '',
      percent: (data['percent'] ?? 0.0).toDouble(),
      passed: data['passed'] ?? 0,
      failed: data['failed'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'framework': framework,
      'percent': percent,
      'passed': passed,
      'failed': failed,
    };
  }
}
