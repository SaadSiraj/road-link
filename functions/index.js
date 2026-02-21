const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

/**
 * When a new message is created in a conversation, send an FCM data message
 * to the recipient so they get a chat notification (unless they're in that chat).
 * Payload matches what the Flutter app expects: conversationId, otherUserId,
 * otherUserName, otherUserPhotoUrl, body, title.
 */
exports.sendChatNotification = onDocumentCreated(
  {
    document: "conversations/{conversationId}/messages/{messageId}",
    region: "us-central1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const messageId = event.params.messageId;
    const conversationId = event.params.conversationId;
    const data = snap.data();
    const senderId = data.senderId;
    const text = (data.text || "").trim();
    if (!senderId || !text) return;

    const convRef = db.collection("conversations").doc(conversationId);
    const convSnap = await convRef.get();
    if (!convSnap.exists) return;

    const convData = convSnap.data();
    const participantIds = convData.participantIds || [];
    const recipientId = participantIds.find((id) => id !== senderId);
    if (!recipientId) return;

    const [senderSnap, recipientSnap] = await Promise.all([
      db.collection("users").doc(senderId).get(),
      db.collection("users").doc(recipientId).get(),
    ]);

    const senderName = senderSnap.exists
      ? (senderSnap.data().name || "Someone")
      : "Someone";
    const senderPhotoUrl = senderSnap.exists
      ? (senderSnap.data().photoUrl || "")
      : "";
    const fcmToken = recipientSnap.exists
      ? (recipientSnap.data().fcmToken || null)
      : null;

    if (!fcmToken) return;

    // Vehicle inquiry = someone scanned your car — don't expose scanner's identity in the notification
    const isVehicleInquiry = text.startsWith("📋 Vehicle Inquiry");
    const notifTitle = isVehicleInquiry ? "Someone scanned your car" : senderName;
    const notifBody = isVehicleInquiry
      ? "A user would like to get in touch"
      : (text.length > 100 ? text.slice(0, 97) + "..." : text);

    const message = {
      notification: {
        title: notifTitle,
        body: notifBody,
      },
      data: {
        conversationId,
        otherUserId: senderId,
        otherUserName: senderName,
        otherUserPhotoUrl: senderPhotoUrl,
        body: notifBody,
        title: notifTitle,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      token: fcmToken,
      android: {
        priority: "high",
        notification: {
          channelId: "roadlink_chat",
          icon: "stock_ticker_update",
          color: "#0000FF",
        },
      },
      apns: {
        payload: {
          aps: {
            contentAvailable: true,
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    try {
      await getMessaging().send(message);
    } catch (err) {
      console.warn("FCM send failed:", err.message);
    }
  }
);
