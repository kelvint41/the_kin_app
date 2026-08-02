# KIN Tier Strategy: Community Wealth Building

## Mission
KIN is not a monetization engine—it's **wealth-building infrastructure for the Black community**. Every feature, every tier, every dollar earned serves one purpose: **create economic opportunity and close the wealth gap**.

We're building:
- **Job market access** (Free: post jobs, find work)
- **Business visibility** (Free: basic listing → Founder: broadcast location → Elite: always featured)
- **Customer discovery** (Customers find Black-owned businesses)
- **Hiring ecosystem** (Business owners find employees without expensive recruiters)
- **Community network** (Wealth circulates within community, not extracted from it)

Money we make enables us to build *better* tools, not to gatekeep opportunity.

---

# Map Page Premium Carousel Strategy

**Location**: Bottom of Google Map page
**Current State**: Rotating 3 premium-tier businesses
**Enhanced Vision**: **Dynamic, continuously scrolling carousel** showing ALL paid-tier businesses with animations and live activity
**Prime Real Estate**: First thing customer eyes go to when they open the map — perfect for premium advertising placement

---

## The Carousel Experience

### **Visual Design**
```
┌────────────────────────────────────────────────────────┐
│ 🎬 [Card 1] ✨ [Card 2] 🚐 [Card 3]→ [Card 4] [Card 5] │
│    (scrolling left ← ← ←)                               │
│    Auto-scroll + User can swipe                         │
└────────────────────────────────────────────────────────┘

- Shows 3-4 businesses visible at once
- Continuous horizontal scroll (left)
- Auto-scrolling + swipe-to-navigate
- Active beacon cards flash/animate
- Smooth transitions between cards
```

### **Animation/Activity**
- **Auto-scroll**: Businesses scroll continuously left
- **Active Beacon Flash**: 🚨 pulse/glow animation when "We're Here" live
- **Card entrance**: Smooth fade-in as new card enters viewport
- **Hover effects**: Card lifts/highlights on hover
- **Delivery services**: Animated delivery icon for active mobile services
- **Draws attention**: Movement + color (gold accents) catch eye immediately

---

## The Opportunity

The bottom carousel is **prime advertising real estate** — it's constantly moving, engaging, and the first thing customers notice. We showcase:

1. **Food Trucks with Active Location Beacons** 🚐
   - Real-time broadcasting status
   - "Now Serving [location]" badge
   - Currently operating indicator

2. **Top-Tier Business Subscribers**
   - Yearly package holders (featured spot)
   - Elite/Professional tier customers
   - Your wife's business as flagship example

3. **Featured Quest Discoveries**
   - Top-rated businesses from KIN Quest
   - High-engagement businesses
   - Community favorites

4. **Seasonal/Promotional Spotlight**
   - Grand openings
   - Special events
   - Flash promotions

---

## Complete Tier Strategy (Carousel + Features)

### **Free Tier** - Community Foundation
- ✅ Basic map listing (visible in directory, discoverable)
- ✅ Google Calendar integration (schedule management for mobile services)
- ✅ Job board access (post openings, find employees)
- ✅ Community networking
- ❌ **No carousel placement** (not featured, but discoverable)
- **Strategy**: High utility, no payment barrier. Drives organic engagement & tier upgrades.
- **Message**: "Post jobs, manage calendar, get discovered. Ready to feature yourself? Upgrade to Founder."

### **Carousel Visibility** (Tiers with Carousel)

**Key Principle: Only Paid Tiers Get Carousel**
Every business with a paid subscription gets carousel placement. The difference is **visibility frequency** and **animation priority**.

### **Founder** ✅
- **Price**: $29/month or $288/year (20% annual discount)
- **Target**: Mobile services (barbers, stylists, cleaners), solopreneurs, gig workers
- **Carousel inclusion**: YES - entry-level visibility
- **Display frequency**: Light rotation (1x/week visibility)
- **Card styling**: Standard card with "Founder" badge
- **Features**: Location Beacon access, basic analytics, job posting boost
- **Visibility**: Carousel rotation 1x/week, featured in "Top Openings" job board
- **Message**: "Broadcast your location, reach more customers"

