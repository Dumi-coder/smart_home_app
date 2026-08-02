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
exports.checkSafetyCutoffs = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const logger = __importStar(require("firebase-functions/logger"));
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
exports.checkSafetyCutoffs = (0, scheduler_1.onSchedule)("every 1 minutes", async () => {
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
            if (elapsedMinutes > data.maxOnDurationMinutes) {
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
                    message: `${data.name} auto-shutoff after exceeding ${data.maxOnDurationMinutes} min limit`,
                    timestamp: firestore_1.FieldValue.serverTimestamp(),
                    acknowledged: false,
                });
                logger.info(`Auto-cutoff triggered for device ${deviceDoc.id} (${data.name})`);
            }
        }
    }
});
//# sourceMappingURL=index.js.map