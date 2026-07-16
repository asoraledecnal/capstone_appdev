import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/incident_model.dart';

class IncidentRepository {
  IncidentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _incidentsRef =>
      _firestore.collection('incidents');

  Stream<List<IncidentLog>> watchIncidents() {
    return _incidentsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncidentLog.fromFirestore(doc))
            .toList());
  }

  Future<void> createIncident(Map<String, dynamic> data) {
    return _incidentsRef.add(data);
  }

  Future<void> updateIncident(String id, Map<String, dynamic> data) {
    return _incidentsRef.doc(id).update(data);
  }

  Future<void> deleteIncident(String id) {
    return _incidentsRef.doc(id).delete();
  }

  Future<void> seedMockIncidents({int count = 50}) async {
    final batch = _firestore.batch();
    final heuristics = [
      'Unusual Login Burst',
      'Port Scan Pattern',
      'Beaconing Spike',
      'Credential Dump Attempt',
      'Privilege Escalation Signal',
    ];
    final severities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
    final tickets = ['OPEN', 'IN PROGRESS', 'RESOLVED'];
    final spokeIds = [
      'SPK-LAG-01',
      'SPK-LAG-02',
      'SPK-CAL-03',
      'SPK-STA-04',
      'SPK-NCR-05',
    ];

    for (int i = 0; i < count; i++) {
      final ref = _incidentsRef.doc();
      final now = DateTime.now().subtract(Duration(minutes: i * 3));
      batch.set(ref, {
        'spoke_id': spokeIds[i % spokeIds.length],
        'timestamp': Timestamp.fromDate(now),
        'alert_type': heuristics[i % heuristics.length],
        'severity': severities[i % severities.length],
        'heuristic_rule': 'RULE-${(i % 9) + 1}',
        'ticket_status': tickets[i % tickets.length],
      });
    }

    await batch.commit();
  }
}
