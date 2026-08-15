import {onSchedule} from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

/**
 * Runs every minute. Force-shuts-off any iron whose ON duration exceeds
 * its configured maxOnDurationMinutes, independent of whether the app is open.
 */
export const checkSafetyCutoffs = onSchedule(
  "every 1 minutes",
  async () => {
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

        const turnedOnAt: Date =
          (data.turnedOnAt as Timestamp).toDate();
        const elapsedMinutes =
          (Date.now() - turnedOnAt.getTime()) / 60000;

        const maxDuration = data.maxOnDurationMinutes ?? 15;
        if (elapsedMinutes > maxDuration) {
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
            message:
              `${data.name} auto-shutoff after exceeding ` +
              `${data.maxOnDurationMinutes} min limit`,
            timestamp: FieldValue.serverTimestamp(),
            acknowledged: false,
          });

          logger.info(
            "Auto-cutoff triggered for device " +
            `${deviceDoc.id} (${data.name})`
          );
        }
      }
    }
  }
);

/**
 * Runs every minute. Turns bulbs ON/OFF based on their scheduleStart/scheduleEnd
 * window (Asia/Colombo time). Handles windows that wrap past midnight.
 */

export const checkBulbSchedules = onSchedule(
  "every 1 minutes",
  async () => {
    // Reliably extract hour & minute in Asia/Colombo timezone.
    // Intl.DateTimeFormat.formatToParts() avoids the brittle
    // toLocaleString -> new Date() round-trip that breaks on Node.js.
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone: "Asia/Colombo",
      hour: "numeric",
      minute: "numeric",
      hour12: false,
    }).formatToParts(new Date());

    const hourPart = parts.find((p) => p.type === "hour")?.value ?? "0";
    const minPart = parts.find((p) => p.type === "minute")?.value ?? "0";
    // Node's Intl can emit "24" for midnight — normalise to 0.
    const currentHour = parseInt(hourPart, 10) % 24;
    const currentMinute = parseInt(minPart, 10);
    const currentMinutes = currentHour * 60 + currentMinute;

    logger.info(
      "checkBulbSchedules: Colombo time " +
      `${currentHour}:${String(currentMinute).padStart(2, "0")} ` +
      `(${currentMinutes} min)`
    );

    const floorsSnap = await db.collection("floors").get();
    for (const floorDoc of floorsSnap.docs) {
      const devicesSnap = await floorDoc.ref
        .collection("devices")
        .where("type", "==", "bulb")
        .get();

      for (const deviceDoc of devicesSnap.docs) {
        const data = deviceDoc.data();
        const scheduleStart: string | undefined = data.scheduleStart;
        const scheduleEnd: string | undefined = data.scheduleEnd;

        if (!scheduleStart || !scheduleEnd) continue;

        const startMinutes = parseTimeToMinutes(scheduleStart);
        const endMinutes = parseTimeToMinutes(scheduleEnd);
        if (startMinutes === null || endMinutes === null) continue;

        const shouldBeOn = isWithinWindow(
          currentMinutes,
          startMinutes,
          endMinutes
        );
        const currentlyOn = data.status === "ON";

        if (shouldBeOn && !currentlyOn) {
          await deviceDoc.ref.update({
            status: "ON",
            turnedOnAt: FieldValue.serverTimestamp(),
          });
          await db.collection("usageLogs").add({
            deviceId: deviceDoc.id,
            floorId: floorDoc.id,
            event: "ON",
            timestamp: FieldValue.serverTimestamp(),
          });
          logger.info(
            `Scheduled ON: ${data.name} ` +
            `(${scheduleStart}-${scheduleEnd})`
          );
        } else if (!shouldBeOn && currentlyOn) {
          await deviceDoc.ref.update({
            status: "OFF",
            turnedOnAt: null,
          });
          await db.collection("usageLogs").add({
            deviceId: deviceDoc.id,
            floorId: floorDoc.id,
            event: "OFF",
            timestamp: FieldValue.serverTimestamp(),
          });
          await db.collection("alerts").add({
            deviceId: deviceDoc.id,
            floorId: floorDoc.id,
            title: "Schedule: light turned off",
            message:
              `${data.name} turned off automatically ` +
              `(schedule: ${scheduleStart}–${scheduleEnd})`,
            severity: "info",
            icon: "schedule",
            timestamp: FieldValue.serverTimestamp(),
            acknowledged: false,
          });
          logger.info(
            `Scheduled OFF: ${data.name} ` +
            `(${scheduleStart}-${scheduleEnd})`
          );
        }
      }
    }
  }
);

/**
 * Parses "HH:mm" into minutes-since-midnight, or null if invalid.
 * @param {string} time - Time string in "HH:mm" format.
 * @return {number | null} Minutes since midnight, or null.
 */
function parseTimeToMinutes(time: string): number | null {
  const match = /^(\d{1,2}):(\d{2})$/.exec(time.trim());
  if (!match) return null;
  const hours = parseInt(match[1], 10);
  const minutes = parseInt(match[2], 10);
  if (hours > 23 || minutes > 59) return null;
  return hours * 60 + minutes;
}

/**
 * Returns true if current is within [start, end).
 * Handles windows that wrap past midnight (e.g. 22:00 -> 06:00).
 * @param {number} current - Current minutes since midnight.
 * @param {number} start - Schedule start in minutes since midnight.
 * @param {number} end - Schedule end in minutes since midnight.
 * @return {boolean} Whether current time is within the window.
 */
function isWithinWindow(
  current: number,
  start: number,
  end: number
): boolean {
  if (start === end) return false;
  if (start < end) {
    return current >= start && current < end;
  }
  return current >= start || current < end;
}
