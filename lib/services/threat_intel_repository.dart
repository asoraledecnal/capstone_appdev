import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ioc_finding_model.dart';

class ThreatIntelRepository {
  ThreatIntelRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _iocsRef =>
      _firestore.collection('ioc_findings');

  Stream<List<IocFinding>> watchIocs() {
    return _iocsRef
        .orderBy('last_seen', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IocFinding.fromFirestore(doc))
            .toList());
  }
}