### **Founding Local** ✅✅
- **Price**: $59/month or $588/year (20% annual discount)
- **Target**: Growing local businesses, small restaurants, boutiques
- **Carousel inclusion**: YES - regular visibility
- **Display frequency**: Standard rotation (1-2x/week visibility)
- **Card styling**: Clean, professional card with "Founding Local" badge
- **Features**: Location Beacons, performance analytics, unlimited job posting
- **Visibility**: Regular carousel scrolling, visible multiple times per session
- **Bonus**: Location Beacon active? → Card highlights with subtle glow

### **Premium Local** ✅✅✅
- **Price**: $99/month or $950/year (20% annual discount)
- **Target**: Established local businesses, multi-location services
- **Carousel inclusion**: YES - premium visibility
- **Display frequency**: Prioritized rotation (3-4x/week visibility)
- **Card styling**: Enhanced card with "Premium Partner" badge + gold accent border
- **Features**: Unlimited Location Beacons, advanced analytics, hiring tools
- **Visibility**: Appears more often in carousel rotation due to tier priority
- **Bonus**: Location Beacon active? → Card pulses with "🚨 We're Here" badge

### **Elite** ✅✅✅✅
- **Price**: $149/month or $1,430/year (20% annual discount)
- **Target**: Flagship businesses, multiple locations, serious hiring
- **Carousel inclusion**: YES - ALWAYS featured prominently
- **Display frequency**: CONSTANT - appears at top, never rotated off
- **Card styling**: Premium featured treatment with "Featured Partner" + "Elite Member" badges
- **Features**: Everything unlimited, priority support, account manager, co-marketing
- **Visibility**: Always visible as top card, stands out dramatically
- **Example**: Your wife's business always featured when she has active beacon
- **Bonus**: Location Beacon active? → Animated "🚨 WE'RE HERE NOW!" announcement with special styling

---

## Carousel Display Sections

### **Section 1: Location Beacons (Real-Time)**
```
🚐 NOW SERVING

[Business 1] - 5th & Main St (2h left)
[Business 2] - Downtown (4h left)
[Business 3] - North End (Until 5 PM)

Rotates every 30 seconds
Shows only ACTIVE beacons (mobile_location_active == true)
Tap to view on map or visit profile
```

**Why it works**:
- Real-time, dynamic content
- Creates urgency (limited time)
- Drives immediate action (customers want to go NOW)
- Premium placement for Location Beacon feature (justifies subscription)

### **Section 2: Featured Partners (Paid Tiers)**
```
🌟 FEATURED PARTNERS

[Elite Member 1] - Featured Partner
[Premium Member 1] - Premium Partner
[Yearly Subscriber] - Featured Partner

Rotates based on tier:
- Yearly/Elite: Every day (featured slot)
- Founding Local+: 3-4x per week
- Founding Local: 1-2x per week
```

### **Section 3: Quest Discoveries (Community)**
```
👑 TOP DISCOVERIES

[Highest-rated business from Quest]
[Most-checked-in business]
[Trending this week]

Shows businesses with:
- 4.5+ star rating
- 20+ Quest check-ins
- Community verified as authentic
```

---

## Implementation: Carousel Carousel Configuration

### Current Implementation
```dart
if (premiumBusinesses.isNotEmpty)
  Align(
    alignment: AlignmentDirectional(0.0, 1.0), // Bottom
    child: Column(
      children: [
        // "See All" link
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              BusinessPreviewCardWidget(...),
              BusinessPreviewCardWidget(...),
              BusinessPreviewCardWidget(...),
            ],
          ),
        ),
      ],
    ),
  ),
```

### Enhanced Implementation

#### **Section A: Location Beacon Carousel** (Highest Priority)
```dart
// Show active Location Beacons at the VERY TOP of carousel
if (activeLocationBeacons.isNotEmpty)
  Align(
    alignment: AlignmentDirectional(0.0, 1.0),
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text("🚐 NOW SERVING"),
              Spacer(),
              Text("See All", style: link),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...activeLocationBeacons.map((business) =>
                LocationBeaconCardPreview(
                  business: business,
                  showCountdown: true,
                  onTap: () => viewMap(business),
                ),
              ),
            ].divide(SizedBox(width: 12.0)),
          ),
        ),
      ],
    ),
  ),
```

