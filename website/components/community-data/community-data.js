/* KIN Community & Data layer — three initializers sharing one stylesheet:
 *
 *   initKinTicker(container, { live, pollMs, items })
 *   initCommunityMap(container, { live, leaflet, city })
 *   initSignupFlash({ live, pollMs, demo, assetBase })
 *
 * Data contract (WEBSITE_BLUEPRINT.md §2.3): the site reads only the
 * sanitized `web_public/{ticker,map,signups}` documents written by the
 * web_projection Cloud Functions. `live: true` polls them through the
 * Firestore REST API (no SDK bytes); the default is brand-styled mock data
 * so every component renders before the backend projections are deployed.
 */

const FIREBASE_PROJECT_ID = "kinvest-build-app";
const FIRESTORE_REST_BASE =
  `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}` +
  `/databases/(default)/documents/web_public`;

// Master Branding Library (CLAUDE.md): transparent mark for toast icons.
const DEFAULT_ASSET_BASE = "../../../assets/KIN_Logo_Assets";
const MARK_PATH = "10_website_header/header_logo_mark_transparent.png";

/* ------------------------- Firestore REST decoding ---------------------- */

// Decodes Firestore's typed REST value format ({stringValue: "x"} etc.)
// into plain JS, enough for the three web_public documents.
function decodeValue(v) {
  if (v == null) return null;
  if ("stringValue" in v) return v.stringValue;
  if ("doubleValue" in v) return Number(v.doubleValue);
  if ("integerValue" in v) return Number(v.integerValue);
  if ("booleanValue" in v) return v.booleanValue;
  if ("timestampValue" in v) return v.timestampValue;
  if ("nullValue" in v) return null;
  if ("arrayValue" in v) return (v.arrayValue.values || []).map(decodeValue);
  if ("mapValue" in v) return decodeFields(v.mapValue.fields || {});
  return null;
}
function decodeFields(fields) {
  const out = {};
  for (const [k, v] of Object.entries(fields)) out[k] = decodeValue(v);
  return out;
}

async function fetchWebPublicDoc(docId) {
  const res = await fetch(`${FIRESTORE_REST_BASE}/${docId}`);
  if (!res.ok) throw new Error(`web_public/${docId}: HTTP ${res.status}`);
  const body = await res.json();
  return decodeFields(body.fields || {});
}

/* ------------------------------ Mock data ------------------------------ */

const MOCK_TICKER = {
  businesses: [
    { ticker: "BRSTX", score: 812.4, trendingUp: true },
    { ticker: "TAQRA", score: 790.1, trendingUp: true },
    { ticker: "JMFIT", score: 655.0, trendingUp: false },
    { ticker: "SABBQ", score: 640.8, trendingUp: true },
    { ticker: "HTXCF", score: 602.3, trendingUp: true },
    { ticker: "ATLBK", score: 588.9, trendingUp: false },
    { ticker: "KURLS", score: 545.2, trendingUp: true },
    { ticker: "PLNTD", score: 512.7, trendingUp: true },
  ],
  members: [
    { ticker: "KVIPR", score: 320.5, trendingUp: true },
    { ticker: "MRTNZ", score: 301.2, trendingUp: true },
    { ticker: "DLOOP", score: 288.0, trendingUp: false },
    { ticker: "JBIRD", score: 254.6, trendingUp: true },
  ],
};

const CITY_VIEWS = {
  "San Antonio": { center: [29.4241, -98.4936], zoom: 11 },
  Houston: { center: [29.7604, -95.3698], zoom: 11 },
  Atlanta: { center: [33.749, -84.388], zoom: 11 },
};

const MOCK_CATEGORIES = [
  "Restaurant", "Barbershop", "Fitness", "Retail", "Beauty",
  "Auto", "Bakery", "Coffee", "Services",
];

