import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wazuh_agent_model.dart';

class WazuhAgentRepository {
  WazuhAgentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _agentsRef =>
      _firestore.collection('wazuh_agents');

  /// Streams Wazuh agents sorted by name, optionally filtered by spoke.
  ///
  /// When [spokeId] is provided the query uses a composite index on
  /// (spoke_id ASC, name ASC) — see firestore.indexes.json.
  Stream<List<WazuhAgent>> watchAgents({String? spokeId}) {
    Query<Map<String, dynamic>> query = _agentsRef;
    if (spokeId != null && spokeId.isNotEmpty) {
      query = query.where('spoke_id', isEqualTo: spokeId);
    }
    return query
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WazuhAgent.fromFirestore(doc))
            .toList());
  }
}
