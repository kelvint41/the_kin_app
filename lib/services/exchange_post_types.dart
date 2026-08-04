import 'package:flutter/material.dart';

/// One selectable category for an Exchange post from a verified business
/// owner, and the call-to-action it implies on the feed card. Selecting a
/// type is optional - a plain post has no post_type/cta_type and renders
/// exactly as it always has.
///
/// ctaType/ctaLabel are fixed per type rather than owner-chosen: pairing
/// 'Flash Offer'/'Schedule Update' with Get Directions (come see this in
/// person, now) and 'New Inventory'/'Behind the Scenes' with View Menu/
/// Services (browse first) is a judgment call, not something in the
/// original request - worth revisiting once there's real usage data on
/// which CTA each type actually drives taps for.
class ExchangePostType {
  const ExchangePostType({
    required this.key,
    required this.label,
    required this.icon,
    required this.ctaType,
    required this.ctaLabel,
  });

  /// Stored in ExchangePostsRecord.postType.
  final String key;
  final String label;
  final IconData icon;

  /// Stored in ExchangePostsRecord.ctaType. 'view_business' pushes to the
  /// tagged business's profile; 'get_directions' opens the device's map
  /// app via launchMap (flutter_flow_util.dart).
  final String ctaType;
  final String ctaLabel;
}

const kExchangePostTypes = <ExchangePostType>[
  ExchangePostType(
    key: 'new_inventory',
    label: 'New Inventory',
    icon: Icons.inventory_2_outlined,
    ctaType: 'view_business',
    ctaLabel: 'View Menu/Services',
  ),
  ExchangePostType(
    key: 'flash_offer',
    label: 'Flash Offer',
    icon: Icons.flash_on_rounded,
    ctaType: 'get_directions',
    ctaLabel: 'Get Directions',
  ),
  ExchangePostType(
    key: 'schedule_update',
    label: 'Schedule Update',
    icon: Icons.event_outlined,
    ctaType: 'get_directions',
    ctaLabel: 'Get Directions',
  ),
  ExchangePostType(
    key: 'behind_the_scenes',
    label: 'Behind the Scenes',
    icon: Icons.camera_alt_outlined,
    ctaType: 'view_business',
    ctaLabel: 'View Menu/Services',
  ),
];

/// Looks up the display info for a stored post_type key. Null for a plain
/// post (empty/missing key) or a key that no longer matches this list -
/// never throws on drift between this list and old data, so an outdated
/// tag just quietly stops rendering a CTA instead of crashing the feed.
ExchangePostType? exchangePostTypeForKey(String? key) {
  if (key == null || key.isEmpty) return null;
  for (final type in kExchangePostTypes) {
    if (type.key == key) return type;
  }
  return null;
}
