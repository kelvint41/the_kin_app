/* Pillar page directory data — San Antonio.
 *
 * ⚠️ PLACEHOLDER_LISTINGS is true: every entry below is FICTIONAL sample
 * data for layout work. Before publishing this page:
 *   1. Replace entries with real, verified businesses from the discovery
 *      pipeline (DISCOVERY_BLUEPRINT.md) — kin_verified/self_attested only.
 *   2. Flip PLACEHOLDER_LISTINGS to false. That removes the on-page sample
 *      notice and enables the ItemList/LocalBusiness JSON-LD (structured
 *      data is only ever emitted for real businesses).
 *   3. Update LAST_UPDATED — the monthly refresh is the freshness signal
 *      the SEO plan depends on (CONTENT_STRATEGY.md §4).
 *
 * Long-term this file is generated from web_public data; the render code
 * in guide.js doesn't change.
 */

export const PLACEHOLDER_LISTINGS = true;

export const LAST_UPDATED = "July 2026";

export const CATEGORIES = [
  {
    id: "restaurants",
    title: "Restaurants & Food",
    blurb:
      "From weekend brunch to late-night barbecue — kitchens owned by your neighbors.",
  },
  {
    id: "beauty",
    title: "Beauty & Barbering",
    blurb: "Chairs, studios, and salons where the culture is the craft.",
  },
  {
    id: "fitness",
    title: "Fitness & Wellness",
    blurb: "Trainers, gyms, and wellness studios building a stronger city.",
  },
  {
    id: "retail",
    title: "Retail & Shopping",
    blurb: "Boutiques and shops with stories you won't find at the mall.",
  },
  {
    id: "services",
    title: "Professional Services",
    blurb: "The businesses that keep other businesses (and homes) running.",
  },
];

export const LISTINGS = [
  // --- Restaurants & Food (fictional samples) ---
  {
    category: "restaurants",
    name: "Sample Smokehouse No. 1",
    ticker: "SABBQ",
    neighborhood: "East Side",
    description:
      "Placeholder entry — replace with a verified San Antonio restaurant from the directory.",
    verified: true,
    website: "",
  },
  {
    category: "restaurants",
    name: "Sample Kitchen No. 2",
    ticker: "TAQRA",
    neighborhood: "Southtown",
    description: "Placeholder entry — replace with a verified listing.",
    verified: true,
    website: "",
  },
  {
    category: "restaurants",
    name: "Sample Coffeehouse No. 3",
    ticker: "BRWBR",
    neighborhood: "Downtown",
    description: "Placeholder entry — replace with a verified listing.",
    verified: false,
    website: "",
  },
  {
    category: "restaurants",
    name: "Sample Bakery No. 4",
    ticker: "SWEET",
    neighborhood: "Medical Center",
    description: "Placeholder entry — replace with a verified listing.",
    verified: false,
    website: "",
  },
  // --- Beauty & Barbering ---
  {
    category: "beauty",
    name: "Sample Barbershop No. 1",
    ticker: "FADES",
    neighborhood: "West Side",
    description: "Placeholder entry — replace with a verified listing.",
    verified: true,
    website: "",
  },
  {
    category: "beauty",
    name: "Sample Curl Studio No. 2",
    ticker: "KURLS",
    neighborhood: "Stone Oak",
    description: "Placeholder entry — replace with a verified listing.",
    verified: true,
    website: "",
  },
  {
    category: "beauty",
    name: "Sample Nail Bar No. 3",
    ticker: "POLSH",
    neighborhood: "Alamo Heights",
    description: "Placeholder entry — replace with a verified listing.",
    verified: false,
    website: "",
  },
  // --- Fitness & Wellness ---
  {
    category: "fitness",
    name: "Sample Fitness Lab No. 1",
    ticker: "JMFIT",
    neighborhood: "North Central",
    description: "Placeholder entry — replace with a verified listing.",
    verified: true,
    website: "",
  },
  {
    category: "fitness",
    name: "Sample Yoga Collective No. 2",
    ticker: "BRETH",
    neighborhood: "Southtown",
    description: "Placeholder entry — replace with a verified listing.",
    verified: false,
    website: "",
  },
  {
    category: "fitness",
    name: "Sample Wellness Spa No. 3",
    ticker: "GLOWS",
    neighborhood: "The Pearl",
    description: "Placeholder entry — replace with a verified listing.",
    verified: false,
    website: "",
  },
  // --- Retail & Shopping ---
  {
    category: "retail",
    name: "Sample Boutique No. 1",
    ticker: "THRDS",
    neighborhood: "Southtown",
    description: "Placeholder entry — replace with a verified listing.",
    verified: true,
    website: "",
  },
  {
    category: "retail",
    name: "Sample Bookshop No. 2",
    ticker: "PAGES",
    neighborhood: "Downtown",
    description: "Placeholder entry — replace with a verified listing.",
    verified: false,
    website: "",
  },
  {
    category: "retail",
    name: "Sample Plant Shop No. 3",
    ticker: "PLNTD",
    neighborhood: "East Side",
    description: "Placeholder entry — replace with a verified listing.",
    verified: true,
    website: "",
  },
  // --- Professional Services ---
  {
    category: "services",
    name: "Sample Autoworks No. 1",
    ticker: "MOTOR",
    neighborhood: "West Side",
    description: "Placeholder entry — replace with a verified listing.",
    verified: true,
    website: "",
  },
  {
    category: "services",
    name: "Sample Design Studio No. 2",
    ticker: "PIXEL",
    neighborhood: "Downtown",
    description: "Placeholder entry — replace with a verified listing.",
    verified: false,
    website: "",
  },
  {
    category: "services",
    name: "Sample Cleaning Co. No. 3",
    ticker: "SHINE",
    neighborhood: "Citywide",
    description: "Placeholder entry — replace with a verified listing.",
    verified: false,
    website: "",
  },
];
