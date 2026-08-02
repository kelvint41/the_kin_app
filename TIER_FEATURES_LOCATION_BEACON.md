# Subscription Tier Features - Location Beacon

## Feature: Location Beacon (Mobile Vendors Only)

### Tier Availability

| Tier | Price | Location Beacon | Details |
|------|-------|-----------------|---------|
| Community | Free | ❌ No | Free tier does not include Location Beacon feature |
| Founding Local | $59/mo | ✅ Yes | Can broadcast current location to customers |
| Founding Local+ | $99/mo | ✅ Yes | Can broadcast current location + extended features |
| Elite | Custom | ✅ Yes | Premium location broadcasting features |

### Feature Requirements

#### Business Requirements
- **Type**: Mobile vendor only (food trucks, mobile services, etc.)
- **Field**: `is_mobile_vendor` must be `true`
- **Claim Status**: Business must be claimed and verified

#### Subscription Requirements
- **Minimum Tier**: Founding Local ($59/mo)
- **Community Tier**: Cannot access feature
- **Access Enforcement**: UI-level gating + backend validation

### What Customers See

#### Customers on ANY Subscription (including free)
- ✅ See active Location Beacons on map
- ✅ See beacon announcements in Exchange feed
- ✅ See beacon status on business cards/carousels
- ✅ See "Now Serving [location]" badge
- ✅ See countdown timer (Xh left, Xm left)
- ✅ Can click "Find us on map" CTA

#### Customers with Community/Free Tier
- Can still discover and report Black-owned businesses
- Receive KIN Quest points for verified discoveries
- See all beacon announcements (no paywall)

### What Vendors See

#### Vendors on Community Tier (Free)
- ❌ Cannot access Location Beacon feature
- ❌ No "Start Broadcasting" button on Owner Profile
- 💡 Upgrade prompt: "Upgrade to Founding Local to broadcast your location"

#### Vendors on Founding Local+ Tiers
- ✅ Can activate Location Beacon
- ✅ Can set broadcast duration (Until 2 PM, Until 5 PM, All day)
- ✅ Can toggle auto-post to Exchange feed
- ✅ See active beacon with countdown timer
- ✅ Can stop broadcasting anytime
- ✅ See broadcast statistics (optional, Phase 4)

### Visibility Across App

#### Locations Where Beacons Display

1. **Exchange Feed**
   - LocationBeaconPostWidget shows announcement
   - Template: "🚨 We're live at [location]!"
   - Business name + "🚐 Live Now" badge
   - "📍 Find us on map" CTA button
   - Auto-post when beacon activated (if enabled)

2. **Business Carousels**
   - LocationBeaconBadgeWidget on business cards
   - "🚨 Now Serving [location]" badge
   - Countdown timer: "Xh left" / "Xm left"
   - Green success color to stand out

3. **Map View (GoogleMapPage)**
   - Truck emoji (🚐) marker instead of red pin
   - "Now Serving [location]" popup
   - Tap marker to view business profile
   - Phase 3A implementation

4. **Business Detail Pages**
   - Active beacon banner at top
   - Current location + countdown
   - "Find us on map" button

5. **Owner Profile (Owner Dashboard)**
   - LocationBeaconCardWidget shows status
   - Inactive: "Start Broadcasting" button
   - Active: "Stop Broadcasting" button with countdown
   - Only visible for mobile vendors on Founding Local+

### Business Discovery Integration

#### Customer Feature (Free/All Tiers)
- Customers can submit Black-owned business discoveries
- No paywall - available to all subscription levels
- Submit via DiscoverBlackOwnedBusinessDialog
- Fields: Business Name, Address, Category

#### Reward Structure
- 10-25 KIN Quest points per verified discovery
- Points awarded after admin verification
- No tier restriction - all customers can earn

### Admin Dashboard (Executive Dashboard)

#### AdminBeaconMetricsCard
- Active beacons (24h)
- Weekly beacon usage
- Average broadcast duration
- Mobile vendor count

#### AdminDiscoveryMetricsCard
- Pending reviews (discoveries)
- Verified businesses count
- Disputed count
- Total KIN awarded

### Tier Enforcement

#### Backend Checks
```
When owner tries to start beacon:
1. Verify user is authenticated
2. Fetch user's subscription tier
3. Check if tier is Founding Local or higher
4. Verify business is_mobile_vendor = true
5. Verify business is claimed and verified
6. Allow or deny based on checks
```

#### UI-Level Gating
- Location Beacon card only shows if `is_mobile_vendor == true`
- Start Broadcasting button only active for Founding Local+ tiers
- Community tier users see upgrade prompt instead

### Revenue Impact

- Location Beacon drives users to upgrade from Community ($0) to Founding Local ($59)
- Feature is tier-exclusive and marketing advantage
- Retention driver: businesses want customers to discover them
- Repeat usage: daily/weekly beacon activations

### Launch Checklist

- [ ] Location Beacon feature gated to Founding Local+ tiers
- [ ] Community tier users see upgrade prompt
- [ ] Beacons visible across all app surfaces (map, feed, carousels)
- [ ] Admin metrics display on Executive Dashboard
- [ ] Customer discovery form works for all tiers
- [ ] Tier information added to app marketing/help
- [ ] Support docs explain tier requirements
