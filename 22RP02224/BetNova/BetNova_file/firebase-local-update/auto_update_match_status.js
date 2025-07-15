const admin = require('firebase-admin');
const serviceAccount = require('../rwanda-betting-firebase-adminsdk-fbsvc-cf47c3d8f0.json'); // Hindura path niba key yawe iri ahandi

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function autoUpdateMatchStatus() {
  const now = new Date();
  const matchesSnapshot = await db.collection('matches').get();

  const batch = db.batch();

  matchesSnapshot.docs.forEach(doc => {
    const data = doc.data();
    const start = data.dateTimeStart && data.dateTimeStart.toDate ? data.dateTimeStart.toDate() : data.dateTimeStart;
    const status = data.status;

    // 1. Set to 'live' if start time reached and status is 'open'
    if (status === 'open' && start && start <= now) {
      batch.update(doc.ref, { status: 'live' });
      console.log(`Match ${doc.id} set to live`);
    }

    // 2. Set to 'expired' if 130 minutes passed since start and status is 'live'
    if (status === 'live' && start && ((now - start) / 60000 >= 130)) {
      batch.update(doc.ref, { status: 'expired' });
      console.log(`Match ${doc.id} set to expired`);
    }
  });

  await batch.commit();
  console.log('Auto-update complete!');
}

autoUpdateMatchStatus().catch(console.error);