// Deterministic pseudo-random (mulberry32) so the mock density pattern is
// stable across reloads instead of shimmering on every visit.
function seededRandom(seed) {
  let a = seed;
  return () => {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function mockCityPoints(city, count, seed) {
  const rand = seededRandom(seed);
  const { center } = CITY_VIEWS[city];
  return Array.from({ length: count }, (_, i) => ({
    lat: center[0] + (rand() - 0.5) * 0.28,
    lng: center[1] + (rand() - 0.5) * 0.34,
    name: `${city.split(" ")[0]} Local #${i + 1}`,
    category: MOCK_CATEGORIES[Math.floor(rand() * MOCK_CATEGORIES.length)],
  }));
}

const MOCK_MAP = {
  cities: {
    "San Antonio": mockCityPoints("San Antonio", 46, 41),
    Houston: mockCityPoints("Houston", 28, 42),
    Atlanta: mockCityPoints("Atlanta", 19, 43),
  },
};

const MOCK_SIGNUPS = [
  { id: "m1", name: "Brew & Braid Coffeehouse", city: "San Antonio" },
  { id: "m2", name: "Third Ward Threads", city: "Houston" },
  { id: "m3", name: "Peach Curl Studio", city: "Atlanta" },
  { id: "m4", name: "Alamo City Autoworks", city: "San Antonio" },
];

/* ---------------------------- KIN Score Ticker -------------------------- */

export function initKinTicker(container, options = {}) {
  const pollMs = options.pollMs ?? 60000;

  container.innerHTML = `
    <div class="kin-ticker" role="region" aria-label="KIN Exchange live scores">
      <span class="kin-ticker__label">KIN EXCHANGE</span>
      <div class="kin-ticker__viewport">
        <div class="kin-ticker__track" data-clone="false"></div>
        <div class="kin-ticker__track" data-clone="true" aria-hidden="true"></div>
      </div>
    </div>`;

  const root = container.querySelector(".kin-ticker");
  const tracks = root.querySelectorAll(".kin-ticker__track");

  const itemHtml = (item, group) => `
    <span class="kin-ticker__item">
      <span class="kin-ticker__group">${group}</span>
      <span class="kin-ticker__symbol">$${item.ticker}</span>
      <span class="kin-ticker__score">${item.score.toFixed(1)}</span>
      <span class="kin-ticker__delta ${
        item.trendingUp ? "kin-ticker__delta--up" : "kin-ticker__delta--down"
      }" aria-label="${item.trendingUp ? "trending up" : "trending down"}">${
        item.trendingUp ? "▲" : "▼"
      }</span>
    </span>`;

  const render = (data) => {
    const html =
      data.businesses.map((b) => itemHtml(b, "BIZ")).join("") +
      data.members.map((m) => itemHtml(m, "MBR")).join("");
    const count = data.businesses.length + data.members.length;
    // ~3.5s of travel per item keeps the pace readable at any list size.
    root.style.setProperty("--kin-ticker-duration", `${Math.max(20, count * 3.5)}s`);
    tracks.forEach((t) => { t.innerHTML = html; });
  };

  render(options.items || MOCK_TICKER);

  if (options.live) {
    const refresh = async () => {
      try {
        const data = await fetchWebPublicDoc("ticker");
        if (data.businesses?.length || data.members?.length) render(data);
      } catch (e) {
        // Keep showing the last good data; the band must never blank out.
        console.warn("[kin-ticker]", e.message);
      }
    };
    refresh();
    setInterval(refresh, pollMs);
  }

  return root;
}

/* ---------------------------- Community map ----------------------------- */

export function initCommunityMap(container, options = {}) {
  const L = options.leaflet || globalThis.L;
  if (!L) throw new Error("initCommunityMap: Leaflet (L) not loaded");
  const initialCity = options.city || "San Antonio";

  container.innerHTML = `
    <section class="kin-map" aria-label="KIN business map">
      <div class="kin-map__head">
        <h2 class="kin-map__title">Businesses on the KIN Exchange</h2>
        <div class="kin-map__cities" role="group" aria-label="Choose a city"></div>
        <p class="kin-map__subtitle">Every dot is a local business on the Exchange.</p>
      </div>
      <div class="kin-map__canvas"></div>
      <div class="kin-map__foot">
        <span class="kin-map__dot" aria-hidden="true"></span>
        <span class="kin-map__count"></span>
      </div>
    </section>`;

  const cityBar = container.querySelector(".kin-map__cities");
  const canvas = container.querySelector(".kin-map__canvas");
  const countEl = container.querySelector(".kin-map__count");

  const map = L.map(canvas, {
    center: CITY_VIEWS[initialCity].center,
    zoom: CITY_VIEWS[initialCity].zoom,
    scrollWheelZoom: false, // page scroll must not hijack into the map
    attributionControl: true,
  });
  // CARTO dark basemap — matches the Evergreen/charcoal aesthetic. Swap
  // this one URL for a Mapbox style to upgrade later.
  L.tileLayer(
    "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
    {
      attribution:
        '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/attributions">CARTO</a>',
      maxZoom: 19,
    }
  ).addTo(map);

  const markerLayer = L.layerGroup().addTo(map);
  let mapData = options.data || MOCK_MAP;
  let activeCity = initialCity;

  const renderCityButtons = () => {
    cityBar.innerHTML = Object.keys(CITY_VIEWS)
      .map((city) => {
        const n = (mapData.cities[city] || []).length;
        return `
          <button class="kin-map__city" type="button" data-city="${city}"
                  aria-pressed="${city === activeCity}">
            ${city}<span class="kin-map__city-count">${n}</span>
          </button>`;
      })
      .join("");
  };

  const renderMarkers = () => {
    markerLayer.clearLayers();
    const points = mapData.cities[activeCity] || [];
    points.forEach((p) => {
      L.circleMarker([p.lat, p.lng], {
        radius: 6,
        color: "#0B3D2E",       // Evergreen stroke
        weight: 1.5,
        fillColor: "#D4AF37",   // gold fill
        fillOpacity: 0.85,
      })
        .bindPopup(
          `<span class="kin-map__popup-name">${p.name}</span><br>
           <span class="kin-map__popup-meta">${p.category || ""} · ${activeCity}</span>`
        )
        .addTo(markerLayer);
    });
    countEl.textContent =
      `${points.length} businesses shown in ${activeCity}`;
  };

  const selectCity = (city) => {
    activeCity = city;
    const view = CITY_VIEWS[city];
    map.setView(view.center, view.zoom);
    renderCityButtons();
    renderMarkers();
  };

  cityBar.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-city]");
    if (btn) selectCity(btn.dataset.city);
  });

  renderCityButtons();
  renderMarkers();

  if (options.live) {
    fetchWebPublicDoc("map")
      .then((data) => {
        if (data.cities) {
          mapData = data;
          renderCityButtons();
          renderMarkers();
        }
      })
      .catch((e) => console.warn("[kin-map]", e.message));
  }

  return { map, selectCity };
}

