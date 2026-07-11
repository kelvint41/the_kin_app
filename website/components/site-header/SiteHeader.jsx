/* KIN Site Header — React version. Shares site-header.css with the vanilla
 * component (same class names, same flutter_flow_theme.dart tokens).
 *
 *   import SiteHeader from "./SiteHeader.jsx";
 *   import "./site-header.css";
 *   <SiteHeader activeHref="#home" />
 */

import { useEffect, useState } from "react";

// Gold-text lockup: the header surface is always Evergreen (dark), per the
// CLAUDE.md Master Branding Library selection matrix.
const DEFAULT_ASSET_BASE = "../../../assets/KIN_Logo_Assets";
const LOGO_PATH = "10_website_header/header_logo_lockup_gold_text.png";
const LOGO_WIDTH = 1558;
const LOGO_HEIGHT = 286;

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

export default function SiteHeader({
  links = DEFAULT_LINKS,
  actions = DEFAULT_ACTIONS,
  activeHref = links[0]?.href,
  homeHref = "#home",
  assetBase = DEFAULT_ASSET_BASE,
}) {
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const logoSrc = `${assetBase.replace(/\/$/, "")}/${LOGO_PATH}`;

  return (
    <header
      className="kin-header"
      data-scrolled={String(scrolled)}
      data-menu-open={String(menuOpen)}
      onKeyDown={(e) => {
        if (e.key === "Escape") setMenuOpen(false);
      }}
    >
      <div className="kin-header__inner">
        <a
          className="kin-header__brand"
          href={homeHref}
          aria-label="Kinvest Guidance — home"
        >
          <img
            src={logoSrc}
            alt="Kinvest Guidance"
            width={LOGO_WIDTH}
            height={LOGO_HEIGHT}
            decoding="async"
          />
        </a>
        <button
          className="kin-header__toggle"
          type="button"
          aria-expanded={menuOpen}
          aria-controls="kin-header-menu"
          onClick={() => setMenuOpen((open) => !open)}
        >
          <span className="visually-hidden">Menu</span>
          <span className="kin-header__toggle-bar" aria-hidden="true" />
          <span className="kin-header__toggle-bar" aria-hidden="true" />
          <span className="kin-header__toggle-bar" aria-hidden="true" />
        </button>
        <div className="kin-header__menu" id="kin-header-menu">
          <nav
            className="kin-header__nav"
            aria-label="Primary"
            onClick={() => setMenuOpen(false)}
          >
            {links.map((l) => (
              <a
                key={l.href}
                className="kin-header__link"
                href={l.href}
                aria-current={l.href === activeHref ? "page" : undefined}
              >
                {l.label}
              </a>
            ))}
          </nav>
          <div className="kin-header__actions">
            <a className="kin-header__ghost" href={actions.ghost.href}>
              {actions.ghost.label}
            </a>
            <a className="kin-header__cta" href={actions.cta.href}>
              {actions.cta.label}
            </a>
          </div>
        </div>
      </div>
    </header>
  );
}
