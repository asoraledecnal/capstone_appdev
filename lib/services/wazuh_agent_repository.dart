import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wazuh_agent_model.dart';

class WazuhAgentRepository {
  WazuhAgentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _agentsRef =>
      _firestore.collection('wazuh_agents');

  Stream<List<WazuhAgent>> watchAgents({String? spokeId}) {
    Query<Map<String, dynamic>> query = _agentsRef;
    if (spokeId != null) {
      query = query.where('spoke_id', isEqualTo: spokeId);
    }
    return query
        .snapshots()
        .map((snapshot) {
          final agents = snapshot.docs
              .map((doc) => WazuhAgent.fromFirestore(doc))
              .toList();
          agents.sort((a, b) => a.name.compareTo(b.name));
          return agents;
        });
  }
}