/* -------------------------- New Sign-up Flash --------------------------- */

export function initSignupFlash(options = {}) {
  const pollMs = options.pollMs ?? 30000;
  const toastMs = options.toastMs ?? 6000;
  const maxVisible = 3;
  const assetBase = (options.assetBase || DEFAULT_ASSET_BASE).replace(/\/$/, "");

  let host = document.querySelector(".kin-flash");
  if (!host) {
    host = document.createElement("div");
    host.className = "kin-flash";
    // polite: announces without interrupting the screen reader mid-sentence.
    host.setAttribute("role", "status");
    host.setAttribute("aria-live", "polite");
    document.body.appendChild(host);
  }

  const dismiss = (toast) => {
    toast.setAttribute("data-leaving", "true");
    setTimeout(() => toast.remove(), 250);
  };

  const show = ({ name, city }) => {
    while (host.children.length >= maxVisible) host.firstChild.remove();

    const toast = document.createElement("div");
    toast.className = "kin-flash__toast";
    toast.innerHTML = `
      <span class="kin-flash__icon">
        <img src="${assetBase}/${MARK_PATH}" alt="" width="858" height="819" decoding="async">
      </span>
      <p class="kin-flash__text">
        New business added: <strong>${name}</strong>${city ? ` in ${city}` : ""}!
      </p>
      <button class="kin-flash__close" type="button" aria-label="Dismiss">×</button>`;
    toast.querySelector(".kin-flash__close")
      .addEventListener("click", () => dismiss(toast));
    host.appendChild(toast);
    setTimeout(() => { if (toast.isConnected) dismiss(toast); }, toastMs);
  };

  const seen = new Set();

  if (options.live) {
    // First poll only primes the dedupe set — visitors shouldn't get
    // toasted with everything that happened before they arrived.
    let primed = false;
    const poll = async () => {
      try {
        const data = await fetchWebPublicDoc("signups");
        const items = data.items || [];
        for (const item of [...items].reverse()) {
          if (seen.has(item.id)) continue;
          seen.add(item.id);
          if (primed) show(item);
        }
        primed = true;
      } catch (e) {
        console.warn("[kin-flash]", e.message);
      }
    };
    poll();
    setInterval(poll, pollMs);
  }

  if (options.demo) {
    let i = 0;
    const demoNext = () => show(MOCK_SIGNUPS[i++ % MOCK_SIGNUPS.length]);
    setTimeout(demoNext, options.demoDelayMs ?? 2000);
    setInterval(demoNext, options.demoIntervalMs ?? 12000);
  }

  return { show };
}
