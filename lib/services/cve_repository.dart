import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cve_finding_model.dart';

class CveRepository {
  CveRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _cvesRef =>
      _firestore.collection('cve_findings');

  Stream<List<CveFinding>> watchCves({String? spokeId}) {
    Query<Map<String, dynamic>> query = _cvesRef;
    if (spokeId != null && spokeId.isNotEmpty) {
      return query
          .where('spoke_id', isEqualTo: spokeId)
          .snapshots()
          .map((snapshot) {
            final cves = snapshot.docs
                .map((doc) => CveFinding.fromFirestore(doc))
                .toList();
            cves.sort((a, b) => b.cveId.compareTo(a.cveId));
            return cves;
          });
    }
    return query
        .orderBy('detected_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CveFinding.fromFirestore(doc)).toList());
  }
}
