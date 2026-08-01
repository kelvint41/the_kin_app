// Regenerates ticker_symbol values for a directory CSV export so they match
// the app's real ticker format, and guarantees they're unique both within the
// file and against tickers already assigned elsewhere.
//
// Why this exists:
//   The spreadsheet exports carry a 4-character ticker that's just the first
//   four letters of the business name, so they collide constantly (HAIR x10,
//   BLAC x6, GOLD x3...). import_businesses.js aborts outright on duplicate
//   tickers, and the app's real format is 5 characters anyway - see
//   lib/flutter_flow/kindex_ticker_util.dart, which this file mirrors.
//
// Usage:
//   node generate_tickers.js <input.csv>              # report only, no writes
//   node generate_tickers.js <input.csv> --write      # write <input>.tickers.csv
//
// Reserved tickers (never reused) are read from migration_data.json when it's
// present, so a second import can't collide with the first one's businesses.

const fs = require('fs');
const path = require('path');

// --- Mirrors KindexTickerUtil ------------------------------------------------
// Keep these three in sync with lib/flutter_flow/kindex_ticker_util.dart.
const TICKER_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
const TICKER_LENGTH = 5;
const FILLER_WORDS = ['LLC', 'INC', 'CO', 'THE'];

/// Derives a semantic ticker from [name] ('Rollin Smoke BBQ' -> 'ROLLI'), or
/// null if fewer than TICKER_LENGTH alphanumerics remain after filler words
/// are dropped as whole tokens.
function semanticCandidate(name) {
  const cleaned = String(name)
    .toUpperCase()
    .split(/[^A-Z0-9]+/)
    .filter((w) => w.length > 0 && !FILLER_WORDS.includes(w))
    .join('');
  return cleaned.length >= TICKER_LENGTH
    ? cleaned.slice(0, TICKER_LENGTH)
    : null;
}

/// Deterministic stand-in for KindexTickerUtil.randomCandidate(). The app uses
/// randomness because it retries against a live registry; a batch import wants
/// reproducibility instead - the same business must regenerate the same ticker
/// so re-running the import stays idempotent. Output is the same shape and
/// alphabet, so it's indistinguishable from a random one downstream.
function derivedCandidate(seed, attempt) {
  // FNV-1a, salted with the attempt number so a collision yields a fresh draw.
  let hash = 0x811c9dc5;
  const input = `${seed}#${attempt}`;
  for (let i = 0; i < input.length; i++) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193) >>> 0;
  }
  let out = '';
  for (let i = 0; i < TICKER_LENGTH; i++) {
    out += TICKER_CHARS[hash % TICKER_CHARS.length];
    hash = Math.floor(hash / TICKER_CHARS.length) + Math.imul(hash, 31) % 997;
    hash = hash >>> 0;
  }
  return out;
}

// --- CSV (RFC 4180: quoted fields, embedded commas, doubled quotes) ----------
function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = '';
  let inQuotes = false;
  const src = text.replace(/\r\n/g, '\n');

  for (let i = 0; i < src.length; i++) {
    const ch = src[i];
    if (inQuotes) {
      if (ch === '"') {
        if (src[i + 1] === '"') { field += '"'; i++; }
        else inQuotes = false;
      } else field += ch;
    } else if (ch === '"') {
      inQuotes = true;
    } else if (ch === ',') {
      row.push(field); field = '';
    } else if (ch === '\n') {
      row.push(field); field = '';
      if (row.length > 1 || row[0] !== '') rows.push(row);
      row = [];
    } else field += ch;
  }
  if (field !== '' || row.length > 0) {
    row.push(field);
    if (row.length > 1 || row[0] !== '') rows.push(row);
  }
  return rows;
}

