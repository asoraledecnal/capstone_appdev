import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wazuh_agent_model.dart';

class WazuhAgentRepository {
  WazuhAgentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _agentsRef =>
      _firestore.collection('wazuh_agents');

  Stream<List<WazuhAgent>> watchAgents() {
    return _agentsRef
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WazuhAgent.fromFirestore(doc))
            .toList());
  }
}
