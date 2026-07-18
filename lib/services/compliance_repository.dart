import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/compliance_record_model.dart';

class ComplianceRepository {
  ComplianceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _recordsRef =>
      _firestore.collection('compliance_records');

  Stream<List<ComplianceRecord>> watchRecords() {
    return _recordsRef
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplianceRecord.fromFirestore(doc))
            .toList());
  }
}