function toCsvField(value) {
  const s = value == null ? '' : String(value);
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

function toCsv(rows) {
  return rows.map((r) => r.map(toCsvField).join(',')).join('\n') + '\n';
}

// --- Reserved tickers from any prior import ----------------------------------
function loadReservedTickers() {
  const reserved = new Set();
  const migrationPath = path.join(__dirname, '..', '..', 'migration_data.json');
  if (!fs.existsSync(migrationPath)) return reserved;
  try {
    const records = JSON.parse(fs.readFileSync(migrationPath, 'utf8'));
    for (const r of records) {
      if (r && r.ticker_symbol) reserved.add(String(r.ticker_symbol).toUpperCase());
    }
  } catch (err) {
    console.warn(`Warning: could not read migration_data.json (${err.message}) - `
      + 'proceeding without its reserved tickers.');
  }
  return reserved;
}

function main() {
  const args = process.argv.slice(2);
  const isWrite = args.includes('--write');
  const inputPath = args.find((a) => !a.startsWith('--'));

  if (!inputPath) {
    console.error('Usage: node generate_tickers.js <input.csv> [--write]');
    process.exit(1);
  }
  if (!fs.existsSync(inputPath)) {
    console.error(`No such file: ${inputPath}`);
    process.exit(1);
  }

  const rows = parseCsv(fs.readFileSync(inputPath, 'utf8'));
  if (rows.length < 2) {
    console.error('CSV has no data rows.');
    process.exit(1);
  }

  const header = rows[0];
  const nameIdx = header.indexOf('business_name');
  const tickerIdx = header.indexOf('ticker_symbol');
  const addressIdx = header.indexOf('address');
  const cityIdx = header.indexOf('city');

  if (nameIdx === -1 || tickerIdx === -1) {
    console.error('CSV must have business_name and ticker_symbol columns. '
      + `Found: ${header.join(', ')}`);
    process.exit(1);
  }

  const reserved = loadReservedTickers();
  const reservedCount = reserved.size;
  const taken = new Set(reserved);

  const originalCounts = new Map();
  for (let i = 1; i < rows.length; i++) {
    const t = (rows[i][tickerIdx] || '').toUpperCase();
    if (t) originalCounts.set(t, (originalCounts.get(t) || 0) + 1);
  }

  const changes = [];
  let semanticWins = 0;
  let derivedFallbacks = 0;

  for (let i = 1; i < rows.length; i++) {
    const row = rows[i];
    const name = row[nameIdx];
    if (!name) continue;

    // Identity seed: name + address (or city) - stable across re-exports, and
    // distinct for same-named businesses at different locations, which is the
    // common case here (four Golden Corrals, three Bubba's 33s).
    const seed = [name, row[addressIdx] || '', row[cityIdx] || ''].join('|');

    let ticker = semanticCandidate(name);
    let usedSemantic = Boolean(ticker);
    if (!ticker || taken.has(ticker)) {
      usedSemantic = false;
      let attempt = 0;
      do {
        ticker = derivedCandidate(seed, attempt++);
      } while (taken.has(ticker) && attempt < 1000);
      if (taken.has(ticker)) {
        console.error(`Exhausted ticker attempts for "${name}" - aborting.`);
        process.exit(1);
      }
    }

    taken.add(ticker);
    if (usedSemantic) semanticWins++; else derivedFallbacks++;

    const before = row[tickerIdx];
    if (before !== ticker) {
      changes.push({ line: i + 1, name, before, after: ticker });
    }
    row[tickerIdx] = ticker;
  }

  const dataRows = rows.length - 1;
  const collidingGroups = [...originalCounts.entries()].filter(([, c]) => c > 1);
  const rowsLost = collidingGroups.reduce((sum, [, c]) => sum + (c - 1), 0);

  console.log(`Input:            ${inputPath}`);
  console.log(`Data rows:        ${dataRows}`);
  console.log(`Reserved tickers: ${reservedCount} (from migration_data.json)`);
  console.log('');
  console.log('Before:');
  console.log(`  unique tickers:     ${originalCounts.size}`);
  console.log(`  colliding groups:   ${collidingGroups.length}`);
  console.log(`  rows that would be lost / abort the import: ${rowsLost}`);
  if (collidingGroups.length > 0) {
    const worst = collidingGroups.sort((a, b) => b[1] - a[1]).slice(0, 8)
      .map(([t, c]) => `${t}x${c}`).join('  ');
    console.log(`  worst offenders:    ${worst}`);
  }
  console.log('');
  console.log('After:');
  console.log(`  unique tickers:     ${taken.size - reservedCount} (of ${dataRows} rows)`);
  console.log(`  semantic:           ${semanticWins}`);
  console.log(`  derived fallback:   ${derivedFallbacks}`);
  console.log(`  changed from input: ${changes.length}`);

  if (changes.length > 0) {
    console.log('\nSample changes:');
    for (const c of changes.slice(0, 10)) {
      console.log(`  line ${String(c.line).padStart(4)}  ${(c.before || '(blank)').padEnd(6)} -> ${c.after}  ${c.name.slice(0, 44)}`);
    }
    if (changes.length > 10) console.log(`  ... and ${changes.length - 10} more`);
  }

  if (!isWrite) {
    console.log('\nReport only - re-run with --write to produce the corrected CSV.');
    return;
  }

  const outPath = inputPath.replace(/\.csv$/i, '') + '.tickers.csv';
  fs.writeFileSync(outPath, toCsv(rows));
  console.log(`\nWrote ${outPath}`);
}

main();
