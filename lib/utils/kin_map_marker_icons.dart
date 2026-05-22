import 'dart:ui' as ui;

import '/components/kin_business_map_pin_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Builds and caches map marker bitmaps for each ownership combination.
class KinMapMarkerIcons {
  KinMapMarkerIcons._();

  static final Map<String, BitmapDescriptor> _cache = {};

  static String _cacheKey({
    required bool isBlackOwned,
    required bool isVeteran,
  }) =>
      '$isBlackOwned|$isVeteran';

  static Future<BitmapDescriptor> forOwnership({
    required bool isBlackOwned,
    required bool isVeteran,
    double logicalSize = 56.0,
  }) async {
    final key = _cacheKey(
      isBlackOwned: isBlackOwned,
      isVeteran: isVeteran,
    );
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }

    final descriptor = await _widgetToBitmapDescriptor(
      KinBusinessMapPinIcon(
        isBlackOwned: isBlackOwned,
        isVeteran: isVeteran,
        size: logicalSize,
      ),
      logicalSize: logicalSize,
      pixelRatio: 3.0,
    );
    _cache[key] = descriptor;
    return descriptor;
  }

  static Future<BitmapDescriptor> _widgetToBitmapDescriptor(
    Widget widget, {
    required double logicalSize,
    required double pixelRatio,
  }) async {
    final repaintBoundary = RenderRepaintBoundary();
    final view = ui.PlatformDispatcher.instance.views.first;
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        physicalConstraints: BoxConstraints.tight(
          Size.square(logicalSize * pixelRatio),
        ),
        logicalConstraints: BoxConstraints.tight(Size.square(logicalSize)),
        devicePixelRatio: pixelRatio,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(
      pixelRatio: pixelRatio,
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(
      bytes,
      size: Size.square(logicalSize),
    );
  }
}
