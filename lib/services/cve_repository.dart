import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cve_finding_model.dart';

class CveRepository {
  CveRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _cvesRef =>
      _firestore.collection('cve_findings');

  Stream<List<CveFinding>> watchCves() {
    return _cvesRef
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CveFinding.fromFirestore(doc))
            .toList());
  }
}
