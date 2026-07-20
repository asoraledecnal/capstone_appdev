import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ioc_finding_model.dart';

class ThreatIntelRepository {
  ThreatIntelRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _iocsRef =>
      _firestore.collection('ioc_findings');

  Stream<List<IocFinding>> watchIocs({String? spokeId}) {
    Query<Map<String, dynamic>> query = _iocsRef;
    if (spokeId != null && spokeId.isNotEmpty) {
      return query
          .where('spoke_id', isEqualTo: spokeId)
          .snapshots()
          .map((snapshot) {
            final iocs = snapshot.docs
                .map((doc) => IocFinding.fromFirestore(doc))
                .toList();
            iocs.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
            return iocs;
          });
    }
    return query
        .orderBy('last_seen', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IocFinding.fromFirestore(doc))
            .toList());
  }
}
