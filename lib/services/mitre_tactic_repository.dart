import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mitre_tactic_model.dart';

class MitreTacticRepository {
  MitreTacticRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tacticsRef =>
      _firestore.collection('mitre_tactics');

  Stream<List<MitreTactic>> watchTactics() {
    return _tacticsRef
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MitreTactic.fromFirestore(doc))
            .toList());
  }
}
