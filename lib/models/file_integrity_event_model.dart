import 'package:cloud_firestore/cloud_firestore.dart';

class FileIntegrityEvent {
  final String id;
  final DateTime timestamp;
  final String agentName;
  final String filePath;
  final String action;

  FileIntegrityEvent({
    required this.id,
    required this.timestamp,
    required this.agentName,
    required this.filePath,
    required this.action,
  });

  factory FileIntegrityEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FileIntegrityEvent(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      agentName: data['agent_name'] ?? data['endpoint'] ?? '',
      filePath: data['file_path'] ?? '',
      action: data['action'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'agent_name': agentName,
      'file_path': filePath,
      'action': action,
    };
  }
}
