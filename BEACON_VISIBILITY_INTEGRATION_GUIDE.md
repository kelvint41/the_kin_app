# Location Beacon Visibility Integration Guide

## Overview
Location Beacons should be visible throughout the app so customers can discover mobile vendors regardless of where they are browsing. This guide specifies where each beacon widget should appear and how to implement the visibility.

## Components Created

### 1. LocationBeaconBadgeWidget
**File**: `lib/components/location_beacon_badge_widget.dart`

**Purpose**: Display active beacon status on business cards/carousels

**Display Format**:
```
🚨 Now Serving [Location]
🚐 Live • Xh/m left
```

**Properties**:
- `location` (String): Current broadcast location (e.g., "5th & Main St")
- `expiresAt` (DateTime?): When beacon expires

**Styling**:
- Green success color background
- White text
- Rounded corners (8.0)
- Compact padding for card display

### 2. LocationBeaconPostWidget
**File**: `lib/components/location_beacon_post_widget.dart`

**Purpose**: Display beacon announcements in Exchange feed

**Display Format**:
```
[Business Name]
🚐 Live Now

🚨 We're live at [location]!

[📍 Find us on map] [CTA Button]

❤️ 0 reactions
```

**Properties**:
- `post` (ExchangePostsRecord): Auto-generated beacon post
- `author` (UsersRecord?): Business owner
- `business` (BusinessesRecord?): Business details

**Features**:
- Green border to distinguish from regular posts
- Auto-post when beacon activated (if enabled)
- "Find us on map" button navigation
- Reaction counter

## Integration Locations

### A. Exchange Feed (NearbyFeedWidget / ExchangeFeedWidget)

**Current Location**: `lib/pages/nearby_feed/nearby_feed_widget.dart`

**Implementation**:
```dart
// When building Exchange feed posts
if (post.postType == 'location_beacon') {
  // Display LocationBeaconPostWidget
  LocationBeaconPostWidget(
    post: post,
    author: authorData,
    business: businessData,
  )
} else {
  // Display regular post widget
  ExchangePostItemWidget(...)
}
```

**Query Filter**:
- Include posts with `postType == 'location_beacon'`
- Order by `createdAt` descending (newest first)
- Filter by active beacons only (`currentLocation != null` AND `mobileLocationActive == true`)

**Display Order**:
1. Active Location Beacon posts (at top of feed)
2. Regular Exchange posts below

### B. Business Carousels (BrowseBusinessesWidget)

**Current Location**: `lib/pages/*/business_carousel.dart` or business card widgets

**Implementation**:
```dart
// When displaying business in carousel/list
StreamBuilder<BusinessesRecord>(
  stream: BusinessesRecord.getDocument(businessRef),
  builder: (context, snapshot) {
    final business = snapshot.data;
    
    return Stack(
      children: [
        // Business card background
        BusinessCardWidget(...),
        
        // Overlay beacon badge if active
        if (business?.mobileLocationActive == true && 
            business?.currentLocation != null)
          Positioned(
            top: 8.0,
            right: 8.0,
            child: LocationBeaconBadgeWidget(
              location: business!.currentLocation!,
              expiresAt: business.currentLocationExpiresAt,
            ),
          ),
      ],
    );
  },
)
```

**Display Priority**:
- Beacon badge appears as overlay on business card
- Shows current location and countdown
- Visible in all business carousels:
  - Browse Businesses
  - Search results
  - Nearby businesses
  - Featured businesses
  - Business lists

### C. Map View (GoogleMapPage)

**Current Location**: `lib/pages/google_map/google_map_page_widget.dart`

**Implementation**:
```dart
// Instead of red marker for beacon businesses
if (business.mobileLocationActive == true) {
  // Use truck emoji marker (🚐)
  marker = Marker(
    markerId: MarkerId(business.reference.id),
    position: LatLng(business.latitude, business.longitude),
    infoWindow: InfoWindow(
      title: business.businessName,
      snippet: '🚨 Now Serving ${business.currentLocation}',
      onTap: () {
        // Navigate to business profile
      },
    ),
    // Custom marker icon with truck emoji
    icon: BitmapDescriptor.fromAsset('assets/truck_marker.png'),
  );
}
```

**Features**:
- Truck emoji (🚐) instead of red pin
- Info window shows location and time remaining
- Tap to navigate to business profile
- Cluster active beacons at top of map

**Query**:
```dart
queryBusinessesRecord(
  queryBuilder: (businesses) => businesses
    .where('mobile_location_active', isEqualTo: true)
    .where('current_location', isNotEqualTo: null),
)
```

### D. Business Detail Pages

**Locations**:
- `lib/pages/business_profile_v2/business_profile_v2_widget.dart`
- Owner Profile (`lib/pages/owner_profile/owner_profile_widget.dart`)
- Search result detail pages

**Implementation**:
```dart
// At top of business detail page
if (business.mobileLocationActive == true && 
    business.currentLocation != null) {
  LocationBeaconBadgeWidget(
    location: business.currentLocation!,
    expiresAt: business.currentLocationExpiresAt,
  )
}

// Then business details below
```

**Display Position**:
- Top of page, above business name
- Prominent so customers immediately see beacon is active
- Click "Find us on map" button to navigate to map

