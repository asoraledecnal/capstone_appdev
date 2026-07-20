import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/incident_model.dart';

class IncidentRepository {
  IncidentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _incidentsRef =>
      _firestore.collection('incidents');

  Stream<List<IncidentLog>> watchIncidents({String? spokeId}) {
    Query<Map<String, dynamic>> query = _incidentsRef;
    if (spokeId != null && spokeId.isNotEmpty) {
      return query
          .where('spoke_id', isEqualTo: spokeId)
          .snapshots()
          .map((snapshot) {
            final incidents = snapshot.docs
                .map((doc) => IncidentLog.fromFirestore(doc))
                .toList();
            incidents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return incidents;
          });
    }
    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncidentLog.fromFirestore(doc))
            .toList());
  }

  /// Creates a new incident document. Throws [FirebaseException] on failure
  /// so the calling UI can show an error SnackBar.
  Future<void> createIncident(Map<String, dynamic> data) async {
    try {
      await _incidentsRef.add(data);
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to create incident: $e');
    }
  }

  /// Updates an existing incident document. Throws on failure.
  Future<void> updateIncident(String id, Map<String, dynamic> data) async {
    try {
      await _incidentsRef.doc(id).update(data);
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update incident: $e');
    }
  }

  /// Deletes an incident document. Throws on failure.
  Future<void> deleteIncident(String id) async {
    try {
      await _incidentsRef.doc(id).delete();
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete incident: $e');
    }
  }

  /// Seeds mock incidents using the correct SPOKE-xx IDs that match the
  /// sidebar configuration, and uses [IncidentLog.toFirestore()] to ensure
  /// consistent field names and types.
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
    final statuses = ['Open', 'Investigating', 'Mitigated', 'Resolved'];
    // Must match the IDs defined in provincial_sidebar.dart
    final spokeIds = [
      'SPOKE-01',
      'SPOKE-02',
      'SPOKE-03',
      'SPOKE-04',
      'SPOKE-05',
    ];

    for (int i = 0; i < count; i++) {
      final ref = _incidentsRef.doc(); // Firestore auto-generated unique ID
      final now = DateTime.now().subtract(Duration(minutes: i * 3));
      final log = IncidentLog(
        id: ref.id,
        spokeId: spokeIds[i % spokeIds.length],
        timestamp: now,
        alertType: heuristics[i % heuristics.length],
        severity: severities[i % severities.length],
        heuristicRule: 'RULE-${(i % 9) + 1}',
        ticketStatus: statuses[i % statuses.length],
      );
      batch.set(ref, log.toFirestore());
    }

    await batch.commit();
  }
}
