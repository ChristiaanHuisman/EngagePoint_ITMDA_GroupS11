import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();
const db = admin.firestore();

// Reusable Helper Function for Checking Notification Preferences

/**
 * Checks if a user can receive a notification based on their preferences.
 * @param {FirebaseFirestore.DocumentData} userData The user's full document data.
 * @param {string} preferenceKey The key for the notification type (e.g., "onNewPost").
 * @param {string | null} postTag The tag of the post, if applicable for filtering.
 * @return {boolean} Returns true if the notification should be sent.
 */
function canReceiveNotification(
  userData: admin.firestore.DocumentData,
  preferenceKey: string,
  postTag: string | null = null
): boolean {
  const prefs = userData.notificationPreferences || {};
  const userId = userData.uid; // Assumes uid is on the user document

  // CHECK 1: Is the main toggle for this notification type disabled?
  if (prefs[preferenceKey] === false) {
    logger.log(`User ${userId} has disabled '${preferenceKey}' notifications.`);
    return false;
  }

  // CHECK 2: If filtering by tags, does the post tag match?
  if (preferenceKey === "onNewPost") {
    const subscribedTags = prefs.subscribedTags || [];
    if (subscribedTags.length > 0 && (!postTag || !subscribedTags.includes(postTag))) {
      logger.log(`User ${userId} is filtering and post tag '${postTag}' is not a match. Skipping.`);
      return false;
    }
  }

  // CHECK 3: Is it currently quiet time for the user?
  if (prefs.quietTimeEnabled === true) {
    const userTimezone = userData.timezone || "UTC";
    const nowUtc = new Date();

    // Convert UTC time → local user time using Intl API
    const formatter = new Intl.DateTimeFormat("en-US", {
      timeZone: userTimezone,
      hour12: false,
      hour: "2-digit",
      minute: "2-digit",
    });

    // Extract local hour and minute
    const parts = formatter.formatToParts(nowUtc);
    const hour = parseInt(parts.find(p => p.type === "hour")?.value || "0");
    const minute = parseInt(parts.find(p => p.type === "minute")?.value || "0");
    const currentMinutes = hour * 60 + minute;

    // Parse quiet start/end in minutes
    const [startHour, startMin] = (prefs.quietTimeStart || "22:00").split(":").map(Number);
    const [endHour, endMin] = (prefs.quietTimeEnd || "08:00").split(":").map(Number);
    const startMinutes = startHour * 60 + startMin;
    const endMinutes = endHour * 60 + endMin;

    let isQuietTime = false;
    if (startMinutes > endMinutes) {
      // Quiet time spans midnight
      if (currentMinutes >= startMinutes || currentMinutes < endMinutes) {
        isQuietTime = true;
      }
    } else {
      // Quiet time in same day
      if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
        isQuietTime = true;
      }
    }

    if (isQuietTime) {
      logger.log(
        `Quiet time active for user ${userId} (timezone: ${userTimezone}) — current local ${hour}:${minute
          .toString()
          .padStart(2, "0")}, range ${prefs.quietTimeStart}-${prefs.quietTimeEnd}`
      );
      return false;
    }
  }

  // If all checks pass, the user can receive the notification.
  return true;
}


// Notification Functions 

export const sendPostNotification =
  onDocumentCreated("posts/{postId}", async (event) => {
    const postData = event.data?.data();
    if (!postData) return;

    const { businessId, title: postTitle, tag: postTag } = postData;
    const postId = event.params.postId;

    const businessDoc = await admin.firestore().collection("users").doc(businessId).get();
    const businessName = businessDoc.data()?.name || "A business you follow";

    const followsSnapshot = await admin.firestore().collection("follows").where("businessId", "==", businessId).get();
    if (followsSnapshot.empty) return;

    const followerIds = followsSnapshot.docs.map((doc) => doc.data().customerId);
    const messages: admin.messaging.Message[] = [];

    for (const userId of followerIds) {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (!userDoc.exists) continue;

      const userData = userDoc.data()!;

      if (canReceiveNotification(userData, "onNewPost", postTag)) {
        const deviceSnapshot = await admin.firestore().collection("users").doc(userId).collection("devices").get();
        deviceSnapshot.docs.forEach((doc) => {
          messages.push({
            notification: { title: `${businessName} has a new post!`, body: postTitle },
            data: { type: "new_post", postId: postId },
            token: doc.data().token,
          });
        });
      }
    }

    if (messages.length > 0) {
      logger.log(`Sending post notification to ${messages.length} devices.`);
      return admin.messaging().sendEach(messages);
    }
    return;
  });

