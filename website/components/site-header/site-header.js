/* KIN Site Header — framework-free component.
 *
 * Usage:
 *   <link rel="stylesheet" href="site-header.css">
 *   <div id="site-header"></div>
 *   <script type="module">
 *     import { initSiteHeader } from "./site-header.js";
 *     initSiteHeader(document.getElementById("site-header"), { activeHref: "#home" });
 *   </script>
 *
 * Shares the Notify-Me component's design tokens (flutter_flow_theme.dart)
 * and asset conventions (CLAUDE.md Master Branding Library).
 */

// Gold-text lockup: the header surface is always Evergreen (dark), so per
// the CLAUDE.md selection matrix this is the one correct variant here.
const DEFAULT_ASSET_BASE = "../../../assets/KIN_Logo_Assets";
const LOGO_PATH = "10_website_header/header_logo_lockup_gold_text.png";
const LOGO_WIDTH = 1558;
const LOGO_HEIGHT = 286;

// Core navigation placeholders; swap hrefs for real routes/anchors as the
// shell pages come online.
const DEFAULT_LINKS = [
  { label: "Home", href: "#home" },
  { label: "About", href: "#about" },
  { label: "Spotlight", href: "#spotlight" },
  { label: "KIN Score", href: "#kin-score" },
];

const DEFAULT_ACTIONS = {
  ghost: { label: "Support", href: "#support" },
  cta: { label: "Get the App", href: "#get-the-app" },
};

export function initSiteHeader(container, options = {}) {
  const assetBase = (options.assetBase || DEFAULT_ASSET_BASE).replace(/\/$/, "");
  const links = options.links || DEFAULT_LINKS;
  const actions = { ...DEFAULT_ACTIONS, ...(options.actions || {}) };
  const activeHref = options.activeHref || links[0]?.href;
  const homeHref = options.homeHref || "#home";

  const navLinks = links
    .map(
      (l) => `
        <a class="kin-header__link" href="${l.href}"
           ${l.href === activeHref ? 'aria-current="page"' : ""}>${l.label}</a>`
    )
    .join("");

  container.innerHTML = `
    <header class="kin-header" data-scrolled="false" data-menu-open="false">
      <div class="kin-header__inner">
        <a class="kin-header__brand" href="${homeHref}" aria-label="Kinvest Guidance — home">
          <img
            src="${assetBase}/${LOGO_PATH}"
            alt="Kinvest Guidance"
            width="${LOGO_WIDTH}"
            height="${LOGO_HEIGHT}"
            decoding="async"
          >
        </a>
        <button class="kin-header__toggle" type="button"
                aria-expanded="false" aria-controls="kin-header-menu">
          <span class="visually-hidden">Menu</span>
          <span class="kin-header__toggle-bar" aria-hidden="true"></span>
          <span class="kin-header__toggle-bar" aria-hidden="true"></span>
          <span class="kin-header__toggle-bar" aria-hidden="true"></span>
        </button>
        <div class="kin-header__menu" id="kin-header-menu">
          <nav class="kin-header__nav" aria-label="Primary">${navLinks}</nav>
          <div class="kin-header__actions">
            <a class="kin-header__ghost" href="${actions.ghost.href}">${actions.ghost.label}</a>
            <a class="kin-header__cta" href="${actions.cta.href}">${actions.cta.label}</a>
          </div>
        </div>
      </div>
    </header>`;

  const header = container.querySelector(".kin-header");
  const toggle = header.querySelector(".kin-header__toggle");
  const menu = header.querySelector(".kin-header__menu");

  // .kin-header's `position: sticky` can only stick within its parent, and
  // this mount container is exactly one header tall — so the container
  // itself must be the sticky element or the header scrolls away with it.
  container.style.position = "sticky";
  container.style.top = "0";
  container.style.zIndex = "100";

  // Translucent-blur treatment once the page leaves the top.
  const onScroll = () => {
    header.setAttribute("data-scrolled", window.scrollY > 8 ? "true" : "false");
  };
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  const setMenu = (open) => {
    header.setAttribute("data-menu-open", String(open));
    toggle.setAttribute("aria-expanded", String(open));
  };

  toggle.addEventListener("click", () => {
    setMenu(header.getAttribute("data-menu-open") !== "true");
  });

  // Close the mobile panel after navigating or on Escape.
  menu.addEventListener("click", (e) => {
    if (e.target.closest("a")) setMenu(false);
  });
  header.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
      setMenu(false);
      toggle.focus();
    }
  });

  return header;
}
