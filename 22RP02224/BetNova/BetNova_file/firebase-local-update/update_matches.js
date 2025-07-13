const admin = require('firebase-admin');
const serviceAccount = require('../rwanda-betting-firebase-adminsdk-fbsvc-cf47c3d8f0.json'); // NB: one level up from firebase-local-update

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateAllMatches() {
  const matchesSnapshot = await db.collection('matches').get();
  const batch = db.batch();
  matchesSnapshot.docs.forEach(doc => {
    batch.update(doc.ref, { visible: true, status: 'open' });
  });
  await batch.commit();
  console.log('All matches updated to visible: true and status: open');
}

updateAllMatches().catch(console.error);