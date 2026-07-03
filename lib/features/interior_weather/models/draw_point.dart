import 'dart:ui';

/// Point de tracé pour le canvas Météo Intérieure.
class DrawPoint {
  const DrawPoint(this.offset, this.isDrawing);
  final Offset offset;
  final bool isDrawing;
}
