import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ioc_finding_model.dart';

class ThreatIntelRepository {
  ThreatIntelRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _iocsRef =>
      _firestore.collection('ioc_findings');

  /// Streams IoC findings ordered by last_seen, newest first.
  ///
  /// When [spokeId] is provided the query uses a composite index on
  /// (spoke_id ASC, last_seen DESC) — see firestore.indexes.json.
  Stream<List<IocFinding>> watchIocs({String? spokeId}) {
    Query<Map<String, dynamic>> query = _iocsRef;
    if (spokeId != null && spokeId.isNotEmpty) {
      query = query.where('spoke_id', isEqualTo: spokeId);
    }
    return query
        .orderBy('last_seen', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IocFinding.fromFirestore(doc))
            .toList());
  }
}
