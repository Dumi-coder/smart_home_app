
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

export const checkSafetyCutoffs = onSchedule("every 1 minutes", async () => {
  const floorsSnap = await db.collection("floors").get();

  for (const floorDoc of floorsSnap.docs) {
    const devicesSnap = await floorDoc.ref
      .collection("devices")
      .where("type", "==", "iron")
      .where("status", "==", "ON")
      .get();

    for (const deviceDoc of devicesSnap.docs) {
      const data = deviceDoc.data();
      if (!data.turnedOnAt) continue;

      const turnedOnAt: Date = (data.turnedOnAt as Timestamp).toDate();
      const elapsedMinutes = (Date.now() - turnedOnAt.getTime()) / 60000;

      if (elapsedMinutes > data.maxOnDurationMinutes) {
        await deviceDoc.ref.update({
          status: "OFF",
          turnedOnAt: null,
        });

        await db.collection("usageLogs").add({
          deviceId: deviceDoc.id,
          floorId: floorDoc.id,
          event: "AUTO_CUTOFF",
          timestamp: FieldValue.serverTimestamp(),
        });

        await db.collection("alerts").add({
          deviceId: deviceDoc.id,
          message: `${data.name} auto-shutoff after exceeding ${data.maxOnDurationMinutes} min limit`,
          timestamp: FieldValue.serverTimestamp(),
          acknowledged: false,
        });

        logger.info(
          `Auto-cutoff triggered for device ${deviceDoc.id} (${data.name})`
        );
      }
    }
  }
});