import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/file_integrity_event_model.dart';

class FileIntegrityRepository {
  FileIntegrityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('file_integrity_events');

  Stream<List<FileIntegrityEvent>> watchEvents() {
    return _eventsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FileIntegrityEvent.fromFirestore(doc))
            .toList());
  }
}
