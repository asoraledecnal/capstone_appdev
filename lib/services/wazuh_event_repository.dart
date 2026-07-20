import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wazuh_event_model.dart';

class WazuhEventRepository {
  WazuhEventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('wazuh_events');

  /// Streams the [limit] most-recent events, optionally filtered by [spokeId].
  ///
  /// When [spokeId] is provided the query uses a composite index on
  /// (spoke_id ASC, timestamp DESC).  Create this index once in the
  /// Firebase Console (or deploy via firestore.indexes.json) to avoid
  /// the "requires an index" runtime error:
  ///
  ///   Collection : wazuh_events
  ///   Fields     : spoke_id  Ascending
  ///                timestamp Descending
  ///
  /// This replaces the previous approach that fetched ALL documents for a
  /// spoke and sorted/limited them in Dart — which would download millions
  /// of records on every screen load in a production SIEM deployment.
  Stream<List<WazuhEvent>> watchEvents({int limit = 100, String? spokeId}) {
    Query<Map<String, dynamic>> query = _eventsRef;

    if (spokeId != null && spokeId.isNotEmpty) {
      query = query.where('spoke_id', isEqualTo: spokeId);
    }

    return query
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WazuhEvent.fromFirestore(doc))
            .toList());
  }
}
