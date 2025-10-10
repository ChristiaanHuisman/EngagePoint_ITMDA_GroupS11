import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();

export const sendPostNotification =
  onDocumentCreated("posts/{postId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.log("No data associated with the event.");
      return;
    }
    const postData = snapshot.data();
    const postId = event.params.postId;
    const businessId = postData.businessId;
    const postTitle = postData.title;

    const businessDoc = await admin
      .firestore()
      .collection("users")
      .doc(businessId)
      .get();

    if (!businessDoc.exists) {
      logger.error(`Business profile not found for ID: ${businessId}`);
      return;
    }
    const businessName = businessDoc.data()?.name || "A business you follow";

    const followsSnapshot = await admin
      .firestore()
      .collection("follows")
      .where("businessId", "==", businessId)
      .get();

    if (followsSnapshot.empty) {
      logger.log(`No followers found for business: ${businessId}`);
      return;
    }

    const followerIds = followsSnapshot.docs.map(
      (doc) => doc.data().customerId
    );

    const tokenPromises = followerIds.map(async (userId) => {
      const deviceSnapshot = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .collection("devices")
        .get();
      return deviceSnapshot.docs.map((doc) => doc.data().token);
    });

    const allTokensNested = await Promise.all(tokenPromises);
    const tokens = allTokensNested.flat();

    if (tokens.length === 0) {
      logger.log("No device tokens found for any followers.");
      return;
    }

    const message = {
      notification: {
        title: `${businessName} has a new post!`,
        body: postTitle,
      },
      data: {
        postId: postId,
      },
      tokens: tokens,
    };

    logger.log(`Sending notification to ${tokens.length} tokens.`);

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const messaging = admin.messaging() as any;
if (typeof messaging.sendMulticast === "function") {
  return messaging.sendMulticast(message);
} else {
  logger.log("sendMulticast not found — using sendToDevice fallback.");
  return messaging.sendToDevice(message.tokens, {
    notification: message.notification,
    data: message.data,
  });
}

  });
