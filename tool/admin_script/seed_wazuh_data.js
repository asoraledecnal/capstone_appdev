const admin = require('firebase-admin');
const fs = require('fs');

// 1. UPDATE THIS PATH TO YOUR SERVICE ACCOUNT JSON FILE
const serviceAccountPath = './service-account-key.json'; 

if (!fs.existsSync(serviceAccountPath)) {
  console.error(`Error: Service account key not found at ${serviceAccountPath}`);
  console.log('Please copy your Firebase Admin SDK JSON key into the tool/admin_script directory');
  console.log('and rename it to "service-account-key.json", then run this script again.');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const tenantSpokeIds = {
  'Cavite Provincial Office': 'SPOKE-01',
  'Laguna Provincial Office': 'SPOKE-02',
  'Rizal Provincial Office': 'SPOKE-04',
  'Quezon Provincial Office': 'SPOKE-05',
};

const eventTemplates = [
  {
    type: 'Login Attempt',
    severity: 'High',
    description: 'Multiple failed SSH login attempts (15 attempts in 2 minutes)',
    action: 'Block IP',
  },
  {
    type: 'File Transfer',
    severity: 'Medium',
    description: 'Large file transfer to external IP (2.4GB to unknown destination)',
    action: 'Review Transfer',
  },
  {
    type: 'Suspicious Traffic',
    severity: 'Low',
    description: 'Unusual outbound traffic pattern detected on port 8080',
    action: 'Investigate',
  },
  {
    type: 'Unauthorized Access',
    severity: 'Medium',
    description: 'Attempted access to restricted directory /admin/config',
    action: 'Review Permissions',
  },
  {
    type: 'File Download',
    severity: 'Low',
    description: 'Executable file downloaded from external source',
    action: 'Scan File',
  },
];

async function seedData() {
  console.log('Starting seed process for wazuh_agents and wazuh_events...');
  try {
    const agentsRef = db.collection('wazuh_agents');
    const eventsRef = db.collection('wazuh_events');

    // Fetch existing docs to clear them out so we don't duplicate data on multiple runs
    const existingAgents = await agentsRef.where('agent_id', '==', '').get();
    const spokeIds = Object.values(tenantSpokeIds);
    const existingEvents = await eventsRef.where('spoke_id', 'in', spokeIds).get();

    const batch = db.batch();

    console.log(`Clearing ${existingAgents.size} old agents and ${existingEvents.size} old events...`);
    existingAgents.forEach((doc) => batch.delete(doc.ref));
    existingEvents.forEach((doc) => batch.delete(doc.ref));

    let agentCount = 0;
    let eventCount = 0;
    const now = new Date();

    for (const [tenantName, spokeId] of Object.entries(tenantSpokeIds)) {
      const prefix = tenantName.split(' ')[0].toUpperCase();

      // Seed 7 endpoints per tenant
      for (let i = 0; i < 7; i++) {
        const isServer = i % 3 === 0;
        const hostname = `${prefix}-${isServer ? 'SRV' : 'WS'}-${(i + 1).toString().padStart(2, '0')}`;
        const ref = agentsRef.doc();
        batch.set(ref, {
          name: hostname,
          ip: `10.45.${i + 1}.${10 + i}`,
          active: Math.random() > 0.15,
          spoke_id: spokeId,
          agent_id: '',
          os: '',
          version: '',
        });
        agentCount++;
      }

      // Seed 5 events per tenant
      const endpoints = [
        `${prefix}-WS-012`,
        `${prefix}-SRV-03`,
        `${prefix}-WS-007`,
        `${prefix}-WS-019`,
        `${prefix}-SRV-01`,
      ];

      for (let i = 0; i < eventTemplates.length; i++) {
        const t = eventTemplates[i];
        const ref = eventsRef.doc();
        const pastTime = new Date(now.getTime() - (4 + i * 13) * 60000);
        batch.set(ref, {
          timestamp: admin.firestore.Timestamp.fromDate(pastTime),
          agent: `${prefix.toLowerCase()}-po-agent`,
          rule_id: `${5000 + Math.floor(Math.random() * 5000)}`,
          level: 0,
          description: t.description,
          spoke_id: spokeId,
          endpoint: endpoints[i],
          severity: t.severity,
          source_ip: `192.168.${10 + i}.${40 + i}`,
          action: t.action,
        });
        eventCount++;
      }
    }

    console.log(`Committing batch write for ${agentCount} agents and ${eventCount} events...`);
    await batch.commit();

    console.log('Successfully seeded database with dummy Wazuh data!');
  } catch (error) {
    console.error('Failed to seed database:', error);
  }
}

seedData();
