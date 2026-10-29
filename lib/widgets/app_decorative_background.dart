import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Fondo decorativo compartido por Historial, Compras y Alertas: un círculo
/// tenue arriba y dos cuadrados grandes (uno girado) abajo a la izquierda.
/// Va detrás del contenido y no intercepta gestos.
class AppDecorativeBackground extends StatelessWidget {
  const AppDecorativeBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _DecorationPainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DecorationPainter extends CustomPainter {
  const _DecorationPainter();

  // Medidas del canvas de Figma; todo se escala a partir de este ancho y alto.
  static const double _figmaWidth = 428;
  static const double _figmaHeight = 926;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _figmaWidth;
    final scaleY = size.height / _figmaHeight;
    final scale = math.min(scaleX, scaleY);

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..color = AppColors.subtleSurface;
    final squarePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..color = AppColors.outlineColor;

    // Círculo de 496 x 496 en x=23, y=-171.
    const radius = 248.0;
    canvas.drawCircle(
      Offset((23 + radius) * scaleX, (-171 + radius) * scaleY),
      radius * scale,
      circlePaint,
    );

    // Cuadrados de 372 x 372 anclados al borde inferior. El spec no da su
    // posición exacta, así que se ubican de forma aproximada.
    final side = 372 * scale;
    _drawSquare(
      canvas,
      squarePaint,
      center: Offset(-20 * scaleX, size.height - 120 * scaleY),
      side: side,
      angle: 0,
    );
    _drawSquare(
      canvas,
      squarePaint,
      center: Offset(70 * scaleX, size.height - 40 * scaleY),
      side: side,
      angle: 16 * math.pi / 180,
    );
  }

  void _drawSquare(
    Canvas canvas,
    Paint paint, {
    required Offset center,
    required double side,
    required double angle,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: side, height: side),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DecorationPainter oldDelegate) => false;
}
