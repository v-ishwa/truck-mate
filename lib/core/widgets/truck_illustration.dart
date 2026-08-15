import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget — renders a vehicle line-art illustration scaled to [size].
// [tyreCount] should be 4, 6, 8, 10, or 12+.
// Use [TruckIllustration.parseTyreCount] to extract the count from strings
// like "6 Tyre · Container" or "4 Tyre - Mini (Dost)".
// ─────────────────────────────────────────────────────────────────────────────

class TruckIllustration extends StatelessWidget {
  final int tyreCount;
  final Color color;
  final Size size;

  const TruckIllustration({
    super.key,
    required this.tyreCount,
    required this.color,
    this.size = const Size(200, 90),
  });

  /// Parses tyre count from strings like:
  ///   "6 Tyre · Container"  →  6
  ///   "4 Tyre - Mini (Dost)" → 4
  ///   "10 Tyre Open Body"    → 10
  static int parseTyreCount(String text) {
    final match = RegExp(r'(\d+)\s*tyre', caseSensitive: false).firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 6;
    }
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _TruckPainterFactory.forTyres(tyreCount, color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Factory
// ─────────────────────────────────────────────────────────────────────────────
class _TruckPainterFactory {
  static CustomPainter forTyres(int tyres, Color color) {
    if (tyres <= 4) return _MiniTruckPainter(color: color);
    if (tyres <= 6) return _SixTyrePainter(color: color);
    if (tyres <= 8) return _EightTyrePainter(color: color);
    if (tyres <= 10) return _TenTyrePainter(color: color);
    return _HeavyTruckPainter(color: color);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Base helpers
// ─────────────────────────────────────────────────────────────────────────────
abstract class _BaseTruckPainter extends CustomPainter {
  final Color color;
  const _BaseTruckPainter({required this.color});

  Paint get _paint => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void drawWheel(Canvas canvas, double cx, double cy, double r) {
    canvas.drawCircle(Offset(cx, cy), r, _paint);
  }

  @override
  bool shouldRepaint(covariant _BaseTruckPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. 4 TYRE — Mini / Dost  (short pickup)
// ─────────────────────────────────────────────────────────────────────────────
class _MiniTruckPainter extends _BaseTruckPainter {
  const _MiniTruckPainter({required super.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = _paint;
    final w = size.width;
    final h = size.height;
    final wr = h * 0.16;
    final gY = h * 0.72;

    // Cargo box (short)
    final box = Path()
      ..moveTo(w * 0.04, gY)
      ..lineTo(w * 0.04, gY - h * 0.38)
      ..lineTo(w * 0.52, gY - h * 0.38)
      ..lineTo(w * 0.52, gY)
      ..close();
    canvas.drawPath(box, p);

    // Cab (tall, rounded top)
    final cab = Path()
      ..moveTo(w * 0.52, gY)
      ..lineTo(w * 0.52, gY - h * 0.44)
      ..quadraticBezierTo(w * 0.58, gY - h * 0.52, w * 0.70, gY - h * 0.50)
      ..lineTo(w * 0.95, gY - h * 0.50)
      ..lineTo(w * 0.95, gY)
      ..close();
    canvas.drawPath(cab, p);

    // Windshield
    canvas.drawLine(
        Offset(w * 0.53, gY - h * 0.42),
        Offset(w * 0.70, gY - h * 0.48), p);

    // 4 wheels (rear single, rear2, front single) — close together
    drawWheel(canvas, w * 0.18, gY, wr);
    drawWheel(canvas, w * 0.38, gY, wr);
    drawWheel(canvas, w * 0.77, gY, wr);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. 6 TYRE — Standard container/covered truck
// ─────────────────────────────────────────────────────────────────────────────
class _SixTyrePainter extends _BaseTruckPainter {
  const _SixTyrePainter({required super.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = _paint;
    final w = size.width;
    final h = size.height;
    final wr = h * 0.15;
    final gY = h * 0.72;

    // Trailer body
    final trailer = Path()
      ..moveTo(w * 0.02, gY)
      ..lineTo(w * 0.02, gY - h * 0.42)
      ..lineTo(w * 0.60, gY - h * 0.42)
      ..lineTo(w * 0.60, gY);
    canvas.drawPath(trailer, p);
    canvas.drawLine(Offset(w * 0.02, gY), Offset(w * 0.60, gY), p);

    // Cab
    final cab = Path()
      ..moveTo(w * 0.60, gY)
      ..lineTo(w * 0.60, gY - h * 0.34)
      ..lineTo(w * 0.72, gY - h * 0.44)
      ..lineTo(w * 0.96, gY - h * 0.44)
      ..lineTo(w * 0.96, gY)
      ..close();
    canvas.drawPath(cab, p);

    // Windshield
    final ws = Path()
      ..moveTo(w * 0.61, gY - h * 0.32)
      ..lineTo(w * 0.71, gY - h * 0.42)
      ..lineTo(w * 0.96, gY - h * 0.42);
    canvas.drawPath(ws, p);

    // Wheels: rear dual + mid + front
    drawWheel(canvas, w * 0.14, gY, wr);
    drawWheel(canvas, w * 0.26, gY, wr);
    canvas.drawLine(Offset(w * 0.14, gY), Offset(w * 0.26, gY), p);
    drawWheel(canvas, w * 0.45, gY, wr);
    drawWheel(canvas, w * 0.80, gY, wr);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. 8 TYRE — Tipper / tanker (medium-heavy)
// ─────────────────────────────────────────────────────────────────────────────
class _EightTyrePainter extends _BaseTruckPainter {
  const _EightTyrePainter({required super.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = _paint;
    final w = size.width;
    final h = size.height;
    final wr = h * 0.13;
    final gY = h * 0.74;

    // Tipper body (slight forward tilt at top)
    final body = Path()
      ..moveTo(w * 0.02, gY)
      ..lineTo(w * 0.02, gY - h * 0.46)
      ..lineTo(w * 0.08, gY - h * 0.50)
      ..lineTo(w * 0.60, gY - h * 0.50)
      ..lineTo(w * 0.60, gY);
    canvas.drawPath(body, p);
    canvas.drawLine(Offset(w * 0.02, gY), Offset(w * 0.60, gY), p);

    // Cab
    final cab = Path()
      ..moveTo(w * 0.60, gY)
      ..lineTo(w * 0.60, gY - h * 0.36)
      ..lineTo(w * 0.73, gY - h * 0.46)
      ..lineTo(w * 0.97, gY - h * 0.46)
      ..lineTo(w * 0.97, gY)
      ..close();
    canvas.drawPath(cab, p);

    canvas.drawLine(
        Offset(w * 0.61, gY - h * 0.34), Offset(w * 0.72, gY - h * 0.44), p);
    canvas.drawLine(
        Offset(w * 0.72, gY - h * 0.44), Offset(w * 0.97, gY - h * 0.44), p);

    // 8 Wheels: 2 dual rear axles + 1 front dual
    drawWheel(canvas, w * 0.09, gY, wr);
    drawWheel(canvas, w * 0.19, gY, wr);
    canvas.drawLine(Offset(w * 0.09, gY), Offset(w * 0.19, gY), p);

    drawWheel(canvas, w * 0.33, gY, wr);
    drawWheel(canvas, w * 0.43, gY, wr);
    canvas.drawLine(Offset(w * 0.33, gY), Offset(w * 0.43, gY), p);

    drawWheel(canvas, w * 0.80, gY, wr);
    drawWheel(canvas, w * 0.89, gY, wr);
    canvas.drawLine(Offset(w * 0.80, gY), Offset(w * 0.89, gY), p);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. 10 TYRE — Large open-body truck
// ─────────────────────────────────────────────────────────────────────────────
class _TenTyrePainter extends _BaseTruckPainter {
  const _TenTyrePainter({required super.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = _paint;
    final w = size.width;
    final h = size.height;
    final wr = h * 0.13;
    final gY = h * 0.76;

    // Open body (walls, no roof)
    final openBody = Path()
      ..moveTo(w * 0.02, gY - h * 0.50)
      ..lineTo(w * 0.02, gY)
      ..lineTo(w * 0.59, gY)
      ..lineTo(w * 0.59, gY - h * 0.50);
    canvas.drawPath(openBody, p);
    // Top edge markers
    canvas.drawLine(Offset(w * 0.02, gY - h * 0.50),
        Offset(w * 0.07, gY - h * 0.50), p);
    canvas.drawLine(Offset(w * 0.54, gY - h * 0.50),
        Offset(w * 0.59, gY - h * 0.50), p);

    // Cab
    final cab = Path()
      ..moveTo(w * 0.59, gY)
      ..lineTo(w * 0.59, gY - h * 0.38)
      ..lineTo(w * 0.72, gY - h * 0.48)
      ..lineTo(w * 0.97, gY - h * 0.48)
      ..lineTo(w * 0.97, gY)
      ..close();
    canvas.drawPath(cab, p);
    canvas.drawLine(Offset(w * 0.60, gY - h * 0.36),
        Offset(w * 0.71, gY - h * 0.45), p);
    canvas.drawLine(Offset(w * 0.71, gY - h * 0.45),
        Offset(w * 0.97, gY - h * 0.45), p);

    // 10 Wheels: 3 rear axles + 1 front dual
    drawWheel(canvas, w * 0.07, gY, wr);
    drawWheel(canvas, w * 0.16, gY, wr);
    canvas.drawLine(Offset(w * 0.07, gY), Offset(w * 0.16, gY), p);

    drawWheel(canvas, w * 0.27, gY, wr);
    drawWheel(canvas, w * 0.36, gY, wr);
    canvas.drawLine(Offset(w * 0.27, gY), Offset(w * 0.36, gY), p);

    drawWheel(canvas, w * 0.47, gY, wr);

    drawWheel(canvas, w * 0.79, gY, wr);
    drawWheel(canvas, w * 0.88, gY, wr);
    canvas.drawLine(Offset(w * 0.79, gY), Offset(w * 0.88, gY), p);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. 12+ TYRE — Heavy semi-trailer
// ─────────────────────────────────────────────────────────────────────────────
class _HeavyTruckPainter extends _BaseTruckPainter {
  const _HeavyTruckPainter({required super.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = _paint;
    final w = size.width;
    final h = size.height;
    final wr = h * 0.12;
    final gY = h * 0.76;

    // Long trailer
    final trailer = Path()
      ..moveTo(w * 0.01, gY)
      ..lineTo(w * 0.01, gY - h * 0.48)
      ..lineTo(w * 0.56, gY - h * 0.48)
      ..lineTo(w * 0.56, gY);
    canvas.drawPath(trailer, p);
    canvas.drawLine(Offset(w * 0.01, gY), Offset(w * 0.56, gY), p);

    // Kingpin connector
    canvas.drawLine(Offset(w * 0.56, gY - h * 0.10),
        Offset(w * 0.60, gY - h * 0.10), p);

    // Tractor unit
    final tractor = Path()
      ..moveTo(w * 0.60, gY)
      ..lineTo(w * 0.60, gY - h * 0.40)
      ..lineTo(w * 0.72, gY - h * 0.50)
      ..lineTo(w * 0.97, gY - h * 0.50)
      ..lineTo(w * 0.97, gY)
      ..close();
    canvas.drawPath(tractor, p);
    canvas.drawLine(Offset(w * 0.61, gY - h * 0.38),
        Offset(w * 0.71, gY - h * 0.47), p);
    canvas.drawLine(Offset(w * 0.71, gY - h * 0.47),
        Offset(w * 0.97, gY - h * 0.47), p);

    // 12 Wheels
    drawWheel(canvas, w * 0.06, gY, wr);
    drawWheel(canvas, w * 0.14, gY, wr);
    canvas.drawLine(Offset(w * 0.06, gY), Offset(w * 0.14, gY), p);

    drawWheel(canvas, w * 0.22, gY, wr);
    drawWheel(canvas, w * 0.30, gY, wr);
    canvas.drawLine(Offset(w * 0.22, gY), Offset(w * 0.30, gY), p);

    drawWheel(canvas, w * 0.39, gY, wr);
    drawWheel(canvas, w * 0.47, gY, wr);
    canvas.drawLine(Offset(w * 0.39, gY), Offset(w * 0.47, gY), p);

    drawWheel(canvas, w * 0.65, gY, wr);
    drawWheel(canvas, w * 0.73, gY, wr);
    canvas.drawLine(Offset(w * 0.65, gY), Offset(w * 0.73, gY), p);

    drawWheel(canvas, w * 0.84, gY, wr);
    drawWheel(canvas, w * 0.92, gY, wr);
    canvas.drawLine(Offset(w * 0.84, gY), Offset(w * 0.92, gY), p);
  }
}
