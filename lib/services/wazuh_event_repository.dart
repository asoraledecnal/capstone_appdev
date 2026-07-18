import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wazuh_event_model.dart';

class WazuhEventRepository {
  WazuhEventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('wazuh_events');

  Stream<List<WazuhEvent>> watchEvents({int limit = 100, String? spokeId}) {
    Query<Map<String, dynamic>> query = _eventsRef;
    
    // If a spokeId is provided, querying with both .where() and .orderBy() 
    // on different fields requires a Firestore composite index. 
    // To bypass the need for manually creating an index in the Firebase Console, 
    // we filter by spokeId on the server, and sort + limit locally in Dart.
    if (spokeId != null) {
      return query
          .where('spoke_id', isEqualTo: spokeId)
          .snapshots()
          .map((snapshot) {
            final events = snapshot.docs
                .map((doc) => WazuhEvent.fromFirestore(doc))
                .toList();
            
            // Sort locally (newest first)
            events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            
            // Limit locally
            return events.length > limit ? events.sublist(0, limit) : events;
          });
    }

    // For the Regional Overview (no spokeId), we can rely on the server 
    // to sort and limit since it's only using one field.
    return query
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WazuhEvent.fromFirestore(doc))
            .toList());
  }
}