### E. Owner Dashboard (OwnerProfileWidget)

**Current Location**: `lib/pages/owner_profile/owner_profile_widget.dart`

**Implementation** (Already exists):
```dart
LocationBeaconCardWidget(
  businessRef: business.reference,
  businessName: business.businessName,
  isMobileVendor: business.isMobileVendor,
  currentLocation: business.currentLocation,
  expiresAt: business.currentLocationExpiresAt,
  isActive: business.mobileLocationActive,
)
```

**Features**:
- Inactive state: "Start Broadcasting" button
- Active state: Current location + countdown timer + "Stop Broadcasting" button
- Only shows for mobile vendors on Founding Local+ tiers

## Data Flow for Visibility

### When Beacon Activated

```
Owner calls startLocationBeacon()
  ↓
BusinessesRecord updated:
  - current_location = selected location
  - current_location_expires_at = expiry time
  - mobile_location_active = true
  - (optionally) creates Exchange post with auto_post=true
  ↓
All feed queries that include 'mobile_location_active == true'
auto-update via StreamBuilder
  ↓
All connected widgets re-render:
  - LocationBeaconBadgeWidget appears on carousels
  - LocationBeaconPostWidget appears in feed
  - Map marker changes to truck emoji
  - Business detail pages show beacon
```

### When Beacon Expires/Stopped

```
Beacon expires OR owner calls stopLocationBeacon()
  ↓
BusinessesRecord updated:
  - mobile_location_active = false
  - current_location = null
  ↓
All connected widgets remove beacon displays
  ↓
Normal business view returns
```

## Query Optimization

### For Carousel/Search Results
```dart
// Query to check if business has active beacon
queryBusinessesRecord(
  queryBuilder: (businesses) => businesses
    .where('mobile_location_active', isEqualTo: true)
    .limit(1000),
)
// Use in StreamBuilder to conditionally show badge
```

### For Feed Posts
```dart
// Query beacon posts in Exchange feed
queryExchangePostsRecord(
  queryBuilder: (posts) => posts
    .where('postType', isEqualTo: 'location_beacon')
    .where('created_at', isGreaterThan: DateTime.now().subtract(Duration(hours: 24)))
    .orderBy('created_at', descending: true)
    .limit(50),
)
```

### For Map Display
```dart
// Query all active beacons for map
queryBusinessesRecord(
  queryBuilder: (businesses) => businesses
    .where('mobile_location_active', isEqualTo: true)
    .where('current_location', isNotEqualTo: null)
    .limit(500),
)
```

## Tier Gating Notes

**What Customers See (All Tiers)**:
- ✅ Location beacons on map (truck emoji)
- ✅ Beacon posts in Exchange feed
- ✅ Beacon badges on business cards
- ✅ "Find us on map" CTAs
- ✅ Business discovery form

**What Vendors See**:
- Community Tier: No "Start Broadcasting" button
- Founding Local+: Full beacon feature access

**Backend Enforcement**:
- `startLocationBeacon()` checks tier before allowing activation
- Non-Founding Local+ tier calls return `ServiceResult.failure()`
- UI shows upgrade prompt if tier insufficient

## Testing Checklist

### Carousel/Search Results
- [ ] Beacon badge appears on active mobile vendor cards
- [ ] Badge shows current location
- [ ] Badge shows countdown timer
- [ ] Badge disappears when beacon expires
- [ ] Multiple active beacons display on same screen
- [ ] Badge styling matches design system (green, white text)

### Exchange Feed
- [ ] LocationBeaconPostWidget displays for beacon posts
- [ ] Post shows "🚨 We're live at [location]!" text
- [ ] Post shows business name + "🚐 Live Now" badge
- [ ] "📍 Find us on map" button is functional
- [ ] Beacon posts appear at top of feed (before regular posts)
- [ ] Old beacon posts disappear from feed after expiry

### Map View
- [ ] Truck emoji (🚐) marker instead of red pin for active beacons
- [ ] Info window shows location + time remaining
- [ ] Tap marker navigates to business profile
- [ ] Multiple beacons display on map simultaneously
- [ ] Beacons update in real-time as they expire

### Business Detail Pages
- [ ] Beacon badge appears at top of page if active
- [ ] Location and countdown display correctly
- [ ] "Find us on map" button works
- [ ] Badge disappears when beacon stops

### Owner Dashboard
- [ ] Location Beacon card only visible for mobile vendors
- [ ] LocationBeaconCardWidget shows correct status
- [ ] Countdown timer updates in real-time
- [ ] Start/Stop buttons functional

## Future Enhancements

1. **Beacon Notifications**
   - Notify nearby customers when vendor activates beacon
   - "🚨 [Business Name] just went live at [location]"

2. **Beacon Analytics**
   - Track how many customers viewed each beacon
   - Engagement metrics on owner dashboard

3. **Beacon Filtering**
   - Filter feed to show only beacons
   - Filter map to show only beacons
   - Search/sort by distance to beacon

4. **Smart Timing**
   - Suggest optimal broadcast times based on customer traffic
   - Auto-schedule recurring beacons

5. **Photo Sharing**
   - Owners can share photos while broadcasting
   - Customers see real-time updates from vendor
