import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Network image for business photos that degrades gracefully instead of
/// crash-rendering the page.
///
/// Business photo URLs reach us from three places that all produce bad
/// values: bulk-imported records (often no photo at all), owner uploads
/// (may 404 later), and leftover FlutterFlow scaffolding that stores a
/// bare placeholder token rather than a URL - e.g.
/// `'800x400?luxury-business#1'`.
///
/// That last shape is the dangerous one: `CachedNetworkImage` throws
/// synchronously on a URI with no host ("Invalid argument(s): No host
/// specified in URI"), and because it throws during build the whole
/// surrounding screen fails to render rather than just the image. So the
/// URL is validated up front here, and anything unusable - along with any
/// runtime load failure - falls back to the KIN logo on a themed
/// background.
class BusinessImage extends StatelessWidget {
  const BusinessImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  static const String fallbackAsset = 'assets/images/kin_logo.png';

  /// Whether [url] is something `CachedNetworkImage` can actually load:
  /// an absolute http(s) URL with a host. Anything else (null, empty, a
  /// bare placeholder token, a relative path) returns false so callers
  /// render the fallback instead of throwing.
  static bool isLoadable(String? url) {
    if (url == null) return false;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Widget _fallback(BuildContext context) => Container(
        width: width,
        height: height,
        color: FlutterFlowTheme.of(context).secondaryBackground,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.asset(
            fallbackAsset,
            fit: BoxFit.contain,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!isLoadable(imageUrl)) {
      return _fallback(context);
    }
    // Caches the decoded bitmap at display size (scaled for device pixel
    // ratio) instead of full source resolution, which is often several MB
    // for an owner-uploaded photo shown in a 44x44 thumbnail.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    int? cacheDim(double? d) =>
        (d == null || !d.isFinite) ? null : (d * dpr).round();

    return CachedNetworkImage(
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      imageUrl: imageUrl!.trim(),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      memCacheWidth: cacheDim(width),
      memCacheHeight: cacheDim(height),
      errorWidget: (context, _, __) => _fallback(context),
      placeholder: (context, _) => Container(
        width: width,
        height: height,
        color: FlutterFlowTheme.of(context).secondaryBackground,
      ),
    );
  }
}
