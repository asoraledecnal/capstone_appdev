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
        .map((snapshot) {
          final all = snapshot.docs
              .map((doc) => MitreTactic.fromFirestore(doc))
              .toList();

          // Deduplicate by tacticName — keep the entry with the highest score
          // per unique tactic (since we seed one record per spoke × tactic).
          final Map<String, MitreTactic> unique = {};
          for (final t in all) {
            final existing = unique[t.tacticName];
            if (existing == null || t.score > existing.score) {
              unique[t.tacticName] = t;
            }
          }

          // Sort by score descending so the most active tactics appear first
          final result = unique.values.toList()
            ..sort((a, b) => b.score.compareTo(a.score));

          return result;
        });
  }
}