export const newReviewNotification =
  onDocumentCreated("reviews/{reviewId}", async (event) => {
    const reviewData = event.data?.data();
    if (!reviewData) return;

    const { businessId, customerId, rating } = reviewData;

    const customerDoc = await admin.firestore().collection("users").doc(customerId).get();
    const customerName = customerDoc.data()?.name || "A customer";

    const businessDoc = await admin.firestore().collection("users").doc(businessId).get();
    if (!businessDoc.exists) return;
    const businessData = businessDoc.data()!;

    if (!canReceiveNotification(businessData, "onNewReview")) return;

    const devicesSnapshot = await admin.firestore().collection("users").doc(businessId).collection("devices").get();
    if (devicesSnapshot.empty) return;

    const tokens = devicesSnapshot.docs.map((doc) => doc.data().token);
    const messages = tokens.map((token) => ({
      notification: { title: "You have a new review! ⭐️", body: `${customerName} left a ${rating}-star review for you.` },
      data: { type: "new_review", reviewId: event.params.reviewId },
      token: token,
    }));

    logger.log(`Sending new review notification to business ${businessId}`);
    return admin.messaging().sendEach(messages);
  });

export const reviewResponseNotification =
  onDocumentUpdated("reviews/{reviewId}", async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (beforeData && afterData && !beforeData.response && afterData.response) {
      const { customerId, businessId } = afterData;

      const businessDoc = await admin.firestore().collection("users").doc(businessId).get();
      const businessName = businessDoc.data()?.name || "A business";

      const customerDoc = await admin.firestore().collection("users").doc(customerId).get();
      if (!customerDoc.exists) return;
      const customerData = customerDoc.data()!;

      if (!canReceiveNotification(customerData, "onReviewResponse")) return;

      const devicesSnapshot = await admin.firestore().collection("users").doc(customerId).collection("devices").get();
      if (devicesSnapshot.empty) return;

      const tokens = devicesSnapshot.docs.map((doc) => doc.data().token);
      const messages = tokens.map((token) => ({
        notification: { title: `${businessName} replied to your review!`, body: "Tap to see their response." },
        data: { type: "review_response", reviewId: event.params.reviewId },
        token: token,
      }));

      logger.log(`Sending review response notification to customer ${customerId}`);
      return admin.messaging().sendEach(messages);
    }
    return null;
  });

export const newFollowerNotification =
  onDocumentCreated("follows/{followId}", async (event) => {
    const followData = event.data?.data();
    if (!followData) return;

    const { businessId, customerId } = followData;

    const customerDoc = await admin.firestore().collection("users").doc(customerId).get();
    const customerName = customerDoc.data()?.name || "Someone new";

    const businessDoc = await admin.firestore().collection("users").doc(businessId).get();
    if (!businessDoc.exists) return;
    const businessData = businessDoc.data()!;

    if (!canReceiveNotification(businessData, "onNewFollower")) return;

    const devicesSnapshot = await admin.firestore().collection("users").doc(businessId).collection("devices").get();
    if (devicesSnapshot.empty) return;

    const tokens = devicesSnapshot.docs.map((doc) => doc.data().token);
    const messages = tokens.map((token) => ({
      notification: { title: "You have a new follower! 🎉", body: `${customerName} is now following you.` },
      data: { type: "new_follower", followerId: customerId },
      token: token,
    }));

    logger.log(`Sending new follower notification to business ${businessId}`);
    return admin.messaging().sendEach(messages);
  });

