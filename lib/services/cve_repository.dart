import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cve_finding_model.dart';

class CveRepository {
  CveRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _cvesRef =>
      _firestore.collection('cve_findings');

  /// Streams CVE findings ordered by detection date, newest first.
  ///
  /// When [spokeId] is provided the query uses a composite index on
  /// (spoke_id ASC, detected_at DESC) — see firestore.indexes.json.
  Stream<List<CveFinding>> watchCves({String? spokeId}) {
    Query<Map<String, dynamic>> query = _cvesRef;
    if (spokeId != null && spokeId.isNotEmpty) {
      query = query.where('spoke_id', isEqualTo: spokeId);
    }
    return query
        .orderBy('detected_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CveFinding.fromFirestore(doc))
            .toList());
  }
}
