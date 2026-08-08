const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const AGGREGATE_COLLECTION = "community_impact_stats";
const AGGREGATE_DOC_ID = "aggregate";

/**
 * Turns a free-text city/category into a Firestore map key: lowercase,
 * non-alphanumerics collapsed to underscores, trimmed. "San Antonio"  and
 * "san antonio" land on the same key so a handful of accounts typing the
 * same city slightly differently still roll up together. Falls back to
 * "unspecified" for anything that slugifies to nothing (e.g. an
 * all-punctuation string) rather than writing an empty map key, which
 * Firestore map fields don't reliably support.
 */
function slugify(value) {
  const slug = String(value)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
  return slug || "unspecified";
}

/**
 * Applies [sign] * the entry's amount/count to community_impact_stats -
 * +1 on create, -1 on delete, so the aggregate stays correct if a
 * customer removes a logged entry rather than only ever growing.
 *
 * Uses `set(..., {merge: true})` with *nested plain objects* for
 * city_totals/city_labels, not dotted string keys - Firestore only
 * interprets a dotted key ('city_totals.austin') as a nested field path
 * for `update()`; under `set()` with merge, a dotted string is a single
 * literal field name containing a dot. Nested objects are the documented
 * way to merge one key of a map field without clobbering its siblings.
 *
 * No transaction: FieldValue.increment() is itself the concurrency-safe
 * primitive here (Firestore applies it as a server-side atomic delta,
 * not a read-modify-write), so concurrent writes from different
 * customers logging spend at the same moment can't lose an increment
 * the way a plain read-then-write would.
 */
async function applyDelta(data, sign) {
  if (!data || typeof data.amount !== "number") return;

  const db = admin.firestore();
  const ref = db.collection(AGGREGATE_COLLECTION).doc(AGGREGATE_DOC_ID);
  const amountDelta = sign * data.amount;

  const update = {
    total_spend: admin.firestore.FieldValue.increment(amountDelta),
    total_entries: admin.firestore.FieldValue.increment(sign),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (data.business_city) {
    const citySlug = slugify(data.business_city);
    update.city_totals = { [citySlug]: admin.firestore.FieldValue.increment(amountDelta) };
    // Labels only ever get set, never decremented - a city's display name
    // doesn't change because one entry citing it was deleted, and the
    // slug->label mapping should never regress to missing once known.
    if (sign > 0) {
      update.city_labels = { [citySlug]: data.business_city.trim() };
    }
  }

  if (data.business_category) {
    const categorySlug = slugify(data.business_category);
    update.category_totals = {
      [categorySlug]: admin.firestore.FieldValue.increment(amountDelta),
    };
    if (sign > 0) {
      update.category_labels = { [categorySlug]: data.business_category.trim() };
    }
  }

  await ref.set(update, { merge: true });
}

exports.recordSpendLogAggregate = functions.firestore
  .document("spend_logs/{logId}")
  .onCreate((snapshot) => applyDelta(snapshot.data(), 1));

exports.removeSpendLogAggregate = functions.firestore
  .document("spend_logs/{logId}")
  .onDelete((snapshot) => applyDelta(snapshot.data(), -1));

exports._internals = { applyDelta, slugify };