#### **Section B: Tier-Based Featured Partners**
```dart
if (premiumBusinesses.isNotEmpty)
  Align(
    alignment: AlignmentDirectional(0.0, 1.0),
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text("🌟 FEATURED PARTNERS"),
              Spacer(),
              Text("See All", style: link),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...premiumBusinesses.map((business) {
                final tier = business.subscriptionTier;
                final isFeatured = tier == 'Elite' || 
                                   tier == 'Yearly';
                return FeaturedBusinessCard(
                  business: business,
                  badge: isFeatured ? "Featured Partner" : 
                         tier == 'Founding Local+' ? 
                         "Premium Partner" : 
                         "Founding Local",
                  isHighlight: isFeatured,
                );
              }),
            ].divide(SizedBox(width: 12.0)),
          ),
        ),
      ],
    ),
  ),
```

---

## Business Card Design Variations

### **Location Beacon Card**
```
┌─────────────────────┐
│ 🚐 NOW SERVING      │
│                     │
│ [Business Name]     │
│ [Category]          │
│                     │
│ 5th & Main St       │
│ ⏱ 2 hours left      │
│                     │
│ ⭐ 4.8 (126 reviews)│
│                     │
│ [OPEN NOW] [VISIT MAP]│
└─────────────────────┘
```

**Colors**: Green border (active/live status)
**Actions**: Tap card → view profile, "Visit Map" → navigate map

### **Featured Partner Card** (Premium Tier)
```
┌─────────────────────┐
│ 🌟 FEATURED PARTNER │
│                     │
│ [Business Name]     │
│ [Category]          │
│ [Hero Image]        │
│                     │
│ ⭐ 4.8 (126)       │
│                     │
│ [VIEW PROFILE]      │
└─────────────────────┘
```

**Colors**: Gold accent (premium), higher visual hierarchy
**Badge**: "Featured Partner" / "Premium Partner" / "Founding Local"

### **Quest Discovery Card**
```
┌─────────────────────┐
│ 👑 TOP DISCOVERY    │
│                     │
│ [Business Name]     │
│ [Category]          │
│                     │
│ 🏅 4.9 ⭐          │
│ 28 Quest Check-ins  │
│                     │
│ [DISCOVER]          │
└─────────────────────┘
```

**Colors**: Gold/accent
**Shows**: Community engagement metrics

---

## Rotation & Scheduling Logic

### **Location Beacons**
```
Query: mobile_location_active == true
Rotation: Real-time (refresh every 5 min)
Display: All active beacons (scroll horizontally)
Priority: Most recent activation first
```

### **Featured Partners**
```
Query: subscription_tier in ['Elite', 'Yearly', 'Founding Local+']
Rotation Schedule:
  - Elite/Yearly: Display every day (featured slot)
  - Founding Local+: Display 3-4x per week (rotated)
  - Founding Local: Display 1-2x per week (rotated)
Priority Within Tier:
  - Yearly packages: First
  - Elite: Second
  - Founding Local+: Third
```

### **Quest Discoveries** (Optional)
```
Query: quest_check_in_count >= 20 AND rating >= 4.5
Rotation: Weekly (changes Monday)
Display: Top 3 discovered businesses
Priority: Highest quest engagement first
```

---

## Revenue Model: Carousel as Monetization

### **Carousel as Premium Feature**

