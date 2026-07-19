import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/compliance_record_model.dart';

class ComplianceRepository {
  ComplianceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _recordsRef =>
      _firestore.collection('compliance_records');

  Stream<List<ComplianceRecord>> watchRecords({String? spokeId}) {
    Query<Map<String, dynamic>> query = _recordsRef;
    if (spokeId != null && spokeId.isNotEmpty) {
      query = query.where('spoke_id', isEqualTo: spokeId);
    }

    return query.snapshots().map((snapshot) {
      if (spokeId != null && spokeId.isNotEmpty) {
        // Provincial View: Return specific records
        return snapshot.docs
            .map((doc) => ComplianceRecord.fromFirestore(doc))
            .toList();
      } else {
        // Regional View: Aggregate across all spokes
        final Map<String, ComplianceRecord> aggregated = {};
        for (var doc in snapshot.docs) {
          final record = ComplianceRecord.fromFirestore(doc);
          if (aggregated.containsKey(record.framework)) {
            final existing = aggregated[record.framework]!;
            final totalPassed = existing.passed + record.passed;
            final totalFailed = existing.failed + record.failed;
            final totalChecks = totalPassed + totalFailed;
            final newPercent = totalChecks == 0 ? 0.0 : (totalPassed / totalChecks) * 100.0;
            
            aggregated[record.framework] = ComplianceRecord(
              id: existing.id,
              framework: existing.framework,
              percent: newPercent,
              passed: totalPassed,
              failed: totalFailed,
            );
          } else {
            aggregated[record.framework] = record;
          }
        }
        return aggregated.values.toList();
      }
    });
  }
}
