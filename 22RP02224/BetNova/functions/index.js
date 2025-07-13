const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.autoUpdateMatchStatus = functions.pubsub
    .schedule("every 1 minutes")
    .onRun(async (context) => {
      const now = new Date();
      const matchesRef = admin.firestore().collection("matches");

      // 1. Set matches to 'live' if start time reached
      const openMatches = await matchesRef.where("status", "==", "open").get();
      for (const doc of openMatches.docs) {
        const data = doc.data();
        if (data.dateTimeStart && data.dateTimeStart.toDate() <= now) {
          await doc.ref.update({status: "live"});
        }
      }

      // 2. Set matches to 'expired' if 90 minutes passed since start
      const liveMatches = await matchesRef.where("status", "==", "live").get();
      for (const doc of liveMatches.docs) {
        const data = doc.data();
        if (
          data.dateTimeStart &&
        (now - data.dateTimeStart.toDate()) / 60000 >= 90
        ) {
          await doc.ref.update({status: "expired"});
        }
      }

      return null;
    });

// Send push notification to admins when new admin notification is created
exports.sendAdminNotification = functions.firestore
    .document("admin_notifications/{notificationId}")
    .onCreate(async (snap, context) => {
      const notificationData = snap.data();

      // Get all admin users
      const adminUsers = await admin.firestore()
          .collection("users")
          .where("role", "==", "admin")
          .get();

      const adminTokens = [];
      adminUsers.forEach((doc) => {
        const fcmToken = doc.data().fcmToken;
        if (fcmToken) {
          adminTokens.push(fcmToken);
        }
      });

      if (adminTokens.length === 0) {
        console.log("No admin FCM tokens found");
        return null;
      }

      // Prepare notification message
      const message = {
        notification: {
          title: "New Admin Notification",
          body: `${notificationData.userName}: ${notificationData.action}`,
        },
        data: {
          type: notificationData.type,
          userId: notificationData.userId || "",
          amount: notificationData.amount ? notificationData.amount.toString() : "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        tokens: adminTokens,
      };

      try {
        const response = await admin.messaging().sendMulticast(message);
        console.log("Successfully sent admin notification:", 
          response.successCount, "successful,", response.failureCount, "failed");

        // Log failed tokens for debugging
        if (response.failureCount > 0) {
          const failedTokens = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              failedTokens.push(adminTokens[idx]);
            }
          });
          console.log("Failed tokens:", failedTokens);
        }
      } catch (error) {
        console.error("Error sending admin notification:", error);
      }

      return null;
    });

// Create admin notification when bet is placed
exports.createBetNotification = functions.firestore
    .document("bets/{betId}")
    .onCreate(async (snap, context) => {
      const betData = snap.data();

      // Get user information
      const userDoc = await admin.firestore()
          .collection("users")
          .doc(betData.userId)
          .get();

      const userName = userDoc.data() ? 
        userDoc.data().name || "Unknown User" : "Unknown User";

      // Create admin notification
      await admin.firestore().collection("admin_notifications").add({
        type: "bet",
        userName: userName,
        action: `placed a bet with ${betData.selections.length} selections`,
        amount: betData.wager,
        userId: betData.userId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      });

      return null;
    });

// Create admin notification when bet status changes
exports.createBetStatusNotification = functions.firestore
    .document("bets/{betId}")
    .onUpdate(async (change, context) => {
      const beforeData = change.before.data();
      const afterData = change.after.data();

      // Only trigger if status changed
      if (beforeData.status === afterData.status) {
        return null;
      }

      // Get user information
      const userDoc = await admin.firestore()
          .collection("users")
          .doc(afterData.userId)
          .get();

      const userName = userDoc.data() ? 
        userDoc.data().name || "Unknown User" : "Unknown User";

      // Create admin notification
      await admin.firestore().collection("admin_notifications").add({
        type: "bet",
        userName: userName,
        action: `bet was ${afterData.status}`,
        amount: afterData.wager,
        userId: afterData.userId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      });

      return null;
    });

// HTTP function to set all matches to visible: true and status: 'open'
exports.setAllMatchesVisibleAndOpen = functions.https.onRequest(async (req, res) => {
  try {
    const matchesSnapshot = await admin.firestore().collection('matches').get();
    const batch = admin.firestore().batch();
    matchesSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, { visible: true, status: 'open' });
    });
    await batch.commit();
    res.status(200).send('All matches updated to visible: true and status: open');
  } catch (error) {
    console.error('Error updating matches:', error);
    res.status(500).send('Error updating matches: ' + error);
  }
});
