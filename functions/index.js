const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

admin.initializeApp();

const db = admin.firestore();

function targetQuery(target, data) {
  let query = db.collection("fcm_tokens");

  if (target === "customers" || target === "customer") {
    return query.where("userType", "==", "customer");
  }

  if (target === "washes" || target === "wash") {
    return query.where("userType", "==", "wash");
  }

  if (target === "specific_customer") {
    return query
      .where("userType", "==", "customer")
      .where("userId", "==", data.customerId || "");
  }

  return query;
}

exports.sendPushForNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    if (data.sendPush !== true) return;
    if (data.isActive === false) return;

    const title = (data.title || "").toString().trim();
    const body = (data.body || "").toString().trim();

    if (!title || !body) {
      await snapshot.ref.update({
        pushStatus: "skipped",
        pushError: "Missing title or body",
        pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    const target = (data.target || "all").toString();
    const tokensSnapshot = await targetQuery(target, data).get();
    const tokens = [];

    tokensSnapshot.forEach((doc) => {
      const token = (doc.data().token || "").toString();
      if (token) tokens.push(token);
    });

    if (tokens.length === 0) {
      await snapshot.ref.update({
        pushStatus: "no_tokens",
        pushSentCount: 0,
        pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {title, body},
      data: {
        notificationId: snapshot.id,
        target,
        type: (data.type || "general").toString(),
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    logger.info("Push notification sent", {
      notificationId: snapshot.id,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });

    await snapshot.ref.update({
      pushStatus: "sent",
      pushSentCount: response.successCount,
      pushFailedCount: response.failureCount,
      pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  },
);
