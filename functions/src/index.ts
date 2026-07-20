import * as admin from "firebase-admin";
import { auth } from "firebase-functions/v1";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { defineSecret, defineString } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";

admin.initializeApp();

const VALID_ROLES = ["CITIZEN", "POLICE", "AMBULANCE", "FIRE", "ADMIN"] as const;
type Role = (typeof VALID_ROLES)[number];

/**
 * Every new Firebase Auth user gets a default CITIZEN role custom claim.
 * firestore.rules and storage.rules key off `request.auth.token.role`, so
 * every user must have this claim set before their first Firestore write.
 */
export const assignDefaultRole = auth.user().onCreate(async (user) => {
  await admin.auth().setCustomUserClaims(user.uid, { role: "CITIZEN" satisfies Role });
});

/**
 * Elevates a user to an authority role (POLICE / AMBULANCE / FIRE / ADMIN).
 * Callable only by an existing ADMIN — there is no public path to grant
 * authority roles.
 */
export const setUserRole = onCall<{ uid: string; role: Role }>(async (request) => {
  if (request.auth?.token.role !== "ADMIN") {
    throw new HttpsError("permission-denied", "Only an ADMIN can change user roles.");
  }

  const { uid, role } = request.data;
  if (!uid || !VALID_ROLES.includes(role)) {
    throw new HttpsError("invalid-argument", "A valid uid and role are required.");
  }

  await admin.auth().setCustomUserClaims(uid, { role });
  return { uid, role };
});

// ---------------------------------------------------------------------------
// Incidents-Geo Cache Sync
//
// ai_engine's crime heatmap (KDE) and model retraining read incident
// geodata from a MongoDB `incidents_geo` cache — MongoDB's native
// 2dsphere indexing ($geoWithin/$nearSphere) is a better fit for that
// workload than Firestore's limited geo support. Firestore's `incidents`
// collection stays the single source of truth; this trigger keeps the
// Mongo cache current by calling ai_engine's internal sync endpoint on
// every incident create/update/delete. See backend/docs/mongodb-schema.md.
// ---------------------------------------------------------------------------
const aiEngineInternalUrl = defineString("AI_ENGINE_INTERNAL_URL", {
  default: "http://localhost:8001",
});
const aiEngineInternalToken = defineSecret("AI_ENGINE_INTERNAL_TOKEN");

export const syncIncidentGeoCache = onDocumentWritten(
  { document: "incidents/{incidentId}", secrets: [aiEngineInternalToken] },
  async (event) => {
    const incidentId = event.params.incidentId;
    const url = `${aiEngineInternalUrl.value()}/internal/incidents-geo/sync`;
    const token = aiEngineInternalToken.value();

    const afterSnap = event.data?.after;
    const wasDeleted = !afterSnap || !afterSnap.exists;

    const payload = wasDeleted
      ? { action: "delete", incident_id: incidentId }
      : buildUpsertPayload(incidentId, afterSnap!.data()!);

    if (payload === null) {
      // Missing/invalid location — nothing to sync, and no clean way to
      // upsert a geo-indexed doc without one.
      logger.warn(`Incident ${incidentId} has no valid [lng, lat] location — skipping geo-cache sync`);
      return;
    }

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify(payload),
      });
      if (!response.ok) {
        logger.error(
          `incidents-geo sync failed for ${incidentId}: HTTP ${response.status} ${await response.text()}`
        );
      }
    } catch (error) {
      logger.error(`incidents-geo sync request failed for ${incidentId}: ${error}`);
    }
  }
);

function buildUpsertPayload(
  incidentId: string,
  data: FirebaseFirestore.DocumentData
): Record<string, unknown> | null {
  const location = data.location as number[] | undefined; // [lng, lat]
  if (!Array.isArray(location) || location.length !== 2) {
    return null;
  }

  return {
    action: "upsert",
    incident_id: incidentId,
    longitude: location[0],
    latitude: location[1],
    incident_type: data.incidentType ?? "OTHER",
    severity: data.severity ?? null,
    // Not populated by the mobile app yet — zone derivation (e.g. reverse
    // geocoding to a patrol zone) is GIS-phase scope, not implemented here.
    zone_id: data.zoneId ?? null,
    status: data.status ?? null,
    created_at: data.createdAt ?? null,
  };
}
