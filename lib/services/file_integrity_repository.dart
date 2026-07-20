import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/file_integrity_event_model.dart';

class FileIntegrityRepository {
  FileIntegrityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('file_integrity_events');

  /// Streams file integrity events ordered by timestamp, newest first.
  ///
  /// When [spokeId] is provided the query uses a composite index on
  /// (spoke_id ASC, timestamp DESC) — see firestore.indexes.json.
  Stream<List<FileIntegrityEvent>> watchEvents({String? spokeId}) {
    Query<Map<String, dynamic>> query = _eventsRef;
    if (spokeId != null && spokeId.isNotEmpty) {
      query = query.where('spoke_id', isEqualTo: spokeId);
    }
    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FileIntegrityEvent.fromFirestore(doc))
            .toList());
  }
}
