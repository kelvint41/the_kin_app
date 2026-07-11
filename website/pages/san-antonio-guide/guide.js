/* Renders the San Antonio pillar-page directory from listings.js.
 * JSON-LD (ItemList of LocalBusiness) is emitted ONLY when
 * PLACEHOLDER_LISTINGS is false — structured data must never describe
 * fictional sample businesses.
 */

import {
  PLACEHOLDER_LISTINGS,
  LAST_UPDATED,
  WAITLIST_URL,
  CATEGORIES,
  LISTINGS,
} from "./listings.js";

function esc(s) {
  return String(s ?? "").replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  }[c]));
}

function formatPhone(raw) {
  const d = String(raw || "").replace(/\D/g, "");
  return d.length === 10 ? `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}` : "";
}

export function renderGuide() {
  document.getElementById("guide-updated").textContent =
    `Updated ${LAST_UPDATED} · ${LISTINGS.length} businesses · curated & audited by Kinvest Guidance`;

  // Sample-data notice: visible until real listings replace the placeholders.
  if (PLACEHOLDER_LISTINGS) {
    const notice = document.createElement("p");
    notice.className = "guide-sample-notice";
    notice.textContent =
      "Preview build: the listings below are placeholder sample data for " +
      "layout review — not real businesses. Real verified listings from " +
      "the KIN directory land here before this page publishes.";
    document.querySelector(".guide-intro").appendChild(notice);
  }

  // Category table of contents (with live counts)
  const toc = document.getElementById("guide-toc");
  toc.innerHTML = CATEGORIES.map((c) => {
    const n = LISTINGS.filter((l) => l.category === c.id).length;
    return `<a href="#${c.id}">${esc(c.title)} (${n})</a>`;
  }).join("");

  // Directory sections — featured entries get priority placement.
  const main = document.getElementById("guide-sections");
  main.innerHTML = CATEGORIES.map((cat) => {
    const items = LISTINGS.filter((l) => l.category === cat.id).sort(
      (a, b) => (b.featured === true) - (a.featured === true)
    );
    const cards = items
      .map((l) => {
        const phone = formatPhone(l.phone);
        const place =
          l.city === "San Antonio"
            ? `${l.neighborhood} · San Antonio, TX`
            : `${l.city}, TX`;
        return `
        <article class="biz-card${l.featured ? " biz-card--featured" : ""}">
          <div class="biz-card__top">
            <h3 class="biz-card__name">${esc(l.name)}</h3>
            <span class="biz-card__ticker">$${esc(l.ticker)}</span>
          </div>
          ${l.featured ? '<span class="biz-card__featured-chip">★ Featured</span>' : ""}
          ${l.verified ? '<span class="biz-card__badge">KIN Verified</span>' : ""}
          <p class="biz-card__meta">${esc(place)}${phone ? ` · ${phone}` : ""}</p>
          <p class="biz-card__desc">${esc(l.description)}</p>
          ${
            l.website
              ? `<a class="biz-card__link" href="${esc(l.website)}"
                   rel="noopener">Visit website →</a>`
              : `<a class="biz-card__link" href="${esc(WAITLIST_URL)}"
                   rel="noopener">Find them in The KIN App →</a>`
          }
        </article>`;
      })
      .join("");
    return `
      <section class="guide-section" id="${cat.id}">
        <h2>${esc(cat.title)}</h2>
        <p class="section-blurb">${esc(cat.blurb)}</p>
        <div class="guide-grid">${cards}</div>
      </section>`;
  }).join("");

  // Structured data — real listings only.
  if (!PLACEHOLDER_LISTINGS) {
    const itemList = {
      "@context": "https://schema.org",
      "@type": "ItemList",
      name: "Black-Owned Businesses in San Antonio — The KIN Directory",
      numberOfItems: LISTINGS.length,
      itemListElement: LISTINGS.map((l, i) => {
        const digits = String(l.phone || "").replace(/\D/g, "");
        return {
          "@type": "ListItem",
          position: i + 1,
          item: {
            "@type": "LocalBusiness",
            name: l.name,
            address: {
              "@type": "PostalAddress",
              addressLocality: l.city || "San Antonio",
              addressRegion: "TX",
            },
            ...(digits.length === 10 ? { telephone: `+1${digits}` } : {}),
            ...(l.website ? { url: l.website } : {}),
          },
        };
      }),
    };
    const tag = document.createElement("script");
    tag.type = "application/ld+json";
    tag.textContent = JSON.stringify(itemList);
    document.head.appendChild(tag);
  }
}
