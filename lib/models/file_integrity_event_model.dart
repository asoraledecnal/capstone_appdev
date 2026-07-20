import 'package:cloud_firestore/cloud_firestore.dart';

class FileIntegrityEvent {
  final String id;
  final DateTime timestamp;
  final String agentName;
  final String filePath;
  final String action;
  final String spokeId; // FK -> spokes/{spokeId}, e.g. 'SPOKE-01'

  FileIntegrityEvent({
    required this.id,
    required this.timestamp,
    required this.agentName,
    required this.filePath,
    required this.action,
    this.spokeId = '',
  });

  factory FileIntegrityEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawTs = data['timestamp'];
    final DateTime ts;
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return FileIntegrityEvent(
      id: doc.id,
      timestamp: ts,
      agentName: data['agent_name'] ?? data['endpoint'] ?? '',
      filePath: data['file_path'] ?? '',
      action: data['action'] ?? '',
      spokeId: data['spoke_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'agent_name': agentName,
      'file_path': filePath,
      'action': action,
      'spoke_id': spokeId,
    };
  }
}
