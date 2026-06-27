import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Same horn-mascot silhouette as the mobile app's MascotIcon — kept as a
/// separate small copy here rather than in `shared` since it's a UI widget,
/// not a model (the `shared` package stays pure-Dart, no Flutter widgets).
class MascotIcon extends StatelessWidget {
  final double size;
  const MascotIcon({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _HornPainter()));
  }
}

class _HornPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Path()
      ..moveTo(w * 0.50, h * 0.04)
      ..cubicTo(w * 0.24, h * 0.22, w * 0.16, h * 0.58, w * 0.33, h * 0.92)
      ..cubicTo(w * 0.42, h * 1.00, w * 0.60, h * 0.97, w * 0.67, h * 0.80)
      ..cubicTo(w * 0.78, h * 0.53, w * 0.72, h * 0.18, w * 0.50, h * 0.04)
      ..close();
    final stripe = Path()
      ..moveTo(w * 0.48, h * 0.16)
      ..cubicTo(w * 0.36, h * 0.36, w * 0.35, h * 0.56, w * 0.44, h * 0.78);

    canvas.drawPath(body, Paint()..color = AppColors.red);
    canvas.drawPath(
      stripe,
      Paint()
        ..color = Colors.white.withValues(alpha: .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
