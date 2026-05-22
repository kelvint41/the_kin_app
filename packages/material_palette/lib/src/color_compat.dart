import 'dart:ui';

/// Flutter 3.19 compatibility for normalized channel accessors used by shaders.
extension MaterialPaletteColorCompat on Color {
  double get r => red / 255.0;
  double get g => green / 255.0;
  double get b => blue / 255.0;
  double get a => opacity;
}
