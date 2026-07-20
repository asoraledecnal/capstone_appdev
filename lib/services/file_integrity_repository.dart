import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/file_integrity_event_model.dart';

class FileIntegrityRepository {
  FileIntegrityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('file_integrity_events');

  Stream<List<FileIntegrityEvent>> watchEvents({String? spokeId}) {
    Query<Map<String, dynamic>> query = _eventsRef;
    if (spokeId != null && spokeId.isNotEmpty) {
      return query
          .where('spoke_id', isEqualTo: spokeId)
          .snapshots()
          .map((snapshot) {
            final events = snapshot.docs
                .map((doc) => FileIntegrityEvent.fromFirestore(doc))
                .toList();
            events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return events;
          });
    }
    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FileIntegrityEvent.fromFirestore(doc))
            .toList());
  }
}
