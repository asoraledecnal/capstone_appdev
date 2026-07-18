import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wazuh_event_model.dart';

class WazuhEventRepository {
  WazuhEventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('wazuh_events');

  Stream<List<WazuhEvent>> watchEvents({int limit = 100}) {
    return _eventsRef
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WazuhEvent.fromFirestore(doc))
            .toList());
  }
}
