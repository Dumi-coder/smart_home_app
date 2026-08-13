"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkBulbSchedules = exports.checkSafetyCutoffs = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const logger = __importStar(require("firebase-functions/logger"));
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
// ─────────────────────────────────────────────
//  Iron safety cutoff
// ─────────────────────────────────────────────
exports.checkSafetyCutoffs = (0, scheduler_1.onSchedule)("every 1 minutes", async () => {
    var _a;
    const floorsSnap = await db.collection("floors").get();
    for (const floorDoc of floorsSnap.docs) {
        const devicesSnap = await floorDoc.ref
            .collection("devices")
            .where("type", "==", "iron")
            .where("status", "==", "ON")
            .get();
        for (const deviceDoc of devicesSnap.docs) {
            const data = deviceDoc.data();
            if (!data.turnedOnAt)
                continue;
            const turnedOnAt = data.turnedOnAt.toDate();
            const elapsedMinutes = (Date.now() - turnedOnAt.getTime()) / 60000;
            const maxDuration = (_a = data.maxOnDurationMinutes) !== null && _a !== void 0 ? _a : 15;
            if (elapsedMinutes > maxDuration) {
                await deviceDoc.ref.update({
                    status: "OFF",
                    turnedOnAt: null,
                });
                await db.collection("usageLogs").add({
                    deviceId: deviceDoc.id,
                    floorId: floorDoc.id,
                    event: "AUTO_CUTOFF",
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
                });
                await db.collection("alerts").add({
                    deviceId: deviceDoc.id,
                    message: `${data.name} auto-shutoff after exceeding ` +
                        `${data.maxOnDurationMinutes} min limit`,
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
                    acknowledged: false,
                });
                logger.info("Auto-cutoff triggered for device " +
                    `${deviceDoc.id} (${data.name})`);
            }
        }
    }
});
// ─────────────────────────────────────────────
//  Bulb scheduling
// ─────────────────────────────────────────────
exports.checkBulbSchedules = (0, scheduler_1.onSchedule)("every 1 minutes", async () => {
    var _a, _b, _c, _d;
    // Reliably extract hour & minute in Asia/Colombo timezone.
    // Intl.DateTimeFormat.formatToParts() avoids the brittle
    // toLocaleString -> new Date() round-trip that breaks on Node.js.
    const parts = new Intl.DateTimeFormat("en-US", {
        timeZone: "Asia/Colombo",
        hour: "numeric",
        minute: "numeric",
        hour12: false,
    }).formatToParts(new Date());
    const hourPart = (_b = (_a = parts.find((p) => p.type === "hour")) === null || _a === void 0 ? void 0 : _a.value) !== null && _b !== void 0 ? _b : "0";
    const minPart = (_d = (_c = parts.find((p) => p.type === "minute")) === null || _c === void 0 ? void 0 : _c.value) !== null && _d !== void 0 ? _d : "0";
    // Node's Intl can emit "24" for midnight — normalise to 0.
    const currentHour = parseInt(hourPart, 10) % 24;
    const currentMinute = parseInt(minPart, 10);
    const currentMinutes = currentHour * 60 + currentMinute;
    logger.info("checkBulbSchedules: Colombo time " +
        `${currentHour}:${String(currentMinute).padStart(2, "0")} ` +
        `(${currentMinutes} min)`);
    const floorsSnap = await db.collection("floors").get();
    for (const floorDoc of floorsSnap.docs) {
        const devicesSnap = await floorDoc.ref
            .collection("devices")
            .where("type", "==", "bulb")
            .get();
        for (const deviceDoc of devicesSnap.docs) {
            const data = deviceDoc.data();
            const scheduleStart = data.scheduleStart;
            const scheduleEnd = data.scheduleEnd;
            if (!scheduleStart || !scheduleEnd)
                continue;
            const startMinutes = parseTimeToMinutes(scheduleStart);
            const endMinutes = parseTimeToMinutes(scheduleEnd);
            if (startMinutes === null || endMinutes === null)
                continue;
            const shouldBeOn = isWithinWindow(currentMinutes, startMinutes, endMinutes);
            const currentlyOn = data.status === "ON";
            if (shouldBeOn && !currentlyOn) {
                await deviceDoc.ref.update({
                    status: "ON",
                    turnedOnAt: firestore_1.FieldValue.serverTimestamp(),
                });
                await db.collection("usageLogs").add({
                    deviceId: deviceDoc.id,
                    floorId: floorDoc.id,
                    event: "ON",
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
                });
                logger.info(`Scheduled ON: ${data.name} ` +
                    `(${scheduleStart}-${scheduleEnd})`);
            }
            else if (!shouldBeOn && currentlyOn) {
                await deviceDoc.ref.update({
                    status: "OFF",
                    turnedOnAt: null,
                });
                await db.collection("usageLogs").add({
                    deviceId: deviceDoc.id,
                    floorId: floorDoc.id,
                    event: "OFF",
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
                });
                await db.collection("alerts").add({
                    deviceId: deviceDoc.id,
                    floorId: floorDoc.id,
                    title: "Schedule: light turned off",
                    message: `${data.name} turned off automatically ` +
                        `(schedule: ${scheduleStart}–${scheduleEnd})`,
                    severity: "info",
                    icon: "schedule",
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
                    acknowledged: false,
                });
                logger.info(`Scheduled OFF: ${data.name} ` +
                    `(${scheduleStart}-${scheduleEnd})`);
            }
        }
    }
});
/**
 * Parses "HH:mm" into minutes-since-midnight, or null if invalid.
 * @param {string} time - Time string in "HH:mm" format.
 * @return {number | null} Minutes since midnight, or null.
 */
function parseTimeToMinutes(time) {
    const match = /^(\d{1,2}):(\d{2})$/.exec(time.trim());
    if (!match)
        return null;
    const hours = parseInt(match[1], 10);
    const minutes = parseInt(match[2], 10);
    if (hours > 23 || minutes > 59)
        return null;
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
function isWithinWindow(current, start, end) {
    if (start === end)
        return false;
    if (start < end) {
        return current >= start && current < end;
    }
    return current >= start || current < end;
}
//# sourceMappingURL=index.js.map