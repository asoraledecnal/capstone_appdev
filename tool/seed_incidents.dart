import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:capstone_appdev/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final incidents = firestore.collection('incidents');
  final batch = firestore.batch();

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

  for (int i = 0; i < 50; i++) {
    final ref = incidents.doc();
    final timestamp = DateTime.now().subtract(Duration(minutes: i * 3));

    batch.set(ref, {
      'spoke_id': spokeIds[i % spokeIds.length],
      'timestamp': Timestamp.fromDate(timestamp),
      'alert_type': heuristics[i % heuristics.length],
      'severity': severities[i % severities.length],
      'heuristic_rule': 'RULE-${(i % 9) + 1}',
      'ticket_status': tickets[i % tickets.length],
    });
  }

  await batch.commit();
  print('Seeded 50 metadata-only incident records into Firestore.');
}