| Tier | Display Frequency | Position | Monthly | Annual | Value |
|------|-------------------|----------|---------|--------|-------|
| Founding Local | 1-2x/week | Regular slot | $59 | $588 | Exposure to map visitors |
| Premium Local | 3-4x/week | Premium slot | $99 | $950 | 2-3x more visibility |
| Elite | Daily | Featured (#1-3) | $149 | $1,430 | Maximum visibility |

**Business Owner Perspective**:
- "Where will my customers see me first?" → Carousel
- "How do I get more visibility on the map?" → Premium Local tier
- "Can I guarantee daily visibility?" → Elite package

**KIN Revenue Projections**:
- $59 × 1000 Founding Local subscribers = $59k/month
- $99 × 500 Premium Local subscribers = $49.5k/month  
- $149 × 100 Elite subscribers = $14.9k/month
- **Total: ~$123k/month (conservative) to $150k+/month (with growth)**

**Annual Incentive**:
- Annual discounts (20% off) incentivize longer commitments
- Customers who switch to annual increase LTV by 2.4x
- Example: 30% annual conversion = +$30k/month lifetime value

---

## Location Beacon + Carousel Integration

### **The Flywheel**

```
Food truck owner subscribes to Location Beacon feature
        ↓
Requires Founding Local+ tier minimum ($99/month)
        ↓
Automatically eligible for featured carousel placement
        ↓
When beacon is ACTIVE → Carousel shows them
        ↓
Customers see "NOW SERVING" in real-time
        ↓
Higher conversion (immediate action vs. general interest)
        ↓
Owner sees ROI, renews subscription, upgrades tier
        ↓
Cycle repeats → Owner becomes loyal paying customer
```

### **Incentive Logic**

```
Owner subscribes Founding Local+ ($99/month)
  ✓ Gets Location Beacon feature access
  ✓ Gets carousel placement eligibility (3-4x/week)
  ✓ When beacon active → featured slot priority

Owner upgrades to Elite/Yearly ($249/month)
  ✓ Gets carousel placement daily
  ✓ Always featured when checking map (prominent position)
  ✓ Special "Featured Partner" badge
  ✓ Highest visibility = highest ROI

Result: Location Beacon and Carousel create 
a powerful upsell path
```

---

## Carousel Performance Metrics

Track these KPIs:

```
Engagement:
- Carousel impressions (map page views)
- Carousel card clicks (% of impressions)
- Click-through to profile (conversion)
- Click-through to "Visit Map" (action)

Business Metrics:
- Tier distribution (how many in each tier)
- Carousel visibility correlation with sales
- Customer LTV by carousel tier
- Churn rate by visibility tier

Revenue:
- Monthly recurring revenue from carousel visibility
- ARPU (average revenue per user) by tier
- Carousel tier upgrade rate
- Location Beacon adoption by tier
```

---

## Example: Your Wife's Business Placement

### **Showcase Strategy**

Your wife's business (yearly package) is **ALWAYS FEATURED** in carousel:

```
Top of carousel:
┌─────────────────────┐
│ 🌟 FEATURED         │
│ [Your Wife's        │
│  Business Name]     │
│ [Category/Details]  │
│ ⭐ 4.9 (215)       │
│ [VIEW PROFILE]      │
└─────────────────────┘

Constantly visible, highest real estate
Shows off best example of KIN ecosystem success
Drives aspiration: "I want to be featured like that"
```

**Benefits**:
- Flagship example of platform power
- Demonstrates that premium placement works
- Inspires other business owners to upgrade tiers
- First thing customers see when opening map

---

## Implementation Roadmap

### **Phase 1: Location Beacon Carousel** (Week 1-2)
- [ ] Add Location Beacon carousel section at top
- [ ] Query active beacons real-time
- [ ] Display with countdown timers
- [ ] "NOW SERVING" badge styling
- [ ] Link to map/profile

### **Phase 2: Tier-Based Featured** (Week 3-4)
- [ ] Reorganize premium carousel by tier
- [ ] Add rotation scheduling (daily for Elite)
- [ ] Visual differentiation (featured vs. premium)
- [ ] Badge system (Featured Partner, Premium Partner)

### **Phase 3: Quest Integration** (Week 5-6)
- [ ] Add "Top Discoveries" carousel section
- [ ] Query high-engagement Quest businesses
- [ ] Community badge styling
- [ ] Weekly rotation

### **Phase 4: Analytics & Monitoring** (Week 7-8)
- [ ] Track carousel impressions
- [ ] Monitor tier CTR (click-through rates)
- [ ] Revenue correlation dashboards
- [ ] A/B test carousel order/styling

---

## Summary

**The map carousel is your prime advertising real estate.**

**Tier Strategy**:
- **Free**: No carousel (drives upgrades)
- **Founding Local**: 1-2x/week regular visibility
- **Founding Local+**: 3-4x/week premium visibility
- **Elite/Yearly**: Daily featured (premium slot)

**Content Strategy**:
- **Location Beacons** (real-time, urgent)
- **Featured Partners** (tier-based visibility)
- **Quest Discoveries** (community engagement)

**Revenue Impact**:
- Carousel becomes core monetization feature
- Premium placement justifies tier pricing
- Location Beacon drives Founding Local+ upgrades
- Your wife's business as flagship example

**Result**: Map page becomes your highest-converting sales funnel for premium tier subscriptions. 🚀
