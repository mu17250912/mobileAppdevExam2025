const admin = require('firebase-admin');

// Replace with the path to your service account key file
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixUsers() {
  const usersRef = db.collection('users');
  const snapshot = await usersRef.get();

  const updates = [];
  snapshot.forEach(doc => {
    const data = doc.data();
    const updateData = {};

    if (!data.updatedAt) updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    if (!data.userType) updateData.userType = 'buyer';
    if (!data.favorites) updateData.favorites = [];
    if (!data.savedSearches) updateData.savedSearches = [];
    if (!data.preferences) updateData.preferences = {};
    if (typeof data.isVerified === 'undefined') updateData.isVerified = false;
    if (typeof data.isActive === 'undefined') updateData.isActive = true;

    if (Object.keys(updateData).length > 0) {
      updates.push(usersRef.doc(doc.id).update(updateData));
      console.log(`Updating user ${doc.id}:`, updateData);
    }
  });

  await Promise.all(updates);
  console.log('All users updated!');
}

fixUsers().catch(console.error); 