export const postLikeNotification =
  onDocumentCreated("posts/{postId}/reactions/{userId}", async (event) => {
    if (!event.data) return;

    const { postId, userId: likerId } = event.params;

    const postDoc = await admin.firestore().collection("posts").doc(postId).get();
    if (!postDoc.exists) return;

    const { businessId, title: postTitle } = postDoc.data()!;
    if (businessId === likerId) return;

    const businessDoc = await admin.firestore().collection("users").doc(businessId).get();
    if (!businessDoc.exists) return;
    const businessData = businessDoc.data()!;


    if (!canReceiveNotification(businessData, "onPostLike")) return;

    const likerDoc = await admin.firestore().collection("users").doc(likerId).get();
    const likerName = likerDoc.data()?.name || "Someone";

    const devicesSnapshot = await admin.firestore().collection("users").doc(businessId).collection("devices").get();
    if (devicesSnapshot.empty) return;

    const tokens = devicesSnapshot.docs.map((doc) => doc.data().token);
    const messages = tokens.map((token) => ({
      notification: { title: "Your post got a like! ❤️", body: `${likerName} liked your post: "${postTitle}"` },
      data: { type: "post_like", postId: postId },
      token: token,
    }));

    logger.log(`Sending post like notification to business ${businessId}`);
    return admin.messaging().sendEach(messages);
  });

// Function for resetting verification fields on certain user field updates
export const syncBusinessFields = onDocumentUpdated(
  {
    document: "users/{uid}",
    region: "africa-south1",
    timeoutSeconds: 60,
    minInstances: 0,
    maxInstances: 20,
  },
  async (event) => {
    const uid = event.params.uid;

    type UserDoc = {
      role?: string;
      email?: string;
      name?: string;
      website?: string;
      emailVerified?: boolean;
      verificationStatus?: string;
    };

    const beforeSnap = event.data?.before;
    const afterSnap = event.data?.after;

    const before = beforeSnap?.data() as UserDoc || {};
    const after = afterSnap?.data() as UserDoc || {};

    const role = after.role;
    const isBusiness = role === "business";

    const updatesToUser: Record<string, any> = {};
    const updatesToVerification: Record<string, any> = {};

    // Detect changes
    const hasEmailChanged = before.email !== after.email;
    const hasNameChanged = before.name !== after.name;
    const hasWebsiteChanged = before.website !== after.website;

    // All users: email changed - reset emailVerified
    if (hasEmailChanged) {
      updatesToUser.emailVerified = false;
    }

    // Business-specific logic
    if (isBusiness) {
      if (hasEmailChanged || hasNameChanged || hasWebsiteChanged) {
        updatesToUser.verificationStatus = "notStarted";

        const businessVerificationRef = db
          .collection("users")
          .doc(uid)
          .collection("businessVerification")
          .doc(uid);

        updatesToVerification.verificationStatus = "notStarted";
        updatesToVerification.verificationStatusUpdatedAt = admin.firestore.Timestamp.now();

        if (hasEmailChanged) {
          updatesToVerification.emailVerified = false;
        }

        // Apply updates in a batch
        const batch = db.batch();
        if (Object.keys(updatesToUser).length > 0) {
          batch.update(db.collection("users").doc(uid), updatesToUser);
        }
        batch.set(businessVerificationRef, updatesToVerification, { merge: true });

        logger.info("Applying business updates", { updatesToUser, updatesToVerification });
        return batch.commit();
      }
    }

    // Non-business users
    if (!isBusiness && hasEmailChanged && Object.keys(updatesToUser).length > 0) {
      logger.info("Applying non-business email update", updatesToUser);
      return db.collection("users").doc(uid).update(updatesToUser);
    }

    // No relevant changes - do nothing
    logger.info("No relevant changes detected, skipping update", { uid });
    return null;
  }
);